import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Helpers/playlist.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Services/isolate_service.dart';
import 'package:blackhole/Services/yt_music.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

/// Custom StreamAudioSource that proxies YouTube streams through Dart
/// This bypasses ExoPlayer's HTTP client which causes 403 errors
class YouTubeAudioSource extends StreamAudioSource {
  final Uri uri;
  final Map<String, String> headers;
  final String? tag;

  YouTubeAudioSource(this.uri, {this.headers = const {}, this.tag});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print('🌐 [YOUTUBE PROXY] Requesting range: $start-$end');

    // Add range header if specified
    final requestHeaders = Map<String, String>.from(headers);
    if (start != null || end != null) {
      final rangeStart = start ?? 0;
      final rangeEnd = end != null ? end - 1 : '';
      requestHeaders['Range'] = 'bytes=$rangeStart-$rangeEnd';
    }

    try {
      final response = await http.get(uri, headers: requestHeaders);
      print('🌐 [YOUTUBE PROXY] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 206) {
        // Parse content range to get total length
        int? sourceLength;
        final contentRange = response.headers['content-range'];
        if (contentRange != null) {
          final match =
              RegExp(r'bytes (\d+)-(\d+)/(\d+)').firstMatch(contentRange);
          if (match != null) {
            sourceLength = int.parse(match.group(3)!);
          }
        } else {
          // If no content-range, use content-length
          final contentLength = response.headers['content-length'];
          if (contentLength != null) {
            sourceLength = int.parse(contentLength);
          }
        }

        print('🌐 [YOUTUBE PROXY] Content length: $sourceLength bytes');
        print(
            '🌐 [YOUTUBE PROXY] Response body size: ${response.bodyBytes.length} bytes');

        return StreamAudioResponse(
          sourceLength: sourceLength,
          contentLength: response.bodyBytes.length,
          offset: start ?? 0,
          stream: Stream.value(response.bodyBytes),
          contentType: response.headers['content-type'] ?? 'audio/mp4',
        );
      } else {
        print('❌ [YOUTUBE PROXY] HTTP error: ${response.statusCode}');
        print('❌ [YOUTUBE PROXY] Response headers: ${response.headers}');
        throw Exception('HTTP Status Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [YOUTUBE PROXY] Request failed: $e');
      rethrow;
    }
  }
}

class AudioPlayerHandlerImpl extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements AudioPlayerHandler {
  int? count;
  Timer? _sleepTimer;
  bool recommend = true;
  bool loadStart = true;
  bool useDown = true;
  AndroidEqualizerParameters? _equalizerParams;

  late AudioPlayer? _player;
  late String connectionType = 'mobile';
  late String preferredQuality;
  late String preferredWifiQuality;
  late String preferredMobileQuality;
  late List<int> preferredCompactNotificationButtons = [1, 2, 3];
  late bool resetOnSkip;
  // late String? stationId = '';
  // late List<String> stationNames = [];
  // late String stationType = 'entity';
  late bool cacheSong;
  final _equalizer = AndroidEqualizer();

  Box? downloadsBox =
      Hive.isBoxOpen('downloads') ? Hive.box('downloads') : null;
  final List<String> refreshLinks = [];
  bool jobRunning = false;
  Completer<void>? _playlistInitialized;
  final Map<String, DateTime> _validatedUrls = {}; // Cache for validated URLs
  bool _isRefreshingUrl =
      false; // Flag to prevent multiple simultaneous refreshes

  final BehaviorSubject<List<MediaItem>> _recentSubject =
      BehaviorSubject.seeded(<MediaItem>[]);
  final _playlist = ConcatenatingAudioSource(children: []);
  @override
  final BehaviorSubject<double> volume = BehaviorSubject.seeded(1.0);
  @override
  final BehaviorSubject<double> speed = BehaviorSubject.seeded(1.0);
  final _mediaItemExpando = Expando<MediaItem>();

  Stream<List<IndexedAudioSource>> get _effectiveSequence => Rx.combineLatest3<
              List<IndexedAudioSource>?,
              List<int>?,
              bool,
              List<IndexedAudioSource>?>(_player!.sequenceStream,
          _player!.shuffleIndicesStream, _player!.shuffleModeEnabledStream,
          (sequence, shuffleIndices, shuffleModeEnabled) {
        if (sequence == null) return [];
        if (!shuffleModeEnabled) return sequence;
        if (shuffleIndices == null) return null;
        if (shuffleIndices.length != sequence.length) return null;
        return shuffleIndices.map((i) => sequence[i]).toList();
      }).whereType<List<IndexedAudioSource>>();

  int? getQueueIndex(
    int? currentIndex,
    List<int>? shuffleIndices, {
    bool shuffleModeEnabled = false,
  }) {
    final effectiveIndices = _player!.effectiveIndices ?? [];
    final shuffleIndicesInv = List.filled(effectiveIndices.length, 0);
    for (var i = 0; i < effectiveIndices.length; i++) {
      shuffleIndicesInv[effectiveIndices[i]] = i;
    }
    return (shuffleModeEnabled &&
            ((currentIndex ?? 0) < shuffleIndicesInv.length))
        ? shuffleIndicesInv[currentIndex ?? 0]
        : currentIndex;
  }

  @override
  Stream<QueueState> get queueState =>
      Rx.combineLatest3<List<MediaItem>, PlaybackState, List<int>, QueueState>(
        queue,
        playbackState,
        _player!.shuffleIndicesStream.whereType<List<int>>(),
        (queue, playbackState, shuffleIndices) => QueueState(
          queue,
          playbackState.queueIndex,
          playbackState.shuffleMode == AudioServiceShuffleMode.all
              ? shuffleIndices
              : null,
          playbackState.repeatMode,
        ),
      ).where(
        (state) =>
            state.shuffleIndices == null ||
            state.queue.length == state.shuffleIndices!.length,
      );

  AudioPlayerHandlerImpl() {
    _init();
  }

  Future<void> _init() async {
    Logger.root.info('starting audio service');
    if (Hive.isBoxOpen('settings')) {
      preferredCompactNotificationButtons = Hive.box('settings').get(
        'preferredCompactNotificationButtons',
        defaultValue: [1, 2, 3],
      ) as List<int>;
      if (preferredCompactNotificationButtons.length > 3) {
        preferredCompactNotificationButtons = [1, 2, 3];
      }
    }
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    await startService();

    await startBackgroundProcessing();

    speed.debounceTime(const Duration(milliseconds: 250)).listen((speed) {
      playbackState.add(playbackState.value.copyWith(speed: speed));
    });

    Logger.root.info('checking connectivity & setting quality');

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile) {
        connectionType = 'mobile';
        Logger.root.info(
          'player | switched to mobile data, changing quality to $preferredMobileQuality',
        );
        preferredQuality = preferredMobileQuality;
      } else if (result == ConnectivityResult.wifi) {
        connectionType = 'wifi';
        Logger.root.info(
          'player | wifi connected, changing quality to $preferredWifiQuality',
        );
        preferredQuality = preferredWifiQuality;
      } else if (result == ConnectivityResult.none) {
        Logger.root.severe(
          'player | internet connection not available',
        );
      } else {
        Logger.root.info(
          'player | unidentified network connection',
        );
      }
    });

    preferredMobileQuality = Hive.box('settings')
        .get('streamingQuality', defaultValue: '96 kbps')
        .toString();
    preferredWifiQuality = Hive.box('settings')
        .get('streamingWifiQuality', defaultValue: '320 kbps')
        .toString();
    preferredQuality = connectionType == 'wifi'
        ? preferredWifiQuality
        : preferredMobileQuality;
    resetOnSkip =
        Hive.box('settings').get('resetOnSkip', defaultValue: false) as bool;
    cacheSong =
        Hive.box('settings').get('cacheSong', defaultValue: false) as bool;
    recommend =
        Hive.box('settings').get('autoplay', defaultValue: true) as bool;
    loadStart =
        Hive.box('settings').get('loadStart', defaultValue: true) as bool;

    mediaItem.whereType<MediaItem>().listen((item) {
      if (count != null) {
        count = count! - 1;
        if (count! <= 0) {
          count = null;
          stop();
        }
      }

      if (item.artUri.toString().startsWith('http')) {
        addRecentlyPlayed(item);
        _recentSubject.add([item]);

        if (recommend && item.extras!['autoplay'] as bool) {
          final List<MediaItem> mediaQueue = queue.value;
          final int index = mediaQueue.indexOf(item);
          final int queueLength = mediaQueue.length;
          if (queueLength - index < 5) {
            Logger.root.info('less than 5 songs remaining, adding more songs');
            Future.delayed(const Duration(seconds: 80), () async {
              print('i am loaded....................test 11');
              if (item == mediaItem.value) {
                print('i am loaded....................test 22');
                if (item.genre != 'YouTube') {
                  print('i am loaded....................test 33');
                  final List value = await SaavnAPI().getReco(item.id);
                  print('i am loaded....................test 44');
                  value.shuffle();
                  print('i am loaded....................test 55');
                  // final List value = await SaavnAPI().getRadioSongs(
                  //     stationId: stationId!, count: queueLength - index - 20);

                  for (int i = 0; i < value.length; i++) {
                    print('i am loaded....................test 66');
                    final element = MediaItemConverter.mapToMediaItem(
                      value[i] as Map,
                      addedByAutoplay: true,
                    );
                    print('i am loaded....................test 77');
                    if (!mediaQueue.contains(element)) {
                      print('i am loaded....................test 88');
                      addQueueItem(element);
                    }
                  }
                } else {
                  // DISABLED: YouTube queue/recommendations to prevent wasteful URL conversions
                  // User only wants to play the clicked song, not load entire queue
                  print(
                      '⏭️ [QUEUE] Skipping YouTube recommendations to save resources');
                  Logger.root.info(
                      'YouTube recommendations disabled - only playing clicked song');

                  // Commented out to prevent wasteful processing:
                  // final res = await YtMusicService().getWatchPlaylist(
                  //   videoId: item.id,
                  //   limit: 15,
                  // );
                  // Logger.root.info('Recieved recommendations: $res');
                  // refreshLinks.addAll(res);
                  // if (!jobRunning) {
                  //   refreshJob();
                  // }
                }
              }
            });
          }
        }
      }
    });

    Rx.combineLatest4<int?, List<MediaItem>, bool, List<int>?, MediaItem?>(
        _player!.currentIndexStream,
        queue,
        _player!.shuffleModeEnabledStream,
        _player!.shuffleIndicesStream,
        (index, queue, shuffleModeEnabled, shuffleIndices) {
      final queueIndex = getQueueIndex(
        index,
        shuffleIndices,
        shuffleModeEnabled: shuffleModeEnabled,
      );
      return (queueIndex != null && queueIndex < queue.length)
          ? queue[queueIndex]
          : null;
    }).whereType<MediaItem>().distinct().listen(mediaItem.add);

    // Propagate all events from the audio player to AudioService clients.
    _player!.playbackEventStream
        .listen(_broadcastState, onError: _playbackError);

    _player!.shuffleModeEnabledStream
        .listen((enabled) => _broadcastState(_player!.playbackEvent));

    _player!.loopModeStream
        .listen((event) => _broadcastState(_player!.playbackEvent));

    _player!.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
        _player!.seek(Duration.zero, index: 0);
      }
    });
    // Broadcast the current queue.
    _effectiveSequence
        .map(
          (sequence) =>
              sequence.map((source) => _mediaItemExpando[source]!).toList(),
        )
        .pipe(queue);

    // Initialize completer to track playlist initialization
    _playlistInitialized = Completer<void>();

    try {
      if (loadStart) {
        final List lastQueueList = await Hive.box('cache')
            .get('lastQueue', defaultValue: [])?.toList() as List;

        final int lastIndex =
            await Hive.box('cache').get('lastIndex', defaultValue: 0) as int;

        final int lastPos =
            await Hive.box('cache').get('lastPos', defaultValue: 0) as int;

        if (lastQueueList.isNotEmpty &&
            lastQueueList.first['genre'] != 'YouTube') {
          final List<MediaItem> lastQueue = lastQueueList
              .map((e) => MediaItemConverter.mapToMediaItem(e as Map))
              .toList();
          if (lastQueue.isEmpty) {
            await _player!
                .setAudioSource(_playlist, preload: false)
                .onError((error, stackTrace) {
              _onError(error, stackTrace, stopService: true);
              return null;
            });
            _playlistInitialized?.complete();
            _playlistInitialized = null;
          } else {
            await _playlist.addAll(await _itemsToSources(lastQueue));
            try {
              await _player!
                  .setAudioSource(
                _playlist,
                // commented out due to some bug in audio_service which causes app to freeze
                // instead manually seeking after audiosource initialised

                // initialIndex: lastIndex,
                // initialPosition: Duration(seconds: lastPos),
              )
                  .onError((error, stackTrace) {
                _onError(error, stackTrace, stopService: true);
                return null;
              });
              _playlistInitialized?.complete();
              _playlistInitialized = null;
              if (lastIndex != 0 || lastPos > 0) {
                await _player!
                    .seek(Duration(seconds: lastPos), index: lastIndex);
              }
            } catch (e) {
              Logger.root.severe('Error while setting last audiosource', e);
              await _player!
                  .setAudioSource(_playlist, preload: false)
                  .onError((error, stackTrace) {
                _onError(error, stackTrace, stopService: true);
                return null;
              });
              _playlistInitialized?.complete();
              _playlistInitialized = null;
            }
          }
        } else {
          await _player!
              .setAudioSource(_playlist, preload: false)
              .onError((error, stackTrace) {
            _onError(error, stackTrace, stopService: true);
            return null;
          });
          _playlistInitialized?.complete();
          _playlistInitialized = null;
        }
      } else {
        await _player!
            .setAudioSource(_playlist, preload: false)
            .onError((error, stackTrace) {
          _onError(error, stackTrace, stopService: true);
          return null;
        });
        _playlistInitialized?.complete();
        _playlistInitialized = null;
      }
    } catch (e) {
      Logger.root.severe('Error while loading last queue', e);
      await _player!
          .setAudioSource(_playlist, preload: false)
          .onError((error, stackTrace) {
        _onError(error, stackTrace, stopService: true);
        return null;
      });
      _playlistInitialized?.complete();
      _playlistInitialized = null;
    }
    if (!jobRunning) {
      refreshJob();
    }
  }

  Future<void> refreshJob() async {
    jobRunning = true;
    while (refreshLinks.isNotEmpty) {
      addIdToBackgroundProcessingIsolate(refreshLinks.removeAt(0));
    }
    jobRunning = false;
  }

  Future<void> refreshLink(Map newData) async {
    Logger.root.info('player | received new link for ${newData['title']}');
    if (newData['url'] == null) {
      return;
    }
    final MediaItem newItem = MediaItemConverter.mapToMediaItem(newData);

    // Mark the new URL as validated
    final newUrl = newData['url']?.toString();
    if (newUrl != null) {
      _validatedUrls[newUrl] = DateTime.now();
    }

    // Update current media item if it matches
    final currentItem = mediaItem.value;
    if (currentItem != null && currentItem.id == newItem.id) {
      Logger.root.info('Updating current media item with refreshed URL');
      currentItem.extras!['url'] = newItem.extras!['url'];
      currentItem.extras!['expire_at'] = newItem.extras!['expire_at'];

      // Update the audio source if currently playing this item
      final currentIndex = _player!.currentIndex;
      if (currentIndex != null) {
        try {
          final newSource = await _itemToSource(newItem);
          if (newSource != null) {
            await _playlist.removeAt(currentIndex);
            await _playlist.insert(currentIndex, newSource);
            _mediaItemExpando[newSource] = newItem;

            // Resume playback at current position
            final currentPosition = _player!.position;
            await _player!.seek(currentPosition, index: currentIndex);
            Logger.root.info('Successfully updated current item with new URL');
          }
        } catch (e) {
          Logger.root.severe('Error updating current item URL: $e');
        }
      }
    } else {
      // Add to queue if not current item
      addQueueItem(newItem);
    }
  }

  Map<String, String> _getAudioHeaders({bool isYouTube = false}) {
    if (isYouTube) {
      // YouTube-specific headers - Enhanced to better mimic real browser behavior
      return {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br, zstd',
        'Connection': 'keep-alive',
        'Referer': 'https://www.youtube.com/',
        'Origin': 'https://www.youtube.com',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'cross-site',
        'Sec-Ch-Ua': '"Chromium";v="131", "Not_A Brand";v="24"',
        'Sec-Ch-Ua-Mobile': '?0',
        'Sec-Ch-Ua-Platform': '"Windows"',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };
    } else {
      // JioSaavn headers
      return {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Connection': 'keep-alive',
        'Referer': 'https://www.jiosaavn.com/',
        'Origin': 'https://www.jiosaavn.com',
      };
    }
  }

  Future<AudioSource?> _itemToSource(MediaItem mediaItem,
      {bool skipRefresh = false}) async {
    AudioSource? audioSource;
    // Use YouTube headers for YouTube content, JioSaavn headers for others
    final isYouTube = mediaItem.genre == 'YouTube';
    final headers = _getAudioHeaders(isYouTube: isYouTube);

    if (!skipRefresh) {
      print('🎵 [AUDIO SOURCE] Creating audio source for: ${mediaItem.title}');
      print(
          '🎵 [AUDIO SOURCE] Genre: ${mediaItem.genre}, IsYouTube: $isYouTube');
    }
    final urlString = mediaItem.extras?['url']?.toString() ?? '';
    final urlPreview =
        urlString.length > 80 ? '${urlString.substring(0, 80)}...' : urlString;
    if (!skipRefresh) {
      print('🎵 [AUDIO SOURCE] URL: $urlPreview');
      print('🎵 [AUDIO SOURCE] Headers Referer: ${headers['Referer']}');
    }

    try {
      if (mediaItem.artUri.toString().startsWith('file:')) {
        audioSource =
            AudioSource.uri(Uri.file(mediaItem.extras!['url'].toString()));
      } else {
        if (downloadsBox != null &&
            downloadsBox!.containsKey(mediaItem.id) &&
            useDown) {
          Logger.root.info('Found ${mediaItem.id} in downloads');
          audioSource = AudioSource.uri(
            Uri.file(
              (downloadsBox!.get(mediaItem.id) as Map)['path'].toString(),
            ),
            tag: mediaItem.id,
          );
        } else {
          if (mediaItem.genre == 'YouTube') {
            print('🔍 [DEBUG] Processing YouTube item: ${mediaItem.title}');
            print('🔍 [DEBUG] skipRefresh flag: $skipRefresh');

            String? urlToUse;
            bool shouldRefreshUrl = false;

            final int expiredAt =
                int.parse((mediaItem.extras!['expire_at'] ?? '0').toString());
            final int currentTime =
                DateTime.now().millisecondsSinceEpoch ~/ 1000;

            print('🔍 [DEBUG] Current time (seconds): $currentTime');
            print('🔍 [DEBUG] Expiry time (seconds): $expiredAt');
            print(
                '🔍 [DEBUG] Time until expiry: ${expiredAt - currentTime} seconds');

            // Check if current URL is expired
            if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 350 >
                expiredAt) {
              print('🔍 [DEBUG] URL is expired or about to expire');
              // Check Hive cache for a fresh URL
              if (Hive.box('ytlinkcache').containsKey(mediaItem.id)) {
                final cachedData = Hive.box('ytlinkcache').get(mediaItem.id);
                if (cachedData is List) {
                  int minExpiredAt = 0;
                  for (final e in cachedData) {
                    final int cachedExpiredAt =
                        int.parse(e['expireAt'].toString());
                    if (minExpiredAt == 0 || cachedExpiredAt < minExpiredAt) {
                      minExpiredAt = cachedExpiredAt;
                    }
                  }

                  if ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 350 >
                      minExpiredAt) {
                    // Cache is also expired
                    print('🔍 [DEBUG] Cache is also expired');
                    shouldRefreshUrl = true;
                  } else {
                    // Found valid URL in cache
                    urlToUse = cachedData.last['url']?.toString();
                    if (urlToUse != null) {
                      mediaItem.extras!['url'] = urlToUse;
                      print('🔍 [DEBUG] Found valid URL in cache');
                      Logger.root.info('Found valid YouTube URL in Hive cache');
                    } else {
                      print('🔍 [DEBUG] Cache URL is null');
                      shouldRefreshUrl = true;
                    }
                  }
                } else {
                  print('🔍 [DEBUG] Cache data is not a List');
                  shouldRefreshUrl = true;
                }
              } else {
                print('🔍 [DEBUG] No cache found for this video');
                shouldRefreshUrl = true;
              }
            } else {
              // Current URL is likely valid
              print('🔍 [DEBUG] URL is still valid');
              urlToUse = mediaItem.extras!['url']?.toString();
              if (urlToUse == null) {
                print('🔍 [DEBUG] But URL is null in mediaItem');
                shouldRefreshUrl = true;
              } else {
                print('🔍 [DEBUG] Using URL from mediaItem');
              }
            }

            print('🔍 [DEBUG] shouldRefreshUrl: $shouldRefreshUrl');
            print(
                '🔍 [DEBUG] urlToUse: ${urlToUse != null ? "EXISTS" : "NULL"}');

            // If URL is expired and we're not skipping refresh, fetch a fresh one NOW
            if (shouldRefreshUrl && !skipRefresh) {
              print('🔄 [DEBUG] Fetching fresh URL from YouTube API...');
              try {
                final freshData = await YtMusicService().getSongData(
                  videoId: mediaItem.id,
                  quality: preferredQuality,
                );

                if (freshData.isNotEmpty && freshData['url'] != null) {
                  urlToUse = freshData['url'].toString();
                  mediaItem.extras!['url'] = urlToUse;
                  mediaItem.extras!['expire_at'] =
                      freshData['expire_at'].toString();
                  shouldRefreshUrl = false; // We now have a fresh URL
                  print(
                      '✅ [DEBUG] Got fresh URL! Expires: ${freshData['expire_at']}');
                } else {
                  print('❌ [DEBUG] Failed to get fresh URL from API');
                  return null;
                }
              } catch (e) {
                print('❌ [DEBUG] Error fetching fresh URL: $e');
                return null;
              }
            } else if (shouldRefreshUrl && skipRefresh) {
              print(
                  '⏸️ [DEBUG] URL expired but skipRefresh=true, returning null');
              return null;
            }

            // If we have a URL, stream it directly (don't download separately)
            if (!shouldRefreshUrl && urlToUse != null) {
              print('✅ [DEBUG] Creating audio source for streaming!');
              print(
                  '🔗 [STREAM URL] ${urlToUse.substring(0, urlToUse.length > 100 ? 100 : urlToUse.length)}...');

              // Mark as validated
              _validatedUrls[urlToUse] = DateTime.now();

              // Use LockCachingAudioSource to stream and cache directly
              // Now that we have valid URLs from youtube_explode_dart (decrypted signatures),
              // we don't need the custom proxy anymore.
              try {
                audioSource = LockCachingAudioSource(
                  Uri.parse(urlToUse),
                  tag: mediaItem.id,
                  headers: {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
                    'Referer': 'https://www.youtube.com/',
                  },
                );
                _mediaItemExpando[audioSource] = mediaItem;
                print(
                    '✅ [STREAM] Audio source created successfully (Direct Stream)!');
                return audioSource;
              } catch (e) {
                print('❌ [STREAM] Error creating audio source: $e');
                return null;
              }
            }

            // If still no valid URL after all attempts, return null
            if (shouldRefreshUrl || urlToUse == null) {
              print(
                  '❌ [DEBUG] No valid URL available after all attempts, returning null');
              return null;
            }
          } else {
            // Non-YouTube content (JioSaavn) logic preserved
            if (cacheSong) {
              audioSource = LockCachingAudioSource(
                Uri.parse(
                  mediaItem.extras!['url'].toString().replaceAll(
                        '_96.',
                        "_${preferredQuality.replaceAll(' kbps', '')}.",
                      ),
                ),
                headers: headers,
              );
            } else {
              audioSource = AudioSource.uri(
                Uri.parse(
                  mediaItem.extras!['url'].toString().replaceAll(
                        '_96.',
                        "_${preferredQuality.replaceAll(' kbps', '')}.",
                      ),
                ),
                headers: headers,
              );
            }
          }
        }
      }
    } catch (e) {
      Logger.root.severe('Error while creating audiosource', e);
    }
    if (audioSource != null) {
      _mediaItemExpando[audioSource] = mediaItem;
    }
    return audioSource;
  }

  Future<List<AudioSource>> _itemsToSources(List<MediaItem> mediaItems,
      {int? currentIndex}) async {
    preferredMobileQuality = Hive.box('settings')
        .get('streamingQuality', defaultValue: '96 kbps')
        .toString();
    preferredWifiQuality = Hive.box('settings')
        .get('streamingWifiQuality', defaultValue: '320 kbps')
        .toString();
    preferredQuality = connectionType == 'wifi'
        ? preferredWifiQuality
        : preferredMobileQuality;
    cacheSong =
        Hive.box('settings').get('cacheSong', defaultValue: false) as bool;
    useDown = Hive.box('settings').get('useDown', defaultValue: true) as bool;

    print(
        '🎯 [QUEUE] Processing ${mediaItems.length} items, current index: $currentIndex');

    final futures = mediaItems.asMap().entries.map((entry) async {
      final index = entry.key;
      final mediaItem = entry.value;

      // Only process YouTube URLs for current song and next song to avoid wasteful conversions
      // Other songs will be processed on-demand when they become current
      // When currentIndex is null, treat index 0 as the current song
      final shouldRefresh = currentIndex != null
          ? (index == currentIndex || index == currentIndex + 1)
          : (index == 0); // Process first song when currentIndex is null

      if (mediaItem.genre == 'YouTube' && !shouldRefresh) {
        print(
            '⏭️ [QUEUE] Deferring YouTube conversion for "${mediaItem.title}" (index $index)');
      } else if (mediaItem.genre == 'YouTube' && shouldRefresh) {
        print(
            '▶️ [QUEUE] Processing YouTube song "${mediaItem.title}" (index $index)');
      }

      return await _itemToSource(mediaItem, skipRefresh: !shouldRefresh);
    });

    final results = await Future.wait(futures);
    return results.whereType<AudioSource>().toList();
  }

  @override
  Future<void> onTaskRemoved() async {
    final bool stopForegroundService = Hive.box('settings')
        .get('stopForegroundService', defaultValue: true) as bool;
    if (stopForegroundService) {
      await stop();
    }
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        return _recentSubject.value;
      default:
        return queue.value;
    }
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        final stream = _recentSubject.map((_) => <String, dynamic>{});
        return _recentSubject.hasValue
            ? stream.shareValueSeeded(<String, dynamic>{})
            : stream.shareValue();
      default:
        return Stream.value(queue.value)
            .map((_) => <String, dynamic>{})
            .shareValue();
    }
  }

  Future<void> startService() async {
    bool withPipeline = false;
    if (Hive.isBoxOpen('settings')) {
      withPipeline =
          Hive.box('settings').get('supportEq', defaultValue: false) as bool;
    }

    // Configure optimized buffer settings for long videos (especially YouTube)
    final audioLoadConfiguration = AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        // Minimum buffer duration before playback starts (increased from default 2.5s to 5s)
        bufferForPlaybackDuration: const Duration(seconds: 5),
        // Minimum buffer duration before resuming after rebuffer (increased from default 5s to 10s)
        bufferForPlaybackAfterRebufferDuration: const Duration(seconds: 10),
        // Minimum amount to keep buffered ahead (increased from default 15s to 30s)
        minBufferDuration: const Duration(seconds: 30),
        // Maximum amount to buffer ahead (increased from default 50s to 180s / 3 minutes for long videos)
        maxBufferDuration: const Duration(seconds: 180),
        // Prioritize time-based buffering over size thresholds
        prioritizeTimeOverSizeThresholds: true,
      ),
    );

    if (withPipeline && Platform.isAndroid) {
      Logger.root.info('starting with eq pipeline and optimized buffer config');
      final AudioPipeline pipeline = AudioPipeline(
        androidAudioEffects: [
          _equalizer,
        ],
      );
      _player = AudioPlayer(
        audioPipeline: pipeline,
        audioLoadConfiguration: audioLoadConfiguration,
      );

      // Enable equalizer if used earlier
      Logger.root.info('setting eq enabled');
      final eqValue =
          Hive.box('settings').get('setEqualizer', defaultValue: false) as bool;
      _equalizer.setEnabled(eqValue);

      // set equalizer params & bands
      _equalizer.parameters.then((value) {
        Logger.root.info('setting eq params');
        _equalizerParams ??= value;

        final List<AndroidEqualizerBand> bands = _equalizerParams!.bands;
        bands.map(
          (e) {
            final gain = Hive.box('settings')
                .get('equalizerBand${e.index}', defaultValue: 0.5) as double;
            _equalizerParams!.bands[e.index].setGain(gain);
          },
        );
      });
    } else {
      Logger.root.info(
          'starting without eq pipeline but with optimized buffer config');
      _player = AudioPlayer(
        audioLoadConfiguration: audioLoadConfiguration,
      );
    }

    // Log buffer configuration for debugging
    print('🔧 [BUFFER CONFIG] AudioPlayer initialized with:');
    print('   - bufferForPlaybackDuration: 5s');
    print('   - bufferForPlaybackAfterRebufferDuration: 10s');
    print('   - minBufferDuration: 30s');
    print('   - maxBufferDuration: 180s (3 minutes)');
    print('   - prioritizeTimeOverSizeThresholds: true');
  }

  Future<void> addRecentlyPlayed(MediaItem mediaitem) async {
    Logger.root.info('adding ${mediaitem.id} to recently played');
    List recentList = await Hive.box('cache')
        .get('recentSongs', defaultValue: [])?.toList() as List;

    final Map songStats =
        await Hive.box('stats').get(mediaitem.id, defaultValue: {}) as Map;

    final Map mostPlayed =
        await Hive.box('stats').get('mostPlayed', defaultValue: {}) as Map;

    songStats['lastPlayed'] = DateTime.now().millisecondsSinceEpoch;
    songStats['playCount'] =
        songStats['playCount'] == null ? 1 : songStats['playCount'] + 1;
    songStats['isYoutube'] = mediaitem.genre == 'YouTube';
    songStats['title'] = mediaitem.title;
    songStats['artist'] = mediaitem.artist;
    songStats['album'] = mediaitem.album;
    songStats['id'] = mediaitem.id;
    Hive.box('stats').put(mediaitem.id, songStats);
    if ((songStats['playCount'] as int) >
        (mostPlayed['playCount'] as int? ?? 0)) {
      Hive.box('stats').put('mostPlayed', songStats);
    }
    Logger.root.info('adding ${mediaitem.id} data to stats');

    final Map item = MediaItemConverter.mediaItemToMap(mediaitem);
    recentList.insert(0, item);

    final jsonList = recentList.map((item) => jsonEncode(item)).toList();
    final uniqueJsonList = jsonList.toSet().toList();
    recentList = uniqueJsonList.map((item) => jsonDecode(item)).toList();

    if (recentList.length > 30) {
      recentList = recentList.sublist(0, 30);
    }
    Hive.box('cache').put('recentSongs', recentList);
  }

  Future<void> addLastQueue(List<MediaItem> queue) async {
    if (queue.isNotEmpty && queue.first.genre != 'YouTube') {
      Logger.root.info('saving last queue');
      final lastQueue =
          queue.map((item) => MediaItemConverter.mediaItemToMap(item)).toList();
      Hive.box('cache').put('lastQueue', lastQueue);
    }
  }

  Future<void> skipToMediaItem(String? id, int? idx) async {
    if (idx == null && id == null) return;
    final index = idx ?? queue.value.indexWhere((item) => item.id == id);
    if (index != -1) {
      _player!.seek(
        Duration.zero,
        index: _player!.shuffleModeEnabled
            ? _player!.shuffleIndices![index]
            : index,
      );
    } else {
      Logger.root.severe('skipToMediaItem: MediaItem not found');
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // Ensure playlist is initialized before adding items
    if (_playlistInitialized != null && !_playlistInitialized!.isCompleted) {
      await _playlistInitialized!.future;
    }
    final res = await _itemToSource(mediaItem);
    if (res != null) {
      try {
        await _playlist.add(res);
      } catch (e) {
        Logger.root.severe('Error adding queue item: $e');
        // If playlist is not initialized, initialize it now
        if (_player != null) {
          final completer = Completer<void>();
          _playlistInitialized = completer;
          await _player!
              .setAudioSource(_playlist, preload: false)
              .onError((error, stackTrace) {
            _onError(error, stackTrace, stopService: false);
            return null;
          });
          completer.complete();
          _playlistInitialized = null;
          // Retry adding the item
          await _playlist.add(res);
        }
      }
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // Ensure playlist is initialized before adding items
    if (_playlistInitialized != null && !_playlistInitialized!.isCompleted) {
      await _playlistInitialized!.future;
    }
    try {
      await _playlist.addAll(await _itemsToSources(mediaItems));
    } catch (e) {
      Logger.root.severe('Error adding queue items: $e');
      // If playlist is not initialized, initialize it now
      if (_player != null) {
        final completer = Completer<void>();
        _playlistInitialized = completer;
        await _player!
            .setAudioSource(_playlist, preload: false)
            .onError((error, stackTrace) {
          _onError(error, stackTrace, stopService: false);
          return null;
        });
        completer.complete();
        _playlistInitialized = null;
        // Retry adding the items
        await _playlist.addAll(await _itemsToSources(mediaItems));
      }
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    // Ensure playlist is initialized before inserting items
    if (_playlistInitialized != null && !_playlistInitialized!.isCompleted) {
      await _playlistInitialized!.future;
    }
    final res = await _itemToSource(mediaItem);
    if (res != null) {
      try {
        await _playlist.insert(index, res);
      } catch (e) {
        Logger.root.severe('Error inserting queue item: $e');
        // If playlist is not initialized, initialize it now
        if (_player != null) {
          final completer = Completer<void>();
          _playlistInitialized = completer;
          await _player!
              .setAudioSource(_playlist, preload: false)
              .onError((error, stackTrace) {
            _onError(error, stackTrace, stopService: false);
            return null;
          });
          completer.complete();
          _playlistInitialized = null;
          // Retry inserting the item
          await _playlist.insert(index, res);
        }
      }
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue,
      {int? currentIndex}) async {
    // Ensure playlist is initialized before clearing
    if (_playlistInitialized != null && !_playlistInitialized!.isCompleted) {
      await _playlistInitialized!.future;
    }

    try {
      await _playlist.clear();
      await _playlist
          .addAll(await _itemsToSources(newQueue, currentIndex: currentIndex));
    } catch (e) {
      Logger.root.severe('Error updating queue: $e');
      // If playlist is not initialized, initialize it now
      if (_player != null) {
        final completer = Completer<void>();
        _playlistInitialized = completer;
        await _player!
            .setAudioSource(_playlist, preload: false)
            .onError((error, stackTrace) {
          _onError(error, stackTrace, stopService: false);
          return null;
        });
        completer.complete();
        _playlistInitialized = null;
        // Retry updating the queue
        await _playlist.clear();
        await _playlist.addAll(
            await _itemsToSources(newQueue, currentIndex: currentIndex));
      }
    }
    addLastQueue(newQueue);
    // stationId = '';
    // stationNames = newQueue.map((e) => e.id).toList();
    // SaavnAPI()
    //     .createRadio(names: stationNames, stationType: stationType)
    //     .then((value) async {
    //   stationId = value;
    //   final List songsList = await SaavnAPI()
    //       .getRadioSongs(stationId: stationId!, count: 20 - newQueue.length);

    //   for (int i = 0; i < songsList.length; i++) {
    //     final element = MediaItemConverter.mapToMediaItem(
    //       songsList[i] as Map,
    //       addedByAutoplay: true,
    //     );
    //     if (!queue.value.contains(element)) {
    //       addQueueItem(element);
    //     }
    //   }
    // });
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    _mediaItemExpando[_player!.sequence![index]] = mediaItem;
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = queue.value.indexOf(mediaItem);
    await _playlist.removeAt(index);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    await _playlist.move(currentIndex, newIndex);
  }

  @override
  Future<void> skipToNext() => _player!.seekToNext();

  /// This is called when the user presses the "like" button.
  @override
  Future<void> fastForward() async {
    if (mediaItem.value?.id != null) {
      addItemToPlaylist('Favorite Songs', mediaItem.value!);
      _broadcastState(_player!.playbackEvent);
    }
  }

  @override
  Future<void> rewind() async {
    if (mediaItem.value?.id != null) {
      removeLiked(mediaItem.value!.id);
      _broadcastState(_player!.playbackEvent);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    resetOnSkip =
        Hive.box('settings').get('resetOnSkip', defaultValue: false) as bool;
    if (resetOnSkip) {
      if ((_player?.position.inSeconds ?? 5) <= 5) {
        _player!.seekToPrevious();
      } else {
        _player!.seek(Duration.zero);
      }
    } else {
      _player!.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.children.length) return;

    _player!.seek(
      Duration.zero,
      index:
          _player!.shuffleModeEnabled ? _player!.shuffleIndices![index] : index,
    );
  }

  @override
  Future<void> play() => _player!.play();

  @override
  Future<void> pause() async {
    _player!.pause();
    await Hive.box('cache').put('lastIndex', _player!.currentIndex);
    await Hive.box('cache').put('lastPos', _player!.position.inSeconds);
    await addLastQueue(queue.value);
  }

  @override
  Future<void> seek(Duration position) => _player!.seek(position);

  @override
  Future<void> stop() async {
    Logger.root.info('stopping player');
    await _player!.stop();
    await playbackState.firstWhere(
      (state) => state.processingState == AudioProcessingState.idle,
    );
    Logger.root.info('caching last index and position');
    await Hive.box('cache').put('lastIndex', _player!.currentIndex);
    await Hive.box('cache').put('lastPos', _player!.position.inSeconds);
    await addLastQueue(queue.value);
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) {
    if (name == 'sleepTimer') {
      _sleepTimer?.cancel();
      if (extras?['time'] != null &&
          extras!['time'].runtimeType == int &&
          extras['time'] > 0 as bool) {
        _sleepTimer = Timer(Duration(minutes: extras['time'] as int), () {
          stop();
        });
      }
    }
    if (name == 'sleepCounter') {
      if (extras?['count'] != null &&
          extras!['count'].runtimeType == int &&
          extras['count'] > 0 as bool) {
        count = extras['count'] as int;
      }
    }

    if (name == 'setBandGain') {
      final bandIdx = extras!['band'] as int;
      final gain = extras['gain'] as double;
      _equalizerParams!.bands[bandIdx].setGain(gain);
    }

    if (name == 'setEqualizer') {
      _equalizer.setEnabled(extras!['value'] as bool);
    }

    if (name == 'fastForward') {
      try {
        const stepInterval = Duration(seconds: 10);
        Duration newPosition = _player!.position + stepInterval;
        if (newPosition < Duration.zero) newPosition = Duration.zero;
        if (newPosition > _player!.duration!) newPosition = _player!.duration!;
        _player!.seek(newPosition);
      } catch (e) {
        Logger.root.severe('Error in fastForward', e);
      }
    }

    if (name == 'rewind') {
      try {
        const stepInterval = Duration(seconds: 10);
        Duration newPosition = _player!.position - stepInterval;
        if (newPosition < Duration.zero) newPosition = Duration.zero;
        if (newPosition > _player!.duration!) newPosition = _player!.duration!;
        _player!.seek(newPosition);
      } catch (e) {
        Logger.root.severe('Error in rewind', e);
      }
    }

    if (name == 'getEqualizerParams') {
      return getEqParms();
    }

    if (name == 'refreshLink') {
      if (extras?['newData'] != null) {
        refreshLink(extras!['newData'] as Map);
      }
    }

    if (name == 'skipToMediaItem') {
      skipToMediaItem(extras!['id'] as String?, extras['index'] as int?);
    }
    return super.customAction(name, extras);
  }

  Future<Map> getEqParms() async {
    _equalizerParams ??= await _equalizer.parameters;
    final List<AndroidEqualizerBand> bands = _equalizerParams!.bands;
    final List<Map> bandList = bands
        .map(
          (e) => {
            'centerFrequency': e.centerFrequency,
            'gain': e.gain,
            'index': e.index,
          },
        )
        .toList();

    return {
      'maxDecibels': _equalizerParams!.maxDecibels,
      'minDecibels': _equalizerParams!.minDecibels,
      'bands': bandList,
    };
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    final enabled = mode == AudioServiceShuffleMode.all;
    if (enabled) {
      await _player!.shuffle();
    }
    playbackState.add(playbackState.value.copyWith(shuffleMode: mode));
    await _player!.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    await _player!.setLoopMode(LoopMode.values[repeatMode.index]);
  }

  @override
  Future<void> setSpeed(double speed) async {
    this.speed.add(speed);
    await _player!.setSpeed(speed);
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume.add(volume);
    await _player!.setVolume(volume);
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.media:
        _handleMediaActionPressed();
      case MediaButton.next:
        await skipToNext();
      case MediaButton.previous:
        await skipToPrevious();
    }
  }

  late BehaviorSubject<int> _tappedMediaActionNumber;
  Timer? _timer;

  void _handleMediaActionPressed() {
    if (_timer == null) {
      _tappedMediaActionNumber = BehaviorSubject.seeded(1);
      _timer = Timer(const Duration(milliseconds: 800), () {
        final tappedNumber = _tappedMediaActionNumber.value;
        switch (tappedNumber) {
          case 1:
            if (playbackState.value.playing) {
              pause();
            } else {
              play();
            }
          case 2:
            skipToNext();
          case 3:
            skipToPrevious();
          default:
            break;
        }
        _tappedMediaActionNumber.close();
        _timer!.cancel();
        _timer = null;
      });
    } else {
      final current = _tappedMediaActionNumber.value;
      _tappedMediaActionNumber.add(current + 1);
    }
  }

  void _playbackError(err) {
    Logger.root.severe('Playback Error from audioservice: ${err.code}', err);

    // Debug: Print full error details
    if (err is PlatformException) {
      print('🔍 [ERROR DEBUG] PlatformException detected');
      print('🔍 [ERROR DEBUG] Error code: ${err.code}');
      print('🔍 [ERROR DEBUG] Error message: ${err.message}');
      print('🔍 [ERROR DEBUG] Error details: ${err.details}');
      print('🔍 [ERROR DEBUG] Error toString: ${err.toString()}');
    } else {
      print('🔍 [ERROR DEBUG] Error type: ${err.runtimeType}');
      print('🔍 [ERROR DEBUG] Error toString: ${err.toString()}');
    }

    if (err is PlatformException &&
        err.code == 'abort' &&
        err.message == 'Connection aborted') return;

    // Handle 403 errors by refreshing the URL
    // Check multiple possible error formats from ExoPlayer
    bool is403Error = false;
    if (err is PlatformException) {
      final errorCode = err.code.toString().toLowerCase();
      final errorMessage = err.message.toString().toLowerCase();
      final errorDetails = err.details?.toString().toLowerCase() ?? '';
      final errorString = err.toString().toLowerCase();

      // Enhanced 403 detection - check all possible places where 403 might appear
      is403Error = errorCode.contains('403') ||
          errorMessage.contains('403') ||
          errorMessage.contains('response code: 403') ||
          errorMessage.contains('forbidden') ||
          errorDetails.contains('403') ||
          errorDetails.contains('response code: 403') ||
          errorString.contains('403') ||
          errorString.contains('response code: 403') ||
          errorString.contains('forbidden') ||
          errorString.contains('invalidresponsecodexception') ||
          // ExoPlayer sometimes uses code '0' for source errors with 403
          (err.code == '0' && errorMessage.contains('source error')) ||
          // Check for TYPE_SOURCE errors which often indicate 403
          errorMessage.contains('type_source');

      if (is403Error) {
        print(
            '🚨 [403 DETECTED] 403 error detected! Code: ${err.code}, Message: ${err.message}');
        Logger.root
            .info('Detected 403 error, attempting to refresh URL immediately');

        // Immediately trigger URL refresh
        _handle403Error();
        return;
      } else {
        print(
            'ℹ️ [ERROR] Not a 403 error - Code: ${err.code}, Message: ${err.message}');
      }
    }

    _onError(err, null);
  }

  Future<void> _handle403Error() async {
    if (_isRefreshingUrl) {
      print('⏳ [403 HANDLER] URL refresh already in progress, skipping');
      Logger.root.info('URL refresh already in progress, skipping');
      return;
    }

    final currentItem = mediaItem.value;
    if (currentItem == null) {
      print('⚠️ [403 HANDLER] No current media item to refresh');
      Logger.root.warning('No current media item to refresh');
      return;
    }

    // Skip if not a YouTube item or if it's a local file
    if (currentItem.genre != 'YouTube' ||
        currentItem.extras?['url']?.toString().startsWith('file:') == true) {
      print('ℹ️ [403 HANDLER] Not a YouTube item or is local file, skipping');
      return;
    }

    _isRefreshingUrl = true;
    try {
      print('🔄 [403 HANDLER] Starting URL refresh for: ${currentItem.title}');
      Logger.root.info('Refreshing URL for: ${currentItem.title}');

      // Mark current URL as invalid immediately
      final currentUrl = currentItem.extras?['url']?.toString();
      if (currentUrl != null) {
        _validatedUrls.remove(currentUrl);
        print('❌ [403 HANDLER] Marked current URL as invalid');
      }

      // Clear the cache for this video to force a fresh fetch
      if (Hive.box('ytlinkcache').containsKey(currentItem.id)) {
        await Hive.box('ytlinkcache').delete(currentItem.id);
        print('🗑️ [403 HANDLER] Cleared cached URL to force fresh fetch');
      }

      // Trigger refresh
      refreshLinks.add(currentItem.id);
      if (!jobRunning) {
        refreshJob();
      }

      // Wait for the refresh to complete with exponential backoff
      bool urlRefreshed = false;
      final maxAttempts = 8; // Increased attempts for better recovery
      final delays = [
        1,
        1,
        2,
        2,
        3,
        3,
        4,
        5
      ]; // Exponential-ish backoff in seconds

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final delaySeconds = delays[attempt];
        print(
            '⏳ [403 HANDLER] Waiting ${delaySeconds}s before check (attempt ${attempt + 1}/$maxAttempts)...');
        await Future.delayed(Duration(seconds: delaySeconds));

        // Try to get the refreshed URL from cache
        if (Hive.box('ytlinkcache').containsKey(currentItem.id)) {
          final cachedData = Hive.box('ytlinkcache').get(currentItem.id);
          if (cachedData is List && cachedData.isNotEmpty) {
            final newUrl = cachedData.last['url']?.toString();
            if (newUrl != null && newUrl != currentUrl) {
              print(
                  '✅ [403 HANDLER] Found refreshed URL on attempt ${attempt + 1}');
              Logger.root.info('Found refreshed URL, updating media item');

              // Update the media item with new URL
              currentItem.extras!['url'] = newUrl;
              currentItem.extras!['expire_at'] =
                  cachedData.last['expireAt']?.toString() ??
                      (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600)
                          .toString();

              // Mark new URL as validated
              _validatedUrls[newUrl] = DateTime.now();

              // Get current index and replace the audio source
              final currentIndex = _player!.currentIndex;
              if (currentIndex != null) {
                final newSource = await _itemToSource(currentItem);
                if (newSource != null) {
                  try {
                    print(
                        '🔄 [403 HANDLER] Replacing audio source at index $currentIndex');

                    // Save current position before replacing
                    final currentPosition = _player!.position;

                    // Replace the current source
                    await _playlist.removeAt(currentIndex);
                    await _playlist.insert(currentIndex, newSource);

                    // Seek to current position and resume playback
                    await _player!.seek(currentPosition, index: currentIndex);

                    // Auto-play if we were playing before
                    if (playbackState.value.playing) {
                      await _player!.play();
                      print('▶️ [403 HANDLER] Resumed playback automatically');
                    }

                    print(
                        '✅ [403 HANDLER] Successfully refreshed and updated URL');
                    Logger.root.info('Successfully refreshed and updated URL');
                    urlRefreshed = true;
                    break;
                  } catch (e) {
                    print('❌ [403 HANDLER] Error replacing audio source: $e');
                    Logger.root.severe('Error replacing audio source: $e');
                  }
                } else {
                  print('❌ [403 HANDLER] Failed to create new audio source');
                }
              } else {
                print('❌ [403 HANDLER] Current index is null');
              }
            } else {
              print(
                  '⏳ [403 HANDLER] URL not refreshed yet (attempt ${attempt + 1}/$maxAttempts)');
            }
          }
        } else {
          print(
              '⏳ [403 HANDLER] Cache not updated yet (attempt ${attempt + 1}/$maxAttempts)');
        }
      }

      if (!urlRefreshed) {
        print(
            '⚠️ [403 HANDLER] URL refresh timeout - could not get new URL after $maxAttempts attempts');
        Logger.root.warning(
            'URL refresh timeout - could not get new URL after $maxAttempts attempts');
      }
    } catch (e) {
      print('❌ [403 HANDLER] Error handling 403: $e');
      Logger.root.severe('Error handling 403: $e');
    } finally {
      _isRefreshingUrl = false;
      print('🏁 [403 HANDLER] Refresh process completed');
    }
  }

  void _onError(err, stacktrace, {bool stopService = false}) {
    Logger.root.severe('Error from audioservice: ${err.code}', err);
    if (stopService) stop();
  }

  /// Broadcasts the current state to all clients.
  void _broadcastState(PlaybackEvent event) {
    final playing = _player!.playing;
    bool liked = false;
    if (mediaItem.value != null) {
      liked = checkPlaylist('Favorite Songs', mediaItem.value!.id);
    }
    final queueIndex = getQueueIndex(
      event.currentIndex,
      _player!.shuffleIndices,
      shuffleModeEnabled: _player!.shuffleModeEnabled,
    );
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          // workaround to add like button
          if (!Platform.isIOS)
            if (liked) MediaControl.rewind else MediaControl.fastForward,
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          if (!Platform.isIOS) MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: preferredCompactNotificationButtons,
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player!.processingState]!,
        playing: playing,
        updatePosition: _player!.position,
        bufferedPosition: _player!.bufferedPosition,
        speed: _player!.speed,
        queueIndex: queueIndex,
      ),
    );
  }
}
