import 'package:blackhole/CustomWidgets/box_switch_tile.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Screens/Home/saavn.dart' as home_screen;
import 'package:blackhole/Screens/Top Charts/top.dart' as top_screen;
import 'package:blackhole/constants/countrycodes.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

class MusicPlaybackPageController extends GetxController {
  final Function? callback;

  MusicPlaybackPageController({this.callback});

  final streamingMobileQuality = '96 kbps'.obs;
  final streamingWifiQuality = '320 kbps'.obs;
  final ytQuality = 'Low'.obs;
  final region = 'India'.obs;
  final preferredLanguage = <dynamic>[].obs;

  final List<String> languages = [
    'Hindi',
    'English',
    'Punjabi',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Bengali',
    'Kannada',
    'Bhojpuri',
    'Malayalam',
    'Urdu',
    'Haryanvi',
    'Rajasthani',
    'Odia',
    'Assamese',
  ];

  @override
  void onInit() {
    super.onInit();
    streamingMobileQuality.value = Hive.box('settings')
        .get('streamingQuality', defaultValue: '96 kbps') as String;
    streamingWifiQuality.value = Hive.box('settings')
        .get('streamingWifiQuality', defaultValue: '320 kbps') as String;
    ytQuality.value =
        Hive.box('settings').get('ytQuality', defaultValue: 'Low') as String;
    region.value =
        Hive.box('settings').get('region', defaultValue: 'India') as String;
    preferredLanguage.value = (Hive.box('settings').get('preferredLanguage',
            defaultValue: ['Hindi'])?.toList() as List?) ??
        ['Hindi'];
  }

  void updateStreamingMobileQuality(String value) {
    streamingMobileQuality.value = value;
    Hive.box('settings').put('streamingQuality', value);
  }

  void updateStreamingWifiQuality(String value) {
    streamingWifiQuality.value = value;
    Hive.box('settings').put('streamingWifiQuality', value);
  }

  void updateYtQuality(String value) {
    ytQuality.value = value;
    Hive.box('settings').put('ytQuality', value);
  }

  void updatePreferredLanguage(List checked) {
    preferredLanguage.value = checked;
    Hive.box('settings').put('preferredLanguage', checked);
    home_screen.fetched = false;
    home_screen.preferredLanguage = preferredLanguage;
    if (callback != null) {
      callback!();
    }
  }

  Future<void> updateRegion(BuildContext context) async {
    region.value = await SpotifyCountry().changeCountry(context: context);
  }
}

class MusicPlaybackPage extends StatelessWidget {
  final Function? callback;
  const MusicPlaybackPage({super.key, this.callback});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MusicPlaybackPageController(callback: callback));

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
                .musicPlayback,
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
                      .musicLang,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .musicLangSub,
                ),
                trailing: SizedBox(
                  width: 150,
                  child: Text(
                    controller.preferredLanguage.isEmpty
                        ? 'None'
                        : controller.preferredLanguage.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                dense: true,
                onTap: () {
                  showModalBottomSheet(
                    isDismissible: true,
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (BuildContext context) {
                      final List checked =
                          List.from(controller.preferredLanguage);
                      return StatefulBuilder(
                        builder: (
                          BuildContext context,
                          StateSetter setStt,
                        ) {
                          return BottomGradientContainer(
                            borderRadius: BorderRadius.circular(
                              20.0,
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      10,
                                      0,
                                      10,
                                    ),
                                    itemCount: controller.languages.length,
                                    itemBuilder: (context, idx) {
                                      return CheckboxListTile(
                                        activeColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        checkColor: Theme.of(context)
                                                    .colorScheme
                                                    .secondary ==
                                                Colors.white
                                            ? Colors.black
                                            : null,
                                        value: checked.contains(
                                          controller.languages[idx],
                                        ),
                                        title: Text(
                                          controller.languages[idx],
                                        ),
                                        onChanged: (bool? value) {
                                          value!
                                              ? checked.add(
                                                  controller.languages[idx])
                                              : checked.remove(
                                                  controller.languages[idx],
                                                );
                                          setStt(
                                            () {},
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
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
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                      onPressed: () {
                                        controller
                                            .updatePreferredLanguage(checked);
                                        Navigator.pop(context);
                                        if (controller
                                            .preferredLanguage.isEmpty) {
                                          ShowSnackBar().showSnackBar(
                                            context,
                                            AppLocalizations.of(
                                              context,
                                            )!
                                                .noLangSelected,
                                          );
                                        }
                                      },
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!
                                            .ok,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Obx(
              () => ListTile(
                title: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .chartLocation,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .chartLocationSub,
                ),
                trailing: SizedBox(
                  width: 150,
                  child: Text(
                    controller.region.value,
                    textAlign: TextAlign.end,
                  ),
                ),
                dense: true,
                onTap: () async {
                  await controller.updateRegion(context);
                },
              ),
            ),
            Obx(
              () => ListTile(
                title: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .streamQuality,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .streamQualitySub,
                ),
                onTap: () {},
                trailing: DropdownButton(
                  value: controller.streamingMobileQuality.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateStreamingMobileQuality(newValue);
                    }
                  },
                  items: <String>['96 kbps', '160 kbps', '320 kbps']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
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
                      .streamWifiQuality,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .streamWifiQualitySub,
                ),
                onTap: () {},
                trailing: DropdownButton(
                  value: controller.streamingWifiQuality.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateStreamingWifiQuality(newValue);
                    }
                  },
                  items: <String>['96 kbps', '160 kbps', '320 kbps']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
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
                      .ytStreamQuality,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!
                      .ytStreamQualitySub,
                ),
                onTap: () {},
                trailing: DropdownButton(
                  value: controller.ytQuality.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateYtQuality(newValue);
                    }
                  },
                  items: <String>['Low', 'High']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                dense: true,
              ),
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .loadLast,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .loadLastSub,
              ),
              keyName: 'loadStart',
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .resetOnSkip,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .resetOnSkipSub,
              ),
              keyName: 'resetOnSkip',
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .enforceRepeat,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .enforceRepeatSub,
              ),
              keyName: 'enforceRepeat',
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .autoplay,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .autoplaySub,
              ),
              keyName: 'autoplay',
              defaultValue: true,
              isThreeLine: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .cacheSong,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .cacheSongSub,
              ),
              keyName: 'cacheSong',
              defaultValue: false,
            ),
          ],
        ),
      ),
    );
  }
}

class SpotifyCountry {
  Future<String> changeCountry({required BuildContext context}) async {
    String region =
        Hive.box('settings').get('region', defaultValue: 'India') as String;
    if (!CountryCodes.localChartCodes.containsKey(region)) {
      region = 'India';
    }

    await showModalBottomSheet(
      isDismissible: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        const Map<String, String> codes = CountryCodes.localChartCodes;
        final List<String> countries = codes.keys.toList();
        return BottomGradientContainer(
          borderRadius: BorderRadius.circular(
            20.0,
          ),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              0,
              10,
              0,
              10,
            ),
            itemCount: countries.length,
            itemBuilder: (context, idx) {
              return ListTileTheme(
                selectedColor: Theme.of(context).colorScheme.secondary,
                child: ListTile(
                  title: Text(
                    countries[idx],
                  ),
                  leading: Radio(
                    value: countries[idx],
                    groupValue: region,
                    onChanged: (value) {
                      top_screen.localSongs = [];
                      region = countries[idx];
                      top_screen.localFetched = false;
                      top_screen.localFetchFinished.value = false;
                      Hive.box('settings').put('region', region);
                      Navigator.pop(context);
                    },
                  ),
                  selected: region == countries[idx],
                  onTap: () {
                    top_screen.localSongs = [];
                    region = countries[idx];
                    top_screen.localFetchFinished.value = false;
                    Hive.box('settings').put('region', region);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        );
      },
    );
    return region;
  }
}
