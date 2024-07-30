// // Coded by Naseer Ahmed
//
// import 'dart:io';
//
// import 'package:blackhole/CustomWidgets/bottom_nav_bar.dart';
// import 'package:blackhole/CustomWidgets/drawer.dart';
// import 'package:blackhole/CustomWidgets/gradient_containers.dart';
// import 'package:blackhole/CustomWidgets/miniplayer.dart';
// import 'package:blackhole/CustomWidgets/snackbar.dart';
// import 'package:blackhole/Helpers/backup_restore.dart';
// import 'package:blackhole/Helpers/downloads_checker.dart';
// import 'package:blackhole/Helpers/github.dart';
// import 'package:blackhole/Helpers/route_handler.dart';
// import 'package:blackhole/Helpers/update.dart';
// import 'package:blackhole/Screens/Common/routes.dart';
// import 'package:blackhole/Screens/Home/home_screen.dart';
// import 'package:blackhole/Screens/Library/library.dart';
// import 'package:blackhole/Screens/LocalMusic/downed_songs.dart';
// import 'package:blackhole/Screens/LocalMusic/downed_songs_desktop.dart';
// import 'package:blackhole/Screens/Player/audioplayer.dart';
// import 'package:blackhole/Screens/Settings/new_settings_page.dart';
// import 'package:blackhole/Screens/Top Charts/top.dart';
// import 'package:blackhole/Screens/YouTube/youtube_home.dart';
// import 'package:blackhole/Services/ext_storage_provider.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:logging/logging.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
// import 'package:url_launcher/url_launcher.dart';
// // import 'package:url_launcher/url_launcher.dart';
//
// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   Future<bool> _onWillPop() async {
//     await Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (BuildContext context) {
//           return HomeScreen();
//         },
//       ),
//     );
//     return true;
//   }
//
//   final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
//   String? appVersion;
//   String name =
//       Hive.box('settings').get('name', defaultValue: 'Guest') as String;
//   bool checkUpdate =
//       Hive.box('settings').get('checkUpdate', defaultValue: true) as bool;
//   bool autoBackup =
//       Hive.box('settings').get('autoBackup', defaultValue: false) as bool;
//   List sectionsToShow = Hive.box('settings').get(
//     'sectionsToShow',
//     defaultValue: ['Home', 'Top Charts', 'YouTube', 'Library'],
//   ) as List;
//   DateTime? backButtonPressTime;
//   final bool useDense = Hive.box('settings').get(
//     'useDenseMini',
//     defaultValue: false,
//   ) as bool;
//
//   void callback() {
//     sectionsToShow = Hive.box('settings').get(
//       'sectionsToShow',
//       defaultValue: ['Home', 'Top Charts', 'YouTube', 'Library'],
//     ) as List;
//     onItemTapped(0);
//     setState(() {});
//   }
//   // bool WillpopUp(){
//   //   if (_selectedIndex.value == 0) {
//   //     if (_pageController.page!.toInt() == 0) {
//   //       return true;
//   //     } else {
//   //       _pageController.animateToPage(
//   //         0,
//   //         duration: const Duration(milliseconds: 300),
//   //         curve: Curves.easeInOut,
//   //       );
//   //       return false;
//   //     }
//   //   } else {
//   //     onItemTapped(0);
//   //     return false;
//   //   }
//   // }
//
//   void onItemTapped(int index) {
//     _selectedIndex.value = index;
//     _controller.jumpToTab(
//       index,
//     );
//   }
//
//   // Future<bool> handleWillPop(BuildContext? context) async {
//   //   if (context == null) return false;
//   //   final now = DateTime.now();
//   //   final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
//   //       backButtonPressTime == null ||
//   //           now.difference(backButtonPressTime!) > const Duration(seconds: 3);
//   //
//   //   if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
//   //     backButtonPressTime = now;
//   //     ShowSnackBar().showSnackBar(
//   //       context,
//   //       AppLocalizations.of(context)!.exitConfirm,
//   //       duration: const Duration(seconds: 2),
//   //       noAction: true,
//   //     );
//   //     return false;
//   //   }
//   //   return true;
//   // }
//
//   void checkVersion() {
//     PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
//       appVersion = packageInfo.version;
//
//       if (checkUpdate) {
//         Logger.root.info('Checking for update');
//         GitHub.getLatestVersion().then((String version) async {
//           if (compareVersion(
//             version,
//             appVersion!,
//           )) {
//             Logger.root.info('Update available');
//             ShowSnackBar().showSnackBar(
//               context,
//               AppLocalizations.of(context)!.updateAvailable,
//               duration: const Duration(seconds: 15),
//               action: SnackBarAction(
//                 textColor: Theme.of(context).colorScheme.secondary,
//                 label: AppLocalizations.of(context)!.update,
//                 onPressed: () async {
//                   if (Platform.isAndroid) {
//                     List? abis = await Hive.box('settings').get('supportedAbis')
//                         as List?;
//
//                     if (abis == null) {
//                       final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//                       final AndroidDeviceInfo androidDeviceInfo =
//                           await deviceInfo.androidInfo;
//                       abis = androidDeviceInfo.supportedAbis;
//                       await Hive.box('settings').put('supportedAbis', abis);
//                     }
//                     if (abis.contains('arm64')) {
//                     } else if (abis.contains('armeabi')) {}
//                   }
//                   Navigator.pop(context);
//                   launchUrl(
//                     Uri.parse(
//                       'https://play.google.com/store/apps/details?id=com.appware.cloudSpot',
//                     ),
//                     mode: LaunchMode.externalApplication,
//                   );
//                 },
//               ),
//             );
//           } else {
//             Logger.root.info('No update available');
//           }
//         });
//       }
//       if (autoBackup) {
//         final List<String> checked = [
//           AppLocalizations.of(
//             context,
//           )!
//               .settings,
//           AppLocalizations.of(
//             context,
//           )!
//               .downs,
//           AppLocalizations.of(
//             context,
//           )!
//               .playlists,
//         ];
//         final List playlistNames = Hive.box('settings').get(
//           'playlistNames',
//           defaultValue: ['Favorite Songs'],
//         ) as List;
//         final Map<String, List> boxNames = {
//           AppLocalizations.of(
//             context,
//           )!
//               .settings: ['settings'],
//           AppLocalizations.of(
//             context,
//           )!
//               .cache: ['cache'],
//           AppLocalizations.of(
//             context,
//           )!
//               .downs: ['downloads'],
//           AppLocalizations.of(
//             context,
//           )!
//               .playlists: playlistNames,
//         };
//         final String autoBackPath = Hive.box('settings').get(
//           'autoBackPath',
//           defaultValue: '',
//         ) as String;
//         if (autoBackPath == '') {
//           ExtStorageProvider.getExtStorage(
//             dirName: 'CloudSpot/Backups',
//             writeAccess: true,
//           ).then((value) {
//             Hive.box('settings').put('autoBackPath', value);
//             createBackup(
//               context,
//               checked,
//               boxNames,
//               path: value,
//               fileName: 'CloudSpot_AutoBackup',
//               showDialog: false,
//             );
//           });
//         } else {
//           createBackup(
//             context,
//             checked,
//             boxNames,
//             path: autoBackPath,
//             fileName: 'CloudSpot_AutoBackup',
//             showDialog: false,
//           ).then(
//             (value) => {
//               if (value.contains('No such file or directory'))
//                 {
//                   ExtStorageProvider.getExtStorage(
//                     dirName: 'CloudSpot/Backups',
//                     writeAccess: true,
//                   ).then(
//                     (value) {
//                       Hive.box('settings').put('autoBackPath', value);
//                       createBackup(
//                         context,
//                         checked,
//                         boxNames,
//                         path: value,
//                         fileName: 'CloudSpot_AutoBackup',
//                       );
//                     },
//                   ),
//                 },
//             },
//           );
//         }
//       }
//     });
//     downloadChecker();
//   }
//
//   final PageController _pageController = PageController();
//   final PersistentTabController _controller = PersistentTabController();
//
//   @override
//   void initState() {
//     super.initState();
//     checkVersion();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double screenWidth = MediaQuery.sizeOf(context).width;
//     final bool rotated = MediaQuery.sizeOf(context).height < screenWidth;
//     final miniplayer = MiniPlayer();
//     return GradientContainer(
//       child: Scaffold(
//         appBar: AppBar(
//           toolbarHeight: 0,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//         ),
//         extendBodyBehindAppBar: true,
//         resizeToAvoidBottomInset: false,
//         backgroundColor: Colors.transparent,
//         drawerEnableOpenDragGesture: false,
//
//         body: Row(
//           children: [
//             if (rotated)
//               ValueListenableBuilder(
//                 valueListenable: _selectedIndex,
//                 builder: (BuildContext context, int indexValue, Widget? child) {
//                   return NavigationRail(
//                     minWidth: 70.0,
//                     groupAlignment: 0.0,
//                     backgroundColor:
//                         // Colors.transparent,
//                         Theme.of(context).cardColor,
//                     selectedIndex: indexValue,
//                     onDestinationSelected: (int index) {
//                       onItemTapped(index);
//                     },
//                     labelType: screenWidth > 1050
//                         ? NavigationRailLabelType.selected
//                         : NavigationRailLabelType.none,
//                     selectedLabelTextStyle: TextStyle(
//                       color: Theme.of(context).colorScheme.secondary,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     unselectedLabelTextStyle: TextStyle(
//                       color: Theme.of(context).iconTheme.color,
//                     ),
//                     selectedIconTheme: Theme.of(context).iconTheme.copyWith(
//                           color: Theme.of(context).colorScheme.secondary,
//                         ),
//                     unselectedIconTheme: Theme.of(context).iconTheme,
//                     useIndicator: screenWidth < 1050,
//                     indicatorColor: Theme.of(context)
//                         .colorScheme
//                         .secondary
//                         .withOpacity(0.2),
//                     leading: homeDrawer(
//                       context: context,
//                       padding: const EdgeInsets.symmetric(vertical: 5.0),
//                     ),
//                     destinations: sectionsToShow.map((e) {
//                       switch (e) {
//                         case 'Home':
//                           return NavigationRailDestination(
//                             icon: const Icon(Icons.home_rounded),
//                             label: Text(AppLocalizations.of(context)!.home),
//                           );
//                         case 'Top Charts':
//                           return NavigationRailDestination(
//                             icon: const Icon(Icons.trending_up_rounded),
//                             label: Text(
//                               AppLocalizations.of(context)!.topCharts,
//                             ),
//                           );
//                         case 'YouTube':
//                           return NavigationRailDestination(
//                             icon: const Icon(MdiIcons.youtube),
//                             label: Text(AppLocalizations.of(context)!.youTube),
//                           );
//                         case 'Library':
//                           return NavigationRailDestination(
//                             icon: const Icon(Icons.my_library_music_rounded),
//                             label: Text(AppLocalizations.of(context)!.library),
//                           );
//                         default:
//                           return NavigationRailDestination(
//                             icon: const Icon(Icons.settings_rounded),
//                             label: Text(
//                               AppLocalizations.of(context)!.settings,
//                             ),
//                           );
//                       }
//                     }).toList(),
//                   );
//                 },
//               ),
//             Expanded(
//               child:
//               PersistentTabView.custom(///FIXME: PersistentTabView.custom
//                 context,
//                 controller: _controller,
//                 itemCount: sectionsToShow.length,
//                 // handleAndroidBackButtonPress: _onWillPop(),
//                 // handleAndroidBackButtonPress: WillpopUp(),
//                 // handleAndroidBackButtonPress: handleWillPop(context),
//                 // onWillPop: callback,
//                 // handleAndroidBackButtonPress: _onWillPop,
//                 navBarHeight: 60 +
//                     (rotated ? 0 : 70) +
//                     (useDense ? 0 : 10) +
//                     (rotated && useDense ? 10 : 0),
//                 // confineInSafeArea: false,
//                 onItemTapped: onItemTapped,
//                 handleAndroidBackButtonPress: true,
//
//                 // ,
//                 // onWillPop: ,
//                 // onWillPop: _onWillPop(),
//                 routeAndNavigatorSettings:
//                 CustomWidgetRouteAndNavigatorSettings(
//                   routes: namedRoutes,
//                   onGenerateRoute: (RouteSettings settings) {
//                     if (settings.name == '/player') {
//                       return PageRouteBuilder(
//                         opaque: false,
//                         pageBuilder: (_, __, ___) => const PlayScreen(),
//                       );
//                     }
//                     return HandleRoute.handleRoute(settings.name);
//                   },
//                 ),
//                 customWidget: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     miniplayer,
//                     if (!rotated)
//                       ValueListenableBuilder(
//                         valueListenable: _selectedIndex,
//                         builder: (
//                             BuildContext context,
//                             int indexValue,
//                             Widget? child,
//                             ) {
//                           return AnimatedContainer(
//                             duration: const Duration(milliseconds: 100),
//                             height: 60,
//                             child: CustomBottomNavBar(
//                               currentIndex: indexValue,
//                               backgroundColor: Theme.of(context).brightness ==
//                                   Brightness.dark
//                                   ? Colors.black.withOpacity(0.9)
//                                   : Colors.white.withOpacity(0.9),
//                               onTap: (index) {
//                                 onItemTapped(index);
//                               },
//                               items: _navBarItems(context),
//                             ),
//                           );
//                         },
//                       ),
//                   ],
//                 ),
//                 screens: sectionsToShow.map((e) {
//                   switch (e) {
//                     case 'Home':
//                       return const HomeScreen();
//                     case 'Top Charts':
//                       return TopCharts(
//                         pageController: _pageController,
//                       );
//                     case 'YouTube':
//                       return const YouTube();
//                     case 'Library':
//                       return const LibraryPage();
//                     default:
//                       return NewSettingsPage(callback: callback);
//                   }
//                 }).toList(),
//               )
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   List<CustomBottomNavBarItem> _navBarItems(BuildContext context) {
//     return sectionsToShow.map((section) {
//       switch (section) {
//         case 'Home':
//           return CustomBottomNavBarItem(
//             icon: const Icon(Icons.home_rounded),
//             title: Text(AppLocalizations.of(context)!.home),
//             selectedColor: Theme.of(context).colorScheme.secondary,
//           );
//         case 'Top Charts':
//           return CustomBottomNavBarItem(
//             icon: const Icon(Icons.trending_up_rounded),
//             title: Text(AppLocalizations.of(context)!.topCharts),
//             selectedColor: Theme.of(context).colorScheme.secondary,
//           );
//         case 'YouTube':
//           return CustomBottomNavBarItem(
//             icon: const Icon(MdiIcons.youtube),
//             title: Text(AppLocalizations.of(context)!.youTube),
//             selectedColor: Theme.of(context).colorScheme.secondary,
//           );
//         case 'Library':
//           return CustomBottomNavBarItem(
//             icon: const Icon(Icons.my_library_music_rounded),
//             title: Text(AppLocalizations.of(context)!.library),
//             selectedColor: Theme.of(context).colorScheme.secondary,
//           );
//         default:
//           return CustomBottomNavBarItem(
//             icon: const Icon(Icons.settings_rounded),
//             title: Text(AppLocalizations.of(context)!.settings),
//             selectedColor: Theme.of(context).colorScheme.secondary,
//           );
//       }
//     }).toList();
//   }
// }
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

  void checkVersion() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      appVersion = packageInfo.version;

      if (checkUpdate) {
        Logger.root.info('Checking for update');
        GitHub.getLatestVersion().then((String version) async {
          if (compareVersion(version, appVersion!)) {
            Logger.root.info('Update available');
            ShowSnackBar().showSnackBar(
              context,
              AppLocalizations.of(context)!.updateAvailable,
              duration: const Duration(seconds: 15),
              action: SnackBarAction(
                textColor: Theme.of(context).colorScheme.secondary,
                label: AppLocalizations.of(context)!.update,
                onPressed: () async {
                  if (Platform.isAndroid) {
                    List? abis = await Hive.box('settings').get('supportedAbis')
                        as List?;

                    if (abis == null) {
                      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                      final AndroidDeviceInfo androidDeviceInfo =
                          await deviceInfo.androidInfo;
                      abis = androidDeviceInfo.supportedAbis;
                      await Hive.box('settings').put('supportedAbis', abis);
                    }
                    if (abis.contains('arm64')) {
                    } else if (abis.contains('armeabi')) {}
                  }
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.appware.cloudSpot',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            );
          } else {
            Logger.root.info('No update available');
          }
        });
      }
      if (autoBackup) {
        final List<String> checked = [
          AppLocalizations.of(context)!.settings,
          AppLocalizations.of(context)!.downs,
          AppLocalizations.of(context)!.playlists,
        ];
        final List playlistNames = Hive.box('settings').get(
          'playlistNames',
          defaultValue: ['Favorite Songs'],
        ) as List;
        final Map<String, List> boxNames = {
          AppLocalizations.of(context)!.settings: ['settings'],
          AppLocalizations.of(context)!.cache: ['cache'],
          AppLocalizations.of(context)!.downs: ['downloads'],
          AppLocalizations.of(context)!.playlists: playlistNames,
        };
        final String autoBackPath = Hive.box('settings').get(
          'autoBackPath',
          defaultValue: '',
        ) as String;
        if (autoBackPath == '') {
          ExtStorageProvider.getExtStorage(
            dirName: 'CloudSpot/Backups',
            writeAccess: true,
          ).then((value) {
            Hive.box('settings').put('autoBackPath', value);
            createBackup(
              context,
              checked,
              boxNames,
              path: value,
              fileName: 'CloudSpot_AutoBackup',
              showDialog: false,
            );
          });
        } else {
          createBackup(
            context,
            checked,
            boxNames,
            path: autoBackPath,
            fileName: 'CloudSpot_AutoBackup',
            showDialog: false,
          ).then(
            (value) => {
              if (value.contains('No such file or directory'))
                {
                  ExtStorageProvider.getExtStorage(
                    dirName: 'CloudSpot/Backups',
                    writeAccess: true,
                  ).then(
                    (value) {
                      Hive.box('settings').put('autoBackPath', value);
                      createBackup(
                        context,
                        checked,
                        boxNames,
                        path: value,
                        fileName: 'CloudSpot_AutoBackup',
                      );
                    },
                  ),
                },
            },
          );
        }
      }
    });
    downloadChecker();
  }

  @override
  void initState() {
    super.initState();
    checkVersion();
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
            if (rotated)
              ValueListenableBuilder(
                valueListenable: _selectedIndex,
                builder: (BuildContext context, int indexValue, Widget? child) {
                  return NavigationRail(
                    minWidth: 70.0,
                    groupAlignment: 0.0,
                    backgroundColor:
//                         // Colors.transparent,
                        Theme.of(context).cardColor,
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
                      // NavigationRailDestination(
                      //   icon: Icon(Icons.bar_chart_rounded),
                      //   label: Text('Top Charts'),
                      // ),
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
                      // popAllScreensOnTapOfSelectedTab: true,
                      // itemAnimationProperties: ItemAnimationProperties(
                      //   duration: Duration(milliseconds: 400),
                      //   curve: Curves.ease,
                      // ),
                      // screenTransitionAnimation: ScreenTransitionAnimation(
                      //   animateTabTransition: true,
                      //   curve: Curves.ease,
                      //   duration: Duration(milliseconds: 200),
                      // ),
                      navBarStyle: NavBarStyle.style3,
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: SizedBox(
                        height: useDense ? 65.0 : 70.0,
                        child: miniplayer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // drawer: AppDrawer(
        //   miniplayer: miniplayer,
        //   updateCallback: callback,
        // ),
      ),
    );
  }
}
