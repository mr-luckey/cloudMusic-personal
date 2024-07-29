// Coded by Naseer Ahmed

import 'package:blackhole/Screens/About/about.dart';
import 'package:blackhole/Screens/Home/home.dart';
import 'package:blackhole/Screens/Library/downloads.dart';
import 'package:blackhole/Screens/Library/nowplaying.dart';
import 'package:blackhole/Screens/Library/playlists.dart';
import 'package:blackhole/Screens/Library/recent.dart';
import 'package:blackhole/Screens/Library/stats.dart';
import 'package:blackhole/Screens/Login/auth.dart';
import 'package:blackhole/Screens/Login/pref.dart';
import 'package:blackhole/Screens/Settings/new_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

Widget initialFuntion() {
  return Hive.box('settings').get('userId') != null ? HomePage() : AuthScreen();
}


final Map<String, Widget Function(BuildContext)> namedRoutes = {
  '/': (context) => initialFuntion(),
  '/pref': (context) => const PrefScreen(),
  '/setting': (context) => const NewSettingsPage(),
  '/about': (context) => AboutScreen(),
  '/playlists': (context) => PlaylistScreen(),
  '/nowplaying': (context) => NowPlaying(),
  '/recent': (context) => RecentlyPlayed(),
  '/downloads': (context) => const Downloads(),
  '/stats': (context) => const Stats(),
};
