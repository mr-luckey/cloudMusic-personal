import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

// ignore: avoid_classes_with_only_static_members
class PlayerInvoke {
  static final AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();

  static Future<void> init({
    required List songsList,
    required int index,
    bool fromMiniplayer = false,
    bool? isOffline,
    bool recommend = true,
    bool fromDownloads = false,
    bool shuffle = false,
    String? playlistBox,
  }) async {
    final int globalIndex = index < 0 ? 0 : index;
    bool? offline = isOffline;
    final List finalList = songsList.toList();
    if (shuffle) finalList.shuffle();
    if (offline == null) {
      if (audioHandler.mediaItem.value?.extras!['url'].startsWith('http')
          as bool) {
        offline = false;
      } else {
        offline = true;
      }
    }

    if (!fromMiniplayer) {
      if (Platform.isIOS) {
        // Don't know why but it fixes the playback issue with iOS Side
        audioHandler.stop();
      }
      if (offline) {
        fromDownloads
            ? setDownValues(finalList, globalIndex)
            : (Platform.isWindows || Platform.isLinux)
                ? setOffDesktopValues(finalList, globalIndex)
                : setOffValues(finalList, globalIndex);
      } else {
        setValues(
          finalList,
          globalIndex,
          recommend: recommend,
          // playlistBox: playlistBox,
        );
      }
    }
  }

  static Future<MediaItem> setTags(
    SongModel response,
    Directory tempDir,
  ) async {
    String playTitle = response.title;
    playTitle == 'Unknown'
        ? playTitle = response.displayNameWOExt
        : playTitle = response.title;
    String playArtist =
        response.artist != null ? response.artist! : '<unknown>';
    playArtist == '<unknown>'
        ? playArtist = 'Unknown'
        : playArtist = response.artist!;

    final String playAlbum =
        response.album != null ? response.album! : '<unknown>';
    final int playDuration = response.duration ?? 180000;
    final String? imagePath =
        '${tempDir.path}/${response.displayNameWOExt}.png';

    final MediaItem tempDict = MediaItem(
      id: response.id.toString(),
      album: playAlbum,
      duration: Duration(milliseconds: playDuration),
      title: playTitle.split('(')[0],
      artist: playArtist,
      genre: response.genre,
      artUri: Uri.file(imagePath!),
      extras: {
        'url': response.data,
        'date_added': response.dateAdded,
        'date_modified': response.dateModified,
        'size': response.size,
        'year': response.getMap['year'],
      },
    );
    return tempDict;
  }

  static void setOffDesktopValues(List response, int index) {
    getTemporaryDirectory().then((tempDir) async {
      final File file = File('${tempDir.path}/cover.jpg');
      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/cover.jpg');
        await file.writeAsBytes(
          byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
      }
      final List<MediaItem> queue = [];
      queue.addAll(
        response.map(
          (song) => MediaItem(
            id: song['id'].toString(),
            album: song['album'].toString(),
            artist: song['artist'].toString(),
            duration: Duration(
              seconds: int.parse(
                (song['duration'] == null || song['duration'] == 'null')
                    ? '180'
                    : song['duration'].toString(),
              ),
            ),
            title: song['title'].toString(),
            artUri: Uri.file(file.path),
            genre: song['genre'].toString(),
            extras: {
              'url': song['path'].toString(),
              'subtitle': song['subtitle'],
              'quality': song['quality'],
            },
          ),
        ),
      );
      updateNplay(queue, index);
    });
  }

  static void setOffValues(List response, int index) {
    getTemporaryDirectory().then((tempDir) async {
      final File file = File('${tempDir.path}/cover.jpg');
      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/cover.jpg');
        await file.writeAsBytes(
          byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
      }

      final List<MediaItem> queue = [];
      for (int i = 0; i < response.length; i++) {
        queue.add(
          await setTags(response[i] as SongModel, tempDir),
        );
      }
      updateNplay(queue, index);
    });
  }

  static void setDownValues(List response, int index) {
    final List<MediaItem> queue = [];
    queue.addAll(
      response.map(
        (song) => MediaItemConverter.downMapToMediaItem(song as Map),
      ),
    );
    updateNplay(queue, index);
  }

  /// Refreshes YouTube link if expired. Returns true if successful, false otherwise.
  /// Does NOT throw exceptions - caller should check return value.
  static Future<bool> refreshYtLink(Map playItem) async {
    try {
      final int expiredAt =
          int.parse((playItem['expire_at'] ?? '0').toString());
      final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int timeUntilExpiry = expiredAt - currentTime;

      // Check if URL already exists and is a valid stream URL (not just a watch URL)
      final existingUrl = playItem['url']?.toString() ?? '';
      final bool hasValidStreamUrl = existingUrl.isNotEmpty && 
          (existingUrl.contains('googlevideo.com') || existingUrl.contains('google.com'));

      // If URL is valid and not expired, no need to refresh
      if (hasValidStreamUrl && currentTime + 350 <= expiredAt) {
        Logger.root.info('YouTube URL still valid for ${playItem["title"]}');
        return true;
      }

      Logger.root.info(
        'before service | youtube link needs refresh for ${playItem["title"]} (expired: ${currentTime + 350 > expiredAt}, hasValidUrl: $hasValidStreamUrl)',
      );

      // Try cache first
      if (Hive.isBoxOpen('ytlinkcache') &&
          Hive.box('ytlinkcache').containsKey(playItem['id'])) {
        final cache = Hive.box('ytlinkcache').get(playItem['id']);

        if (cache is List && cache.isNotEmpty) {
          int minExpiredAt = 0;
          for (final e in cache) {
            try {
              final int cachedExpiredAt = int.parse(e['expireAt'].toString());
              if (minExpiredAt == 0 || cachedExpiredAt < minExpiredAt) {
                minExpiredAt = cachedExpiredAt;
              }
            } catch (e) {
              minExpiredAt = 0;
              break;
            }
          }

          // Check if cache is still valid
          if (minExpiredAt > 0 && currentTime + 350 <= minExpiredAt) {
            Logger.root.info('youtube link found in cache for ${playItem["title"]}');
            final lastCacheItem = cache.last as Map;
            if (lastCacheItem['url'] != null &&
                lastCacheItem['url'].toString().isNotEmpty) {
              playItem['url'] = lastCacheItem['url'];
              playItem['expire_at'] = lastCacheItem['expireAt'];
              return true;
            }
          }
        }
      }

      // Cache miss or expired, fetch fresh URL
      Logger.root.info('Fetching fresh YouTube link for ${playItem["title"]}');
      final newData = await YouTubeServices.instance
          .refreshLink(playItem['id'].toString())
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Logger.root.warning('Timeout refreshing YouTube link for ${playItem["title"]}');
          return null;
        },
      );

      if (newData != null &&
          newData['url'] != null &&
          newData['url'].toString().isNotEmpty) {
        playItem['url'] = newData['url'];
        playItem['duration'] = newData['duration'] ?? playItem['duration'];
        playItem['expire_at'] = newData['expire_at'];
        Logger.root.info('Successfully refreshed YouTube link for ${playItem["title"]}');
        return true;
      } else {
        Logger.root.warning('Failed to refresh YouTube link for ${playItem["title"]}: API returned null or empty');
        return false;
      }
    } catch (e) {
      Logger.root.severe('Error refreshing YouTube link for ${playItem["title"]}', e);
      return false;
    }
  }

  static Future<void> setValues(
    List response,
    int index, {
    bool recommend = true,
    // String? playlistBox,
  }) async {
    try {
      final List<MediaItem> queue = [];
      final Map playItem = response[index] as Map;
      final Map? nextItem =
          index == response.length - 1 ? null : response[index + 1] as Map;

      // Refresh YouTube link for the current item (required to play)
      if (playItem['genre'] == 'YouTube' || playItem['language'] == 'YouTube') {
        final success = await refreshYtLink(playItem);
        if (!success) {
          Logger.root.warning('Failed to get YouTube URL for ${playItem["title"]}, playback may fail');
          // Continue anyway - the audio service will handle the error
        }
      }

      // Pre-fetch next item in background (non-blocking)
      if (nextItem != null && (nextItem['genre'] == 'YouTube' || nextItem['language'] == 'YouTube')) {
        // Don't await - let it happen in background
        refreshYtLink(nextItem).then((success) {
          if (!success) {
            Logger.root.info('Background refresh failed for next item ${nextItem["title"]}');
          }
        });
      }

      queue.addAll(
        response.map(
          (song) => MediaItemConverter.mapToMediaItem(
            song as Map,
            autoplay: recommend,
            // playlistBox: playlistBox,
          ),
        ),
      );
      await updateNplay(queue, index);
    } catch (e, stackTrace) {
      Logger.root.severe('Error in setValues', e, stackTrace);
      // Don't rethrow - we don't want to crash the app
    }
  }

  static Future<void> updateNplay(List<MediaItem> queue, int index) async {
    await audioHandler.updateQueue(queue);
    await audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    await audioHandler.customAction('skipToMediaItem', {'id': queue[index].id});
    await audioHandler.play();
    final String repeatMode =
        Hive.box('settings').get('repeatMode', defaultValue: 'None').toString();
    final bool enforceRepeat =
        Hive.box('settings').get('enforceRepeat', defaultValue: false) as bool;
    if (enforceRepeat) {
      switch (repeatMode) {
        case 'None':
          audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        case 'All':
          audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        case 'One':
          audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        default:
          break;
      }
    } else {
      audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
      Hive.box('settings').put('repeatMode', 'None');
    }
  }
}
