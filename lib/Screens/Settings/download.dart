// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/box_switch_tile.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Services/ext_storage_provider.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

class DownloadPageController extends GetxController {
  final Box settingsBox = Hive.box('settings');
  final downloadPath = ''.obs;
  final downloadQuality = '320 kbps'.obs;
  final ytDownloadQuality = 'High'.obs;
  final downFilename = 0.obs;

  @override
  void onInit() {
    super.onInit();
    downloadPath.value = Hive.box('settings').get('downloadPath',
        defaultValue: '/storage/emulated/0/Music') as String;
    downloadQuality.value = Hive.box('settings')
        .get('downloadQuality', defaultValue: '320 kbps') as String;
    ytDownloadQuality.value = Hive.box('settings')
        .get('ytDownloadQuality', defaultValue: 'High') as String;
    downFilename.value =
        Hive.box('settings').get('downFilename', defaultValue: 0) as int;
  }

  void updateDownloadQuality(String value) {
    downloadQuality.value = value;
    Hive.box('settings').put('downloadQuality', value);
  }

  void updateYtDownloadQuality(String value) {
    ytDownloadQuality.value = value;
    Hive.box('settings').put('ytDownloadQuality', value);
  }

  Future<void> resetDownloadPath() async {
    downloadPath.value = await ExtStorageProvider.getExtStorage(
          dirName: 'Music',
          writeAccess: true,
        ) ??
        '/storage/emulated/0/Music';
    Hive.box('settings').put('downloadPath', downloadPath.value);
  }

  Future<void> selectDownloadPath(BuildContext context) async {
    final String temp = await Picker.selectFolder(
      context: context,
      message: AppLocalizations.of(
        context,
      )!
          .selectDownLocation,
    );
    if (temp.trim() != '') {
      downloadPath.value = temp;
      Hive.box('settings').put('downloadPath', temp);
    }
  }
}

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DownloadPageController());

    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            AppLocalizations.of(
              context,
            )!
                .down,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(10.0),
          children: [
            Obx(
              () => ListTile(
                title: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .downQuality,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .downQualitySub,
                ),
                onTap: () {},
                trailing: DropdownButton(
                  value: controller.downloadQuality.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateDownloadQuality(newValue);
                    }
                  },
                  items: <String>['96 kbps', '160 kbps', '320 kbps']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                      ),
                    );
                  }).toList(),
                ),
                dense: true,
              ),
            ),
            Obx(
              () => ListTile(
                title: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .ytDownQuality,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .ytDownQualitySub,
                ),
                onTap: () {},
                trailing: DropdownButton(
                  value: controller.ytDownloadQuality.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateYtDownloadQuality(newValue);
                    }
                  },
                  items: <String>['Low', 'High']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                      ),
                    );
                  }).toList(),
                ),
                dense: true,
              ),
            ),
            Obx(
              () => ListTile(
                title: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .downLocation,
                ),
                subtitle: Text(controller.downloadPath.value),
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[700],
                  ),
                  onPressed: () async {
                    await controller.resetDownloadPath();
                  },
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .reset,
                  ),
                ),
                onTap: () async {
                  await controller.selectDownloadPath(context);
                  if (controller.downloadPath.value.trim() == '') {
                    ShowSnackBar().showSnackBar(
                      context,
                      AppLocalizations.of(
                        context,
                      )!
                          .noFolderSelected,
                    );
                  }
                },
                dense: true,
              ),
            ),
            Obx(
              () => ListTile(
                title: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .downFilename,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .downFilenameSub,
                ),
                dense: true,
                onTap: () {
                  showModalBottomSheet(
                    isDismissible: true,
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (BuildContext context) {
                      return BottomGradientContainer(
                        borderRadius: BorderRadius.circular(
                          20.0,
                        ),
                        child: Obx(
                          () => ListView(
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              10,
                              0,
                              10,
                            ),
                            children: [
                              CheckboxListTile(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                title: Text(
                                  '${AppLocalizations.of(context)!.title} - ${AppLocalizations.of(context)!.artist}',
                                ),
                                value: controller.downFilename.value == 0,
                                selected: controller.downFilename.value == 0,
                                onChanged: (bool? val) {
                                  if (val ?? false) {
                                    controller.downFilename.value = 0;
                                    controller.settingsBox
                                        .put('downFilename', 0);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              CheckboxListTile(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                title: Text(
                                  '${AppLocalizations.of(context)!.artist} - ${AppLocalizations.of(context)!.title}',
                                ),
                                value: controller.downFilename.value == 1,
                                selected: controller.downFilename.value == 1,
                                onChanged: (val) {
                                  if (val ?? false) {
                                    controller.downFilename.value = 1;
                                    controller.settingsBox
                                        .put('downFilename', 1);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              CheckboxListTile(
                                activeColor:
                                    Theme.of(context).colorScheme.secondary,
                                title: Text(
                                  AppLocalizations.of(context)!.title,
                                ),
                                value: controller.downFilename.value == 2,
                                selected: controller.downFilename.value == 2,
                                onChanged: (val) {
                                  if (val ?? false) {
                                    controller.downFilename.value = 2;
                                    controller.settingsBox
                                        .put('downFilename', 2);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .createAlbumFold,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .createAlbumFoldSub,
              ),
              keyName: 'createDownloadFolder',
              isThreeLine: true,
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .createYtFold,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .createYtFoldSub,
              ),
              keyName: 'createYoutubeFolder',
              isThreeLine: true,
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .downLyrics,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .downLyricsSub,
              ),
              keyName: 'downloadLyrics',
              defaultValue: false,
              isThreeLine: true,
            ),
          ],
        ),
      ),
    );
  }
}
