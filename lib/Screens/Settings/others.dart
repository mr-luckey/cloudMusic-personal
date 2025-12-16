// Coded by Naseer Ahmed

import 'dart:io';

import 'package:blackhole/CustomWidgets/box_switch_tile.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/constants/languagecodes.dart';
import 'package:blackhole/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class OthersPageController extends GetxController {
  final Box settingsBox = Hive.box('settings');
  final includeOrExclude = false.obs;
  final includedExcludedPaths = <dynamic>[].obs;
  final lang = 'English'.obs;
  final useProxy = false.obs;
  final proxySettings = ''.obs;
  final cacheSize = 0.obs;

  @override
  void onInit() {
    super.onInit();
    includeOrExclude.value = Hive.box('settings')
        .get('includeOrExclude', defaultValue: false) as bool;
    includedExcludedPaths.value = Hive.box('settings')
        .get('includedExcludedPaths', defaultValue: []) as List;
    lang.value =
        Hive.box('settings').get('lang', defaultValue: 'English') as String;
    useProxy.value =
        Hive.box('settings').get('useProxy', defaultValue: false) as bool;
    updateProxySettings();
  }

  void updateLang(String newLang, BuildContext context) {
    lang.value = newLang;
    MyApp.of(context).setLocale(
      Locale.fromSubtags(
        languageCode: LanguageCodes.languageCodes[newLang] ?? 'en',
      ),
    );
    Hive.box('settings').put('lang', newLang);
  }

  void updateUseProxy(bool val) {
    useProxy.value = val;
  }

  void updateProxySettings() {
    final ip =
        Hive.box('settings').get('proxyIp', defaultValue: '103.47.67.134');
    final port = Hive.box('settings').get('proxyPort', defaultValue: 8080);
    proxySettings.value = '$ip:$port';
  }

  void clearCache() {
    Hive.box('cache').clear();
    cacheSize.value = 0;
  }
}

class OthersPage extends StatelessWidget {
  const OthersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OthersPageController());

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
                .others,
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
                      .lang,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .langSub,
                ),
                onTap: () {},
                trailing: DropdownButton(
                  value: controller.lang.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateLang(newValue, context);
                    }
                  },
                  items: LanguageCodes.languageCodes.keys
                      .map<DropdownMenuItem<String>>((language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(
                        language,
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
                      .includeExcludeFolder,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .includeExcludeFolderSub,
                ),
                dense: true,
                onTap: () {
                  final GlobalKey<AnimatedListState> listKey =
                      GlobalKey<AnimatedListState>();
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
                          () => AnimatedList(
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              10,
                              0,
                              10,
                            ),
                            key: listKey,
                            initialItemCount:
                                controller.includedExcludedPaths.length + 2,
                            itemBuilder: (cntxt, idx, animation) {
                              if (idx == 0) {
                                return Obx(
                                  () => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: <Widget>[
                                          ChoiceChip(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .excluded,
                                            ),
                                            selectedColor: Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withOpacity(0.2),
                                            labelStyle: TextStyle(
                                              color: !controller
                                                      .includeOrExclude.value
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge!
                                                      .color,
                                              fontWeight: !controller
                                                      .includeOrExclude.value
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            selected: !controller
                                                .includeOrExclude.value,
                                            onSelected: (bool selected) {
                                              controller.includeOrExclude
                                                  .value = !selected;
                                              controller.settingsBox.put(
                                                'includeOrExclude',
                                                !selected,
                                              );
                                            },
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          ChoiceChip(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .included,
                                            ),
                                            selectedColor: Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withOpacity(0.2),
                                            labelStyle: TextStyle(
                                              color: controller
                                                      .includeOrExclude.value
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge!
                                                      .color,
                                              fontWeight: controller
                                                      .includeOrExclude.value
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            selected: controller
                                                .includeOrExclude.value,
                                            onSelected: (bool selected) {
                                              controller.includeOrExclude
                                                  .value = selected;
                                              controller.settingsBox.put(
                                                'includeOrExclude',
                                                selected,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 5.0,
                                          top: 5.0,
                                          bottom: 10.0,
                                        ),
                                        child: Text(
                                          controller.includeOrExclude.value
                                              ? AppLocalizations.of(
                                                  context,
                                                )!
                                                  .includedDetails
                                              : AppLocalizations.of(
                                                  context,
                                                )!
                                                  .excludedDetails,
                                          textAlign: TextAlign.start,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              if (idx == 1) {
                                return ListTile(
                                  title: Text(
                                    AppLocalizations.of(context)!.addNew,
                                  ),
                                  leading: const Icon(
                                    CupertinoIcons.add,
                                  ),
                                  onTap: () async {
                                    final String temp =
                                        await Picker.selectFolder(
                                      context: context,
                                    );
                                    if (temp.trim() != '' &&
                                        !controller.includedExcludedPaths
                                            .contains(temp)) {
                                      controller.includedExcludedPaths
                                          .add(temp);
                                      Hive.box('settings').put(
                                        'includedExcludedPaths',
                                        controller.includedExcludedPaths,
                                      );
                                      listKey.currentState!.insertItem(
                                        controller.includedExcludedPaths.length,
                                      );
                                    } else {
                                      if (temp.trim() == '') {
                                        Navigator.pop(context);
                                      }
                                      ShowSnackBar().showSnackBar(
                                        context,
                                        temp.trim() == ''
                                            ? 'No folder selected'
                                            : 'Already added',
                                      );
                                    }
                                  },
                                );
                              }

                              return SizeTransition(
                                sizeFactor: animation,
                                child: ListTile(
                                  leading: const Icon(
                                    CupertinoIcons.folder,
                                  ),
                                  title: Text(
                                    controller.includedExcludedPaths[idx - 2]
                                        .toString(),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.clear,
                                      size: 15.0,
                                    ),
                                    tooltip: 'Remove',
                                    onPressed: () {
                                      controller.includedExcludedPaths
                                          .removeAt(idx - 2);
                                      Hive.box('settings').put(
                                        'includedExcludedPaths',
                                        controller.includedExcludedPaths,
                                      );
                                      listKey.currentState!.removeItem(
                                        idx,
                                        (context, animation) => Container(),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .minAudioLen,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .minAudioLenSub,
              ),
              dense: true,
              onTap: () {
                showTextInputDialog(
                  context: context,
                  title: AppLocalizations.of(
                    context,
                  )!
                      .minAudioAlert,
                  initialText: (Hive.box('settings')
                          .get('minDuration', defaultValue: 10) as int)
                      .toString(),
                  keyboardType: TextInputType.number,
                  onSubmitted: (String value, BuildContext context) {
                    if (value.trim() == '') {
                      value = '0';
                    }
                    Hive.box('settings').put('minDuration', int.parse(value));
                    Navigator.pop(context);
                  },
                );
              },
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .liveSearch,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .liveSearchSub,
              ),
              keyName: 'liveSearch',
              isThreeLine: false,
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .useDown,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .useDownSub,
              ),
              keyName: 'useDown',
              isThreeLine: true,
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .getLyricsOnline,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .getLyricsOnlineSub,
              ),
              keyName: 'getLyricsOnline',
              isThreeLine: true,
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .supportEq,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .supportEqSub,
              ),
              keyName: 'supportEq',
              isThreeLine: true,
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .stopOnClose,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .stopOnCloseSub,
              ),
              isThreeLine: true,
              keyName: 'stopForegroundService',
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .checkUpdate,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .checkUpdateSub,
              ),
              keyName: 'checkUpdate',
              isThreeLine: true,
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .useProxy,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .useProxySub,
              ),
              keyName: 'useProxy',
              defaultValue: false,
              isThreeLine: true,
              onChanged: ({required bool val, required Box box}) {
                controller.updateUseProxy(val);
              },
            ),
            Obx(
              () => Visibility(
                visible: controller.useProxy.value,
                child: ListTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .proxySet,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .proxySetSub,
                  ),
                  dense: true,
                  trailing: Text(
                    controller.proxySettings.value,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final textController = TextEditingController(
                          text: controller.settingsBox
                              .get('proxyIp', defaultValue: '103.47.67.134')
                              .toString(),
                        );
                        final controller2 = TextEditingController(
                          text: controller.settingsBox
                              .get('proxyPort', defaultValue: 8080)
                              .toString(),
                        );
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10.0,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!
                                        .ipAdd,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  ),
                                ],
                              ),
                              TextField(
                                autofocus: true,
                                controller: textController,
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              Row(
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!
                                        .port,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  ),
                                ],
                              ),
                              TextField(
                                autofocus: true,
                                controller: controller2,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!
                                    .cancel,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.secondary ==
                                            Colors.white
                                        ? Colors.black
                                        : null,
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                              onPressed: () {
                                controller.settingsBox.put(
                                  'proxyIp',
                                  textController.text.trim(),
                                );
                                controller.settingsBox.put(
                                  'proxyPort',
                                  int.parse(
                                    controller2.text.trim(),
                                  ),
                                );
                                controller.updateProxySettings();
                                Navigator.pop(context);
                              },
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!
                                    .ok,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Obx(
              () => ListTile(
                title: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .clearCache,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .clearCacheSub,
                ),
                trailing: SizedBox(
                  height: 70.0,
                  width: 70.0,
                  child: Center(
                    child: FutureBuilder(
                      future: File(Hive.box('cache').path!).length(),
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<int> snapshot,
                      ) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return Text(
                            '${((snapshot.data ?? 0) / (1024 * 1024)).toStringAsFixed(2)} MB',
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                dense: true,
                isThreeLine: true,
                onTap: () async {
                  controller.clearCache();
                },
              ),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .shareLogs,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .shareLogsSub,
              ),
              onTap: () async {
                final Directory tempDir = await getTemporaryDirectory();
                final files = <XFile>[XFile('${tempDir.path}/logs/logs.txt')];
                Share.shareXFiles(files);
              },
              dense: true,
              isThreeLine: true,
            ),
          ],
        ),
      ),
    );
  }
}
