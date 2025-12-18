// Coded by Naseer Ahmed

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
// import 'package:blackhole/G-Ads.dart/intersatail_ads.dart';
import 'package:blackhole/Services/download.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

class DownloadButtonController extends GetxController {
  final String songId;
  late Download down;
  final Box downloadsBox = Hive.box('downloads');
  final showStopButton = false.obs;

  DownloadButtonController({required this.songId});

  @override
  void onInit() {
    super.onInit();
    down = Download(songId);
    down.addListener(() {
      update();
    });
  }
}

class DownloadButton extends StatelessWidget {
  final Map data;
  final String? icon;
  final double? size;

  const DownloadButton({
    super.key,
    required this.data,
    this.icon,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final songId = data['id']?.toString() ?? 'unknown_id';
    
    return SizedBox.square(
      dimension: 50,
      child: Center(
        child: GetBuilder<DownloadButtonController>(
          tag: songId,
          init: DownloadButtonController(songId: songId),
          builder: (controller) {
            final id = data['id']?.toString() ?? 'unknown_id';
            return (controller.downloadsBox.containsKey(id))
                ? IconButton(
                    icon: const Icon(Icons.download_done_rounded),
                    tooltip: 'Download Done',
                    color: Theme.of(context).colorScheme.secondary,
                    iconSize: size ?? 24.0,
                    onPressed: () {
                      // AdManager.showInterstitialAd();
                      // rewardedAdManager.showRewardedAd(context, () {
                      controller.down.prepareDownload(context, data);
                      // });
                    },
                  )
                : controller.down.progress == 0
                    ? IconButton(
                        icon: Icon(
                          icon == 'download'
                              ? Icons.download_rounded
                              : Icons.save_alt,
                        ),
                        iconSize: size ?? 24.0,
                        color: Theme.of(context).iconTheme.color,
                        tooltip: 'Download',
                        onPressed: () {
                          // rewardedAdManager.showRewardedAd(context, () {
                          controller.down.prepareDownload(context, data);
                          // });
                          // AdManager.showInterstitialAd();
                          // down.prepareDownload(context, widget.data);
                        },
                      )
                    : GestureDetector(
                        child: Stack(
                          children: [
                            Center(
                              child: CircularProgressIndicator(
                                value: controller.down.progress == 1
                                    ? null
                                    : (controller.down.progress ?? 0),
                              ),
                            ),
                            Center(
                              child: Obx(
                                () {
                                  final showValue =
                                      controller.showStopButton.value;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (!showValue)
                                          Center(
                                            child: Text(
                                              controller.down.progress == null
                                                  ? '0%'
                                                  : '${(100 * (controller.down.progress ?? 0)).round()}%',
                                            ),
                                          ),
                                        if (showValue)
                                          Center(
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                              iconSize: 25.0,
                                              color: Theme.of(context)
                                                  .iconTheme
                                                  .color,
                                              tooltip: AppLocalizations.of(
                                                    context,
                                                  )?.stopDown ??
                                                  'Stop Download',
                                              onPressed: () {
                                                controller.down.download =
                                                    false;
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          controller.showStopButton.value = true;
                          Future.delayed(const Duration(seconds: 2), () async {
                            controller.showStopButton.value = false;
                          });
                        },
                      );
          },
        ),
      ),
    );
  }
}

class MultiDownloadButtonController extends GetxController {
  final List data;
  late Download down;
  final done = 0.obs;

  MultiDownloadButtonController({required this.data});

  @override
  void onInit() {
    super.onInit();
    down = Download(data.first['id'].toString());
    down.addListener(() {
      update();
    });
  }

  Future<void> waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  void incrementDone() {
    done.value++;
  }
}

class MultiDownloadButton extends StatelessWidget {
  final List data;
  final String playlistName;

  const MultiDownloadButton({
    super.key,
    required this.data,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox();
    }

    final controller = Get.put(
      MultiDownloadButtonController(data: data),
      tag: playlistName,
    );

    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: GetBuilder<MultiDownloadButtonController>(
          tag: playlistName,
          builder: (controller) {
            return (controller.down.lastDownloadId == data.last['id'])
                ? IconButton(
                    icon: const Icon(
                      Icons.download_done_rounded,
                    ),
                    color: Theme.of(context).colorScheme.secondary,
                    iconSize: 25.0,
                    tooltip: AppLocalizations.of(context)?.downDone ??
                        'Download Done',
                    onPressed: () {},
                  )
                : controller.down.progress == 0
                    ? Center(
                        child: IconButton(
                          icon: const Icon(
                            Icons.download_rounded,
                          ),
                          iconSize: 25.0,
                          tooltip:
                              AppLocalizations.of(context)?.down ?? 'Download',
                          onPressed: () async {
                            // AdManager.showInterstitialAd();
                            // rewardedAdManager.showRewardedAd(context, () async {
                            for (final items in data) {
                              controller.down.prepareDownload(
                                context,
                                items as Map,
                                createFolder: true,
                                folderName: playlistName,
                              );
                              await controller
                                  .waitUntilDone(items['id'].toString());
                              controller.incrementDone();
                            }
                            // });
                          },
                        ),
                      )
                    : Obx(
                        () => Stack(
                          children: [
                            Center(
                              child: Text(
                                controller.down.progress == null
                                    ? '0%'
                                    : '${(100 * (controller.down.progress ?? 0)).round()}%',
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                height: 35,
                                width: 35,
                                child: CircularProgressIndicator(
                                  value: controller.down.progress == 1
                                      ? null
                                      : controller.down.progress,
                                ),
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                height: 30,
                                width: 30,
                                child: CircularProgressIndicator(
                                  value: controller.done.value / data.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
          },
        ),
      ),
    );
  }
}

class AlbumDownloadButtonController extends GetxController {
  final String albumId;
  final String albumName;
  late Download down;
  final done = 0.obs;
  final data = <dynamic>[].obs;
  final finished = false.obs;

  AlbumDownloadButtonController({
    required this.albumId,
    required this.albumName,
  });

  @override
  void onInit() {
    super.onInit();
    down = Download(albumId);
    down.addListener(() {
      update();
    });
  }

  Future<void> waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  void incrementDone() {
    done.value++;
  }
}

class AlbumDownloadButton extends StatelessWidget {
  final String albumId;
  final String albumName;

  const AlbumDownloadButton({
    super.key,
    required this.albumId,
    required this.albumName,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AlbumDownloadButtonController(
        albumId: albumId,
        albumName: albumName,
      ),
      tag: albumId,
    );

    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: GetBuilder<AlbumDownloadButtonController>(
          tag: albumId,
          builder: (controller) {
            return Obx(
              () => controller.finished.value
                  ? IconButton(
                      icon: const Icon(
                        Icons.download_done_rounded,
                      ),
                      color: Theme.of(context).colorScheme.secondary,
                      iconSize: 25.0,
                      tooltip: AppLocalizations.of(context)?.downDone ??
                          'Download Done',
                      onPressed: () {},
                    )
                  : controller.down.progress == 0
                      ? Center(
                          child: IconButton(
                            icon: const Icon(
                              Icons.download_rounded,
                            ),
                            iconSize: 25.0,
                            color: Theme.of(context).iconTheme.color,
                            tooltip: AppLocalizations.of(context)?.down ??
                                'Download',
                            onPressed: () async {
                              // AdManager.showInterstitialAd();
                              ShowSnackBar().showSnackBar(
                                context,
                                '${AppLocalizations.of(context)?.downingAlbum ?? 'Downloading album'} "$albumName"',
                              );

                              // rewardedAdManager.showRewardedAd(context, () async {
                              controller.data.value = (await SaavnAPI()
                                  .fetchAlbumSongs(albumId))['songs'] as List;
                              for (final items in controller.data) {
                                controller.down.prepareDownload(
                                  context,
                                  items as Map,
                                  createFolder: true,
                                  folderName: albumName,
                                );
                                await controller
                                    .waitUntilDone(items['id'].toString());
                                controller.incrementDone();
                              }
                              controller.finished.value = true;
                              // });
                            },
                          ),
                        )
                      : Stack(
                          children: [
                            Center(
                              child: Text(
                                controller.down.progress == null
                                    ? '0%'
                                    : '${(100 * (controller.down.progress ?? 0)).round()}%',
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                height: 35,
                                width: 35,
                                child: CircularProgressIndicator(
                                  value: controller.down.progress == 1
                                      ? null
                                      : controller.down.progress,
                                ),
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                height: 30,
                                width: 30,
                                child: CircularProgressIndicator(
                                  value: controller.data.isEmpty
                                      ? 0
                                      : controller.done.value /
                                          controller.data.length,
                                ),
                              ),
                            ),
                          ],
                        ),
            );
          },
        ),
      ),
    );
  }
}
