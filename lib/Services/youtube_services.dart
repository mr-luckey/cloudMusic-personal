// Coded by Naseer Ahmed

import 'dart:convert';
import 'dart:io';

import 'package:blackhole/Services/yt_music.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeServices {
  static const String searchAuthority = 'www.youtube.com';
  static const Map paths = {
    'search': '/results',
    'channel': '/channel',
    'music': '/music',
    'playlist': '/playlist',
  };
  static const Map<String, String> headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; rv:96.0) Gecko/20100101 Firefox/96.0',
  };
  final YoutubeExplode yt = YoutubeExplode();

  YouTubeServices._privateConstructor();

  static final YouTubeServices _instance =
      YouTubeServices._privateConstructor();

  static YouTubeServices get instance {
    return _instance;
  }

  Future<List<Video>> getPlaylistSongs(String id) async {
    final List<Video> results = await yt.playlists.getVideos(id).toList();
    return results;
  }

  Future<Video?> getVideoFromId(String id) async {
    try {
      final Video result = await yt.videos.get(id);
      return result;
    } catch (e) {
      Logger.root.severe('Error while getting video from id', e);
      return null;
    }
  }

  Future<Map?> formatVideoFromId({
    required String id,
    Map? data,
    bool? getUrl,
  }) async {
    try {
      // Retry logic to handle transient errors
      int retryCount = 0;
      const maxRetries = 2;
      Video? vid;

      while (retryCount <= maxRetries) {
        try {
          if (retryCount > 0) {
            await Future.delayed(Duration(milliseconds: 300 * retryCount));
          }
          vid = await getVideoFromId(id);
          if (vid != null) break;
        } catch (e) {
          if (retryCount >= maxRetries) {
            return null;
          }
        }
        retryCount++;
      }

      if (vid == null) {
        return null;
      }

      if (vid.duration != null && vid.duration!.inSeconds > 600) {}

      final String quality = Hive.box('settings')
          .get(
            'ytQuality',
            defaultValue: 'Low',
          )
          .toString();

      // Always get URL when formatVideoFromId is called (user clicked to play)
      final Map? response = await formatVideo(
        video: vid,
        quality: quality,
        data: data,
        getUrl: getUrl ?? true,
      );

      if (response == null) {
        Logger.root.warning(
            'formatVideo returned null for video $id - unable to format video data');
        return null;
      }

      // Validate URL is present
      if (response['url'] == null || response['url'].toString().isEmpty) {
        Logger.root.warning(
            'No valid URL found in response for video $id - stream URL is missing or empty');
        return null;
      }

      Logger.root.info('Successfully formatted video $id with valid URL');
      return response;
    } catch (e, stackTrace) {
      Logger.root.severe(
          'Error in formatVideoFromId for $id: ${e.toString()}', e, stackTrace);
      return null;
    }
  }

  Future<Map?> refreshLink(String id, {bool useYTM = true}) async {
    try {
      String quality;
      try {
        if (Hive.isBoxOpen('settings')) {
          quality = Hive.box('settings')
              .get('ytQuality', defaultValue: 'Low')
              .toString();
        } else {
          quality = 'Low';
        }
      } catch (e) {
        Logger.root.warning('Error reading ytQuality setting, using Low', e);
        quality = 'Low';
      }

      // 1) Try via YouTube Music API (often better metadata)
      if (useYTM) {
        try {
          final Map ytmRes = await YtMusicService()
              .getSongData(
            videoId: id,
            quality: quality,
          )
              .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              Logger.root.warning('YTM getSongData timeout for $id');
              return <String, dynamic>{};
            },
          );
          // Validate that we got a valid response with URL
          if (ytmRes.isNotEmpty &&
              ytmRes['url'] != null &&
              ytmRes['url'].toString().isNotEmpty) {
            return ytmRes;
          } else {
            Logger.root.warning(
              'YTM refreshLink returned empty/invalid response for $id, falling back to direct YouTubeExplode',
            );
            // Fall through to direct YouTubeExplode flow instead of returning null
          }
        } catch (e, stackTrace) {
          Logger.root.warning(
            'Error in YTM getSongData for $id, falling back to direct YouTubeExplode',
            e,
            stackTrace,
          );
          // Fall through to direct YouTubeExplode flow
        }
      }

      // 2) Fallback: direct YouTubeExplode stream info (more reliable for some long videos)
      try {
        final Video? directVideo = await getVideoFromId(id).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            Logger.root.warning('getVideoFromId timeout for $id');
            return null;
          },
        );
        if (directVideo == null) {
          Logger.root.warning('Failed to get video from ID (direct): $id');
          return null;
        }
        final Map? directData = await formatVideo(
          video: directVideo,
          quality: quality,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            Logger.root.warning('formatVideo timeout for $id');
            return null;
          },
        );
        // Validate that we got a valid response with URL
        if (directData != null &&
            directData['url'] != null &&
            directData['url'].toString().isNotEmpty) {
          return directData;
        } else {
          Logger.root.warning(
            'Direct formatVideo returned empty or invalid response for $id',
          );
          return null;
        }
      } catch (e, stackTrace) {
        Logger.root.warning(
          'Error in direct YouTubeExplode flow for $id',
          e,
          stackTrace,
        );
        return null;
      }
    } catch (e, stackTrace) {
      Logger.root.severe('Error in refreshLink for $id', e, stackTrace);
      return null;
    }
  }

  Future<Playlist> getPlaylistDetails(String id) async {
    final Playlist metadata = await yt.playlists.get(id);
    return metadata;
  }

  Future<Map<String, List>> getMusicHome() async {
    final Uri link = Uri.https(
      searchAuthority,
      paths['music'].toString(),
    );
    try {
      final Response response = await get(link);
      if (response.statusCode != 200) {
        return {};
      }
      final String searchResults =
          RegExp(r'(\"contents\":{.*?}),\"metadata\"', dotAll: true)
              .firstMatch(response.body)![1]!;
      final Map data = json.decode('{$searchResults}') as Map;

      final List result = data['contents']['twoColumnBrowseResultsRenderer']
              ['tabs'][0]['tabRenderer']['content']['sectionListRenderer']
          ['contents'] as List;

      final List headResult = data['header']['carouselHeaderRenderer']
          ['contents'][0]['carouselItemRenderer']['carouselItems'] as List;

      final List shelfRenderer = result.map((element) {
        return element['itemSectionRenderer']['contents'][0]['shelfRenderer'];
      }).toList();

      final List finalResult = shelfRenderer.map((element) {
        final playlistItems = element['title']['runs'][0]['text'].trim() ==
                    'Charts' ||
                element['title']['runs'][0]['text'].trim() == 'Classements'
            ? formatChartItems(
                element['content']['horizontalListRenderer']['items'] as List,
              )
            : element['title']['runs'][0]['text']
                        .toString()
                        .contains('Music Videos') ||
                    element['title']['runs'][0]['text']
                        .toString()
                        .contains('Nouveaux clips') ||
                    element['title']['runs'][0]['text']
                        .toString()
                        .contains('En Musique Avec Moi') ||
                    element['title']['runs'][0]['text']
                        .toString()
                        .contains('Performances Uniques')
                ? formatVideoItems(
                    element['content']['horizontalListRenderer']['items']
                        as List,
                  )
                : formatItems(
                    element['content']['horizontalListRenderer']['items']
                        as List,
                  );
        if (playlistItems.isNotEmpty) {
          return {
            'title': element['title']['runs'][0]['text'],
            'playlists': playlistItems,
          };
        } else {
          Logger.root.severe(
            "got null in getMusicHome for '${element['title']['runs'][0]['text']}'",
          );
          return null;
        }
      }).toList();

      final List finalHeadResult = formatHeadItems(headResult);
      finalResult.removeWhere((element) => element == null);

      return {'body': finalResult, 'head': finalHeadResult};
    } catch (e) {
      Logger.root.severe('Error in getMusicHome: $e');
      return {};
    }
  }

  Future<List> getSearchSuggestions({required String query}) async {
    const baseUrl =
        'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=';
    // 'https://invidious.snopyta.org/api/v1/search/suggestions?q=';
    final Uri link = Uri.parse(baseUrl + query);
    try {
      final Response response = await get(link, headers: headers);
      if (response.statusCode != 200) {
        return [];
      }
      final unescape = HtmlUnescape();
      // final Map res = jsonDecode(response.body) as Map;
      final List res = (jsonDecode(response.body) as List)[1] as List;
      // return (res['suggestions'] as List).map((e) => unescape.convert(e.toString())).toList();
      return res.map((e) => unescape.convert(e.toString())).toList();
    } catch (e) {
      Logger.root.severe('Error in getSearchSuggestions: $e');
      return [];
    }
  }

  List formatVideoItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['gridVideoRenderer']['title']['simpleText'],
          'type': 'video',
          'description': e['gridVideoRenderer']['shortBylineText']['runs'][0]
              ['text'],
          'count': e['gridVideoRenderer']['shortViewCountText']['simpleText'],
          'videoId': e['gridVideoRenderer']['videoId'],
          'firstItemId': e['gridVideoRenderer']['videoId'],
          'image':
              e['gridVideoRenderer']['thumbnail']['thumbnails'].last['url'],
          'imageMin': e['gridVideoRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageMedium': e['gridVideoRenderer']['thumbnail']['thumbnails'][1]
              ['url'],
          'imageStandard': e['gridVideoRenderer']['thumbnail']['thumbnails'][2]
              ['url'],
          'imageMax':
              e['gridVideoRenderer']['thumbnail']['thumbnails'].last['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      Logger.root.severe('Error in formatVideoItems: $e');
      return List.empty();
    }
  }

  List formatChartItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['gridPlaylistRenderer']['title']['runs'][0]['text'],
          'type': 'chart',
          'description': e['gridPlaylistRenderer']['shortBylineText']['runs'][0]
              ['text'],
          'count': e['gridPlaylistRenderer']['videoCountText']['runs'][0]
              ['text'],
          'playlistId': e['gridPlaylistRenderer']['navigationEndpoint']
              ['watchEndpoint']['playlistId'],
          'firstItemId': e['gridPlaylistRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'image': e['gridPlaylistRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageMedium': e['gridPlaylistRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageStandard': e['gridPlaylistRenderer']['thumbnail']['thumbnails']
              [0]['url'],
          'imageMax': e['gridPlaylistRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      Logger.root.severe('Error in formatChartItems: $e');
      return List.empty();
    }
  }

  List formatItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['compactStationRenderer']['title']['simpleText'],
          'type': 'playlist',
          'description': e['compactStationRenderer']['description']
              ['simpleText'],
          'count': e['compactStationRenderer']['videoCountText']['runs'][0]
              ['text'],
          'playlistId': e['compactStationRenderer']['navigationEndpoint']
                  ['watchEndpoint']?['playlistId'] ??
              e['compactStationRenderer']['navigationEndpoint']
                  ['watchPlaylistEndpoint']['playlistId'],
          'firstItemId': e['compactStationRenderer']['navigationEndpoint']
              ['watchEndpoint']?['videoId'],
          'image': e['compactStationRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageMedium': e['compactStationRenderer']['thumbnail']['thumbnails']
              [0]['url'],
          'imageStandard': e['compactStationRenderer']['thumbnail']
              ['thumbnails'][1]['url'],
          'imageMax': e['compactStationRenderer']['thumbnail']['thumbnails'][2]
              ['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      Logger.root.severe('Error in formatItems: $e');
      return List.empty();
    }
  }

  List formatHeadItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['defaultPromoPanelRenderer']['title']['runs'][0]['text'],
          'type': 'video',
          'description':
              (e['defaultPromoPanelRenderer']['description']['runs'] as List)
                  .map((e) => e['text'])
                  .toList()
                  .join(),
          'videoId': e['defaultPromoPanelRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'firstItemId': e['defaultPromoPanelRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'image': e['defaultPromoPanelRenderer']
                          ['largeFormFactorBackgroundThumbnail']
                      ['thumbnailLandscapePortraitRenderer']['landscape']
                  ['thumbnails']
              .last['url'],
          'imageMedium': e['defaultPromoPanelRenderer']
                      ['largeFormFactorBackgroundThumbnail']
                  ['thumbnailLandscapePortraitRenderer']['landscape']
              ['thumbnails'][1]['url'],
          'imageStandard': e['defaultPromoPanelRenderer']
                      ['largeFormFactorBackgroundThumbnail']
                  ['thumbnailLandscapePortraitRenderer']['landscape']
              ['thumbnails'][2]['url'],
          'imageMax': e['defaultPromoPanelRenderer']
                          ['largeFormFactorBackgroundThumbnail']
                      ['thumbnailLandscapePortraitRenderer']['landscape']
                  ['thumbnails']
              .last['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      Logger.root.severe('Error in formatHeadItems: $e');
      return List.empty();
    }
  }

  Future<Map?> formatVideo({
    required Video video,
    required String quality,
    Map? data,
    bool getUrl = true,
    // bool preferM4a = true,
  }) async {
    // Handle null duration gracefully
    final int? durationSeconds = video.duration?.inSeconds;
    if (durationSeconds == null) {
      // Don't return null immediately, try to get duration from stream info if available
    }

    if (durationSeconds != null && durationSeconds > 600) {}

    List<String> allUrls = [];
    List<Map> urlsData = [];
    String finalUrl = '';
    String expireAt = '0';

    if (getUrl) {
      try {
        urlsData = await getYtStreamUrls(video.id.value);

        if (urlsData.isEmpty) {
          Logger.root
              .severe('No stream URLs available for video ${video.id.value}');
          return null; // Return null if no URLs are available
        }

        // Select quality - prefer middle quality for better reliability
        final Map finalUrlData;
        if (quality == 'High' && urlsData.length > 1) {
          finalUrlData = urlsData.last;
        } else if (quality == 'Low' && urlsData.length > 1) {
          finalUrlData = urlsData.first;
        } else {
          // Default to first available
          finalUrlData = urlsData.first;
        }

        finalUrl = finalUrlData['url']?.toString() ?? '';
        expireAt = finalUrlData['expireAt']?.toString() ??
            (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600 * 5)
                .toString();
        allUrls = urlsData
            .map((e) => e['url']?.toString() ?? '')
            .where((url) => url.isNotEmpty)
            .toList();

        // Validate URL
        if (finalUrl.isEmpty) {
          if (urlsData.isNotEmpty) {
            // Try to find any valid URL
            for (final urlData in urlsData) {
              final url = urlData['url']?.toString() ?? '';
              if (url.isNotEmpty) {
                finalUrl = url;
                expireAt = urlData['expireAt']?.toString() ?? expireAt;
                break;
              }
            }
          }
        }
      } catch (e) {
        return null;
      }
    }

    // Safely access video properties that might be null at runtime
    // (despite type annotations suggesting otherwise)
    String videoTitle;
    String videoAuthor;
    String? channelId;

    try {
      videoTitle = video.title.trim();
    } catch (e) {
      Logger.root.warning('Video title is null for ${video.id.value}');
      videoTitle = 'Unknown Title';
    }

    try {
      videoAuthor = video.author.replaceAll('- Topic', '').trim();
    } catch (e) {
      Logger.root.warning('Video author is null for ${video.id.value}');
      videoAuthor = 'Unknown Artist';
    }

    try {
      channelId = video.channelId.value;
    } catch (e) {
      Logger.root.warning('Video channelId is null for ${video.id.value}');
      channelId = null;
    }

    final String videoId = video.id.value;
    final String? thumbnailMaxRes = video.thumbnails.maxResUrl;
    final String? thumbnailHighRes = video.thumbnails.highResUrl;
    final String? videoUrl = video.url;
    final String? publishDateStr = video.publishDate?.toString();
    final String? yearStr = video.uploadDate?.year.toString();

    // Safely access data map properties
    final String album = (data != null &&
            data['album'] != null &&
            data['album'].toString().isNotEmpty)
        ? data['album'].toString()
        : videoAuthor;

    final String title = (data != null &&
            data['title'] != null &&
            data['title'].toString().isNotEmpty)
        ? data['title'].toString()
        : videoTitle;

    final String artist = (data != null &&
            data['artist'] != null &&
            data['artist'].toString().isNotEmpty)
        ? data['artist'].toString()
        : videoAuthor;

    final String subtitle = (data != null &&
            data['subtitle'] != null &&
            data['subtitle'].toString().isNotEmpty)
        ? data['subtitle'].toString()
        : videoAuthor;

    return {
      'id': videoId,
      'album': album,
      'duration':
          durationSeconds?.toString() ?? data?['duration']?.toString() ?? '180',
      'title': title,
      'artist': artist,
      'image': thumbnailMaxRes ?? thumbnailHighRes ?? '',
      'secondImage': thumbnailHighRes ?? thumbnailMaxRes ?? '',
      'language': 'YouTube',
      'genre': 'YouTube',
      'expire_at': expireAt,
      'url': finalUrl,
      'allUrls': allUrls,
      'urlsData': urlsData,
      'year': yearStr,
      '320kbps': 'false',
      'has_lyrics': 'false',
      'release_date': publishDateStr ?? '',
      'album_id': channelId ?? '',
      'subtitle': subtitle,
      'perma_url': videoUrl ?? '',
    };
  }

  Future<List<Map>> fetchSearchResults(String query) async {
    try {
      final List<Video> searchResults = await yt.search.search(query);
      final List<Map> videoResult = [];
      for (final Video vid in searchResults) {
        try {
          // Don't fetch URLs in search to reduce loading time - will fetch when clicked
          final res =
              await formatVideo(video: vid, quality: 'Low', getUrl: false);
          if (res != null && res.isNotEmpty) {
            videoResult.add(res);
          }
        } catch (e, stackTrace) {
          // Check if it's a null check error (likely from formatVideo)
          final String errorStr = e.toString();
          if (errorStr.contains('Null check operator used on a null value')) {
            Logger.root.warning(
              'Null check error formatting video ${vid.id.value} in search (possible API change): $e',
            );
          } else {
            Logger.root.warning(
              'Error formatting video ${vid.id.value} in search: $e',
              e,
              stackTrace,
            );
          }
          // Continue with other videos
        }
      }
      return [
        {
          'title': 'Videos',
          'items': videoResult,
          'allowViewAll': false,
        }
      ];
    } catch (e, stackTrace) {
      final String errorStr = e.toString();
      if (errorStr.contains('Null check operator used on a null value')) {
        Logger.root.severe(
          'Null check error in fetchSearchResults (possible API change): $e',
          e,
          stackTrace,
        );
      } else {
        Logger.root.severe(
          'Error in fetchSearchResults: $e',
          e,
          stackTrace,
        );
      }
      return [
        {
          'title': 'Videos',
          'items': [],
          'allowViewAll': false,
        }
      ];
    }
  }

  String getExpireAt(String url) {
    try {
      final match = RegExp(r'expire=(\d+)&').firstMatch(url);
      if (match != null && match.group(1) != null) {
        final expireAt = match.group(1)!;
        return expireAt;
      } else {
        final fallback =
            (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600 * 5.5)
                .toString();
        return fallback;
      }
    } catch (e) {
      final fallback =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600 * 5.5)
              .toString();
      return fallback;
    }
  }

  Future<List<Map>> getYtStreamUrls(String videoId) async {
    try {
      List<Map> urlData = [];

      // check cache first
      if (!Hive.isBoxOpen('ytlinkcache')) {
      } else if (Hive.box('ytlinkcache').containsKey(videoId)) {
        final cachedData = Hive.isBoxOpen('ytlinkcache')
            ? Hive.box('ytlinkcache').get(videoId)
            : null;

        if (cachedData is List) {
          int minExpiredAt = 0;

          for (final e in cachedData) {
            try {
              final int cachedExpiredAt = int.parse(e['expireAt'].toString());
              if (minExpiredAt == 0 || cachedExpiredAt < minExpiredAt) {
                minExpiredAt = cachedExpiredAt;
              }
            } catch (e) {
              // Invalid expireAt format, treat as expired
              minExpiredAt = 0;
              break;
            }
          }

          final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          if (currentTime + 350 > minExpiredAt) {
            urlData = await getUri(videoId);
          } else {
            Logger.root.info('cache found for $videoId');
            urlData = cachedData as List<Map>;
          }
        } else {
          urlData = await getUri(videoId);
        }
      } else {
        urlData = await getUri(videoId);
      }

      if (urlData.isNotEmpty) {
        for (int i = 0; i < urlData.length; i++) {}
      }

      // Cache the results
      try {
        if (Hive.isBoxOpen('ytlinkcache')) {
          await Hive.box('ytlinkcache')
              .put(
            videoId,
            urlData,
          )
              .onError(
            (error, stackTrace) {
              Logger.root.warning(
                'Hive Error saving cache for $videoId',
                error,
                stackTrace,
              );
            },
          );
        } else {}
      } catch (e, stackTrace) {
        Logger.root.warning(
          'Hive Error saving cache for $videoId',
          e,
          stackTrace,
        );
      }

      return urlData;
    } catch (e, stackTrace) {
      final String errorStr = e.toString();
      if (errorStr.contains('Null check operator used on a null value')) {
        // This is usually caused by a YouTube API / response change or a bug
        // inside the youtube_explode_dart package. Treat it as a soft failure
        // for this particular video instead of a hard app error.
        Logger.root.warning(
          'Error in getYtStreamUrls (likely manifest/null API issue): $errorStr',
          e,
          stackTrace,
        );
      } else {
        Logger.root.severe(
          'Error in getYtStreamUrls: $errorStr',
          e,
          stackTrace,
        );
      }
      return [];
    }
  }

  Future<List<Map>> getUri(
    String videoId,
    // {bool preferM4a = true}
  ) async {
    try {
      Logger.root.fine('Getting stream URIs for video $videoId');
      final List<AudioOnlyStreamInfo> sortedStreamInfo =
          await getStreamInfo(videoId);

      final result = sortedStreamInfo
          .map(
            (e) => {
              'bitrate': e.bitrate.kiloBitsPerSecond.round().toString(),
              'codec': e.codec.subtype,
              'qualityLabel': e.qualityLabel,
              'size': e.size.totalMegaBytes.toStringAsFixed(2),
              'url': e.url.toString(),
              'expireAt': getExpireAt(e.url.toString()),
            },
          )
          .toList();

      Logger.root.info(
          'Successfully extracted ${result.length} stream URLs for video $videoId');
      return result;
    } catch (e, stackTrace) {
      Logger.root.severe(
          'Error getting stream URIs for video $videoId', e, stackTrace);
      rethrow;
    }
  }

  Future<List<AudioOnlyStreamInfo>> getStreamInfo(
    String videoId, {
    bool onlyMp4 = false,
  }) async {
    // Retry logic to handle transient errors
    int retryCount = 0;
    const maxRetries = 2;
    Exception? lastError;

    while (retryCount <= maxRetries) {
      // Create a fresh YoutubeExplode instance for each attempt
      // This prevents state corruption from previous requests
      YoutubeExplode? freshYt;

      try {
        if (retryCount > 0) {
          Logger.root.info(
              'Retrying stream manifest retrieval for $videoId (attempt ${retryCount + 1}/${maxRetries + 1})');
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }

        Logger.root.fine('Getting stream manifest for video $videoId');

        // CRITICAL FIX: Create fresh instance to avoid state corruption
        freshYt = YoutubeExplode();

        // Add timeout to prevent hanging
        final StreamManifest manifest = await freshYt.videos.streamsClient
            .getManifest(VideoId(videoId))
            .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            Logger.root.warning(
                'Stream manifest retrieval timeout for video $videoId');
            throw Exception(
                'Timeout while getting stream manifest for video $videoId');
          },
        );

        final List<AudioOnlyStreamInfo> sortedStreamInfo = manifest.audioOnly
            .toList()
          ..sort((a, b) => a.bitrate.compareTo(b.bitrate));

        if (sortedStreamInfo.isEmpty) {
          Logger.root.warning('No audio streams available for video $videoId');
          throw Exception('No audio streams available for video $videoId');
        }

        Logger.root.info(
            'Successfully retrieved ${sortedStreamInfo.length} audio streams for video $videoId');

        if (onlyMp4 || Platform.isIOS || Platform.isMacOS) {
          final List<AudioOnlyStreamInfo> m4aStreams = sortedStreamInfo
              .where((element) => element.audioCodec.contains('mp4'))
              .toList();

          if (m4aStreams.isNotEmpty) {
            Logger.root.fine(
                'Using ${m4aStreams.length} m4a streams for video $videoId');
            // Close the instance before returning
            freshYt.close();
            return m4aStreams;
          } else {
            Logger.root.warning(
                'No m4a streams found for video $videoId, using all available streams');
          }
        }

        // Close the instance before returning
        freshYt.close();
        return sortedStreamInfo;
      } catch (e, stackTrace) {
        // Determine error type for better logging
        String errorType = 'Unknown error';
        if (e.toString().contains('Null check operator used on a null value')) {
          errorType = 'Null check error (possible API response change)';
        } else if (e.toString().contains('timeout') ||
            e.toString().contains('Timeout')) {
          errorType = 'Timeout error';
        } else if (e.toString().contains('VideoUnavailable')) {
          errorType = 'Video unavailable';
        } else if (e.toString().contains('VideoRequiresPurchase')) {
          errorType = 'Video requires purchase';
        } else if (e.toString().contains('VideoUnplayable')) {
          errorType = 'Video unplayable';
        } else if (e.toString().contains('SocketException')) {
          errorType = 'Network error';
        }

        lastError = e is Exception ? e : Exception(e.toString());

        if (retryCount >= maxRetries) {
          Logger.root.severe(
              'Failed to get stream manifest for video $videoId after ${maxRetries + 1} attempts. Error type: $errorType',
              e,
              stackTrace);
          // Close instance on error
          freshYt?.close();
          rethrow;
        }

        Logger.root.warning(
            'Error getting stream manifest for video $videoId (attempt ${retryCount + 1}/${maxRetries + 1}). Error type: $errorType. Will retry...',
            e);

        // Close instance before retry
        freshYt?.close();
      }

      retryCount++;
    }

    // Shouldn't reach here, but just in case
    throw lastError ?? Exception('Failed after retries');
  }

  Stream<List<int>> getStreamClient(
    AudioOnlyStreamInfo streamInfo,
  ) {
    return yt.videos.streamsClient.get(streamInfo);
  }

  /// Clear expired entries from the YouTube link cache
  /// This should be called periodically to prevent cache bloat
  Future<void> clearExpiredCache() async {
    try {
      final cacheBox = Hive.box('ytlinkcache');
      final List<String> keysToDelete = [];
      final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      for (final key in cacheBox.keys) {
        try {
          final cachedData = cacheBox.get(key);
          if (cachedData is List && cachedData.isNotEmpty) {
            // Find the minimum expire time
            int minExpiredAt = 0;
            for (final e in cachedData) {
              try {
                final int cachedExpiredAt = int.parse(e['expireAt'].toString());
                if (minExpiredAt == 0 || cachedExpiredAt < minExpiredAt) {
                  minExpiredAt = cachedExpiredAt;
                }
              } catch (e) {
                // Invalid expireAt format, mark for deletion
                keysToDelete.add(key.toString());
                break;
              }
            }

            // Check if expired (with 1 hour buffer)
            if (minExpiredAt > 0 && currentTime > minExpiredAt + 3600) {
              keysToDelete.add(key.toString());
            }
          } else {
            // Invalid cache format, mark for deletion
            keysToDelete.add(key.toString());
          }
        } catch (e) {
          keysToDelete.add(key.toString());
        }
      }

      // Delete expired entries
      for (final key in keysToDelete) {
        try {
          await cacheBox.delete(key);
        } catch (e) {}
      }
    } catch (e) {
      Logger.root.severe('Error clearing expired cache', e);
    }
  }
}
