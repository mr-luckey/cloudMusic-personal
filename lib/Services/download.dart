import 'dart:async';
import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
// import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/lyrics.dart';
import 'package:blackhole/Services/ext_storage_provider.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:blackhole/localization/app_localizations.dart';
// import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Download with ChangeNotifier {
  static final Map<String, Download> _instances = {};
  final String id;

  factory Download(String id) {
    if (_instances.containsKey(id)) {
      return _instances[id]!;
    } else {
      final instance = Download._internal(id);
      _instances[id] = instance;
      return instance;
    }
  }

  Download._internal(this.id);

  int? rememberOption;
  final ValueNotifier<bool> remember = ValueNotifier<bool>(false);
  String preferredDownloadQuality = Hive.box('settings')
      .get('downloadQuality', defaultValue: '320 kbps') as String;
  String preferredYtDownloadQuality = Hive.box('settings')
      .get('ytDownloadQuality', defaultValue: 'High') as String;
  String downloadFormat = Hive.box('settings')
      .get('downloadFormat', defaultValue: 'm4a')
      .toString();
  bool createDownloadFolder = Hive.box('settings')
      .get('createDownloadFolder', defaultValue: false) as bool;
  bool createYoutubeFolder = Hive.box('settings')
      .get('createYoutubeFolder', defaultValue: false) as bool;
  double? progress = 0.0;
  String lastDownloadId = '';
  bool downloadLyrics =
      Hive.box('settings').get('downloadLyrics', defaultValue: false) as bool;
  bool download = true;
  bool _isDownloading = false;
  int _downloadGeneration = 0;
  int _lastLoggedPercent = -1;
  StreamSubscription<List<int>>? _streamSubscription;
  Client? _httpClient;
  String? _activeFilepath;
  String? _activeImagePath;

  bool get isDownloading => _isDownloading;

  Future<void> cancelDownload() async {
    if (!_isDownloading) {
      Logger.root.info('Cancel ignored — no active download for $id');
      return;
    }
    Logger.root.info('Cancelling download for $id');
    _downloadGeneration++;
    download = false;
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _httpClient?.close();
    _httpClient = null;
    await _resetAfterCancel();
    Logger.root.info('Download cancelled for $id');
  }

  Future<void> _resetAfterCancel() async {
    download = true;
    progress = 0.0;
    _isDownloading = false;
    _lastLoggedPercent = -1;
    _streamSubscription = null;
    _httpClient = null;
    if (_activeFilepath != null) {
      try {
        await File(_activeFilepath!).delete();
      } catch (_) {}
    }
    if (_activeImagePath != null) {
      try {
        await File(_activeImagePath!).delete();
      } catch (_) {}
    }
    _activeFilepath = null;
    _activeImagePath = null;
    notifyListeners();
  }

  void _resetOnError() {
    download = true;
    progress = 0.0;
    _isDownloading = false;
    _lastLoggedPercent = -1;
    _streamSubscription = null;
    _httpClient = null;
    _activeFilepath = null;
    _activeImagePath = null;
    notifyListeners();
  }

  bool _isStale(int generation) =>
      !download || generation != _downloadGeneration;

  bool _isYouTubeSong(Map data) {
    final url = data['url']?.toString() ?? '';
    final language = data['language']?.toString() ?? '';
    final genre = data['genre']?.toString() ?? '';
    return language == 'YouTube' ||
        genre == 'YouTube' ||
        url.contains('google') ||
        url.contains('youtube');
  }

  bool _isDirectStreamUrl(String url) {
    return url.startsWith('http') &&
        (url.contains('googlevideo') ||
            url.contains('googleusercontent') ||
            url.contains('saavncdn') ||
            url.contains('jiosaavn'));
  }

  Map<String, String> _youtubeHeaders() => {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Referer': 'https://www.youtube.com/',
        'Origin': 'https://www.youtube.com',
        'Accept': '*/*',
      };

  Future<String> _resolveDownloadPath(String preferredPath) async {
    if (preferredPath.isNotEmpty) {
      try {
        final dir = Directory(preferredPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        // Verify write access with a tiny probe file.
        final probe = File('${dir.path}/.cloudspot_write_test');
        await probe.writeAsString('ok');
        await probe.delete();
        return preferredPath;
      } catch (e) {
        Logger.root.warning(
          'Download path not writable ($preferredPath), falling back: $e',
        );
      }
    }
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final fallback = '${docsDir.path}/Music';
    final fallbackDir = Directory(fallback);
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    await Hive.box('settings').put('downloadPath', fallback);
    return fallback;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _logProgress(int received, int total) {
    final receivedLabel = _formatBytes(received);
    if (total <= 0) {
      // Log every ~128 KB when size is unknown.
      final bucket = received ~/ (128 * 1024);
      if (bucket <= _lastLoggedPercent && received > 0) return;
      _lastLoggedPercent = bucket;
      final msg =
          '⬇️ Downloading [$id]: $receivedLabel / ? (size unknown)';
      print(msg);
      Logger.root.info(msg);
      return;
    }
    final percent = ((received / total) * 100).floor();
    // Log every 5% so progress is visible in console.
    if (percent < _lastLoggedPercent + 5 && percent < 100 && percent > 0) {
      return;
    }
    // Always log first chunk and completion.
    if (percent == _lastLoggedPercent && percent != 0 && percent != 100) {
      return;
    }
    _lastLoggedPercent = percent;
    final totalLabel = _formatBytes(total);
    final msg =
        '⬇️ Downloading [$id]: $receivedLabel / $totalLabel ($percent%)';
    print(msg);
    Logger.root.info(msg);
  }

  Future<void> prepareDownload(
    BuildContext context,
    Map data, {
    bool createFolder = false,
    String? folderName,
  }) async {
    Logger.root.info('Preparing download for ${data['title']}');
    final generation = ++_downloadGeneration;
    download = true;
    _isDownloading = true;
    // null => indeterminate spinner in UI (not stuck on "download" icon)
    progress = null;
    _lastLoggedPercent = -1;
    notifyListeners();
    if (Platform.isAndroid || Platform.isIOS) {
      Logger.root.info('Requesting storage permission');
      try {
        PermissionStatus status = await Permission.accessMediaLocation.status;
        if (status.isDenied) {
          Logger.root.info('Request denied');
          await [
            Permission.storage,
            Permission.accessMediaLocation,
            Permission.mediaLibrary,
          ].request();
        }
        status = await Permission.storage.status;
        if (status.isPermanentlyDenied) {
          Logger.root.info('Storage permanently denied — continuing with app dir fallback');
        }
      } catch (e) {
        Logger.root.warning('Permission request failed, continuing: $e');
      }
    }
    if (_isStale(generation)) {
      await _resetAfterCancel();
      return;
    }
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    data['title'] = data['title'].toString().split('(From')[0].trim();

    String filename = '';
    final int downFilename =
        Hive.box('settings').get('downFilename', defaultValue: 0) as int;
    if (downFilename == 0) {
      filename = '${data["title"]} - ${data["artist"]}';
    } else if (downFilename == 1) {
      filename = '${data["artist"]} - ${data["title"]}';
    } else {
      filename = '${data["title"]}';
    }
    // String filename = '${data["title"]} - ${data["artist"]}';
    String dlPath =
        Hive.box('settings').get('downloadPath', defaultValue: '') as String;
    Logger.root.info('Cached Download path: $dlPath');
    if (filename.length > 200) {
      final String temp = filename.substring(0, 200);
      final List tempList = temp.split(', ');
      tempList.removeLast();
      filename = tempList.join(', ');
    }

    filename = '${filename.replaceAll(avoid, "").replaceAll("  ", " ")}.m4a';
    if (dlPath == '') {
      Logger.root.info('Cached Download path is empty, getting new path');
      try {
        final String? temp = await ExtStorageProvider.getExtStorage(
          dirName: 'Music',
          writeAccess: true,
        );
        if (temp != null && temp.isNotEmpty) {
          dlPath = temp;
        }
      } catch (e) {
        Logger.root.warning('ExtStorageProvider failed: $e');
      }
    }
    dlPath = await _resolveDownloadPath(dlPath);
    Logger.root.info('New Download path: $dlPath');
    if (_isYouTubeSong(data) && createYoutubeFolder) {
      Logger.root.info('Youtube audio detected, creating Youtube folder');
      dlPath = '$dlPath/YouTube';
      if (!await Directory(dlPath).exists()) {
        Logger.root.info('Creating Youtube folder');
        await Directory(dlPath).create(recursive: true);
      }
    }

    if (createFolder && createDownloadFolder && folderName != null) {
      final String foldername = folderName.replaceAll(avoid, '');
      dlPath = '$dlPath/$foldername';
      if (!await Directory(dlPath).exists()) {
        Logger.root.info('Creating folder $foldername');
        await Directory(dlPath).create();
      }
    }

    if (_isStale(generation)) {
      await _resetAfterCancel();
      return;
    }

    final bool exists = await File('$dlPath/$filename').exists();
    if (exists) {
      Logger.root.info('File already exists');
      if (remember.value == true && rememberOption != null) {
        switch (rememberOption) {
          case 0:
            lastDownloadId = data['id'].toString();
            await _resetAfterCancel();
            break;
          case 1:
            downloadSong(
              dlPath,
              filename,
              data,
              generation: generation,
            );
            break;
          case 2:
            while (await File('$dlPath/$filename').exists()) {
              filename = filename.replaceAll('.m4a', ' (1).m4a');
            }
            downloadSong(
              dlPath,
              filename,
              data,
              generation: generation,
            );
            break;
          default:
            lastDownloadId = data['id'].toString();
            await _resetAfterCancel();
            break;
        }
      } else {
        _isDownloading = false;
        progress = 0.0;
        notifyListeners();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: Text(
                AppLocalizations.of(context)!.alreadyExists,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '"${data['title']}" ${AppLocalizations.of(context)!.downAgain}',
                    softWrap: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
              actions: [
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: remember,
                      builder: (
                        BuildContext context,
                        bool rememberValue,
                        Widget? child,
                      ) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                value: rememberValue,
                                onChanged: (bool? value) {
                                  remember.value = value ?? false;
                                },
                              ),
                              Text(
                                AppLocalizations.of(context)!.rememberChoice,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () {
                              lastDownloadId = data['id'].toString();
                              Navigator.pop(context);
                              rememberOption = 0;
                            },
                            child: Text(
                              AppLocalizations.of(context)!.no,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              Hive.box('downloads').delete(data['id']);
                              downloadSong(
                                dlPath,
                                filename,
                                data,
                              );
                              rememberOption = 1;
                            },
                            child:
                                Text(AppLocalizations.of(context)!.yesReplace),
                          ),
                          const SizedBox(width: 5.0),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              while (await File('$dlPath/$filename').exists()) {
                                filename =
                                    filename.replaceAll('.m4a', ' (1).m4a');
                              }
                              rememberOption = 2;
                              downloadSong(
                                dlPath,
                                filename,
                                data,
                              );
                            },
                            child: Text(
                              AppLocalizations.of(context)!.yes,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.secondary ==
                                            Colors.white
                                        ? Colors.black
                                        : null,
                              ),
                            ),
                          ),
                          const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    } else {
      downloadSong(
        dlPath,
        filename,
        data,
        generation: generation,
      );
    }
  }

  Future<void> downloadSong(
    String? dlPath,
    String fileName,
    Map data, {
    int? generation,
  }) async {
    final activeGeneration = generation ?? ++_downloadGeneration;
    Logger.root.info('processing download for ${data['id']} ($fileName)');
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _httpClient?.close();
    _httpClient = null;
    download = true;
    _isDownloading = true;
    progress = null;
    _lastLoggedPercent = -1;
    notifyListeners();
    String? filepath;
    late String filepath2;
    String? appPath;
    String resolvedPath = dlPath ?? '';
    final List<int> bytes = [];
    String lyrics = '';
    final artname = fileName.replaceAll('.m4a', '.jpg');
    try {
      if (!Platform.isWindows) {
        Logger.root.info('Getting App Path for storing image');
        appPath = Hive.box('settings').get('tempDirPath')?.toString();
        appPath ??= (await getTemporaryDirectory()).path;
      } else {
        final Directory? temp =
            await getDownloadsDirectory(); //change here to getApplicationDocumentsDirectory
        appPath = temp!.path;
      }

      if (_isStale(activeGeneration)) {
        await _resetAfterCancel();
        return;
      }

      try {
        Logger.root.info('Creating audio file $resolvedPath/$fileName');
        await File('$resolvedPath/$fileName')
            .create(recursive: true)
            .then((value) => filepath = value.path);
        Logger.root.info('Creating image file $appPath/$artname');
        await File('$appPath/$artname')
            .create(recursive: true)
            .then((value) => filepath2 = value.path);
      } catch (e) {
        Logger.root
            .info('Error creating files, requesting additional permission');
        if (Platform.isAndroid) {
          PermissionStatus status =
              await Permission.manageExternalStorage.status;
          if (status.isDenied) {
            Logger.root.info(
              'ManageExternalStorage permission is denied, requesting permission',
            );
            await [
              Permission.manageExternalStorage,
            ].request();
          }
          status = await Permission.manageExternalStorage.status;
          if (status.isPermanentlyDenied) {
            Logger.root.info(
              'ManageExternalStorage permanently denied — using app documents fallback',
            );
          }
        }

        // Fall back to a writable app documents path if external write failed.
        resolvedPath = await _resolveDownloadPath('');
        Logger.root.info('Retrying to create audio file at $resolvedPath');
        await File('$resolvedPath/$fileName')
            .create(recursive: true)
            .then((value) => filepath = value.path);

        Logger.root.info('Retrying to create image file');
        await File('$appPath/$artname')
            .create(recursive: true)
            .then((value) => filepath2 = value.path);
      }

      if (_isStale(activeGeneration)) {
        await _resetAfterCancel();
        return;
      }

      _activeFilepath = filepath;
      _activeImagePath = filepath2;

      String kUrl = data['url']?.toString() ?? '';
      final bool isYouTube = _isYouTubeSong(data);

      if (!isYouTube && kUrl.contains('_96.')) {
        Logger.root
            .info('Fetching jiosaavn download url with preferred quality');
        kUrl = kUrl.replaceAll(
          '_96.',
          "_${preferredDownloadQuality.replaceAll(' kbps', '')}.",
        );
      }

      int total = 0;
      int recieved = 0;
      Stream<List<int>> stream;
      // Download from yt — prefer existing stream URL (play screen already has
      // one) so we don't hit YouTube rate-limits via getStreamInfo again.
      if (isYouTube) {
        Stream<List<int>>? ytStream;
        if (_isDirectStreamUrl(kUrl)) {
          try {
            Logger.root.info(
              'YouTube download using current stream URL for ${data['id']}',
            );
            _httpClient = Client();
            final request = Request('GET', Uri.parse(kUrl));
            request.headers.addAll(_youtubeHeaders());
            final response = await _httpClient!.send(request);
            if (_isStale(activeGeneration)) {
              _httpClient?.close();
              _httpClient = null;
              await _resetAfterCancel();
              return;
            }
            if (response.statusCode >= 200 && response.statusCode < 300) {
              total = response.contentLength ?? 0;
              ytStream = response.stream;
            } else {
              Logger.root.warning(
                'Direct YT URL returned ${response.statusCode}, falling back to getStreamInfo',
              );
              _httpClient?.close();
              _httpClient = null;
            }
          } catch (e) {
            Logger.root.warning(
              'Direct YT URL download failed, falling back to getStreamInfo: $e',
            );
            _httpClient?.close();
            _httpClient = null;
          }
        }

        if (ytStream == null) {
          final streamInfos = await YouTubeServices.instance
              .getStreamInfo(data['id'].toString());
          if (_isStale(activeGeneration)) {
            await _resetAfterCancel();
            return;
          }
          if (streamInfos.isEmpty) {
            throw Exception('No stream available for ${data['id']}');
          }
          final AudioOnlyStreamInfo streamInfo =
              preferredYtDownloadQuality == 'Low'
                  ? streamInfos.first
                  : streamInfos.last;
          total = streamInfo.size.totalBytes;
          Logger.root.info(
            'YouTube stream size for ${data['id']}: $total bytes',
          );
          ytStream = YouTubeServices.instance.getStreamClient(streamInfo);
        }
        stream = ytStream;
      } else {
        Logger.root.info('Connecting to Client');
        _httpClient = Client();
        final response =
            await _httpClient!.send(Request('GET', Uri.parse(kUrl)));
        if (_isStale(activeGeneration)) {
          _httpClient?.close();
          _httpClient = null;
          await _resetAfterCancel();
          return;
        }
        total = response.contentLength ?? 0;
        Logger.root.info(
          'HTTP download size for ${data['id']}: $total bytes',
        );
        stream = response.stream;
      }
      Logger.root.info('Client connected, Starting download for ${data['id']}');
      final startMsg = total > 0
          ? '⬇️ Download started [$id]: 0 B / ${_formatBytes(total)} (0%)'
          : '⬇️ Download started [$id]: waiting for data...';
      print(startMsg);
      Logger.root.info(startMsg);
      _streamSubscription = stream.listen(
        (value) {
          if (_isStale(activeGeneration)) return;
          bytes.addAll(value);
          recieved += value.length;
          progress = total > 0 ? (recieved / total).clamp(0.0, 1.0) : null;
          _logProgress(recieved, total);
          notifyListeners();
        },
        onDone: () async {
          if (activeGeneration != _downloadGeneration) {
            Logger.root.info(
              'Ignoring stale download completion for ${data['id']}',
            );
            return;
          }
          _streamSubscription = null;
          _httpClient?.close();
          _httpClient = null;
          if (!download) {
            await _resetAfterCancel();
            return;
          }
          try {
            final doneMsg =
                '✅ Download complete [$id]: ${_formatBytes(recieved)}'
                '${total > 0 ? ' / ${_formatBytes(total)}' : ''} — saving file...';
            print(doneMsg);
            Logger.root.info(
              'Download complete for ${data['id']}: $recieved bytes, modifying file',
            );
            final file = File(filepath!);
            await file.writeAsBytes(bytes);

            final imageClient = HttpClient();
            final HttpClientRequest request2 =
                await imageClient.getUrl(Uri.parse(data['image'].toString()));
            final HttpClientResponse response2 = await request2.close();
            final bytes2 = await consolidateHttpClientResponseBytes(response2);
            final File file2 = File(filepath2);

            file2.writeAsBytesSync(bytes2);
            try {
              Logger.root.info('Checking if lyrics required');
              if (downloadLyrics) {
                Logger.root.info('downloading lyrics');
                final Map res = await Lyrics.getLyrics(
                  id: data['id'].toString(),
                  title: data['title'].toString(),
                  artist: data['artist']?.toString() ?? '',
                  album: data['album']?.toString() ?? '',
                  duration: data['duration']?.toString() ?? '180',
                  saavnHas: data['has_lyrics'] == 'true',
                );
                lyrics = res['lyrics'].toString();
              }
            } catch (e) {
              Logger.root.severe('Error fetching lyrics: $e');
              lyrics = '';
            }
            Logger.root.info('Getting audio tags');
            try {
              final Tag tag = Tag(
                title: data['title'].toString(),
                artist: data['artist'].toString(),
                albumArtist: data['album_artist']?.toString() ??
                    data['artist']?.toString().split(', ')[0] ??
                    '',
                artwork: filepath2,
                album: data['album'].toString(),
                genre: data['language'].toString(),
                year: data['year'].toString(),
                lyrics: lyrics,
                comment: 'Cloud Spot',
              );
              Logger.root.info('Started tag editing');
              final tagger = Audiotagger();
              await tagger.writeTags(
                path: filepath!,
                tag: tag,
              );
            } catch (e) {
              Logger.root.severe('Error editing tags: $e');
            }
            Logger.root.info('Closing connection & notifying listeners');
            imageClient.close();
            lastDownloadId = data['id'].toString();

            Logger.root.info('Putting data to downloads database');
            final songData = {
              'id': data['id'].toString(),
              'title': data['title'].toString(),
              'subtitle': data['subtitle'].toString(),
              'artist': data['artist'].toString(),
              'albumArtist': data['album_artist']?.toString() ??
                  data['artist']?.toString().split(', ')[0],
              'album': data['album'].toString(),
              'genre': data['language'].toString(),
              'year': data['year'].toString(),
              'lyrics': lyrics,
              'duration': data['duration'],
              'release_date': data['release_date'].toString(),
              'album_id': data['album_id'].toString(),
              'perma_url': data['perma_url'].toString(),
              'quality': preferredDownloadQuality,
              'path': filepath,
              'image': filepath2,
              'image_url': data['image'].toString(),
              'from_yt': data['language'].toString() == 'YouTube',
              'dateAdded': DateTime.now().toString(),
            };
            await Hive.box('downloads').put(songData['id'].toString(), songData);

            progress = 0.0;
            _isDownloading = false;
            _lastLoggedPercent = -1;
            _activeFilepath = null;
            _activeImagePath = null;
            notifyListeners();

            print('✅ Everything Done! [$id] saved to $filepath');
            Logger.root.info('Everything Done!');
          } catch (e, stackTrace) {
            Logger.root.severe('Error finalizing download: $e', e, stackTrace);
            await _resetAfterCancel();
          }
        },
        onError: (Object e, StackTrace stackTrace) async {
          if (activeGeneration != _downloadGeneration) return;
          Logger.root.severe('Error in download stream: $e', e, stackTrace);
          await _resetAfterCancel();
        },
        cancelOnError: true,
      );
    } catch (e, stackTrace) {
      if (activeGeneration != _downloadGeneration) return;
      Logger.root.severe('Download failed to start: $e', e, stackTrace);
      _resetOnError();
    }
  }
}
