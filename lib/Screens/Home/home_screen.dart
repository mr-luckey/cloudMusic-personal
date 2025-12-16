// Coded by Naseer Ahmed

import 'dart:math';

import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
// import 'package:blackhole/Screens/Home/saavn.dart';
import 'package:blackhole/Screens/LocalMusic/homeScreen_song.dart';
import 'package:blackhole/Screens/Search/search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:upgrader/upgrader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String name =
        Hive.box('settings').get('name', defaultValue: 'Guest') as String;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool rotated = MediaQuery.sizeOf(context).height < screenWidth;
    return UpgradeAlert(
      showIgnore: false,
      showLater: false,
      showReleaseNotes: false,
      // upgrader: Upgrader(
      //   durationUntilAlertAgain: const Duration(seconds: 20),
      // ),
      child: SafeArea(
        child: Stack(
          children: [
            NestedScrollView(
              physics: const BouncingScrollPhysics(),
              controller: _scrollController,
              headerSliverBuilder: (
                BuildContext context,
                bool innerBoxScrolled,
              ) {
                return <Widget>[
                  SliverAppBar(
                    expandedHeight: 120,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    // pinned: true,
                    toolbarHeight: 65,
                    // floating: true,
                    automaticallyImplyLeading: false,
                    flexibleSpace: LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        return FlexibleSpaceBar(
                          titlePadding: EdgeInsets.zero,
                          // collapseMode: CollapseMode.parallax,
                          background: GestureDetector(
                            onTap: () async {
                              showTextInputDialog(
                                context: context,
                                title: 'Name',
                                initialText: name,
                                keyboardType: TextInputType.name,
                                onSubmitted:
                                    (String value, BuildContext context) {
                                  Hive.box('settings').put(
                                    'name',
                                    value.trim(),
                                  );
                                  name = value.trim();
                                  Navigator.pop(context);
                                },
                              );
                              // setState(() {});
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const SizedBox(
                                  height: 40,
                                ),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 15.0,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!
                                            .homeGreet,
                                        style: TextStyle(
                                          letterSpacing: 2,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 15.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      ValueListenableBuilder(
                                        valueListenable: Hive.box(
                                          'settings',
                                        ).listenable(),
                                        builder: (
                                          BuildContext context,
                                          Box box,
                                          Widget? child,
                                        ) {
                                          return Text(
                                            (box.get('name') == null ||
                                                    box.get('name') == '')
                                                ? 'Guest'
                                                : box
                                                    .get(
                                                      'name',
                                                    )
                                                    .split(
                                                      ' ',
                                                    )[0]
                                                    .toString(),
                                            style: const TextStyle(
                                              letterSpacing: 2,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    stretch: true,
                    toolbarHeight: 50,
                    title: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, child) {
                          final bool shouldShowAppBar =
                              _scrollController.hasClients &&
                                  _scrollController.offset > kToolbarHeight;
                          final double appBarHeight = shouldShowAppBar
                              ? 0.0 // Hide the app bar when scrolling down
                              : max(
                                  MediaQuery.of(context).size.width -
                                      _scrollController.offset.roundToDouble(),
                                  MediaQuery.of(context).size.width -
                                      (rotated
                                          ? 0
                                          : 75)); // Show and adjust height when scrolling up
                          final double iconOpacity = shouldShowAppBar
                              ? 0.0
                              : 1.0; // Hide the icon when scrolling up

                          return GestureDetector(
                            child: AnimatedContainer(
                              width: MediaQuery.of(context).size.width,
                              height: appBarHeight,
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(2.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Theme.of(context).cardColor,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5.0,
                                    offset: Offset(1.5, 1.5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 10.0),
                                  AnimatedOpacity(
                                    opacity: iconOpacity,
                                    duration: const Duration(milliseconds: 150),
                                    child: Icon(
                                      CupertinoIcons.search,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Text(
                                    AppLocalizations.of(context)!.searchText,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .color,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchPage(
                                  query: '',
                                  fromHome: true,
                                  autofocus: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ];
              },
              // body: YouTube(),
              body: HomescreenSong(),
              //  SaavnHomePage(),
            ),

            //   ),
          ],
        ),
      ),
    );
  }
}
