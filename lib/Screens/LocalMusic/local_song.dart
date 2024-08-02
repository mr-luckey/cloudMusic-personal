import 'dart:io';
import 'package:blackhole/Services/player_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongsWidget extends StatefulWidget {
  const SongsWidget({Key? key}) : super(key: key);

  @override
  _SongsWidgetState createState() => _SongsWidgetState();
}

class _SongsWidgetState extends State<SongsWidget> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MUSIC"),
        elevation: 2,
      ),
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
                  return ListView.builder(
                    itemCount: item.data!.length,
                    itemBuilder: (context, index) {
                      final song = item.data![index];
                      print(
                          'Song title: ${song.title}, Artist: ${song.artist}');
                      return ListTile(
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(song.artist ?? "No Artist"),
                        leading: QueryArtworkWidget(
                          controller: _audioQuery,
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                        ),
                        onTap: () {
                          PlayerInvoke.init(
                            songsList: item.data!,
                            index: index,
                            isOffline: true,
                            fromDownloads: false,
                            recommend: false,
                          );
                        },
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
