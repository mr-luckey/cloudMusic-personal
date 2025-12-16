// Coded by Naseer Ahmed

import 'dart:io';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/media_tile.dart';
import 'package:blackhole/CustomWidgets/search_bar.dart' as searchbar;
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Helpers/search_helper.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Common/song_list_view.dart';
import 'package:blackhole/Screens/Search/albums.dart';
import 'package:blackhole/Screens/Search/artists.dart';
import 'package:blackhole/Screens/YouTube/youtube_artist.dart';
import 'package:blackhole/Screens/YouTube/youtube_playlist.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:blackhole/Services/yt_music.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

class SearchPageController extends GetxController {
  final String initialQuery;
  final bool initialFromHome;
  final String? initialSearchType;

  SearchPageController({
    required this.initialQuery,
    required this.initialFromHome,
    this.initialSearchType,
  });

  final query = ''.obs;
  final fetchResultCalled = false.obs;
  final fetched = false.obs;
  final alertShown = false.obs;
  final fromHome = Rx<bool?>(null);
  final searchedList = <Map<dynamic, dynamic>>[].obs;
  final searchType =
      Hive.box('settings').get('searchType', defaultValue: 'yt').toString().obs;
  final searchHistory =
      (Hive.box('settings').get('search', defaultValue: []) as List).obs;
  final liveSearch =
      Hive.box('settings').get('liveSearch', defaultValue: true) as bool;
  final loadingSongIndex = Rx<int?>(null);
  final topSearch = <String>[].obs;

  final TextEditingController controller = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    print('[CONTROLLER] 🎬 SearchPageController initialized');
    print('[CONTROLLER] 📥 Initial query: "$initialQuery"');
    controller.text = initialQuery;
    // Make sure reactive query matches the initial text so that all
    // subsequent searches / refreshes use the latest query value.
    query.value = initialQuery;
    print(
        '[CONTROLLER] ✅ Set controller.text and query.value to: "$initialQuery"');
    if (initialSearchType != null) {
      searchType.value = initialSearchType!;
      print('[CONTROLLER] 🔧 Search type set to: "$initialSearchType"');
    }
    fromHome.value = initialFromHome;
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }

  /// Reset search state and go back to the "home" search view
  /// where history + trending chips are visible.
  Future<void> clearSearch() async {
    Logger.root.info('[SEARCH] Clearing search state');
    query.value = '';
    fetched.value = false;
    fetchResultCalled.value = false;
    searchedList.clear();
    fromHome.value = true;
    alertShown.value = false;

    // Reload trending searches so the user sees fresh suggestions.
    try {
      await getTrendingSearch();
    } catch (e, stackTrace) {
      Logger.root.severe(
          '[SEARCH] Error reloading trending search: $e', e, stackTrace);
    }
  }

  Future<void> fetchResults() async {
    // this fetches songs, albums, playlists, artists, etc
    // CRITICAL: Always use query.value directly, NOT a captured final variable
    // to ensure we get the latest query value

    print('[CONTROLLER] 🔍 fetchResults() called');
    print('[CONTROLLER] 📊 Current query.value: "${query.value}"');
    print('[CONTROLLER] 📝 Current controller.text: "${controller.text}"');

    Logger.root.info('[SEARCH] fetchResults called');
    Logger.root.info('[SEARCH] Current query.value: "${query.value}"');
    Logger.root.info('[SEARCH] Current controller.text: "${controller.text}"');

    if (query.value.isEmpty) {
      Logger.root.warning('[SEARCH] fetchResults called with empty query');
      return;
    }

    Logger.root.info(
      '=== SEARCH START === Query: "${query.value}", Type: ${searchType.value}',
    );

    switch (searchType.value) {
      case 'ytm':
        Logger.root.info('[YTM] Starting YouTube Music search...');
        try {
          final value = await YtMusicService().search(query.value);
          Logger.root
              .info('[YTM] Search completed. Sections found: ${value.length}');
          for (final section in value) {
            Logger.root.info(
              '[YTM] Section: ${section['title']}, Items: ${(section['items'] as List?)?.length ?? 0}',
            );
          }

          if (value.isNotEmpty) {
            // Find Songs section if it exists
            final songSectionIndex =
                value.indexWhere((element) => element['title'] == 'Songs');
            if (songSectionIndex != -1) {
              value[songSectionIndex]['allowViewAll'] = true;
              Logger.root
                  .info('[YTM] Found Songs section at index $songSectionIndex');
            } else {
              Logger.root.warning('[YTM] No Songs section found in results');
            }
          }

          searchedList.value = value;
          fetched.value = true;
          Logger.root.info('[YTM] Search results set successfully');
        } catch (e, stackTrace) {
          Logger.root.severe(
            '[YTM] Error during YouTube Music search: $e',
            e,
            stackTrace,
          );
          searchedList.value = [];
          fetched.value = true;
        }

        break;

      case 'yt':
        Logger.root.info('[YT] Starting YouTube search...');
        try {
          final value =
              await YouTubeServices.instance.fetchSearchResults(query.value);
          Logger.root
              .info('[YT] Search completed. Sections found: ${value.length}');
          for (final section in value) {
            Logger.root.info(
              '[YT] Section: ${section['title']}, Items: ${(section['items'] as List?)?.length ?? 0}',
            );
          }

          searchedList.value = value;
          fetched.value = true;
          Logger.root.info('[YT] Search results set successfully');
        } catch (e, stackTrace) {
          Logger.root.severe(
            '[YT] Error during YouTube search: $e',
            e,
            stackTrace,
          );
          searchedList.value = [];
          fetched.value = true;
        }

        break;

      default:
        Logger.root.info('[SAAVN] Starting Saavn search...');
        try {
          searchedList.value = await SaavnAPI().fetchSearchResults(query.value);
          Logger.root.info(
            '[SAAVN] Search completed. Sections found: ${searchedList.length}',
          );
          for (final element in searchedList) {
            if (element['title'] != 'Top Result') {
              element['allowViewAll'] = true;
            }
          }
          fetched.value = true;
          Logger.root.info('[SAAVN] Search results set successfully');
        } catch (e, stackTrace) {
          Logger.root.severe(
            '[SAAVN] Error during Saavn search: $e',
            e,
            stackTrace,
          );
          searchedList.value = [];
          fetched.value = true;
        }
    }

    Logger.root
        .info('=== SEARCH END === Total sections: ${searchedList.length}');
  }

  Future<void> getTrendingSearch() async {
    topSearch.value = await SaavnAPI().getTopSearches();
  }

  void addToHistory(String title) {
    final tempquery = title.trim();
    if (tempquery == '') {
      return;
    }
    final idx = searchHistory.indexOf(tempquery);
    if (idx != -1) {
      searchHistory.removeAt(idx);
    }
    searchHistory.insert(
      0,
      tempquery,
    );
    if (searchHistory.length > 10) {
      searchHistory.value = searchHistory.sublist(0, 10);
    }
    Hive.box('settings').put(
      'search',
      searchHistory,
    );
  }

  void handleBackButton() {
    Logger.root.info('[SEARCH] Back button pressed on search page');
    fromHome.value = true;
    query.value = '';
    fetched.value = false;
    fetchResultCalled.value = false;
    searchedList.clear();
    controller.text = '';
    controller.selection = const TextSelection.collapsed(offset: 0);

    // Ensure trending search is available when returning to home view.
    getTrendingSearch();
  }

  void handleHistoryChipDelete(int index) {
    searchHistory.removeAt(index);
    Hive.box('settings').put(
      'search',
      searchHistory,
    );
  }

  void handleHistoryChipTap(int index) {
    Logger.root.info('[SEARCH] History chip tapped: ${searchHistory[index]}');
    print('[CONTROLLER] 📜 History chip tapped: "${searchHistory[index]}"');
    fetched.value = false;
    query.value = searchHistory.removeAt(index).toString().trim();
    print('[CONTROLLER] 🔄 Updated query.value to: "${query.value}"');
    addToHistory(query.value);
    controller.text = query.value;
    print('[CONTROLLER] 📝 Updated controller.text to: "${controller.text}"');
    controller.selection = TextSelection.fromPosition(
      TextPosition(
        offset: query.value.length,
      ),
    );
    fetchResultCalled.value = false;
    fromHome.value = false;
    searchedList.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    print('[CONTROLLER] 🚀 Triggering fetchResults...');
    // Trigger search
    fetchResults();
  }

  void handleTrendingChipTap(String value) {
    Logger.root.info('[SEARCH] Trending chip tapped: $value');
    print('[CONTROLLER] 🔥 Trending chip tapped: "$value"');
    fetched.value = false;
    query.value = value.trim();
    print('[CONTROLLER] 🔄 Updated query.value to: "${query.value}"');
    controller.text = query.value;
    print('[CONTROLLER] 📝 Updated controller.text to: "${controller.text}"');
    controller.selection = TextSelection.fromPosition(
      TextPosition(
        offset: query.value.length,
      ),
    );
    addToHistory(query.value);
    fetchResultCalled.value = false;
    fromHome.value = false;
    searchedList.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    print('[CONTROLLER] 🚀 Triggering fetchResults...');
    // Trigger search
    fetchResults();
  }

  void handleUseProxy() {
    Hive.box('settings').put('useProxy', true);
    fetched.value = false;
    fetchResultCalled.value = false;
    searchedList.clear();
  }

  void handleSearchTypeChange(String key) {
    Logger.root
        .info('[SEARCH] Search type changed from ${searchType.value} to $key');
    searchType.value = key;
    fetched.value = false;
    fetchResultCalled.value = false;
    Hive.box('settings').put('searchType', key);
    if (key == 'ytm' || key == 'yt') {
      Hive.box('settings').put('searchYtMusic', key == 'ytm');
    }

    // Re-fetch results with the current query if we're not on the home screen
    if (query.value.isNotEmpty && !(fromHome.value ?? true)) {
      Logger.root.info(
          '[SEARCH] Re-fetching results for query: "${query.value}" with new search type');
      fetchResults();
    }
  }

  Future<void> handleSubmit(String submittedQuery) async {
    print('[CONTROLLER] ═══════════════════════════════════════');
    print('[CONTROLLER] ✅ HANDLE SUBMIT CALLED');
    print('[CONTROLLER] 📥 Submitted query: "$submittedQuery"');
    print('[CONTROLLER] 📊 Previous query.value: "${query.value}"');
    Logger.root.info('[SEARCH] ===== SUBMIT STARTED =====');
    Logger.root.info('[SEARCH] Submitted query: "$submittedQuery"');
    Logger.root.info('[SEARCH] Previous query.value: "${query.value}"');
    Logger.root.info('[SEARCH] Previous controller.text: "${controller.text}"');

    final trimmedQuery = submittedQuery.trim();
    if (trimmedQuery.isEmpty) {
      Logger.root.warning('[SEARCH] Empty query submitted, ignoring');
      return;
    }

    fetched.value = false;
    fromHome.value = false;
    fetchResultCalled.value = false;
    query.value = trimmedQuery;
    controller.text = trimmedQuery;
    controller.selection = TextSelection.fromPosition(
      TextPosition(
        offset: query.value.length,
      ),
    );
    searchedList.clear();

    print('[CONTROLLER] ✅ Updated query.value to: "${query.value}"');
    print('[CONTROLLER] ✅ Updated controller.text to: "${controller.text}"');
    Logger.root.info('[SEARCH] Updated query.value: "${query.value}"');
    Logger.root.info('[SEARCH] Updated controller.text: "${controller.text}"');
    Logger.root.info('[SEARCH] Calling fetchResults...');

    // Trigger search first
    await fetchResults();

    // Only add successful / non-empty queries to history,
    // so a tag is not created *before* the actual search.
    if (searchedList.isNotEmpty) {
      addToHistory(trimmedQuery);
    }

    print('[CONTROLLER] ═══════════════════════════════════════');
    Logger.root.info('[SEARCH] ===== SUBMIT COMPLETED =====');
  }

  Future<void> handleSongTap(int index, List items, String itemType) async {
    // Show loading indicator for this specific item
    loadingSongIndex.value = index;

    try {
      final Map? response = (itemType == 'video')
          ? await YouTubeServices.instance.formatVideoFromId(
              id: items[index]['id'].toString(),
              data: items[index] as Map,
            )
          : await YtMusicService().getSongData(
              videoId: items[index]['id'].toString(),
              data: items[index] as Map,
            );

      loadingSongIndex.value = null;

      if (response != null && response.isNotEmpty) {
        PlayerInvoke.init(
          songsList: [
            response,
          ],
          index: 0,
          isOffline: false,
        );
      }
    } catch (e, stackTrace) {
      loadingSongIndex.value = null;
      Logger.root.severe(
        '[SEARCH] Error handling song tap for index $index, type: $itemType, id: ${items[index]['id']}: $e',
        e,
        stackTrace,
      );
    }
  }
}

class SearchPage extends StatefulWidget {
  final String query;
  final bool fromHome;
  final bool fromDirectSearch;
  final String? searchType;
  final bool autofocus;

  const SearchPage({
    super.key,
    required this.query,
    this.fromHome = false,
    this.fromDirectSearch = false,
    this.searchType,
    this.autofocus = false,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Store the tag so it doesn't change on rebuilds
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    // Generate the tag ONCE when the page is first created
    _controllerTag = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Widget nothingFound(BuildContext context, SearchPageController controller) {
    if (!controller.alertShown.value) {
      // Defer showing snackbar to next frame to avoid build conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowSnackBar().showSnackBar(
          context,
          AppLocalizations.of(context)!.useVpn,
          duration: const Duration(seconds: 7),
          action: SnackBarAction(
            textColor: Theme.of(context).colorScheme.secondary,
            label: AppLocalizations.of(context)!.useProxy,
            onPressed: () {
              controller.handleUseProxy();
            },
          ),
        );
      });
      controller.alertShown.value = true;
    }
    return emptyScreen(
      context,
      0,
      ':( ',
      100,
      AppLocalizations.of(context)!.sorry,
      60,
      AppLocalizations.of(context)!.resultsNotFound,
      20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SearchPageController(
        initialQuery: widget.query,
        initialFromHome: widget.fromHome,
        initialSearchType: widget.searchType,
      ),
      tag: _controllerTag, // Use the persistent tag
    );

    if (!controller.fetchResultCalled.value) {
      controller.fetchResultCalled.value = true;
      controller.fromHome.value!
          ? controller.getTrendingSearch()
          : controller.fetchResults();
    }

    return GradientContainer(
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: searchbar.SearchBar(
            controller: controller.controller,
            liveSearch: controller.liveSearch,
            autofocus: widget.autofocus,
            hintText: AppLocalizations.of(context)!.searchText,
            onQueryCleared: () {
              controller.clearSearch();
            },
            onQueryChanged: (String value) async {
              // Generate lightweight suggestions from history + trending.
              final history = controller.searchHistory
                  .map((e) => e.toString())
                  .toList(growable: false);
              final trending = controller.topSearch.toList(growable: false);

              return SearchHelper.generateSuggestions(
                value,
                history,
                trending,
              );
            },
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if ((controller.fromHome.value ?? false) ||
                    widget.fromDirectSearch) {
                  Navigator.pop(context);
                } else {
                  controller.handleBackButton();
                }
              },
            ),
            body: Obx(
              () => (controller.fromHome.value!)
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5.0,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 65,
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Obx(
                              () => Wrap(
                                children: List<Widget>.generate(
                                  controller.searchHistory.length,
                                  (int index) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                        vertical: (Platform.isWindows ||
                                                Platform.isLinux ||
                                                Platform.isMacOS)
                                            ? 5.0
                                            : 0.0,
                                      ),
                                      child: GestureDetector(
                                        child: Chip(
                                          label: Text(
                                            controller.searchHistory[index]
                                                .toString(),
                                          ),
                                          labelStyle: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          onDeleted: () {
                                            controller
                                                .handleHistoryChipDelete(index);
                                          },
                                        ),
                                        onTap: () {
                                          controller
                                              .handleHistoryChipTap(index);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Obx(
                            () {
                              if (controller.topSearch.isEmpty) {
                                return const SizedBox();
                              }
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .trendingSearch,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Wrap(
                                      children: List<Widget>.generate(
                                        controller.topSearch.length,
                                        (int index) {
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 5.0,
                                              vertical: (Platform.isWindows ||
                                                      Platform.isLinux ||
                                                      Platform.isMacOS)
                                                  ? 5.0
                                                  : 0.0,
                                            ),
                                            child: ChoiceChip(
                                              label: Text(
                                                controller.topSearch[index],
                                              ),
                                              selectedColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withValues(alpha: 0.2),
                                              labelStyle: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge!
                                                    .color,
                                                fontWeight: FontWeight.normal,
                                              ),
                                              selected: false,
                                              onSelected: (bool selected) {
                                                if (selected) {
                                                  controller
                                                      .handleTrendingChipTap(
                                                    controller.topSearch[index],
                                                  );
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 70,
                            left: 15,
                          ),
                          child: (controller.query.value.isEmpty &&
                                  widget.query.isEmpty)
                              ? null
                              : Row(
                                  children: getChoices(context, controller, [
                                    // {'label': 'Saavn', 'key': 'saavn'},
                                    {'label': 'YtMusic', 'key': 'ytm'},
                                    {'label': 'YouTube', 'key': 'yt'},
                                  ]),
                                ),
                        ),
                        Expanded(
                          child: !controller.fetched.value
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : (controller.searchedList.isEmpty)
                                  ? nothingFound(context, controller)
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                      ),
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        children: controller.searchedList.map(
                                          (Map section) {
                                            final String title =
                                                section['title'].toString();
                                            final List? items =
                                                section['items'] as List?;

                                            if (items == null ||
                                                items.isEmpty) {
                                              return const SizedBox();
                                            }
                                            return Column(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 17,
                                                    right: 15,
                                                    top: 15,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        title,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                      if (section[
                                                              'allowViewAll'] ==
                                                          true)
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: controller
                                                                          .searchType
                                                                          .value !=
                                                                      'saavn'
                                                                  ? () {
                                                                      Navigator
                                                                          .push(
                                                                        context,
                                                                        PageRouteBuilder(
                                                                          opaque:
                                                                              false,
                                                                          pageBuilder: (
                                                                            _,
                                                                            __,
                                                                            ___,
                                                                          ) =>
                                                                              SongsListViewPage(
                                                                            onTap:
                                                                                (index, listItems) async {
                                                                              final Map response = await YtMusicService().getSongData(
                                                                                videoId: items[index]['id'].toString(),
                                                                                data: items[index] as Map,
                                                                                quality: Hive.box('settings')
                                                                                    .get(
                                                                                      'ytQuality',
                                                                                      defaultValue: 'Low',
                                                                                    )
                                                                                    .toString(),
                                                                              );

                                                                              if (response.isNotEmpty) {
                                                                                PlayerInvoke.init(
                                                                                  songsList: [
                                                                                    response,
                                                                                  ],
                                                                                  index: 0,
                                                                                  isOffline: false,
                                                                                );
                                                                              } else {
                                                                                ShowSnackBar().showSnackBar(
                                                                                  context,
                                                                                  AppLocalizations.of(
                                                                                    context,
                                                                                  )!
                                                                                      .ytLiveAlert,
                                                                                );
                                                                              }
                                                                            },
                                                                            title:
                                                                                title,
                                                                            subtitle:
                                                                                '\nShowing Search Results for',
                                                                            secondarySubtitle:
                                                                                '"${(controller.query.value == '' ? widget.query : controller.query.value).capitalize}"',
                                                                            listItemsTitle:
                                                                                title,
                                                                            loadFunction:
                                                                                () {
                                                                              return YtMusicService().searchSongs(
                                                                                controller.query.value == '' ? widget.query : controller.query.value,
                                                                              );
                                                                            },
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  : () {
                                                                      if (title == 'Albums' ||
                                                                          title ==
                                                                              'Playlists' ||
                                                                          title ==
                                                                              'Artists') {
                                                                        Navigator
                                                                            .push(
                                                                          context,
                                                                          PageRouteBuilder(
                                                                            opaque:
                                                                                false,
                                                                            pageBuilder: (
                                                                              _,
                                                                              __,
                                                                              ___,
                                                                            ) =>
                                                                                AlbumSearchPage(
                                                                              query: controller.query.value == '' ? widget.query : controller.query.value,
                                                                              type: title,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }
                                                                      if (title ==
                                                                          'Songs') {
                                                                        Navigator
                                                                            .push(
                                                                          context,
                                                                          PageRouteBuilder(
                                                                            opaque:
                                                                                false,
                                                                            pageBuilder: (
                                                                              _,
                                                                              __,
                                                                              ___,
                                                                            ) =>
                                                                                SongsListPage(
                                                                              listItem: {
                                                                                'id': controller.query.value == '' ? widget.query : controller.query.value,
                                                                                'title': title,
                                                                                'type': 'songs',
                                                                              },
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                              child: Row(
                                                                children: [
                                                                  Text(
                                                                    AppLocalizations
                                                                            .of(
                                                                      context,
                                                                    )!
                                                                        .viewAll,
                                                                    style:
                                                                        TextStyle(
                                                                      color: Theme
                                                                              .of(
                                                                        context,
                                                                      )
                                                                          .textTheme
                                                                          .bodySmall!
                                                                          .color,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w800,
                                                                    ),
                                                                  ),
                                                                  Icon(
                                                                    Icons
                                                                        .chevron_right_rounded,
                                                                    color: Theme
                                                                            .of(
                                                                      context,
                                                                    )
                                                                        .textTheme
                                                                        .bodySmall!
                                                                        .color,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                ListView.builder(
                                                  itemCount: items.length,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 5,
                                                  ),
                                                  itemBuilder:
                                                      (context, index) {
                                                    final int count =
                                                        items[index]['count']
                                                                as int? ??
                                                            0;
                                                    final itemType = items[
                                                                index]['type']
                                                            ?.toString()
                                                            .toLowerCase() ??
                                                        'video';
                                                    String countText = '';
                                                    if (count >= 1) {
                                                      count > 1
                                                          ? countText =
                                                              '$count ${AppLocalizations.of(context)!.songs}'
                                                          : countText =
                                                              '$count ${AppLocalizations.of(context)!.song}';
                                                    }
                                                    return MediaTile(
                                                      title: items[index]
                                                              ['title']
                                                          .toString(),
                                                      subtitle: countText != ''
                                                          ? '$countText\n${items[index]["subtitle"]}'
                                                          : items[index]
                                                                  ['subtitle']
                                                              .toString(),
                                                      isThreeLine:
                                                          countText != '',
                                                      leadingWidget: imageCard(
                                                        borderRadius: title ==
                                                                    'Artists' ||
                                                                itemType ==
                                                                    'artist'
                                                            ? 50.0
                                                            : 7.0,
                                                        placeholderImage:
                                                            AssetImage(
                                                          title == 'Artists' ||
                                                                  itemType ==
                                                                      'artist'
                                                              ? 'assets/artist.png'
                                                              : title == 'Songs'
                                                                  ? 'assets/cover.jpg'
                                                                  : 'assets/album.png',
                                                        ),
                                                        imageUrl: items[index]
                                                                ['image']
                                                            .toString(),
                                                      ),
                                                      trailingWidget: controller
                                                                  .searchType
                                                                  .value !=
                                                              'saavn'
                                                          ? ((itemType ==
                                                                      'song' ||
                                                                  itemType ==
                                                                      'video')
                                                              ? Obx(
                                                                  () => controller
                                                                              .loadingSongIndex
                                                                              .value ==
                                                                          index
                                                                      ? const SizedBox(
                                                                          width:
                                                                              48,
                                                                          height:
                                                                              48,
                                                                          child:
                                                                              Center(
                                                                            child:
                                                                                SizedBox(
                                                                              width: 24,
                                                                              height: 24,
                                                                              child: CircularProgressIndicator(
                                                                                strokeWidth: 2,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : YtSongTileTrailingMenu(
                                                                          data: items[index]
                                                                              as Map,
                                                                        ),
                                                                )
                                                              : null)
                                                          : title != 'Albums'
                                                              ? title == 'Songs'
                                                                  ? Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        DownloadButton(
                                                                          data: items[index]
                                                                              as Map,
                                                                          icon:
                                                                              'download',
                                                                        ),
                                                                        LikeButton(
                                                                          mediaItem:
                                                                              null,
                                                                          data: items[index]
                                                                              as Map,
                                                                        ),
                                                                        SongTileTrailingMenu(
                                                                          data: items[index]
                                                                              as Map,
                                                                        ),
                                                                      ],
                                                                    )
                                                                  : null
                                                              : AlbumDownloadButton(
                                                                  albumName: items[
                                                                              index]
                                                                          [
                                                                          'title']
                                                                      .toString(),
                                                                  albumId: items[
                                                                              index]
                                                                          ['id']
                                                                      .toString(),
                                                                ),
                                                      onTap: controller
                                                                  .searchType
                                                                  .value !=
                                                              'saavn'
                                                          ? () async {
                                                              if (itemType ==
                                                                  'artist') {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            YouTubeArtist(
                                                                      artistId: items[index]
                                                                              [
                                                                              'id']
                                                                          .toString(),
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                              if (itemType == 'playlist' ||
                                                                  itemType ==
                                                                      'album' ||
                                                                  itemType ==
                                                                      'single') {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            YouTubePlaylist(
                                                                      playlistId:
                                                                          items[index]['id']
                                                                              .toString(),
                                                                      type: itemType == 'album' ||
                                                                              itemType == 'single'
                                                                          ? 'album'
                                                                          : 'playlist',
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                              if (itemType ==
                                                                      'song' ||
                                                                  itemType ==
                                                                      'video') {
                                                                try {
                                                                  await controller
                                                                      .handleSongTap(
                                                                    index,
                                                                    items,
                                                                    itemType,
                                                                  );
                                                                } catch (e) {
                                                                  ShowSnackBar()
                                                                      .showSnackBar(
                                                                    context,
                                                                    'Error loading song: $e',
                                                                  );
                                                                }
                                                              }
                                                            }
                                                          : () {
                                                              if (title ==
                                                                  'Songs') {
                                                                PlayerInvoke
                                                                    .init(
                                                                  songsList: [
                                                                    items[
                                                                        index],
                                                                  ],
                                                                  index: 0,
                                                                  isOffline:
                                                                      false,
                                                                );
                                                              } else {
                                                                Navigator.push(
                                                                  context,
                                                                  PageRouteBuilder(
                                                                    opaque:
                                                                        false,
                                                                    pageBuilder: (
                                                                      _,
                                                                      __,
                                                                      ___,
                                                                    ) =>
                                                                        title == 'Artists' || (title == 'Top Result' && items[0]['type'] == 'artist')
                                                                            ? ArtistSearchPage(
                                                                                data: items[index] as Map,
                                                                              )
                                                                            : SongsListPage(
                                                                                listItem: items[index] as Map,
                                                                              ),
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    ),
                        ),
                      ],
                    ),
            ),
            onSubmitted: (String submittedQuery) {
              controller.handleSubmit(submittedQuery);
            },
          ),
        ),
      ),
    );
  }

  List<Widget> getChoices(
    BuildContext context,
    SearchPageController controller,
    List<Map<String, String>> choices,
  ) {
    return choices.map((Map<String, String> element) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Obx(
          () => ChoiceChip(
            label: Text(element['label']!),
            selectedColor:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: controller.searchType.value == element['key']
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).textTheme.bodyLarge!.color,
              fontWeight: controller.searchType.value == element['key']
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
            selected: controller.searchType.value == element['key'],
            onSelected: (bool selected) {
              if (selected) {
                controller.handleSearchTypeChange(element['key']!);
              }
            },
          ),
        ),
      );
    }).toList();
  }
}
