// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/playlist_head.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Screens/Library/show_songs.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:blackhole/bloc/liked/liked_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final ValueNotifier<bool> selectMode = ValueNotifier<bool>(false);
final Set<String> selectedItems = <String>{};

class LikedSongs extends StatefulWidget {
  final String playlistName;
  final String? showName;
  final bool fromPlaylist;
  final List? songs;
  const LikedSongs({
    super.key,
    required this.playlistName,
    this.showName,
    this.fromPlaylist = false,
    this.songs,
  });
  @override
  _LikedSongsState createState() => _LikedSongsState();
}

class _LikedSongsState extends State<LikedSongs>
    with SingleTickerProviderStateMixin {
  late final LikedBloc _likedBloc;
  TabController? _tcontroller;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showShuffle = ValueNotifier<bool>(true);

  @override
  void initState() {
    _likedBloc = LikedBloc(
      playlistName: widget.playlistName,
      fromPlaylist: widget.fromPlaylist,
      songs: widget.songs,
    );
    _tcontroller = TabController(length: 4, vsync: this);
    _tcontroller!.addListener(() {
      if ((_tcontroller!.previousIndex != 0 && _tcontroller!.index == 0) ||
          (_tcontroller!.previousIndex == 0)) {
        _likedBloc.add(LikedTabIndexChanged(index: _tcontroller!.index));
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        _showShuffle.value = false;
      } else {
        _showShuffle.value = true;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _tcontroller!.dispose();
    _scrollController.dispose();
    _likedBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LikedBloc, LikedState>(
      bloc: _likedBloc,
      builder: (context, state) {
        return GradientContainer(
          child: DefaultTabController(
            length: 4,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  widget.showName == null
                      ? widget.playlistName[0].toUpperCase() +
                          widget.playlistName.substring(1)
                      : widget.showName![0].toUpperCase() +
                          widget.showName!.substring(1),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.secondary,
                elevation: 0,
                bottom: TabBar(
                  controller: _tcontroller,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(
                      text: AppLocalizations.of(context)!.songs,
                    ),
                    Tab(
                      text: AppLocalizations.of(context)!.albums,
                    ),
                    Tab(
                      text: AppLocalizations.of(context)!.artists,
                    ),
                    Tab(
                      text: AppLocalizations.of(context)!.genres,
                    ),
                  ],
                ),
                actions: [
                  ValueListenableBuilder(
                    valueListenable: selectMode,
                    child: Row(
                      children: <Widget>[
                        if (state.songs.isNotEmpty)
                          MultiDownloadButton(
                            data: state.songs,
                            playlistName: widget.showName == null
                                ? widget.playlistName[0].toUpperCase() +
                                    widget.playlistName.substring(1)
                                : widget.showName![0].toUpperCase() +
                                    widget.showName!.substring(1),
                          ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.search),
                          tooltip: AppLocalizations.of(context)!.search,
                          onPressed: () {
                            showSearch(
                              context: context,
                              delegate: DownloadsSearch(
                                data: state.songs,
                                onDelete: (Map item) {
                                  _likedBloc.add(LikedSongDeleted(song: item));
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
                        if (state.currentTabIndex == 0)
                          PopupMenuButton(
                            icon: const Icon(Icons.sort_rounded),
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0)),
                            ),
                            onSelected: (int value) {
                              _likedBloc.add(LikedSongsSorted(value: value));
                            },
                            itemBuilder: (context) {
                              final List<String> sortTypes = [
                                AppLocalizations.of(context)!.displayName,
                                AppLocalizations.of(context)!.dateAdded,
                                AppLocalizations.of(context)!.album,
                                AppLocalizations.of(context)!.artist,
                                AppLocalizations.of(context)!.duration,
                              ];
                              final List<String> orderTypes = [
                                AppLocalizations.of(context)!.inc,
                                AppLocalizations.of(context)!.dec,
                              ];
                              final menuList = <PopupMenuEntry<int>>[];
                              menuList.addAll(
                                sortTypes
                                    .map(
                                      (e) => PopupMenuItem(
                                        value: sortTypes.indexOf(e),
                                        child: Row(
                                          children: [
                                            if (state.sortValue ==
                                                sortTypes.indexOf(e))
                                              Icon(
                                                Icons.check_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                              )
                                            else
                                              const SizedBox(),
                                            const SizedBox(width: 10),
                                            Text(
                                              e,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                              menuList.add(
                                const PopupMenuDivider(
                                  height: 10,
                                ),
                              );
                              menuList.addAll(
                                orderTypes
                                    .map(
                                      (e) => PopupMenuItem(
                                        value: sortTypes.length +
                                            orderTypes.indexOf(e),
                                        child: Row(
                                          children: [
                                            if (state.orderValue ==
                                                orderTypes.indexOf(e))
                                              Icon(
                                                Icons.check_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                              )
                                            else
                                              const SizedBox(),
                                            const SizedBox(width: 10),
                                            Text(
                                              e,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                              return menuList;
                            },
                          ),
                      ],
                    ),
                    builder: (
                      BuildContext context,
                      bool showValue,
                      Widget? child,
                    ) {
                      return showValue
                          ? Row(
                              children: [
                                MultiDownloadButton(
                                  data: state.songs
                                      .where(
                                        (element) => selectedItems
                                            .contains(element['id']),
                                      )
                                      .toList(),
                                  playlistName: widget.showName == null
                                      ? widget.playlistName[0].toUpperCase() +
                                          widget.playlistName.substring(1)
                                      : widget.showName![0].toUpperCase() +
                                          widget.showName!.substring(1),
                                ),
                                IconButton(
                                  onPressed: () {
                                    selectedItems.clear();
                                    selectMode.value = false;
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                              ],
                            )
                          : child!;
                    },
                  ),
                ],
              ),
              body: !state.isLoaded
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : TabBarView(
                      physics: const CustomPhysics(),
                      controller: _tcontroller,
                      children: [
                        SongsTab(
                          songs: state.songs,
                          selectionRevision: state.selectionRevision,
                          onDelete: (Map item) {
                            _likedBloc.add(LikedSongDeleted(song: item));
                          },
                          onReorder: (int oldIndex, int newIndex) {
                            _likedBloc.add(LikedSongsReordered(
                              oldIndex: oldIndex,
                              newIndex: newIndex,
                            ));
                          },
                          onSelectionChanged: () {
                            _likedBloc.add(const LikedSelectionChanged());
                          },
                          playlistName: widget.playlistName,
                          scrollController: _scrollController,
                        ),
                        AlbumsTab(
                          albums: state.albums,
                          type: 'album',
                          offline: false,
                          playlistName: widget.playlistName,
                          sortedAlbumKeysList: state.sortedAlbumKeysList,
                        ),
                        AlbumsTab(
                          albums: state.artists,
                          type: 'artist',
                          offline: false,
                          playlistName: widget.playlistName,
                          sortedAlbumKeysList: state.sortedArtistKeysList,
                        ),
                        AlbumsTab(
                          albums: state.genres,
                          type: 'genre',
                          offline: false,
                          playlistName: widget.playlistName,
                          sortedAlbumKeysList: state.sortedGenreKeysList,
                        ),
                      ],
                    ),
              floatingActionButton: ValueListenableBuilder(
                valueListenable: _showShuffle,
                child: FloatingActionButton(
                  backgroundColor: Theme.of(context).cardColor,
                  child: Icon(
                    Icons.shuffle_rounded,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    size: 24.0,
                  ),
                  onPressed: () {
                    if (state.songs.isNotEmpty) {
                      PlayerInvoke.init(
                        songsList: state.songs,
                        index: 0,
                        isOffline: false,
                        recommend: false,
                        shuffle: true,
                      );
                    }
                  },
                ),
                builder: (
                  BuildContext context,
                  bool showShuffle,
                  Widget? child,
                ) {
                  return AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    offset: showShuffle ? Offset.zero : const Offset(0, 2),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: showShuffle ? 1 : 0,
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class SongsTab extends StatefulWidget {
  final List songs;
  final String playlistName;
  final Function(Map item) onDelete;
  final ScrollController scrollController;
  final Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onSelectionChanged;
  final int selectionRevision;
  const SongsTab({
    super.key,
    required this.songs,
    required this.onDelete,
    required this.playlistName,
    required this.scrollController,
    required this.onReorder,
    required this.onSelectionChanged,
    required this.selectionRevision,
  });

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // selectionRevision triggers rebuild when selection changes
    final _ = widget.selectionRevision;
    return (widget.songs.isEmpty)
        ? emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            50,
            AppLocalizations.of(context)!.addSomething,
            23.0,
          )
        : Column(
            children: [
              PlaylistHead(
                songsList: widget.songs,
                offline: false,
                fromDownloads: false,
              ),
              Expanded(
                child: ReorderableListView.builder(
                  onReorder: widget.onReorder,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10),
                  shrinkWrap: true,
                  itemCount: widget.songs.length,
                  itemExtent: 70.0,
                  itemBuilder: (context, index) {
                    return ValueListenableBuilder(
                      key: Key(widget.songs[index]['id'].toString()),
                      valueListenable: selectMode,
                      builder: (context, value, child) {
                        final bool selected =
                            selectedItems.contains(widget.songs[index]['id']);
                        return ListTile(
                          leading: imageCard(
                            imageUrl: widget.songs[index]['image'].toString(),
                            selected: selected,
                          ),
                          onTap: () {
                            if (selectMode.value) {
                              selectMode.value = false;
                              if (selected) {
                                selectedItems.remove(
                                  widget.songs[index]['id'].toString(),
                                );
                                selectMode.value = true;
                                if (selectedItems.isEmpty) {
                                  selectMode.value = false;
                                }
                              } else {
                                selectedItems
                                    .add(widget.songs[index]['id'].toString());
                                selectMode.value = true;
                              }
                              widget.onSelectionChanged();
                            } else {
                              PlayerInvoke.init(
                                songsList: widget.songs,
                                index: index,
                                isOffline: false,
                                recommend: false,
                                playlistBox: widget.playlistName,
                              );
                            }
                          },
                          selected: selected,
                          selectedTileColor: Colors.white10,
                          title: Text(
                            '${widget.songs[index]['title']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            (widget.songs[index]['album'] ?? '') == ''
                                ? '${widget.songs[index]['artist'] ?? 'Unknown'}'
                                : '${widget.songs[index]['artist'] ?? 'Unknown'} - ${widget.songs[index]['album']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.playlistName != 'Favorite Songs')
                                LikeButton(
                                  mediaItem: null,
                                  data: widget.songs[index] as Map,
                                ),
                              DownloadButton(
                                data: widget.songs[index] as Map,
                                icon: 'download',
                              ),
                              SongTileTrailingMenu(
                                data: widget.songs[index] as Map,
                                isPlaylist: true,
                                deleteLiked: widget.onDelete,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
  }
}

class AlbumsTab extends StatefulWidget {
  final Map<String, List> albums;
  final List sortedAlbumKeysList;
  final String type;
  final bool offline;
  final String? playlistName;
  const AlbumsTab({
    super.key,
    required this.albums,
    required this.offline,
    required this.sortedAlbumKeysList,
    required this.type,
    this.playlistName,
  });

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.sortedAlbumKeysList.isEmpty
        ? emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            50,
            AppLocalizations.of(context)!.addSomething,
            23.0,
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10.0),
                  shrinkWrap: true,
                  itemExtent: 70.0,
                  itemCount: widget.sortedAlbumKeysList.length,
                  itemBuilder: (context, index) {
                    final List imageList = widget
                                .albums[widget.sortedAlbumKeysList[index]]!
                                .length >=
                            4
                        ? widget.albums[widget.sortedAlbumKeysList[index]]!
                            .sublist(0, 4)
                        : widget.albums[widget.sortedAlbumKeysList[index]]!
                            .sublist(
                            0,
                            widget.albums[widget.sortedAlbumKeysList[index]]!
                                .length,
                          );
                    return ListTile(
                      leading: (widget.offline)
                          ? OfflineCollage(
                              imageList: imageList,
                              showGrid: widget.type == 'genre',
                              placeholderImage: widget.type == 'artist'
                                  ? 'assets/artist.png'
                                  : 'assets/album.png',
                            )
                          : Collage(
                              imageList: imageList,
                              showGrid: widget.type == 'genre',
                              placeholderImage: widget.type == 'artist'
                                  ? 'assets/artist.png'
                                  : 'assets/album.png',
                            ),
                      title: Text(
                        '${widget.sortedAlbumKeysList[index]}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        widget.albums[widget.sortedAlbumKeysList[index]]!
                                    .length ==
                                1
                            ? '${widget.albums[widget.sortedAlbumKeysList[index]]!.length} ${AppLocalizations.of(context)!.song}'
                            : '${widget.albums[widget.sortedAlbumKeysList[index]]!.length} ${AppLocalizations.of(context)!.songs}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall!.color,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => widget.offline
                                ? SongsList(
                                    data: widget.albums[
                                        widget.sortedAlbumKeysList[index]]!,
                                    offline: widget.offline,
                                  )
                                : LikedSongs(
                                    playlistName: widget.playlistName!,
                                    fromPlaylist: true,
                                    showName: widget.sortedAlbumKeysList[index]
                                        .toString(),
                                    songs: widget.albums[
                                        widget.sortedAlbumKeysList[index]],
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
  }
}
