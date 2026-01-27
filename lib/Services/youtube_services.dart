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
    print('🎬 [VIDEO->AUDIO] Starting conversion for video ID: $videoId');
    try {
      List<Map> urlData = [];

      // check cache first
      if (Hive.box('ytlinkcache').containsKey(videoId)) {
        print('📦 [VIDEO->AUDIO] Cache found for video: $videoId');
        final cachedData = Hive.box('ytlinkcache').get(videoId);
        if (cachedData is List) {
          print(
              '✅ [VIDEO->AUDIO] Cache is valid list format with ${cachedData.length} entries');
          int minExpiredAt = 0;
          for (final e in cachedData) {
            final int cachedExpiredAt = int.parse(e['expireAt'].toString());
            if (minExpiredAt == 0 || cachedExpiredAt < minExpiredAt) {
              minExpiredAt = cachedExpiredAt;
            }
          }

          final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000000;
          final timeUntilExpiry = minExpiredAt - (currentTime + 350);
          print(
              '⏰ [VIDEO->AUDIO] Cache expiry check - Current: $currentTime, Expires: $minExpiredAt, Time left: ${timeUntilExpiry}s');

          if (currentTime + 350 > minExpiredAt) {
            // cache expired
            print(
                '⏳ [VIDEO->AUDIO] Cache expired, fetching fresh audio URLs...');
            urlData = await getUri(videoId);
          } else {
            // giving cache link
            print(
                '✅ [VIDEO->AUDIO] Using cached audio URLs (${cachedData.length} formats available)');
            Logger.root.info('cache found for $videoId');
            urlData = List<Map>.from(
                cachedData.map((e) => Map<dynamic, dynamic>.from(e as Map)));
            print(
                '🎵 [VIDEO->AUDIO] Cached URLs: ${urlData.map((e) => '${e['bitrate']}kbps (${e['codec']})').join(', ')}');
          }
        } else {
          // old version cache is present
          print('⚠️ [VIDEO->AUDIO] Old cache format detected, refreshing...');
          urlData = await getUri(videoId);
        }
      } else {
        //cache not present
        print(
            '🆕 [VIDEO->AUDIO] No cache found, fetching audio URLs for first time...');
        urlData = await getUri(videoId);
      }

      try {
        print(
            '💾 [VIDEO->AUDIO] Saving ${urlData.length} audio URLs to cache for video: $videoId');
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
        print('✅ [VIDEO->AUDIO] Successfully cached audio URLs');
      } catch (e) {
        Logger.root.severe(
          'Hive Error in formatVideo, you probably forgot to open box.\nError: $e',
        );
        print('❌ [VIDEO->AUDIO] Failed to cache URLs: $e');
      }

      print(
          '🎉 [VIDEO->AUDIO] Conversion complete! Returning ${urlData.length} audio URLs');
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
    // STRATEGY: Use youtube_explode_dart as PRIMARY method
    // It properly handles signature decryption which YouTube Music API doesn't
    // YouTube Music API returns encrypted signatures that cause 403 errors
    Logger.root.info(
      'Attempting to get stream URLs for video $videoId using youtube_explode_dart (primary method)...',
    );

    try {
      // Try youtube_explode_dart first - it properly decrypts signatures
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
            'TypeError fallback: trying YT Music API for video $videoId...',
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

      print(
          '🔄 [VIDEO->AUDIO] Processing ${sortedStreamInfo.length} audio streams from youtube_explode_dart...');
      Logger.root.info(
          'Processing ${sortedStreamInfo.length} streams for video $videoId');

      final List<Map> result = [];
      int processedCount = 0;

      for (final e in sortedStreamInfo) {
        try {
          processedCount++;
          final url = e.url;
          final urlString = url.toString();

          print(
              '🔍 [VIDEO->AUDIO] Processing stream $processedCount/${sortedStreamInfo.length}: ${e.bitrate.kiloBitsPerSecond}kbps ${e.codec.subtype}');

          // Validate URL is not empty and is a valid HTTP/HTTPS URL
          if (urlString.isEmpty || !urlString.startsWith('http')) {
            print('❌ [VIDEO->AUDIO] Invalid URL format: $urlString');
            Logger.root.warning(
              'Stream info has invalid URL for video $videoId: $urlString',
            );
            continue;
          }

          // Validate URL can be parsed
          try {
            final uri = Uri.parse(urlString);
            if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
              print('❌ [VIDEO->AUDIO] Invalid URL scheme: $urlString');
              Logger.root.warning(
                'Stream URL has invalid scheme for video $videoId: $urlString',
              );
              continue;
            }
          } catch (parseError) {
            print('❌ [VIDEO->AUDIO] URL parse error: $parseError');
            Logger.root.warning(
              'Failed to parse stream URL for video $videoId: $parseError',
            );
            continue;
          }

          final streamData = {
            'bitrate': e.bitrate.kiloBitsPerSecond.round().toString(),
            'codec': e.codec.subtype,
            'qualityLabel': e.qualityLabel,
            'size': e.size.totalMegaBytes.toStringAsFixed(2),
            'url': urlString,
            'expireAt': getExpireAt(urlString),
          };

          print(
              '✅ [VIDEO->AUDIO] Added audio stream: ${streamData['bitrate']}kbps ${streamData['codec']}, Size: ${streamData['size']}MB');
          result.add(streamData);
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
    } catch (e) {
      // If youtube_explode_dart fails, try YT Music API as fallback
      Logger.root.warning(
        'youtube_explode_dart failed for $videoId: $e. Trying YT Music API fallback...',
      );
      return await _getUriFromYtMusicFallback(videoId);
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
      print(
          '🎬 [VIDEO->AUDIO] Manifest retrieved! Total audio-only streams in manifest: ${manifest.audioOnly.length}');
      final List<AudioOnlyStreamInfo> validStreams = [];
      int invalidStreams = 0;

      for (final stream in manifest.audioOnly) {
        try {
          // Try to access the URL to ensure it's valid
          // This will catch runtime errors if the URL was constructed from null data
          final url = stream.url;
          final urlString = url.toString();
          print(
              '🔍 [VIDEO->AUDIO] Checking stream: Bitrate=${stream.bitrate.kiloBitsPerSecond}kbps, Codec=${stream.codec.subtype}');

          if (urlString.isNotEmpty && urlString.contains('http')) {
            // Additional validation: ensure URL is actually a valid HTTP/HTTPS URL
            validStreams.add(stream);
            print(
                '✅ [VIDEO->AUDIO] Valid audio stream: ${stream.bitrate.kiloBitsPerSecond}kbps ${stream.codec.subtype}');
          } else {
            invalidStreams++;
            print('❌ [VIDEO->AUDIO] Invalid stream URL: $urlString');
            Logger.root.warning(
              'Stream has invalid URL for video $videoId: $urlString',
            );
          }
        } catch (e) {
          invalidStreams++;
          print('❌ [VIDEO->AUDIO] Error processing stream: $e');
          Logger.root.warning(
            'Skipping invalid stream for video $videoId: $e',
          );
          continue;
        }
      }

      print(
          '📊 [VIDEO->AUDIO] Stream validation: ${validStreams.length} valid, $invalidStreams invalid');

      if (validStreams.isEmpty) {
        print(
            '❌ [VIDEO->AUDIO] No valid audio streams found for video: $videoId');
        Logger.root.warning('No valid streams found for video: $videoId');
        return [];
      }

      print(
          '✅ [VIDEO->AUDIO] Found ${validStreams.length} valid audio streams for video $videoId');
      Logger.root.info(
          'Found ${validStreams.length} valid streams for video $videoId');

      print(
          '🔄 [VIDEO->AUDIO] Sorting ${validStreams.length} streams by bitrate...');
      final List<AudioOnlyStreamInfo> sortedStreamInfo = validStreams
        ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
      print(
          '📊 [VIDEO->AUDIO] Sorted streams: ${sortedStreamInfo.map((e) => '${e.bitrate.kiloBitsPerSecond}kbps').join(' -> ')}');

      if (onlyMp4 || Platform.isIOS || Platform.isMacOS) {
        print(
            '🍎 [VIDEO->AUDIO] Platform requires MP4/M4A format, filtering...');
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
      print(
          '🔍 [VIDEO->AUDIO] Filtering ${adaptiveFormats.length} adaptive formats for audio-only streams...');
      final List<Map> result = [];
      int videoFormatsSkipped = 0;
      int audioFormatsFound = 0;

      for (final format in adaptiveFormats) {
        try {
          // Check if it's audio-only (has audioQuality and no video quality)
          final mimeType = format['mimeType']?.toString() ?? '';
          print('📋 [VIDEO->AUDIO] Checking format: MIME=$mimeType');

          if (!mimeType.contains('audio')) {
            videoFormatsSkipped++;
            print('⏭️ [VIDEO->AUDIO] Skipping video format: $mimeType');
            continue; // Skip video formats
          }

          audioFormatsFound++;
          print('🎵 [VIDEO->AUDIO] Found audio format: $mimeType');

          // Get URL - could be in 'url' or 'signatureCipher'
          String? urlString = format['url']?.toString();

          // If no direct URL, extract from signatureCipher
          if (urlString == null || urlString.isEmpty) {
            final signatureCipher = format['signatureCipher']?.toString();
            if (signatureCipher != null && signatureCipher.isNotEmpty) {
              print(
                  '🔐 [VIDEO->AUDIO] Extracting URL from signature cipher for video $videoId');
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
                    print(
                        '✅ [VIDEO->AUDIO] Extracted signature for video $videoId');
                    Logger.root
                        .info('✅ Extracted signature for video $videoId');
                  } else {
                    urlString = baseUrl;
                    print(
                        '⚠️ [VIDEO->AUDIO] Using base URL without signature for $videoId');
                    Logger.root.warning(
                        '⚠️ Using base URL without signature for $videoId');
                  }
                } else {
                  print(
                      '❌ [VIDEO->AUDIO] Failed to extract base URL from signatureCipher for $videoId');
                  Logger.root.fine(
                      'Failed to extract base URL from signatureCipher for $videoId');
                  continue;
                }
              } catch (cipherError) {
                print(
                    '❌ [VIDEO->AUDIO] Error parsing signatureCipher for $videoId: $cipherError');
                Logger.root.warning(
                    'Error parsing signatureCipher for $videoId: $cipherError');
                continue;
              }
            } else {
              print(
                  '❌ [VIDEO->AUDIO] No URL or signatureCipher found for format');
              continue;
            }
          }

          // Validate URL - at this point urlString should not be null due to flow control above
          final finalUrl = urlString;
          if (finalUrl.isEmpty || !finalUrl.startsWith('http')) {
            print(
                '❌ [VIDEO->AUDIO] Invalid URL after processing: ${finalUrl.isEmpty ? "empty" : "not http"}');
            continue;
          }

          print(
              '✅ [VIDEO->AUDIO] Valid audio URL extracted: ${finalUrl.substring(0, finalUrl.length > 50 ? 50 : finalUrl.length)}...');

          // Extract bitrate and other info
          final bitrate = format['bitrate'] ?? 0;
          final audioQuality = format['audioQuality']?.toString() ?? 'unknown';
          final contentLength = format['contentLength'] ?? '0';

          // Calculate size in MB
          final sizeMB =
              (int.tryParse(contentLength.toString()) ?? 0) / (1024 * 1024);

          final codec = mimeType.contains('mp4')
              ? 'mp4a'
              : (mimeType.contains('webm') ? 'opus' : 'unknown');
          final bitrateKbps = (bitrate ~/ 1000).toString();

          print(
              '✅ [VIDEO->AUDIO] Extracted audio stream: ${bitrateKbps}kbps, $codec, Quality: $audioQuality, Size: ${sizeMB.toStringAsFixed(2)}MB');

          result.add({
            'bitrate': bitrateKbps, // Convert to kbps
            'codec': codec,
            'qualityLabel': audioQuality,
            'size': sizeMB.toStringAsFixed(2),
            'url': finalUrl,
            'expireAt': getExpireAt(finalUrl),
          });
        } catch (formatError) {
          Logger.root.warning(
            'Error processing format for video $videoId: $formatError',
          );
          continue;
        }
      }

      print(
          '📊 [VIDEO->AUDIO] Format filtering summary: $audioFormatsFound audio formats found, $videoFormatsSkipped video formats skipped');

      print(
          '📊 [VIDEO->AUDIO] Format filtering summary: $audioFormatsFound audio formats found, $videoFormatsSkipped video formats skipped');

      if (result.isEmpty) {
        print(
            '❌ [VIDEO->AUDIO] No valid audio formats extracted from YT Music API for video $videoId');
        Logger.root.warning(
          'No valid audio formats extracted from YT Music API for video $videoId',
        );
        return [];
      }

      // Sort by bitrate
      print(
          '🔄 [VIDEO->AUDIO] Sorting ${result.length} audio streams by bitrate...');
      result.sort((a, b) {
        final bitrateA = int.tryParse(a['bitrate'].toString()) ?? 0;
        final bitrateB = int.tryParse(b['bitrate'].toString()) ?? 0;
        return bitrateA.compareTo(bitrateB);
      });

      print(
          '🎵 [VIDEO->AUDIO] Sorted audio streams: ${result.map((e) => '${e['bitrate']}kbps').join(' -> ')}');
      Logger.root.info(
        'Successfully extracted ${result.length} stream URLs using YT Music API fallback for video $videoId',
      );

      print(
          '✅ [VIDEO->AUDIO] YT Music API conversion complete: ${result.length} audio URLs ready');
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
