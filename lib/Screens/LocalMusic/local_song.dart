import 'dart:io';
import 'package:blackhole/Services/player_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongsController extends GetxController {
  final OnAudioQuery audioQuery = OnAudioQuery();
  final hasPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    audioQuery.setLogConfig(logConfig);
    checkAndRequestPermissions();
  }

  Future<void> checkAndRequestPermissions({bool retry = false}) async {
    hasPermission.value = await audioQuery.checkAndRequest(retryRequest: retry);
  }

  Future<void> deleteSong(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        hasPermission.value = hasPermission.value; // Trigger rebuild
      }
    } catch (e) {
      // Handle error
    }
  }
}

class SongsWidget extends StatelessWidget {
  const SongsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SongsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('MUSIC'),
        elevation: 2,
      ),
      body: Center(
        child: Obx(
          () => !controller.hasPermission.value
              ? noAccessToLibraryWidget(controller)
              : FutureBuilder<List<SongModel>>(
                  future: controller.audioQuery.querySongs(
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
                    if (item.data!.isEmpty) return const Text('Nothing found!');
                    return item.data!.isNotEmpty
                        ? ListView.builder(
                            itemCount: item.data!.length,
                            itemBuilder: (context, index) {
                              final song = item.data![index];
                              return ListTile(
                                title: Text(
                                  song.title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(song.artist ?? 'No Artist'),
                                leading: QueryArtworkWidget(
                                  controller: controller.audioQuery,
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
                          )
                        : const Center(child: Text('No songs found'));
                  },
                ),
        ),
      ),
    );
  }

  Widget noAccessToLibraryWidget(SongsController controller) {
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
            onPressed: () => controller.checkAndRequestPermissions(retry: true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }
}
