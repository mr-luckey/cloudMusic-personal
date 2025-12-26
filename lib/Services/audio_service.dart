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
import 'package:blackhole/Services/youtube_services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerHandlerImpl extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements AudioPlayerHandler {
  int? count;
  Timer? _sleepTimer;
  bool recommend = true;
  bool loadStart = true;
  bool useDown = true;
  AndroidEqualizerParameters? _equalizerParams;
  // When true we are bulk-building sources for a whole queue; avoid
  // heavy network work (like refreshing YouTube URLs) here so playback
  // can start quickly and other items are prepared lazily.
  bool _isBuildingSources = false;

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
            Future.delayed(const Duration(seconds: 1), () async {
              if (item == mediaItem.value) {
                if (item.genre != 'YouTube') {
                  final List value = await SaavnAPI().getReco(item.id);
                  value.shuffle();
                  // final List value = await SaavnAPI().getRadioSongs(
                  //     stationId: stationId!, count: queueLength - index - 20);

                  for (int i = 0; i < value.length; i++) {
                    final element = MediaItemConverter.mapToMediaItem(
                      value[i] as Map,
                      addedByAutoplay: true,
                    );
                    if (!mediaQueue.contains(element)) {
                      addQueueItem(element);
                    }
                  }
                } else {
                  final res = await YtMusicService().getWatchPlaylist(
                    videoId: item.id,
                    limit: 15,
                  );
                  Logger.root.info('Recieved recommendations: $res');
                  refreshLinks.addAll(res);
                  if (!jobRunning) {
                    refreshJob();
                  }
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
          } else {
            final sources = await _itemsToSources(lastQueue);
            await _playlist.addAll(sources);
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
            }
          }
        } else {
          await _player!
              .setAudioSource(_playlist, preload: false)
              .onError((error, stackTrace) {
            _onError(error, stackTrace, stopService: true);
            return null;
          });
        }
      } else {
        await _player!
            .setAudioSource(_playlist, preload: false)
            .onError((error, stackTrace) {
          _onError(error, stackTrace, stopService: true);
          return null;
        });
      }
    } catch (e) {
      Logger.root.severe('Error while loading last queue', e);
      await _player!
          .setAudioSource(_playlist, preload: false)
          .onError((error, stackTrace) {
        _onError(error, stackTrace, stopService: true);
        return null;
      });
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

    addQueueItem(newItem);
  }

  Future<AudioSource?> _itemToSource(MediaItem mediaItem) async {
    AudioSource? audioSource;
    try {

      if (mediaItem.artUri.toString().startsWith('file:')) {
        try {
          final urlStr = mediaItem.extras?['url']?.toString();
          if (urlStr == null || urlStr.isEmpty) {
            Logger.root.warning(
              'Local file ${mediaItem.id} has no URL path',
            );
            return null;
          }
          audioSource = AudioSource.uri(Uri.file(urlStr));
        } catch (e, stackTrace) {
          Logger.root.severe(
            'Error creating audio source for local file ${mediaItem.id}',
            e,
            stackTrace,
          );
          return null;
        }
      } else {
        if (downloadsBox != null &&
            downloadsBox!.containsKey(mediaItem.id) &&
            useDown) {
          Logger.root.info('Found ${mediaItem.id} in downloads');
          try {
            final downloadData = downloadsBox!.get(mediaItem.id);
            if (downloadData is Map) {
              final path = downloadData['path']?.toString();
              if (path != null && path.isNotEmpty) {
                audioSource = AudioSource.uri(
                  Uri.file(path),
                  tag: mediaItem.id,
                );
              } else {
                Logger.root.warning(
                  'Download entry for ${mediaItem.id} has no valid path',
                );
                // Fall through to online source
              }
            } else {
              Logger.root.warning(
                'Download entry for ${mediaItem.id} is not a Map',
              );
              // Fall through to online source
            }
          } catch (e, stackTrace) {
            Logger.root.warning(
              'Error accessing download entry for ${mediaItem.id}',
              e,
              stackTrace,
            );
            // Fall through to online source
          }
        }

        if (audioSource == null) {
          if (mediaItem.genre == 'YouTube') {
            try {
              final String urlString =
                  mediaItem.extras?['url']?.toString() ?? '';

              // When building a whole queue, never block on network for
              // YouTube items. We only create sources if we already have
              // a URL; otherwise we skip them and they can be added later
              // on demand (e.g. when user plays them explicitly or via
              // background recommendation job).
              if (_isBuildingSources) {
                if (urlString.isEmpty) {
                  return null;
                }
                try {
                  audioSource = AudioSource.uri(Uri.parse(urlString));
                } catch (e) {
                  Logger.root.warning(
                    'Invalid YouTube URL format for ${mediaItem.id}: $e',
                  );
                  return null;
                }
              } else {
                int expiredAt = 0;
                try {
                  final expireAtStr =
                      (mediaItem.extras?['expire_at'] ?? '0').toString();
                  expiredAt = int.parse(expireAtStr);
                } catch (e) {
                  expiredAt = 0;
                }

                final int currentTime =
                    DateTime.now().millisecondsSinceEpoch ~/ 1000;


                // If we don't have a URL yet or it is expired/expiring soon,
                // refresh it synchronously for THIS item only.
                if (urlString.isEmpty || currentTime + 350 > expiredAt) {

                  Map? newData;
                  int retryCount = 0;
                  const maxRetries = 1;

                  while (retryCount <= maxRetries) {
                    try {
                      if (retryCount > 0) {
                        await Future.delayed(
                          Duration(milliseconds: 500 * retryCount),
                        );
                      }

                      newData = await YouTubeServices.instance
                          .refreshLink(
                        mediaItem.id,
                        useYTM: true,
                      )
                          .timeout(
                        const Duration(seconds: 30),
                        onTimeout: () {
                          return null;
                        },
                      );

                      if (newData != null &&
                          newData['url'] != null &&
                          newData['url'].toString().isNotEmpty) {
                        break;
                      } else {
                        if (retryCount >= maxRetries) {
                          Logger.root.severe(
                            'Failed to refresh YouTube link for ${mediaItem.title} after retries',
                          );
                          return null;
                        }
                      }
                    } catch (e, stackTrace) {
                      Logger.root.warning(
                        'Error in refreshLink retry for ${mediaItem.id}',
                        e,
                        stackTrace,
                      );
                      if (retryCount >= maxRetries) {
                        Logger.root.severe(
                          'Error refreshing YouTube link for ${mediaItem.title} after retries',
                          e,
                          stackTrace,
                        );
                        return null;
                      }
                    }
                    retryCount++;
                  }

                  if (newData != null &&
                      newData['url'] != null &&
                      newData['url'].toString().isNotEmpty) {
                    // Use fresh URL directly; do not try to reassign the
                    // final `extras` field of MediaItem (we only update
                    // the cache and use the URL locally here).
                    final freshUrl = newData['url'].toString();

                    // Update cache if URLs data is available
                    try {
                      final List<Map>? urlsData =
                          newData['urlsData'] as List<Map>?;
                      if (urlsData != null && urlsData.isNotEmpty) {
                        try {
                          if (Hive.isBoxOpen('ytlinkcache')) {
                            await Hive.box('ytlinkcache')
                                .put(mediaItem.id, urlsData);
                          } else {
                          }
                        } catch (e) {
                          Logger.root.warning(
                            'Failed to update cache for ${mediaItem.id}',
                            e,
                          );
                        }
                      }
                    } catch (e) {
                    }

                    try {
                      audioSource = AudioSource.uri(Uri.parse(freshUrl));
                    } catch (e) {
                      Logger.root.severe(
                        'Invalid YouTube URL format after refresh for ${mediaItem.id}: $e',
                      );
                      return null;
                    }
                  } else {
                    return null;
                  }
                } else {
                  if (urlString.isEmpty) {
                    return null;
                  }
                  try {
                    audioSource = AudioSource.uri(Uri.parse(urlString));
                  } catch (e) {
                    Logger.root.severe(
                      'Invalid YouTube URL format for ${mediaItem.id}: $e',
                    );
                    return null;
                  }
                }
              }

              // At this point `audioSource` should not be null for YouTube items.
              if (audioSource != null) {
                _mediaItemExpando[audioSource] = mediaItem;
                return audioSource;
              } else {
                return null;
              }
            } catch (e, stackTrace) {
              Logger.root.severe(
                'Critical error creating YouTube audio source for ${mediaItem.id}',
                e,
                stackTrace,
              );
              return null;
            }
          } else {
            try {
              // Always use progressive streaming for non-YouTube songs as well.
              // This starts playback quickly (after a small buffer) and continues
              // loading in the background, similar to YouTube's behavior.
              //
              // We intentionally avoid full-file disk caching here because that
              // can delay the start of playback on long songs/videos.
              final urlStr = mediaItem.extras?['url']?.toString();
              if (urlStr == null || urlStr.isEmpty) {
                Logger.root.warning(
                  'Non-YouTube song ${mediaItem.id} has no URL',
                );
                return null;
              }

              final uri = Uri.parse(
                urlStr.replaceAll(
                  '_96.',
                  "_${preferredQuality.replaceAll(' kbps', '')}.",
                ),
              );
              audioSource = AudioSource.uri(uri);
            } catch (e, stackTrace) {
              Logger.root.severe(
                'Error creating audio source for non-YouTube song ${mediaItem.id}',
                e,
                stackTrace,
              );
              return null;
            }
          }
        }
      }
    } catch (e, stackTrace) {
      Logger.root.severe(
          'Error while creating audiosource for ${mediaItem.title}',
          e,
          stackTrace);
    }

    if (audioSource != null) {
      _mediaItemExpando[audioSource] = mediaItem;
    } else {
    }

    return audioSource;
  }

  Future<List<AudioSource>> _itemsToSources(List<MediaItem> mediaItems) async {
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

    final List<AudioSource> sources = [];
    _isBuildingSources = true;
    try {
      for (int i = 0; i < mediaItems.length; i++) {
        try {
          final source = await _itemToSource(mediaItems[i]);
          if (source != null) {
            sources.add(source);
          } else {
            Logger.root.warning(
              'Failed to create audio source for ${mediaItems[i].title}',
            );
          }
        } catch (e) {
          Logger.root.severe(
            'Error creating audio source for ${mediaItems[i].title}',
            e,
          );
        }
      }
    } finally {
      _isBuildingSources = false;
    }

    return sources;
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
    if (withPipeline && Platform.isAndroid) {
      Logger.root.info('starting with eq pipeline');
      final AudioPipeline pipeline = AudioPipeline(
        androidAudioEffects: [
          _equalizer,
        ],
      );
      _player = AudioPlayer(audioPipeline: pipeline);

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
      Logger.root.info('starting without eq pipeline');
      _player = AudioPlayer();
    }
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
    final res = await _itemToSource(mediaItem);
    if (res != null) {
      await _playlist.add(res);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final sources = await _itemsToSources(mediaItems);
    await _playlist.addAll(sources);
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    final res = await _itemToSource(mediaItem);
    if (res != null) {
      await _playlist.insert(index, res);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    await _playlist.clear();
    final sources = await _itemsToSources(newQueue);
    await _playlist.addAll(sources);
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
    if (err is PlatformException &&
        err.code == 'abort' &&
        err.message == 'Connection aborted') return;
    _onError(err, null);
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
