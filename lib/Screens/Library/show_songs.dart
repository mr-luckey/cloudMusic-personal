// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

class SongsListController extends GetxController {
  final List initialData;
  final bool initialOffline;

  SongsListController({
    required this.initialData,
    required this.initialOffline,
  });

  final songs = <dynamic>[].obs;
  final original = <dynamic>[].obs;
  final offline = false.obs;
  final added = false.obs;
  final processStatus = false.obs;
  final sortValue =
      (Hive.box('settings').get('sortValue', defaultValue: 1) as int).obs;
  final orderValue =
      (Hive.box('settings').get('orderValue', defaultValue: 1) as int).obs;

  @override
  void onInit() {
    super.onInit();
    getSongs();
  }

  Future<void> getSongs() async {
    added.value = true;
    songs.value = initialData;
    offline.value = initialOffline;
    if (!offline.value) original.value = List.from(songs);

    sortSongs(sortVal: sortValue.value, order: orderValue.value);

    processStatus.value = true;
  }

  void sortSongs({required int sortVal, required int order}) {
    switch (sortVal) {
      case 0:
        songs.sort(
          (a, b) => a['title']
              .toString()
              .toUpperCase()
              .compareTo(b['title'].toString().toUpperCase()),
        );
      case 1:
        songs.sort(
          (a, b) => a['dateAdded']
              .toString()
              .toUpperCase()
              .compareTo(b['dateAdded'].toString().toUpperCase()),
        );
      case 2:
        songs.sort(
          (a, b) => a['album']
              .toString()
              .toUpperCase()
              .compareTo(b['album'].toString().toUpperCase()),
        );
      case 3:
        songs.sort(
          (a, b) => a['artist']
              .toString()
              .toUpperCase()
              .compareTo(b['artist'].toString().toUpperCase()),
        );
      case 4:
        songs.sort(
          (a, b) => a['duration']
              .toString()
              .toUpperCase()
              .compareTo(b['duration'].toString().toUpperCase()),
        );
      default:
        songs.sort(
          (b, a) => a['dateAdded']
              .toString()
              .toUpperCase()
              .compareTo(b['dateAdded'].toString().toUpperCase()),
        );
        break;
    }

    if (order == 1) {
      songs.value = songs.reversed.toList();
    }
  }

  void updateSort(int value) {
    if (value < 5) {
      sortValue.value = value;
      Hive.box('settings').put('sortValue', value);
    } else {
      orderValue.value = value - 5;
      Hive.box('settings').put('orderValue', orderValue.value);
    }
    sortSongs(sortVal: sortValue.value, order: orderValue.value);
  }
}

class SongsList extends StatelessWidget {
  final List data;
  final bool offline;
  final String? title;

  const SongsList({
    super.key,
    required this.data,
    required this.offline,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SongsListController(
        initialData: data,
        initialOffline: offline,
      ),
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title ?? AppLocalizations.of(context)!.songs),
          actions: [
            Obx(
              () => PopupMenuButton(
                icon: const Icon(Icons.sort_rounded),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                ),
                onSelected: (int value) {
                  controller.updateSort(value);
                },
                itemBuilder: (context) {
                  final List<String> sortTypes = [
                    AppLocalizations.of(context)!.displayName,
                    AppLocalizations.of(context)!.dateAdded,
                    AppLocalizations.of(context)!.album,
                    AppLocalizations.of(context)!.artist,
                    AppLocalizations.of(context)!.duration,
                  ];
                  final List<String> orderTypes = [
                    AppLocalizations.of(context)!.inc,
                    AppLocalizations.of(context)!.dec,
                  ];
                  final menuList = <PopupMenuEntry<int>>[];
                  menuList.addAll(
                    sortTypes
                        .map(
                          (e) => PopupMenuItem(
                            value: sortTypes.indexOf(e),
                            child: Row(
                              children: [
                                if (controller.sortValue.value ==
                                    sortTypes.indexOf(e))
                                  Icon(
                                    Icons.check_rounded,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.grey[700],
                                  )
                                else
                                  const SizedBox(),
                                const SizedBox(width: 10),
                                Text(
                                  e,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                  menuList.add(
                    const PopupMenuDivider(
                      height: 10,
                    ),
                  );
                  menuList.addAll(
                    orderTypes
                        .map(
                          (e) => PopupMenuItem(
                            value: sortTypes.length + orderTypes.indexOf(e),
                            child: Row(
                              children: [
                                if (controller.orderValue.value ==
                                    orderTypes.indexOf(e))
                                  Icon(
                                    Icons.check_rounded,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.grey[700],
                                  )
                                else
                                  const SizedBox(),
                                const SizedBox(width: 10),
                                Text(
                                  e,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                  return menuList;
                },
              ),
            ),
          ],
          centerTitle: true,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.transparent
              : Theme.of(context).colorScheme.secondary,
          elevation: 0,
        ),
        body: Obx(
          () => !controller.processStatus.value
              ? const Center(
                  child: CircularProgressIndicator(),
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
                        : ListTile(
                            leading: imageCard(
                              localImage: controller.offline.value,
                              imageUrl: controller.offline.value
                                  ? controller.songs[index]['image'].toString()
                                  : controller.songs[index]['image'].toString(),
                            ),
                            title: Text(
                              '${controller.songs[index]['title']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${controller.songs[index]['artist']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              PlayerInvoke.init(
                                songsList: controller.songs,
                                index: index,
                                isOffline: controller.offline.value,
                                fromDownloads: controller.offline.value,
                                recommend: !controller.offline.value,
                              );
                            },
                          );
                  },
                ),
        ),
      ),
    );
  }
}
