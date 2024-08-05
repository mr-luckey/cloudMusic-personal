// Coded by Naseer Ahmed

import 'dart:io';

import 'package:blackhole/CustomWidgets/bottom_nav_bar.dart';
import 'package:blackhole/CustomWidgets/drawer.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/backup_restore.dart';
import 'package:blackhole/Helpers/downloads_checker.dart';
import 'package:blackhole/Helpers/github.dart';
import 'package:blackhole/Helpers/route_handler.dart';
import 'package:blackhole/Helpers/update.dart';
import 'package:blackhole/Screens/Common/routes.dart';
import 'package:blackhole/Screens/Home/home_screen.dart';
import 'package:blackhole/Screens/Library/library.dart';
import 'package:blackhole/Screens/LocalMusic/downed_songs.dart';
import 'package:blackhole/Screens/LocalMusic/downed_songs_desktop.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Screens/Settings/new_settings_page.dart';
import 'package:blackhole/Screens/Top Charts/top.dart';
import 'package:blackhole/Screens/YouTube/youtube_home.dart';
import 'package:blackhole/Services/ext_storage_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
// import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  final PageController _pageController = PageController();
  String? appVersion;
  String name =
      Hive.box('settings').get('name', defaultValue: 'Guest') as String;
  bool checkUpdate =
      Hive.box('settings').get('checkUpdate', defaultValue: true) as bool;
  bool autoBackup =
      Hive.box('settings').get('autoBackup', defaultValue: false) as bool;
  List sectionsToShow = Hive.box('settings').get(
    'sectionsToShow',
    defaultValue: ['Home', 'YouTube', 'Library', 'Settings'],
  ) as List;
  DateTime? backButtonPressTime;
  final bool useDense = Hive.box('settings').get(
    'useDenseMini',
    defaultValue: false,
  ) as bool;

  void callback() {
    sectionsToShow = Hive.box('settings').get(
      'sectionsToShow',
      defaultValue: ['Home', 'YouTube', 'Library', 'Settings'],
    ) as List;
    onItemTapped(0);
    setState(() {});
  }

  void onItemTapped(int index) {
    _selectedIndex.value = index;
    _controller.jumpToTab(index);
  }

  // void checkVersion() {
  //   PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
  //     appVersion = packageInfo.version;
  //
  //     if (checkUpdate) {
  //       Logger.root.info('Checking for update');
  //       GitHub.getLatestVersion().then((String version) async {
  //         if (compareVersion(version, appVersion!)) {
  //           Logger.root.info('Update available');
  //           ShowSnackBar().showSnackBar(
  //             context,
  //             AppLocalizations.of(context)!.updateAvailable,
  //             duration: const Duration(seconds: 15),
  //             action: SnackBarAction(
  //               textColor: Theme.of(context).colorScheme.secondary,
  //               label: AppLocalizations.of(context)!.update,
  //               onPressed: () async {
  //                 if (Platform.isAndroid) {
  //                   List? abis = await Hive.box('settings').get('supportedAbis')
  //                       as List?;
  //
  //                   if (abis == null) {
  //                     final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //                     final AndroidDeviceInfo androidDeviceInfo =
  //                         await deviceInfo.androidInfo;
  //                     abis = androidDeviceInfo.supportedAbis;
  //                     await Hive.box('settings').put('supportedAbis', abis);
  //                   }
  //                   if (abis.contains('arm64')) {
  //                   } else if (abis.contains('armeabi')) {}
  //                 }
  //                 Navigator.pop(context);
  //                 launchUrl(
  //                   Uri.parse(
  //                     'https://play.google.com/store/apps/details?id=com.appware.cloudSpot',
  //                   ),
  //                   mode: LaunchMode.externalApplication,
  //                 );
  //               },
  //             ),
  //           );
  //         } else {
  //           Logger.root.info('No update available');
  //         }
  //       });
  //     }
  //     if (autoBackup) {
  //       final List<String> checked = [
  //         AppLocalizations.of(context)!.settings,
  //         AppLocalizations.of(context)!.downs,
  //         AppLocalizations.of(context)!.playlists,
  //       ];
  //       final List playlistNames = Hive.box('settings').get(
  //         'playlistNames',
  //         defaultValue: ['Favorite Songs'],
  //       ) as List;
  //       final Map<String, List> boxNames = {
  //         AppLocalizations.of(context)!.settings: ['settings'],
  //         AppLocalizations.of(context)!.cache: ['cache'],
  //         AppLocalizations.of(context)!.downs: ['downloads'],
  //         AppLocalizations.of(context)!.playlists: playlistNames,
  //       };
  //       final String autoBackPath = Hive.box('settings').get(
  //         'autoBackPath',
  //         defaultValue: '',
  //       ) as String;
  //       if (autoBackPath == '') {
  //         ExtStorageProvider.getExtStorage(
  //           dirName: 'CloudSpot/Backups',
  //           writeAccess: true,
  //         ).then((value) {
  //           Hive.box('settings').put('autoBackPath', value);
  //           createBackup(
  //             context,
  //             checked,
  //             boxNames,
  //             path: value,
  //             fileName: 'CloudSpot_AutoBackup',
  //             showDialog: false,
  //           );
  //         });
  //       } else {
  //         createBackup(
  //           context,
  //           checked,
  //           boxNames,
  //           path: autoBackPath,
  //           fileName: 'CloudSpot_AutoBackup',
  //           showDialog: false,
  //         ).then(
  //           (value) => {
  //             if (value.contains('No such file or directory'))
  //               {
  //                 ExtStorageProvider.getExtStorage(
  //                   dirName: 'CloudSpot/Backups',
  //                   writeAccess: true,
  //                 ).then(
  //                   (value) {
  //                     Hive.box('settings').put('autoBackPath', value);
  //                     createBackup(
  //                       context,
  //                       checked,
  //                       boxNames,
  //                       path: value,
  //                       fileName: 'CloudSpot_AutoBackup',
  //                     );
  //                   },
  //                 ),
  //               },
  //           },
  //         );
  //       }
  //     }
  //   });
  //   downloadChecker();
  // }

  @override
  void initState() {
    super.initState();
    // checkVersion();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    return [
      const HomeScreen(),
      // TopCharts(pageController: _pageController),
      const YouTube(),
      const LibraryPage(),
      NewSettingsPage(callback: callback),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems(BuildContext context) {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home),
        title: AppLocalizations.of(context)!.home,
        activeColorPrimary: Theme.of(context).colorScheme.secondary,
        inactiveColorPrimary: Colors.grey,
      ),
      // PersistentBottomNavBarItem(
      //   icon: Icon(Icons.bar_chart),
      //   title: ("Top Charts"),
      //   activeColorPrimary: Colors.blue,
      //   inactiveColorPrimary: Colors.grey,
      // ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.video_library),
        title: AppLocalizations.of(context)!.youTube,
        activeColorPrimary: Theme.of(context).colorScheme.secondary,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.library_music),
        title: AppLocalizations.of(context)!.library,
        activeColorPrimary: Theme.of(context).colorScheme.secondary,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.settings),
        title: AppLocalizations.of(context)!.settings,
        activeColorPrimary: Theme.of(context).colorScheme.secondary,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool rotated = MediaQuery.sizeOf(context).height < screenWidth;
    final miniplayer = MiniPlayer();
    return GradientContainer(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        drawerEnableOpenDragGesture: false,
        body: Row(
          children: [
            // miniplayer,
            if (rotated)
              ValueListenableBuilder(
                valueListenable: _selectedIndex,
                builder: (BuildContext context, int indexValue, Widget? child) {
                  return NavigationRail(
                    minWidth: 70.0,
                    groupAlignment: 0.0,
                    backgroundColor: Theme.of(context).cardColor,
                    selectedIndex: indexValue,
                    onDestinationSelected: (int index) {
                      onItemTapped(index);
                    },
                    labelType: screenWidth > 1050
                        ? NavigationRailLabelType.selected
                        : NavigationRailLabelType.none,
                    selectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).iconTheme.color,
                    ),
                    selectedIconTheme: Theme.of(context).iconTheme.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    unselectedIconTheme: Theme.of(context).iconTheme,
                    useIndicator: screenWidth < 1050,
                    indicatorColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.2),
                    // labelType: NavigationRailLabelType.all,
                    leading: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage:
                                    AssetImage('assets/ic_launcher.png'),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // selectedIconTheme: IconThemeData(
                    //   color: Theme.of(context).colorScheme.secondary,
                    //   size: 40,
                    // ),
                    // unselectedIconTheme: const IconThemeData(
                    //   color: Colors.grey,
                    //   size: 30,
                    // ),
                    // selectedLabelTextStyle: TextStyle(
                    //   color: Theme.of(context).colorScheme.secondary,
                    // ),
                    // unselectedLabelTextStyle: const TextStyle(
                    //   color: Colors.grey,
                    // ),
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_rounded),
                        label: Text(AppLocalizations.of(context)!.home),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.video_library_rounded),
                        label: Text(AppLocalizations.of(context)!.youTube),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.my_library_music_rounded),
                        label: Text(AppLocalizations.of(context)!.library),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_rounded),
                        label: Text(
                          AppLocalizations.of(context)!.settings,
                        ),
                      ),
                    ],
                  );
                },
              ),
            Expanded(
              child: GradientContainer(
                child: Stack(
                  children: [
                    PersistentTabView(
                      context,
                      controller: _controller,
                      screens: _buildScreens(),
                      items: _navBarsItems(context),
                      // confineToSafeArea: true,
                      backgroundColor: Theme.of(context).cardColor,
                      handleAndroidBackButtonPress: true,
                      resizeToAvoidBottomInset: false,
                      stateManagement: true,
                      navBarHeight: rotated ? 0.0 : kBottomNavigationBarHeight,
                      // hideNavigationBarWhenKeyboardShows: true,
                      decoration: NavBarDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        // colorBehindNavBar: Colors.transparent,
                      ),

                      navBarStyle: NavBarStyle.style9,
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 51, left: 5, right: 5),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          // color: Theme.of(context).primaryColor,
                          elevation: 1,

                          child: miniplayer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
