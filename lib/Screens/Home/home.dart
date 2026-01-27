// Coded by Naseer Ahmed

import 'dart:async';

import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/G-Ads.dart/ad_manager.dart';
import 'package:blackhole/G-Ads.dart/intersatail_ads.dart';
// import 'package:blackhole/G-Ads.dart/intersatail_ads.dart';
import 'package:blackhole/Screens/Home/home_screen.dart';
import 'package:blackhole/Screens/Library/library.dart';
import 'package:blackhole/Screens/LocalMusic/homeScreen_song.dart';
import 'package:blackhole/Screens/Settings/new_settings_page.dart';
import 'package:blackhole/Screens/YouTube/youtube_home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
// import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
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

  // void _startAdTimer() {
  //   _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
  //     print('i am loaded....................$_timer');
  //     // AdManager.showInterstitialAd();
  //     // print(
  //     //     'i am loaded....................'); // Show the interstitial ad every 50 seconds
  //   });
  // }

  void onItemTapped(int index) {
    _selectedIndex.value = index;
    _controller.jumpToTab(index);
  }

  @override
  void initState() {
    // AdManager().initialize();
    // AdManager.showInterstitialAd();
    // _startAdTimer();
    super.initState();

    // checkVersion();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    return [
      // HomescreenSong(),
      const HomeScreen(),
      YouTube(),
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
                            bottom: 51, left: 5, right: 5, top: 0),
                        child: miniplayer,
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
