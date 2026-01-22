// Coded by Naseer Ahmed

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blackhole/Services/yt_music.dart';
import 'package:blackhole/Services/ytmusic/nav.dart';
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
    final Video? vid = await getVideoFromId(id);
    if (vid == null) {
      return null;
    }
    final Map? response = await formatVideo(
      video: vid,
      quality: Hive.box('settings')
          .get(
            'ytQuality',
            defaultValue: 'Low',
          )
          .toString(),
      data: data,
      getUrl: getUrl ?? true,
      // preferM4a: Hive.box(
      //         'settings')
      //     .get('preferM4a',
      //         defaultValue:
      //             true) as bool
    );
    return response;
  }

  Future<Map?> refreshLink(String id, {bool useYTM = true}) async {
    String quality;
    try {
      quality =
          Hive.box('settings').get('quality', defaultValue: 'Low').toString();
    } catch (e) {
      quality = 'Low';
    }
    if (useYTM) {
      final Map res = await YtMusicService().getSongData(
        videoId: id,
        quality: quality,
      );
      return res;
    }
    final Video? res = await getVideoFromId(id);
    if (res == null) {
      return null;
    }
    final Map? data = await formatVideo(video: res, quality: quality);
    return data;
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
    if (video.duration?.inSeconds == null) return null;
    List<String> allUrls = [];
    List<Map> urlsData = [];
    String finalUrl = '';
    String expireAt = '0';
    if (getUrl) {
      urlsData = await getYtStreamUrls(video.id.value);
      if (urlsData.isEmpty) {
        Logger.root
            .warning('No stream URLs found for video: ${video.id.value}');
        return null;
      }
      final Map finalUrlData =
          quality == 'High' ? urlsData.last : urlsData.first;
      finalUrl = finalUrlData['url']?.toString() ?? '';
      expireAt = finalUrlData['expireAt']?.toString() ?? '0';
      allUrls = urlsData
          .map((e) => e['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return {
      'id': video.id.value,
      'album': (data?['album'] ?? '') != ''
          ? data!['album']
          : video.author.replaceAll('- Topic', '').trim(),
      'duration': video.duration?.inSeconds.toString(),
      'title':
          (data?['title'] ?? '') != '' ? data!['title'] : video.title.trim(),
      'artist': (data?['artist'] ?? '') != ''
          ? data!['artist']
          : video.author.replaceAll('- Topic', '').trim(),
      'image': video.thumbnails.maxResUrl,
      'secondImage': video.thumbnails.highResUrl,
      'language': 'YouTube',
      'genre': 'YouTube',
      'expire_at': expireAt,
      'url': finalUrl,
      'allUrls': allUrls,
      'urlsData': urlsData,
      'year': video.uploadDate?.year.toString(),
      '320kbps': 'false',
      'has_lyrics': 'false',
      'release_date': video.publishDate.toString(),
      'album_id': video.channelId.value,
      'subtitle':
          (data?['subtitle'] ?? '') != '' ? data!['subtitle'] : video.author,
      'perma_url': video.url,
    };
  }

  Future<List<Map>> fetchSearchResults(String query) async {
    final List<Video> searchResults = await yt.search.search(query);
    final List<Map> videoResult = [];
    for (final Video vid in searchResults) {
      final res = await formatVideo(video: vid, quality: 'High', getUrl: false);
      if (res != null) videoResult.add(res);
    }
    return [
      {
        'title': 'Videos',
        'items': videoResult,
        'allowViewAll': false,
      }
    ];
  }

  String getExpireAt(String url) {
    return RegExp('expire=(.*?)&').firstMatch(url)!.group(1) ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000000 + 3600 * 5.5)
            .toString();
  }

  Future<List<Map>> getYtStreamUrls(String videoId) async {
    try {
      List<Map> urlData = [];

      // check cache first
      if (Hive.box('ytlinkcache').containsKey(videoId)) {
        final cachedData = Hive.box('ytlinkcache').get(videoId);
        if (cachedData is List) {
          int minExpiredAt = 0;
          for (final e in cachedData) {
            final int cachedExpiredAt = int.parse(e['expireAt'].toString());
            if (minExpiredAt == 0 || cachedExpiredAt < minExpiredAt) {
              minExpiredAt = cachedExpiredAt;
            }
          }

          if ((DateTime.now().millisecondsSinceEpoch ~/ 1000000) + 350 >
              minExpiredAt) {
            // cache expired
            urlData = await getUri(videoId);
          } else {
            // giving cache link
            Logger.root.info('cache found for $videoId');
            urlData = List<Map>.from(
                cachedData.map((e) => Map<dynamic, dynamic>.from(e as Map)));
          }
        } else {
          // old version cache is present
          urlData = await getUri(videoId);
        }
      } else {
        //cache not present
        urlData = await getUri(videoId);
      }

      try {
        await Hive.box('ytlinkcache')
            .put(
              videoId,
              urlData,
            )
            .onError(
              (error, stackTrace) => Logger.root.severe(
                'Hive Error in formatVideo, you probably forgot to open box.\nError: $error',
              ),
            );
      } catch (e) {
        Logger.root.severe(
          'Hive Error in formatVideo, you probably forgot to open box.\nError: $e',
        );
      }

      return urlData;
    } catch (e) {
      Logger.root.severe('Error in getYtStreamUrls: $e');
      return [];
    }
  }

  Future<List<Map>> getUri(
    String videoId,
    // {bool preferM4a = true}
  ) async {
    try {
      // STRATEGY: Use YT Music API as PRIMARY method to bypass bot detection
      // youtube_explode_dart is FALLBACK (handles signature decryption)
      Logger.root.info(
        'Attempting to get stream URLs for video $videoId using YT Music API (primary method)...',
      );

      try {
        // Try YT Music API first - bypasses YouTube's bot detection
        final List<Map> ytMusicResult =
            await _getUriFromYtMusicFallback(videoId);

        if (ytMusicResult.isNotEmpty) {
          Logger.root.info(
            '✅ YT Music API success: ${ytMusicResult.length} URLs for video $videoId',
          );
          return ytMusicResult; // Use these URLs directly!
        } else {
          Logger.root.warning(
              'YT Music API returned empty for $videoId, trying youtube_explode_dart...');
        }
      } catch (ytMusicError) {
        Logger.root.warning(
            'YT Music API failed for $videoId: $ytMusicError. Trying youtube_explode_dart...');
      }

      // Fallback to youtube_explode_dart (handles signature decryption)
      Logger.root
          .info('Using youtube_explode_dart fallback for video $videoId...');

      List<AudioOnlyStreamInfo> sortedStreamInfo;
      try {
        sortedStreamInfo = await getStreamInfo(videoId);
      } catch (e) {
        // Catch TypeError specifically from youtube_explode_dart
        if (e is TypeError) {
          Logger.root.severe(
            'TypeError caught in getUri for video $videoId. This is likely a bug in youtube_explode_dart package.',
            e,
          );
          Logger.root.info(
            'TypeError fallback: trying YT Music API again for video $videoId...',
          );
          return await _getUriFromYtMusicFallback(videoId);
        }
        rethrow;
      }

      if (sortedStreamInfo.isEmpty) {
        Logger.root.warning('No stream info found for video: $videoId');
        Logger.root.info(
            'Empty result fallback: trying YT Music API for video $videoId...');
        return await _getUriFromYtMusicFallback(videoId);
      }

      Logger.root.info(
          'Processing ${sortedStreamInfo.length} streams for video $videoId');

      final List<Map> result = [];
      for (final e in sortedStreamInfo) {
        try {
          final url = e.url;
          final urlString = url.toString();

          // Validate URL is not empty and is a valid HTTP/HTTPS URL
          if (urlString.isEmpty || !urlString.startsWith('http')) {
            Logger.root.warning(
              'Stream info has invalid URL for video $videoId: $urlString',
            );
            continue;
          }

          // Validate URL can be parsed
          try {
            final uri = Uri.parse(urlString);
            if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
              Logger.root.warning(
                'Stream URL has invalid scheme for video $videoId: $urlString',
              );
              continue;
            }
          } catch (parseError) {
            Logger.root.warning(
              'Failed to parse stream URL for video $videoId: $parseError',
            );
            continue;
          }

          result.add({
            'bitrate': e.bitrate.kiloBitsPerSecond.round().toString(),
            'codec': e.codec.subtype,
            'qualityLabel': e.qualityLabel,
            'size': e.size.totalMegaBytes.toStringAsFixed(2),
            'url': urlString,
            'expireAt': getExpireAt(urlString),
          });
        } catch (streamError) {
          Logger.root.warning(
            'Error processing stream info for video $videoId: $streamError',
          );
          continue;
        }
      }

      if (result.isEmpty) {
        Logger.root.warning(
          'No valid stream URLs found after processing for video: $videoId',
        );
      } else {
        Logger.root.info(
          'Successfully processed ${result.length} stream URLs for video $videoId',
        );
      }

      return result;
    } catch (e, stackTrace) {
      Logger.root.severe('Error in getUri for video $videoId: $e');
      Logger.root.severe('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<AudioOnlyStreamInfo>> getStreamInfo(
    String videoId, {
    bool onlyMp4 = false,
    int retryCount = 0,
  }) async {
    const maxRetries = 4; // Increased retries for better recovery
    const retryDelaySeconds = [
      3,
      6,
      10,
      15
    ]; // Longer delays for better recovery
    const nullUriErrorDelaySeconds = [
      5,
      10,
      15,
      20
    ]; // Even longer delays for null-to-Uri errors
    const timeoutDuration =
        Duration(seconds: 30); // Timeout for manifest retrieval

    try {
      StreamManifest? manifest;
      Exception? lastError;
      bool lastErrorWasNullUri = false;

      // Try to get manifest with retries and timeout handling
      // Always create a fresh client instance to avoid stale state issues
      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        YoutubeExplode? ytClient;
        try {
          Logger.root.info(
            'Attempting to get manifest for video $videoId (attempt ${attempt + 1}/${maxRetries + 1})',
          );

          // Always create a fresh instance to avoid stale connections and state issues
          // This helps prevent the null-to-Uri error that can occur with reused instances
          ytClient = YoutubeExplode();

          // Add a small delay before making the request to allow client to fully initialize
          if (attempt > 0) {
            await Future.delayed(Duration(seconds: 10));
          }

          try {
            // Add timeout to prevent hanging on longer videos
            manifest = await ytClient.videos.streamsClient
                .getManifest(VideoId(videoId))
                .timeout(
              timeoutDuration,
              onTimeout: () {
                Logger.root.warning(
                  'Manifest retrieval timed out for video $videoId (attempt ${attempt + 1})',
                );
                throw TimeoutException(
                  'Manifest retrieval timed out after ${timeoutDuration.inSeconds}s',
                  timeoutDuration,
                );
              },
            );

            // If successful, break out of retry loop
            Logger.root.info(
                'Successfully got manifest for video $videoId on attempt ${attempt + 1}');

            // Close the client after successful retrieval
            try {
              ytClient.close();
            } catch (e) {
              // Ignore errors when closing
            }
            ytClient = null; // Mark as closed
            break;
          } catch (timeoutError) {
            // Close the client on timeout
            if (ytClient != null) {
              try {
                ytClient.close();
              } catch (e) {
                // Ignore errors when closing
              }
              ytClient = null;
            }
            rethrow;
          }
        } catch (e, stackTrace) {
          // Close client if it's still open
          if (ytClient != null) {
            try {
              ytClient.close();
            } catch (closeError) {
              // Ignore errors when closing
            }
            ytClient = null;
          }

          // Check if this is the specific null-to-Uri error or TypeError
          final errorString = e.toString();
          final isTypeError = e is TypeError;
          final isNullUriError = errorString
                  .contains("'Null' is not a subtype of type 'Uri'") ||
              errorString
                  .contains('type \'Null\' is not a subtype of type \'Uri\'') ||
              errorString.contains("is not a subtype of type 'Uri'") ||
              (isTypeError &&
                  (errorString.contains('Uri') ||
                      errorString.contains('null')));

          if (isNullUriError || isTypeError) {
            lastErrorWasNullUri = true;
            Logger.root.warning(
              'TypeError/Null-to-Uri error detected for video $videoId (attempt ${attempt + 1}). This is a known issue with youtube_explode_dart.',
            );
            if (isTypeError) {
              Logger.root.warning(
                'TypeError details: ${e.runtimeType} - $errorString',
              );
            }
            Logger.root.fine('Stack trace: $stackTrace');
          } else {
            lastErrorWasNullUri = false;
          }

          lastError = e is Exception ? e : Exception(e.toString());
          Logger.root.warning(
            'Attempt ${attempt + 1} failed to get manifest for video $videoId: $e',
          );

          // If this isn't the last attempt, wait before retrying
          if (attempt < maxRetries) {
            final delaySeconds = lastErrorWasNullUri
                ? nullUriErrorDelaySeconds[attempt]
                : retryDelaySeconds[attempt];
            Logger.root.info(
              'Waiting ${delaySeconds}s before retry (null-to-Uri error: $lastErrorWasNullUri)...',
            );
            await Future.delayed(Duration(seconds: delaySeconds));

            // For null-to-Uri errors, add an additional delay to let YouTube's servers reset
            // Also ensure client is fully disposed before creating a new one
            if (lastErrorWasNullUri && attempt < maxRetries - 1) {
              Logger.root.info(
                  'Additional cooldown for null-to-Uri error recovery...');
              await Future.delayed(Duration(seconds: 2));

              // Force garbage collection hint by waiting a bit more
              await Future.delayed(Duration(milliseconds: 500));
            }
          }
        }
      }

      // If we still don't have a manifest after all retries, return empty
      if (manifest == null) {
        Logger.root.severe(
          'Failed to get manifest for video $videoId after ${maxRetries + 1} attempts. Last error: $lastError',
        );
        return [];
      }

      // Filter out any problematic streams before processing
      final List<AudioOnlyStreamInfo> validStreams = [];
      for (final stream in manifest.audioOnly) {
        try {
          // Try to access the URL to ensure it's valid
          // This will catch runtime errors if the URL was constructed from null data
          final url = stream.url;
          final urlString = url.toString();
          if (urlString.isNotEmpty && urlString.contains('http')) {
            // Additional validation: ensure URL is actually a valid HTTP/HTTPS URL
            validStreams.add(stream);
          } else {
            Logger.root.warning(
              'Stream has invalid URL for video $videoId: $urlString',
            );
          }
        } catch (e) {
          Logger.root.warning(
            'Skipping invalid stream for video $videoId: $e',
          );
          continue;
        }
      }

      if (validStreams.isEmpty) {
        Logger.root.warning('No valid streams found for video: $videoId');
        return [];
      }

      Logger.root.info(
          'Found ${validStreams.length} valid streams for video $videoId');

      final List<AudioOnlyStreamInfo> sortedStreamInfo = validStreams
        ..sort((a, b) => a.bitrate.compareTo(b.bitrate));

      if (onlyMp4 || Platform.isIOS || Platform.isMacOS) {
        final List<AudioOnlyStreamInfo> m4aStreams =
            sortedStreamInfo.where((element) {
          try {
            return element.audioCodec.contains('mp4');
          } catch (e) {
            return false;
          }
        }).toList();

        if (m4aStreams.isNotEmpty) {
          Logger.root.info(
              'Returning ${m4aStreams.length} m4a streams for video $videoId');
          return m4aStreams;
        }
      }

      return sortedStreamInfo;
    } catch (e, stackTrace) {
      Logger.root.severe(
        'Unexpected error in getStreamInfo for video $videoId: $e',
      );
      Logger.root.severe('Stack trace: $stackTrace');
      return [];
    }
  }

  Stream<List<int>> getStreamClient(
    AudioOnlyStreamInfo streamInfo,
  ) {
    return yt.videos.streamsClient.get(streamInfo);
  }

  /// Fallback method to get stream URLs using YT Music API when youtube_explode_dart fails
  /// This is a workaround for the null-to-Uri error in youtube_explode_dart
  /// Extracts URLs directly from YT Music API response to avoid circular dependency
  Future<List<Map>> _getUriFromYtMusicFallback(String videoId) async {
    try {
      Logger.root.info('Using YT Music API fallback for video $videoId');

      // Import YtMusicService to access its methods
      final ytMusic = YtMusicService();

      // Initialize if needed
      if (ytMusic.headers == null) {
        await ytMusic.init();
      }

      // Get datestamp for signature
      final DateTime now = DateTime.now();
      final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);
      final Duration difference = now.difference(epoch);
      final int days = difference.inDays;
      final signatureTimestamp = ytMusic.signatureTimestamp ?? (days - 1);

      // Prepare request body
      final body = Map.from(ytMusic.context!);
      body['playbackContext'] = {
        'contentPlaybackContext': {'signatureTimestamp': signatureTimestamp},
      };
      body['video_id'] = videoId;

      // Call player endpoint directly
      final Map response = await ytMusic.sendRequest(
        YtMusicService.endpoints['get_song']!,
        body,
        ytMusic.headers,
      );

      if (response.isEmpty) {
        Logger.root
            .warning('Empty response from YT Music API for video $videoId');
        return [];
      }

      // Extract streamingData
      final streamingData = NavClass.nav(response, ['streamingData']);
      if (streamingData == null) {
        Logger.root.warning(
            'No streamingData found in YT Music API response for video $videoId');
        return [];
      }

      // Extract adaptiveFormats
      final adaptiveFormats = streamingData['adaptiveFormats'] as List?;
      if (adaptiveFormats == null || adaptiveFormats.isEmpty) {
        Logger.root.warning('No adaptiveFormats found for video $videoId');
        return [];
      }

      // Filter for audio-only formats and extract URLs
      final List<Map> result = [];
      for (final format in adaptiveFormats) {
        try {
          // Check if it's audio-only (has audioQuality and no video quality)
          final mimeType = format['mimeType']?.toString() ?? '';
          if (!mimeType.contains('audio')) {
            continue; // Skip video formats
          }

          // Get URL - could be in 'url' or 'signatureCipher'
          String? urlString = format['url']?.toString();

          // If no direct URL, extract from signatureCipher
          if (urlString == null || urlString.isEmpty) {
            final signatureCipher = format['signatureCipher']?.toString();
            if (signatureCipher != null && signatureCipher.isNotEmpty) {
              Logger.root.info(
                  '🔐 Extracting URL from signature cipher for video $videoId');

              try {
                // Parse signatureCipher query string
                // Format: s=SIGNATURE&sp=sig&url=BASE_URL
                final Uri cipherUri = Uri(query: signatureCipher);
                final String? baseUrl = cipherUri.queryParameters['url'];
                final String? signature = cipherUri.queryParameters['s'];
                final String? sigParam =
                    cipherUri.queryParameters['sp'] ?? 'signature';

                if (baseUrl != null && baseUrl.isNotEmpty) {
                  if (signature != null && signature.isNotEmpty) {
                    urlString = '$baseUrl&$sigParam=$signature';
                    Logger.root
                        .info('✅ Extracted signature for video $videoId');
                  } else {
                    urlString = baseUrl;
                    Logger.root.warning(
                        '⚠️ Using base URL without signature for $videoId');
                  }
                } else {
                  Logger.root.fine(
                      'Failed to extract base URL from signatureCipher for $videoId');
                  continue;
                }
              } catch (cipherError) {
                Logger.root.warning(
                    'Error parsing signatureCipher for $videoId: $cipherError');
                continue;
              }
            } else {
              continue;
            }
          }

          // Validate URL
          if (urlString == null ||
              urlString.isEmpty ||
              !urlString.startsWith('http')) {
            continue;
          }

          // Extract bitrate and other info
          final bitrate = format['bitrate'] ?? 0;
          final audioQuality = format['audioQuality']?.toString() ?? 'unknown';
          final contentLength = format['contentLength'] ?? '0';

          // Calculate size in MB
          final sizeMB =
              (int.tryParse(contentLength.toString()) ?? 0) / (1024 * 1024);

          result.add({
            'bitrate': (bitrate ~/ 1000).toString(), // Convert to kbps
            'codec': mimeType.contains('mp4')
                ? 'mp4a'
                : (mimeType.contains('webm') ? 'opus' : 'unknown'),
            'qualityLabel': audioQuality,
            'size': sizeMB.toStringAsFixed(2),
            'url': urlString,
            'expireAt': getExpireAt(urlString),
          });
        } catch (formatError) {
          Logger.root.warning(
            'Error processing format for video $videoId: $formatError',
          );
          continue;
        }
      }

      if (result.isEmpty) {
        Logger.root.warning(
          'No valid audio formats extracted from YT Music API for video $videoId',
        );
        return [];
      }

      // Sort by bitrate
      result.sort((a, b) {
        final bitrateA = int.tryParse(a['bitrate'].toString()) ?? 0;
        final bitrateB = int.tryParse(b['bitrate'].toString()) ?? 0;
        return bitrateA.compareTo(bitrateB);
      });

      Logger.root.info(
        'Successfully extracted ${result.length} stream URLs using YT Music API fallback for video $videoId',
      );

      return result;
    } catch (e, stackTrace) {
      Logger.root.severe(
        'Error in YT Music API fallback for video $videoId: $e',
      );
      Logger.root.severe('Stack trace: $stackTrace');
      return [];
    }
  }
}
