// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/box_switch_tile.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/popup.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/config.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

class ThemePageController extends GetxController {
  final Function? callback;

  ThemePageController({this.callback});

  final Box settingsBox = Hive.box('settings');
  final MyTheme currentTheme = GetIt.I<MyTheme>();
  final canvasColor = 'Grey'.obs;
  final cardColor = 'Grey900'.obs;
  final theme = 'Default'.obs;
  final userThemes = <dynamic, dynamic>{}.obs;
  final themeColor = 'Teal'.obs;
  final colorHue = 400.obs;

  @override
  void onInit() {
    super.onInit();
    canvasColor.value =
        Hive.box('settings').get('canvasColor', defaultValue: 'Grey') as String;
    cardColor.value = Hive.box('settings')
        .get('cardColor', defaultValue: 'Grey900') as String;
    theme.value =
        Hive.box('settings').get('theme', defaultValue: 'Default') as String;
    userThemes.value =
        Hive.box('settings').get('userThemes', defaultValue: {}) as Map;
    themeColor.value =
        Hive.box('settings').get('themeColor', defaultValue: 'Teal') as String;
    colorHue.value =
        Hive.box('settings').get('colorHue', defaultValue: 400) as int;
  }

  void updateAccentColor(String color, int hue) {
    themeColor.value = color;
    colorHue.value = hue;
    currentTheme.switchColor(color, hue);
    switchToCustomTheme();
  }

  void updateBackGradient(int index) {
    settingsBox.put('backGrad', index);
    currentTheme.backGrad = index;
    if (callback != null) {
      callback!();
    }
    switchToCustomTheme();
  }

  void updateCardGradient(int index) {
    settingsBox.put('cardGrad', index);
    currentTheme.cardGrad = index;
    if (callback != null) {
      callback!();
    }
    switchToCustomTheme();
  }

  void updateBottomGradient(int index) {
    settingsBox.put('bottomGrad', index);
    currentTheme.bottomGrad = index;
    switchToCustomTheme();
  }

  void updateCanvasColor(String value) {
    switchToCustomTheme();
    currentTheme.switchCanvasColor(value);
    canvasColor.value = value;
  }

  void updateCardColor(String value) {
    switchToCustomTheme();
    currentTheme.switchCardColor(value);
    cardColor.value = value;
  }

  void updateTheme(String themeChoice) {
    const deflt = 'Default';

    currentTheme.setInitialTheme(themeChoice);

    theme.value = themeChoice;
    if (themeChoice == 'Custom') return;
    final selectedTheme = userThemes[themeChoice];

    settingsBox.put(
      'backGrad',
      themeChoice == deflt ? 2 : selectedTheme['backGrad'],
    );
    currentTheme.backGrad =
        themeChoice == deflt ? 2 : selectedTheme['backGrad'] as int;

    settingsBox.put(
      'cardGrad',
      themeChoice == deflt ? 4 : selectedTheme['cardGrad'],
    );
    currentTheme.cardGrad =
        themeChoice == deflt ? 4 : selectedTheme['cardGrad'] as int;

    settingsBox.put(
      'bottomGrad',
      themeChoice == deflt ? 3 : selectedTheme['bottomGrad'],
    );
    currentTheme.bottomGrad =
        themeChoice == deflt ? 3 : selectedTheme['bottomGrad'] as int;

    currentTheme.switchCanvasColor(
      themeChoice == deflt ? 'Grey' : selectedTheme['canvasColor'] as String,
      notify: false,
    );
    canvasColor.value =
        themeChoice == deflt ? 'Grey' : selectedTheme['canvasColor'] as String;

    currentTheme.switchCardColor(
      themeChoice == deflt ? 'Grey900' : selectedTheme['cardColor'] as String,
      notify: false,
    );
    cardColor.value =
        themeChoice == deflt ? 'Grey900' : selectedTheme['cardColor'] as String;

    themeColor.value =
        themeChoice == deflt ? 'Teal' : selectedTheme['accentColor'] as String;
    colorHue.value =
        themeChoice == deflt ? 400 : selectedTheme['colorHue'] as int;

    currentTheme.switchColor(
      themeColor.value,
      colorHue.value,
      notify: false,
    );

    currentTheme.switchTheme(
      useSystemTheme:
          !(themeChoice == deflt) && selectedTheme['useSystemTheme'] as bool,
      isDark: themeChoice == deflt || selectedTheme['isDark'] as bool,
    );
  }

  void deleteThemeAndUpdate(String value) {
    currentTheme.deleteTheme(value);
    if (currentTheme.getInitialTheme() == value) {
      currentTheme.setInitialTheme('Custom');
      theme.value = 'Custom';
    }
    userThemes.value = currentTheme.getThemes();
  }

  void saveThemeAndUpdate(String value) {
    if (value == '') return;
    currentTheme.saveTheme(value);
    currentTheme.setInitialTheme(value);
    userThemes.value = currentTheme.getThemes();
    theme.value = value;
  }

  void switchToCustomTheme() {
    const custom = 'Custom';
    if (theme.value != custom) {
      currentTheme.setInitialTheme(custom);
      theme.value = custom;
    }
  }
}

class ThemePage extends StatelessWidget {
  final Function? callback;
  const ThemePage({super.key, this.callback});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ThemePageController(callback: callback));

    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          title: Text(
            AppLocalizations.of(
              context,
            )!
                .theme,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        body: Obx(
          () {
            final List<String> userThemesList = <String>[
              'Default',
              ...controller.userThemes.keys.map((theme) => theme as String),
              'Custom',
            ];

            return ListView(
              padding: const EdgeInsets.all(10.0),
              physics: const BouncingScrollPhysics(),
              children: [
                BoxSwitchTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .darkMode,
                  ),
                  keyName: 'darkMode',
                  defaultValue: true,
                  onChanged: ({required bool val, required Box box}) {
                    box.put(
                      'useSystemTheme',
                      false,
                    );
                    controller.currentTheme.switchTheme(
                      isDark: val,
                      useSystemTheme: false,
                    );
                    controller.switchToCustomTheme();
                  },
                ),
                BoxSwitchTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .useSystemTheme,
                  ),
                  keyName: 'useSystemTheme',
                  defaultValue: true,
                  onChanged: ({required bool val, required Box box}) {
                    controller.currentTheme.switchTheme(useSystemTheme: val);
                    controller.switchToCustomTheme();
                  },
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .accent,
                  ),
                  subtitle: Text(
                      '${controller.themeColor.value}, ${controller.colorHue.value}'),
                  trailing: Padding(
                    padding: const EdgeInsets.all(
                      10.0,
                    ),
                    child: Container(
                      height: 25,
                      width: 25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          100.0,
                        ),
                        color: Theme.of(context).colorScheme.secondary,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey[900]!,
                            blurRadius: 5.0,
                            offset: const Offset(
                              0.0,
                              3.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      isDismissible: true,
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (BuildContext context) {
                        final List<String> colors = [
                          'Purple',
                          'Deep Purple',
                          'Indigo',
                          'Blue',
                          'Light Blue',
                          'Cyan',
                          'Teal',
                          'Green',
                          'Light Green',
                          'Lime',
                          'Yellow',
                          'Amber',
                          'Orange',
                          'Deep Orange',
                          'Red',
                          'Pink',
                          'White',
                        ];
                        return BottomGradientContainer(
                          borderRadius: BorderRadius.circular(
                            20.0,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              10,
                              0,
                              10,
                            ),
                            itemCount: colors.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 15.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    for (final hue in [100, 200, 400, 700])
                                      GestureDetector(
                                        onTap: () {
                                          controller.updateAccentColor(
                                              colors[index], hue);
                                          Navigator.pop(context);
                                        },
                                        child: Obx(
                                          () => Container(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                0.125,
                                            height: MediaQuery.sizeOf(context)
                                                    .width *
                                                0.125,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                100.0,
                                              ),
                                              color: MyTheme().getColor(
                                                colors[index],
                                                hue,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey[900]!,
                                                  blurRadius: 5.0,
                                                  offset: const Offset(
                                                    0.0,
                                                    3.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            child: (controller
                                                            .themeColor.value ==
                                                        colors[index] &&
                                                    controller.colorHue.value ==
                                                        hue)
                                                ? const Icon(
                                                    Icons.done_rounded,
                                                  )
                                                : const SizedBox(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  dense: true,
                ),
                Visibility(
                  visible: Theme.of(context).brightness == Brightness.dark,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .bgGrad,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .bgGradSub,
                        ),
                        trailing: Padding(
                          padding: const EdgeInsets.all(
                            10.0,
                          ),
                          child: Container(
                            height: 25,
                            width: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                100.0,
                              ),
                              color: Theme.of(context).colorScheme.secondary,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? controller.currentTheme.getBackGradient()
                                    : [
                                        Colors.white,
                                        Theme.of(context).canvasColor,
                                      ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.white24,
                                  blurRadius: 5.0,
                                  offset: Offset(
                                    0.0,
                                    3.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          final List<List<Color>> gradients =
                              controller.currentTheme.backOpt;
                          PopupDialog().showPopup(
                            context: context,
                            child: SizedBox(
                              width: 500,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  30,
                                  0,
                                  10,
                                ),
                                itemCount: gradients.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 20.0,
                                      right: 20.0,
                                      bottom: 15.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        controller.updateBackGradient(index);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.125,
                                        height:
                                            MediaQuery.sizeOf(context).width *
                                                0.125,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15.0,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: gradients[index],
                                          ),
                                        ),
                                        child: (controller.currentTheme
                                                    .getBackGradient() ==
                                                gradients[index])
                                            ? const Icon(
                                                Icons.done_rounded,
                                              )
                                            : const SizedBox(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .cardGrad,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .cardGradSub,
                        ),
                        trailing: Padding(
                          padding: const EdgeInsets.all(
                            10.0,
                          ),
                          child: Container(
                            height: 25,
                            width: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                100.0,
                              ),
                              color: Theme.of(context).colorScheme.secondary,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? controller.currentTheme.getCardGradient()
                                    : [
                                        Colors.white,
                                        Theme.of(context).canvasColor,
                                      ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.white24,
                                  blurRadius: 5.0,
                                  offset: Offset(
                                    0.0,
                                    3.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          final List<List<Color>> gradients =
                              controller.currentTheme.cardOpt;
                          PopupDialog().showPopup(
                            context: context,
                            child: SizedBox(
                              width: 500,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  30,
                                  0,
                                  10,
                                ),
                                itemCount: gradients.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 20.0,
                                      right: 20.0,
                                      bottom: 15.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        controller.updateCardGradient(index);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.125,
                                        height:
                                            MediaQuery.sizeOf(context).width *
                                                0.125,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15.0,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: gradients[index],
                                          ),
                                        ),
                                        child: (controller.currentTheme
                                                    .getCardGradient() ==
                                                gradients[index])
                                            ? const Icon(
                                                Icons.done_rounded,
                                              )
                                            : const SizedBox(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .bottomGrad,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .bottomGradSub,
                        ),
                        trailing: Padding(
                          padding: const EdgeInsets.all(
                            10.0,
                          ),
                          child: Container(
                            height: 25,
                            width: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                100.0,
                              ),
                              color: Theme.of(context).colorScheme.secondary,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? controller.currentTheme
                                        .getBottomGradient()
                                    : [
                                        Colors.white,
                                        Theme.of(context).canvasColor,
                                      ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.white24,
                                  blurRadius: 5.0,
                                  offset: Offset(
                                    0.0,
                                    3.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          final List<List<Color>> gradients =
                              controller.currentTheme.backOpt;
                          PopupDialog().showPopup(
                            context: context,
                            child: SizedBox(
                              width: 500,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  30,
                                  0,
                                  10,
                                ),
                                itemCount: gradients.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 20.0,
                                      right: 20.0,
                                      bottom: 15.0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        controller.updateBottomGradient(index);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.125,
                                        height:
                                            MediaQuery.sizeOf(context).width *
                                                0.125,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            15.0,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: gradients[index],
                                          ),
                                        ),
                                        child: (controller.currentTheme
                                                    .getBottomGradient() ==
                                                gradients[index])
                                            ? const Icon(
                                                Icons.done_rounded,
                                              )
                                            : const SizedBox(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .canvasColor,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .canvasColorSub,
                        ),
                        onTap: () {},
                        trailing: DropdownButton(
                          value: controller.canvasColor.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          underline: const SizedBox(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              controller.updateCanvasColor(newValue);
                            }
                          },
                          items: <String>['Grey', 'Black']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .cardColor,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .cardColorSub,
                        ),
                        onTap: () {},
                        trailing: DropdownButton(
                          value: controller.cardColor.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          underline: const SizedBox(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              controller.updateCardColor(newValue);
                            }
                          },
                          items: <String>[
                            'Grey800',
                            'Grey850',
                            'Grey900',
                            'Black'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        dense: true,
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .useAmoled,
                  ),
                  dense: true,
                  onTap: () {
                    controller.currentTheme.switchTheme(
                      useSystemTheme: false,
                      isDark: true,
                    );
                    Hive.box('settings').put('darkMode', true);

                    controller.settingsBox.put('backGrad', 4);
                    controller.currentTheme.backGrad = 4;
                    controller.settingsBox.put('cardGrad', 6);
                    controller.currentTheme.cardGrad = 6;
                    controller.settingsBox.put('bottomGrad', 4);
                    controller.currentTheme.bottomGrad = 4;

                    controller.currentTheme.switchCanvasColor('Black');
                    controller.canvasColor.value = 'Black';

                    controller.currentTheme.switchCardColor('Grey900');
                    controller.cardColor.value = 'Grey900';

                    controller.themeColor.value = 'White';
                    controller.colorHue.value = 400;
                    controller.currentTheme.switchColor(
                      'White',
                      controller.colorHue.value,
                    );
                  },
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .currentTheme,
                  ),
                  trailing: DropdownButton(
                    value: controller.theme.value,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    underline: const SizedBox(),
                    onChanged: (String? themeChoice) {
                      if (themeChoice != null) {
                        controller.updateTheme(themeChoice);
                      }
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return userThemesList.map<Widget>((String item) {
                        return Text(item);
                      }).toList();
                    },
                    items: userThemesList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              flex: 2,
                              child: Text(
                                value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (value != 'Default' && value != 'Custom')
                              Flexible(
                                child: IconButton(
                                  //padding: EdgeInsets.zero,
                                  iconSize: 18,
                                  splashRadius: 18,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                        ),
                                        title: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .deleteTheme,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                        ),
                                        content: Text(
                                          '${AppLocalizations.of(
                                            context,
                                          )!.deleteThemeSubtitle} $value?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                Navigator.of(context).pop,
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .cancel,
                                            ),
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: Theme.of(
                                                        context,
                                                      ).colorScheme.secondary ==
                                                      Colors.white
                                                  ? Colors.black
                                                  : null,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                            onPressed: () {
                                              controller
                                                  .deleteThemeAndUpdate(value);
                                              ShowSnackBar().showSnackBar(
                                                context,
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .themeDeleted,
                                              );
                                              return Navigator.of(
                                                context,
                                              ).pop();
                                            },
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .delete,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 5.0,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    isDense: true,
                  ),
                  dense: true,
                ),
                Visibility(
                  visible: controller.theme.value == 'Custom',
                  child: ListTile(
                    title: Text(
                      AppLocalizations.of(
                        context,
                      )!
                          .saveTheme,
                    ),
                    onTap: () {
                      final initialThemeName = '${AppLocalizations.of(
                        context,
                      )!.theme} ${controller.userThemes.length + 1}';
                      showTextInputDialog(
                        context: context,
                        title: AppLocalizations.of(
                          context,
                        )!
                            .enterThemeName,
                        onSubmitted: (String value, BuildContext context) {
                          controller.saveThemeAndUpdate(value);
                          ShowSnackBar().showSnackBar(
                            context,
                            AppLocalizations.of(
                              context,
                            )!
                                .themeSaved,
                          );
                          Navigator.of(context).pop();
                        },
                        keyboardType: TextInputType.text,
                        initialText: initialThemeName,
                      );
                    },
                    dense: true,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
