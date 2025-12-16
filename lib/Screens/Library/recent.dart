// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

class RecentlyPlayedController extends GetxController {
  final songs = <dynamic>[].obs;
  final added = false.obs;

  Future<void> getSongs() async {
    songs.value =
        Hive.box('cache').get('recentSongs', defaultValue: []) as List;
    added.value = true;
  }

  void clearAll() {
    Hive.box('cache').put('recentSongs', []);
    songs.clear();
  }

  void removeSong(int index) {
    songs.removeAt(index);
    Hive.box('cache').put('recentSongs', songs);
  }
}

class RecentlyPlayed extends StatelessWidget {
  const RecentlyPlayed({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RecentlyPlayedController());

    if (!controller.added.value) {
      controller.getSongs();
    }

    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.lastSession),
          centerTitle: true,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.transparent
              : Theme.of(context).colorScheme.secondary,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                controller.clearAll();
              },
              tooltip: AppLocalizations.of(context)!.clearAll,
              icon: const Icon(Icons.clear_all_rounded),
            ),
          ],
        ),
        body: Obx(
          () => controller.songs.isEmpty
              ? emptyScreen(
                  context,
                  3,
                  AppLocalizations.of(context)!.nothingTo,
                  15,
                  AppLocalizations.of(context)!.showHere,
                  50.0,
                  AppLocalizations.of(context)!.playSomething,
                  23.0,
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  shrinkWrap: true,
                  itemCount: controller.songs.length,
                  itemExtent: 70.0,
                  itemBuilder: (context, index) {
                    return controller.songs.isEmpty
                        ? const SizedBox()
                        : Dismissible(
                            key: Key(controller.songs[index]['id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: const ColoredBox(
                              color: Colors.redAccent,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.delete_outline_rounded),
                                  ],
                                ),
                              ),
                            ),
                            onDismissed: (direction) {
                              controller.removeSong(index);
                            },
                            child: ListTile(
                              leading: imageCard(
                                imageUrl:
                                    controller.songs[index]['image'].toString(),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // DownloadButton(
                                  //   data: controller.songs[index] as Map,
                                  //   icon: 'download',
                                  // ),
                                  LikeButton(
                                    mediaItem: null,
                                    data: controller.songs[index] as Map,
                                  ),
                                ],
                              ),
                              title: Text(
                                '${controller.songs[index]["title"]}',
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${controller.songs[index]["artist"]}',
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                PlayerInvoke.init(
                                  songsList: controller.songs,
                                  index: index,
                                  isOffline: false,
                                );
                              },
                            ),
                          );
                  },
                ),
        ),
      ),
    );
  }
}
