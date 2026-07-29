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
import 'package:blackhole/Helpers/extensions.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Common/song_list_view.dart';
import 'package:blackhole/Screens/Search/albums.dart';
import 'package:blackhole/Screens/Search/artists.dart';
import 'package:blackhole/Screens/YouTube/youtube_artist.dart';
import 'package:blackhole/Screens/YouTube/youtube_playlist.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:blackhole/Services/yt_music.dart';
import 'package:blackhole/bloc/search/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

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
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchBloc _searchBloc;
  bool alertShown = false;
  bool liveSearch =
      Hive.box('settings').get('liveSearch', defaultValue: true) as bool;
  final ValueNotifier<List<String>> topSearch = ValueNotifier<List<String>>([]);
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.query;
    _searchBloc = SearchBloc(
      initialQuery: widget.query,
      initialSearchType: widget.searchType,
      initialFromHome: widget.fromHome,
    );

    if (widget.fromHome) {
      _getTrendingSearch();
    } else if (widget.query.isNotEmpty) {
      _searchBloc.add(SearchQuerySubmitted(
        query: widget.query,
        searchType: _searchBloc.state.searchType,
      ));
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchBloc.close();
    super.dispose();
  }

  Future<void> _getTrendingSearch() async {
    topSearch.value = await SaavnAPI().getTopSearches();
  }

  Widget nothingFound(BuildContext context) {
    if (!alertShown) {
      ShowSnackBar().showSnackBar(
        context,
        AppLocalizations.of(context)!.useVpn,
        duration: const Duration(seconds: 7),
        action: SnackBarAction(
          textColor: Theme.of(context).colorScheme.secondary,
          label: AppLocalizations.of(context)!.useProxy,
          onPressed: () {
            Hive.box('settings').put('useProxy', true);
            _searchBloc.add(SearchQuerySubmitted(
              query: _searchBloc.state.query,
              searchType: _searchBloc.state.searchType,
            ));
          },
        ),
      );
      alertShown = true;
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
    return BlocBuilder<SearchBloc, SearchState>(
      bloc: _searchBloc,
      builder: (context, state) {
        return GradientContainer(
          child: SafeArea(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              body: searchbar.SearchBar(
                controller: _controller,
                liveSearch: liveSearch,
                autofocus: widget.autofocus,
                hintText: AppLocalizations.of(context)!.searchText,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    if ((state.fromHome && widget.fromHome) ||
                        widget.fromDirectSearch) {
                      Navigator.pop(context);
                    } else {
                      _controller.text = '';
                      _searchBloc.add(const SearchNavigatedHome());
                    }
                  },
                ),
                body: (state.fromHome)
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5.0,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 65),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Wrap(
                                children: List<Widget>.generate(
                                  state.searchHistory.length,
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
                                            state.searchHistory[index]
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
                                            _searchBloc.add(
                                                SearchHistoryItemRemoved(
                                                    index: index));
                                          },
                                        ),
                                        onTap: () {
                                          final query = state
                                              .searchHistory[index]
                                              .toString()
                                              .trim();
                                          _controller.text = query;
                                          _controller.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset: query.length),
                                          );
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          _searchBloc.add(
                                              SearchQuerySubmitted(
                                                  query: query,
                                                  searchType:
                                                      state.searchType));
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: topSearch,
                              builder: (
                                BuildContext context,
                                List<String> value,
                                Widget? child,
                              ) {
                                if (value.isEmpty) return const SizedBox();
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
                                          value.length,
                                          (int index) {
                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 5.0,
                                                vertical:
                                                    (Platform.isWindows ||
                                                            Platform.isLinux ||
                                                            Platform.isMacOS)
                                                        ? 5.0
                                                        : 0.0,
                                              ),
                                              child: ChoiceChip(
                                                label: Text(value[index]),
                                                selectedColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .secondary
                                                        .withOpacity(0.2),
                                                labelStyle: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge!
                                                      .color,
                                                  fontWeight:
                                                      FontWeight.normal,
                                                ),
                                                selected: false,
                                                onSelected: (bool selected) {
                                                  if (selected) {
                                                    final query =
                                                        value[index].trim();
                                                    _controller.text = query;
                                                    _controller.selection =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                          offset:
                                                              query.length),
                                                    );
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                    _searchBloc.add(
                                                        SearchQuerySubmitted(
                                                            query: query,
                                                            searchType: state
                                                                .searchType));
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
                            child: (state.query.isEmpty &&
                                    widget.query.isEmpty)
                                ? null
                                : Row(
                                    children: _getChoices(context, state, [
                                      {'label': 'YtMusic', 'key': 'ytm'},
                                      {'label': 'YouTube', 'key': 'yt'},
                                    ]),
                                  ),
                          ),
                          Expanded(
                            child: state.status == SearchStatus.loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : (state.searchedList.isEmpty)
                                    ? nothingFound(context)
                                    : SingleChildScrollView(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 5.0,
                                        ),
                                        physics:
                                            const BouncingScrollPhysics(),
                                        child: Column(
                                          children:
                                              state.searchedList.map(
                                            (Map section) {
                                              final String title = section[
                                                      'title']
                                                  .toString();
                                              final List? items =
                                                  section['items']
                                                      as List?;

                                              if (items == null ||
                                                  items.isEmpty) {
                                                return const SizedBox();
                                              }
                                              return Column(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .only(
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
                                                          style:
                                                              TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .secondary,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800,
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
                                                                onTap: state.searchType !=
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
                                                                              onTap: (index, listItems) async {
                                                                                PlayerInvoke.beginPreparing();
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
                                                                                  PlayerInvoke.endPreparing();
                                                                                  ShowSnackBar().showSnackBar(
                                                                                    context,
                                                                                    AppLocalizations.of(
                                                                                      context,
                                                                                    )!
                                                                                        .ytLiveAlert,
                                                                                  );
                                                                                }
                                                                              },
                                                                              title: title,
                                                                              subtitle: '\nShowing Search Results for',
                                                                              secondarySubtitle: '"${(state.query.isEmpty ? widget.query : state.query).capitalize()}"',
                                                                              listItemsTitle: title,
                                                                              loadFunction: () {
                                                                                return YtMusicService().searchSongs(
                                                                                  state.query.isEmpty ? widget.query : state.query,
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
                                                                              opaque: false,
                                                                              pageBuilder: (
                                                                                _,
                                                                                __,
                                                                                ___,
                                                                              ) =>
                                                                                  AlbumSearchPage(
                                                                                query: state.query.isEmpty ? widget.query : state.query,
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
                                                                              opaque: false,
                                                                              pageBuilder: (
                                                                                _,
                                                                                __,
                                                                                ___,
                                                                              ) =>
                                                                                  SongsListPage(
                                                                                listItem: {
                                                                                  'id': state.query.isEmpty ? widget.query : state.query,
                                                                                  'title': title,
                                                                                  'type': 'songs',
                                                                                },
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                child:
                                                                    Row(
                                                                  children: [
                                                                    Text(
                                                                      AppLocalizations
                                                                              .of(
                                                                        context,
                                                                      )!
                                                                          .viewAll,
                                                                      style:
                                                                          TextStyle(
                                                                        color: Theme.of(
                                                                          context,
                                                                        )
                                                                            .textTheme
                                                                            .bodySmall!
                                                                            .color,
                                                                        fontWeight:
                                                                            FontWeight.w800,
                                                                      ),
                                                                    ),
                                                                    Icon(
                                                                      Icons
                                                                          .chevron_right_rounded,
                                                                      color: Theme.of(
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
                                                    itemCount:
                                                        items.length,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 5,
                                                    ),
                                                    itemBuilder:
                                                        (context,
                                                            index) {
                                                      final int count = items[
                                                                      index]
                                                                  [
                                                                  'count']
                                                              as int? ??
                                                          0;
                                                      final itemType = items[
                                                                          index]
                                                                      [
                                                                      'type']
                                                                  ?.toString()
                                                                  .toLowerCase() ??
                                                          'video';
                                                      String
                                                          countText =
                                                          '';
                                                      if (count >= 1) {
                                                        count > 1
                                                            ? countText =
                                                                '$count ${AppLocalizations.of(context)!.songs}'
                                                            : countText =
                                                                '$count ${AppLocalizations.of(context)!.song}';
                                                      }
                                                      return MediaTile(
                                                        title: items[
                                                                    index]
                                                                [
                                                                'title']
                                                            .toString(),
                                                        subtitle: countText !=
                                                                ''
                                                            ? '$countText\n${items[index]["subtitle"]}'
                                                            : items[index]
                                                                    [
                                                                    'subtitle']
                                                                .toString(),
                                                        isThreeLine:
                                                            countText !=
                                                                '',
                                                        leadingWidget:
                                                            imageCard(
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
                                                                : title ==
                                                                        'Songs'
                                                                    ? 'assets/cover.jpg'
                                                                    : 'assets/album.png',
                                                          ),
                                                          imageUrl: items[
                                                                      index]
                                                                  [
                                                                  'image']
                                                              .toString(),
                                                        ),
                                                        trailingWidget: state
                                                                    .searchType !=
                                                                'saavn'
                                                            ? ((itemType ==
                                                                        'song' ||
                                                                    itemType ==
                                                                        'video')
                                                                ? YtSongTileTrailingMenu(
                                                                    data: items[
                                                                            index]
                                                                        as Map,
                                                                  )
                                                                : null)
                                                            : title !=
                                                                    'Albums'
                                                                ? title ==
                                                                        'Songs'
                                                                    ? Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          DownloadButton(
                                                                            data:
                                                                                items[index] as Map,
                                                                            icon:
                                                                                'download',
                                                                          ),
                                                                          LikeButton(
                                                                            mediaItem:
                                                                                null,
                                                                            data:
                                                                                items[index] as Map,
                                                                          ),
                                                                          SongTileTrailingMenu(
                                                                            data:
                                                                                items[index] as Map,
                                                                          ),
                                                                        ],
                                                                      )
                                                                    : null
                                                                : AlbumDownloadButton(
                                                                    albumName: items[index]
                                                                            [
                                                                            'title']
                                                                        .toString(),
                                                                    albumId: items[index]
                                                                            [
                                                                            'id']
                                                                        .toString(),
                                                                  ),
                                                        onTap: state
                                                                    .searchType !=
                                                                'saavn'
                                                            ? () async {
                                                                if (itemType ==
                                                                    'artist') {
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              YouTubeArtist(
                                                                        artistId:
                                                                            items[index]['id'].toString(),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                                if (itemType ==
                                                                        'playlist' ||
                                                                    itemType ==
                                                                        'album' ||
                                                                    itemType ==
                                                                        'single') {
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              YouTubePlaylist(
                                                                        playlistId:
                                                                            items[index]['id'].toString(),
                                                                        type: itemType == 'album' || itemType == 'single'
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
                                                                  PlayerInvoke
                                                                      .beginPreparing();
                                                                  final Map?
                                                                      response =
                                                                      (itemType ==
                                                                              'video')
                                                                          ? await YouTubeServices.instance.formatVideoFromId(
                                                                              id: items[index]['id'].toString(),
                                                                              data: items[index] as Map,
                                                                            )
                                                                          : await YtMusicService().getSongData(
                                                                              videoId: items[index]['id'].toString(),
                                                                              data: items[index] as Map,
                                                                            );

                                                                  if (response !=
                                                                      null) {
                                                                    PlayerInvoke
                                                                        .init(
                                                                      songsList: [
                                                                        response,
                                                                      ],
                                                                      index:
                                                                          0,
                                                                      isOffline:
                                                                          false,
                                                                    );
                                                                  } else {
                                                                    PlayerInvoke
                                                                        .endPreparing();
                                                                    ShowSnackBar()
                                                                        .showSnackBar(
                                                                      context,
                                                                      AppLocalizations.of(
                                                                        context,
                                                                      )!
                                                                          .ytLiveAlert,
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
                                                                    index:
                                                                        0,
                                                                    isOffline:
                                                                        false,
                                                                  );
                                                                } else {
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
                onSubmitted: (String submittedQuery) {
                  _controller.text = submittedQuery;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: submittedQuery.length),
                  );
                  _searchBloc.add(SearchQuerySubmitted(
                    query: submittedQuery,
                    searchType: state.searchType,
                  ));
                },
                onQueryChanged: (changedQuery) {
                  return YouTubeServices.instance
                      .getSearchSuggestions(query: changedQuery);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _getChoices(
    BuildContext context,
    SearchState state,
    List<Map<String, String>> choices,
  ) {
    return choices.map((Map<String, String> element) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: ChoiceChip(
          label: Text(element['label']!),
          selectedColor:
              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: state.searchType == element['key']
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).textTheme.bodyLarge!.color,
            fontWeight: state.searchType == element['key']
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          selected: state.searchType == element['key'],
          onSelected: (bool selected) {
            if (selected) {
              _searchBloc.add(SearchTypeChanged(searchType: element['key']!));
            }
          },
        ),
      );
    }).toList();
  }
}
