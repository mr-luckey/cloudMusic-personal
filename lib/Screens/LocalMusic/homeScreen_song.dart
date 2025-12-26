import 'dart:io';
import 'package:blackhole/Services/player_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomescreenSong extends StatefulWidget {
  const HomescreenSong({super.key});

  @override
  State<HomescreenSong> createState() => _HomescreenSongState();
}

class _HomescreenSongState extends State<HomescreenSong> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _audioQuery.setLogConfig(logConfig);
    checkAndRequestPermissions();
  }

  checkAndRequestPermissions({bool retry = false}) async {
    _hasPermission = await _audioQuery.checkAndRequest(retryRequest: retry);
    if (_hasPermission) setState(() {});
  }

  Future<void> deleteSong(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        setState(() {});
      } else {
        print("File not found");
      }
    } catch (e) {
      print("Error deleting file: $e");
    }
  }

  Map<String, List<SongModel>> groupSongsByFirstLetter(List<SongModel> songs) {
    Map<String, List<SongModel>> groupedSongs = {};
    for (var song in songs) {
      if (song.title != null && song.title!.isNotEmpty) {
        String firstLetter = song.title![0].toUpperCase();
        if (!groupedSongs.containsKey(firstLetter)) {
          groupedSongs[firstLetter] = [];
        }
        groupedSongs[firstLetter]!.add(song);
      }
    }
    return Map.fromEntries(
      groupedSongs.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: const Text("MUSIC"),
      //   elevation: 2,
      // ),
      body: Center(
        child: !_hasPermission
            ? noAccessToLibraryWidget()
            : FutureBuilder<List<SongModel>>(
                future: _audioQuery.querySongs(
                  sortType: SongSortType.TITLE,
                  orderType: OrderType.ASC_OR_SMALLER,
                  uriType: UriType.EXTERNAL,
                  ignoreCase: true,
                ),
                builder: (context, item) {
                  if (item.hasError) {
                    return Text(item.error.toString());
                  }
                  if (item.data == null) {
                    return const CircularProgressIndicator();
                  }
                  if (item.data!.isEmpty) return const Text("Nothing found!");

                  final groupedSongs = groupSongsByFirstLetter(item.data!);

                  return ListView.builder(
                    itemCount: groupedSongs.length,
                    itemBuilder: (context, index) {
                      String letter = groupedSongs.keys.elementAt(index);
                      List<SongModel> songs = groupedSongs[letter]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, top: 8.0, bottom: 8.0),
                            child: Text(
                              letter,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: songs.length,
                              itemBuilder: (context, songIndex) {
                                final song = songs[songIndex];
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      PlayerInvoke.init(
                                        songsList: item.data!,
                                        index: item.data!.indexOf(song),
                                        isOffline: true,
                                        fromDownloads: false,
                                        recommend: false,
                                      );
                                    },
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          width: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Container(
                                        width: 160,
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: QueryArtworkWidget(
                                                controller: _audioQuery,
                                                id: song.id,
                                                type: ArtworkType.AUDIO,
                                                nullArtworkWidget: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Icon(
                                                    Icons.music_note,
                                                    size: 50,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              song.title!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              song.artist ?? "No Artist",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget noAccessToLibraryWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.redAccent.withOpacity(0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Application doesn't have access to the library"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => checkAndRequestPermissions(retry: true),
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }
}
