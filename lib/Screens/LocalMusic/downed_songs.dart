// Coded by Naseer Ahmed

import 'dart:io';

import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/playlist_head.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/audio_query.dart';
import 'package:blackhole/Screens/LocalMusic/localplaylists.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

class DownloadedSongsController extends GetxController
    with GetTickerProviderStateMixin {
  final List<SongModel>? cachedSongs;
  final String? title;
  final int? playlistId;
  final bool showPlaylists;

  DownloadedSongsController({
    this.cachedSongs,
    this.title,
    this.playlistId,
    this.showPlaylists = false,
  });

  final songs = <SongModel>[].obs;
  final tempPath =
      Rx<String?>(Hive.box('settings').get('tempDirPath')?.toString());
  final albums = <String, List<SongModel>>{}.obs;
  final artists = <String, List<SongModel>>{}.obs;
  final genres = <String, List<SongModel>>{}.obs;
  final folders = <String, List<SongModel>>{}.obs;

  final sortedAlbumKeysList = <String>[].obs;
  final sortedArtistKeysList = <String>[].obs;
  final sortedGenreKeysList = <String>[].obs;
  final sortedFolderKeysList = <String>[].obs;

  final added = false.obs;
  final currentTabIndex = 0.obs;

  late TabController tcontroller;
  final OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  final playlistDetails = <PlaylistModel>[].obs;

  int sortValue = Hive.box('settings').get('sortValue', defaultValue: 1) as int;
  int orderValue =
      Hive.box('settings').get('orderValue', defaultValue: 1) as int;
  int albumSortValue =
      Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;
  List dirPaths =
      Hive.box('settings').get('searchPaths', defaultValue: []) as List;
  int minDuration =
      Hive.box('settings').get('minDuration', defaultValue: 10) as int;
  bool includeOrExclude =
      Hive.box('settings').get('includeOrExclude', defaultValue: false) as bool;
  List includedExcludedPaths = Hive.box('settings')
      .get('includedExcludedPaths', defaultValue: []) as List;

  final Map<int, SongSortType> songSortTypes = {
    0: SongSortType.DISPLAY_NAME,
    1: SongSortType.DATE_ADDED,
    2: SongSortType.ALBUM,
    3: SongSortType.ARTIST,
    4: SongSortType.DURATION,
    5: SongSortType.SIZE,
  };

  final Map<int, OrderType> songOrderTypes = {
    0: OrderType.ASC_OR_SMALLER,
    1: OrderType.DESC_OR_GREATER,
  };

  @override
  void onInit() {
    super.onInit();
    tcontroller = TabController(length: showPlaylists ? 6 : 5, vsync: this);
    tcontroller.addListener(() {
      if ((tcontroller.previousIndex != 0 && tcontroller.index == 0) ||
          (tcontroller.previousIndex == 0)) {
        currentTabIndex.value = tcontroller.index;
      }
    });
    getData();
  }

  @override
  void onClose() {
    tcontroller.dispose();
    super.onClose();
  }

  bool checkIncludedOrExcluded(SongModel song) {
    for (final path in includedExcludedPaths) {
      if (song.data.contains(path.toString())) return true;
    }
    return false;
  }

  Future<void> getData() async {
    try {
      Logger.root.info('Requesting permission to access local songs');
      await offlineAudioQuery.requestPermission();
      if (tempPath.value == null) {
        tempPath.value = (await getTemporaryDirectory()).path;
      }
      if (Platform.isAndroid) {
        Logger.root.info('Getting local playlists');
        playlistDetails.value = await offlineAudioQuery.getPlaylists();
      }
      if (cachedSongs == null) {
        Logger.root.info('Cache empty, calling audioQuery');
        final receivedSongs = await offlineAudioQuery.getSongs(
          sortType: songSortTypes[sortValue],
          orderType: songOrderTypes[orderValue],
        );
        Logger.root.info('Received ${receivedSongs.length} songs, filtering');
        songs.value = receivedSongs
            .where(
              (i) =>
                  (i.duration ?? 60000) > 1000 * minDuration &&
                  ((i.isMusic ?? true) ||
                      (i.isPodcast ?? false) ||
                      (i.isAudioBook ?? false)) &&
                  (includeOrExclude
                      ? checkIncludedOrExcluded(i)
                      : !checkIncludedOrExcluded(i)),
            )
            .toList();
      } else {
        Logger.root.info('Setting songs to cached songs');
        songs.value = cachedSongs!;
      }
      added.value = true;
      Logger.root.info('got ${songs.length} songs');
      Logger.root.info('setting albums and artists');
      for (int i = 0; i < songs.length; i++) {
        try {
          if (albums.containsKey(songs[i].album ?? 'Unknown')) {
            albums[songs[i].album ?? 'Unknown']!.add(songs[i]);
          } else {
            albums[songs[i].album ?? 'Unknown'] = [songs[i]];
            sortedAlbumKeysList.add(songs[i].album ?? 'Unknown');
          }

          if (artists.containsKey(songs[i].artist ?? 'Unknown')) {
            artists[songs[i].artist ?? 'Unknown']!.add(songs[i]);
          } else {
            artists[songs[i].artist ?? 'Unknown'] = [songs[i]];
            sortedArtistKeysList.add(songs[i].artist ?? 'Unknown');
          }

          if (genres.containsKey(songs[i].genre ?? 'Unknown')) {
            genres[songs[i].genre ?? 'Unknown']!.add(songs[i]);
          } else {
            genres[songs[i].genre ?? 'Unknown'] = [songs[i]];
            sortedGenreKeysList.add(songs[i].genre ?? 'Unknown');
          }

          final tempPath = songs[i].data.split('/');
          tempPath.removeLast();
          final dirPath = tempPath.join('/');

          if (folders.containsKey(dirPath)) {
            folders[dirPath]!.add(songs[i]);
          } else {
            folders[dirPath] = [songs[i]];
            sortedFolderKeysList.add(dirPath);
          }
        } catch (e) {
          Logger.root.severe('Error in sorting songs', e);
        }
      }
      Logger.root.info('albums, artists, genre & folders set');
    } catch (e) {
      Logger.root.severe('Error in getData', e);
      added.value = true;
    }
  }

  Future<void> sortSongs(int sortVal, int order) async {
    Logger.root.info('Sorting songs');
    switch (sortVal) {
      case 0:
        songs.sort(
          (a, b) => a.displayName.compareTo(b.displayName),
        );
      case 1:
        songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
      case 2:
        songs.sort(
          (a, b) => a.album.toString().compareTo(b.album.toString()),
        );
      case 3:
        songs.sort(
          (a, b) => a.artist.toString().compareTo(b.artist.toString()),
        );
      case 4:
        songs.sort(
          (a, b) => a.duration.toString().compareTo(b.duration.toString()),
        );
      case 5:
        songs.sort(
          (a, b) => a.size.toString().compareTo(b.size.toString()),
        );
      default:
        songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
        break;
    }

    if (order == 1) {
      songs.value = songs.reversed.toList();
    }
    Logger.root.info('Done Sorting songs');
  }

  Future<void> deleteSong(SongModel song) async {
    final audioFile = File(song.data);
    if (albums[song.album]!.length == 1) {
      sortedAlbumKeysList.remove(song.album);
    }
    albums[song.album]!.remove(song);

    if (artists[song.artist]!.length == 1) {
      sortedArtistKeysList.remove(song.artist);
    }
    artists[song.artist]!.remove(song);

    if (genres[song.genre]!.length == 1) {
      sortedGenreKeysList.remove(song.genre);
    }
    genres[song.genre]!.remove(song);

    if (folders[audioFile.parent.path]!.length == 1) {
      sortedFolderKeysList.remove(audioFile.parent.path);
    }
    folders[audioFile.parent.path]!.remove(song);

    songs.remove(song);
  }

  void updateSortValue(int value) {
    sortValue = value;
    Hive.box('settings').put('sortValue', value);
  }

  void updateOrderValue(int value) {
    orderValue = value;
    Hive.box('settings').put('orderValue', value);
  }
}

class DownloadedSongs extends StatelessWidget {
  final List<SongModel>? cachedSongs;
  final String? title;
  final int? playlistId;
  final bool showPlaylists;

  const DownloadedSongs({
    super.key,
    this.cachedSongs,
    this.title,
    this.playlistId,
    this.showPlaylists = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      DownloadedSongsController(
        cachedSongs: cachedSongs,
        title: title,
        playlistId: playlistId,
        showPlaylists: showPlaylists,
      ),
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    return GradientContainer(
      child: DefaultTabController(
        length: showPlaylists ? 6 : 5,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              title ?? AppLocalizations.of(context)!.myMusic,
            ),
            bottom: TabBar(
              isScrollable: showPlaylists,
              controller: controller.tcontroller,
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
                Tab(
                  text: AppLocalizations.of(context)!.folders,
                ),
                if (showPlaylists)
                  Tab(
                    text: AppLocalizations.of(context)!.playlists,
                  ),
              ],
            ),
            actions: [
              Obx(
                () => IconButton(
                  icon: const Icon(CupertinoIcons.search),
                  tooltip: AppLocalizations.of(context)!.search,
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: DataSearch(
                        data: controller.songs,
                        tempPath: controller.tempPath.value!,
                      ),
                    );
                  },
                ),
              ),
              Obx(
                () => controller.currentTabIndex.value == 0
                    ? PopupMenuButton(
                        icon: const Icon(Icons.sort_rounded),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        ),
                        onSelected: (int value) async {
                          if (value < 6) {
                            controller.updateSortValue(value);
                          } else {
                            controller.updateOrderValue(value - 6);
                          }
                          await controller.sortSongs(
                              controller.sortValue, controller.orderValue);
                        },
                        itemBuilder: (context) {
                          final List<String> sortTypes = [
                            AppLocalizations.of(context)!.displayName,
                            AppLocalizations.of(context)!.dateAdded,
                            AppLocalizations.of(context)!.album,
                            AppLocalizations.of(context)!.artist,
                            AppLocalizations.of(context)!.duration,
                            AppLocalizations.of(context)!.size,
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
                                        if (controller.sortValue ==
                                            sortTypes.indexOf(e))
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
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
                                        if (controller.orderValue ==
                                            orderTypes.indexOf(e))
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
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
                      )
                    : const SizedBox(),
              ),
            ],
            centerTitle: true,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Theme.of(context).colorScheme.secondary,
            elevation: 0,
          ),
          body: Obx(
            () => !controller.added.value
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : TabBarView(
                    physics: const CustomPhysics(),
                    controller: controller.tcontroller,
                    children: [
                      SongsTab(
                        songs: controller.songs,
                        playlistId: playlistId,
                        playlistName: title,
                        tempPath: controller.tempPath.value!,
                        deleteSong: controller.deleteSong,
                      ),
                      AlbumsTab(
                        albums: controller.albums,
                        albumsList: controller.sortedAlbumKeysList,
                        tempPath: controller.tempPath.value!,
                      ),
                      AlbumsTab(
                        albums: controller.artists,
                        albumsList: controller.sortedArtistKeysList,
                        tempPath: controller.tempPath.value!,
                      ),
                      AlbumsTab(
                        albums: controller.genres,
                        albumsList: controller.sortedGenreKeysList,
                        tempPath: controller.tempPath.value!,
                      ),
                      AlbumsTab(
                        albums: controller.folders,
                        albumsList: controller.sortedFolderKeysList,
                        tempPath: controller.tempPath.value!,
                        isFolder: true,
                      ),
                      if (showPlaylists)
                        Obx(
                          () => LocalPlaylists(
                            playlistDetails: controller.playlistDetails,
                            offlineAudioQuery: controller.offlineAudioQuery,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class SongsTab extends StatefulWidget {
  final List<SongModel> songs;
  final int? playlistId;
  final String? playlistName;
  final String tempPath;
  final Function(SongModel) deleteSong;
  const SongsTab({
    super.key,
    required this.songs,
    required this.tempPath,
    required this.deleteSong,
    this.playlistId,
    this.playlistName,
  });

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.songs.isEmpty
        ? emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            45,
            AppLocalizations.of(context)!.downloadSomething,
            23.0,
          )
        : Column(
            children: [
              PlaylistHead(
                songsList: widget.songs,
                offline: true,
                fromDownloads: false,
              ),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thickness: 8,
                  thumbVisibility: true,
                  radius: const Radius.circular(10),
                  interactive: true,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 10),
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemExtent: 70.0,
                    itemCount: widget.songs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: OfflineAudioQuery.offlineArtworkWidget(
                          id: widget.songs[index].id,
                          type: ArtworkType.AUDIO,
                          tempPath: widget.tempPath,
                          fileName: widget.songs[index].displayNameWOExt,
                        ),
                        title: Text(
                          widget.songs[index].title.trim() != ''
                              ? widget.songs[index].title
                              : widget.songs[index].displayNameWOExt,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${widget.songs[index].artist?.replaceAll('<unknown>', 'Unknown') ?? AppLocalizations.of(context)!.unknown} - ${widget.songs[index].album?.replaceAll('<unknown>', 'Unknown') ?? AppLocalizations.of(context)!.unknown}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert_rounded),
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                          ),
                          onSelected: (int? value) async {
                            if (value == 0) {
                              AddToOffPlaylist().addToOffPlaylist(
                                context,
                                widget.songs[index].id,
                              );
                            }
                            if (value == 1) {
                              await OfflineAudioQuery().removeFromPlaylist(
                                playlistId: widget.playlistId!,
                                audioId: widget.songs[index].id,
                              );
                              ShowSnackBar().showSnackBar(
                                context,
                                '${AppLocalizations.of(context)!.removedFrom} ${widget.playlistName}',
                              );
                            }

                            if (value == -1) {
                              await widget.deleteSong(widget.songs[index]);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 0,
                              child: Row(
                                children: [
                                  const Icon(Icons.playlist_add_rounded),
                                  const SizedBox(width: 10.0),
                                  Text(
                                    AppLocalizations.of(context)!.addToPlaylist,
                                  ),
                                ],
                              ),
                            ),
                            if (widget.playlistId != null)
                              PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_rounded),
                                    const SizedBox(width: 10.0),
                                    Text(AppLocalizations.of(context)!.remove),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: -1,
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_rounded),
                                  const SizedBox(width: 10.0),
                                  Text(AppLocalizations.of(context)!.delete),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          PlayerInvoke.init(
                            songsList: widget.songs,
                            index: index,
                            isOffline: true,
                            recommend: false,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
  }
}

class AlbumsTab extends StatefulWidget {
  final Map<String, List<SongModel>> albums;
  final List<String> albumsList;
  final String tempPath;
  final bool isFolder;
  const AlbumsTab({
    super.key,
    required this.albums,
    required this.albumsList,
    required this.tempPath,
    this.isFolder = false,
  });

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.albumsList.isEmpty
        ? emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            45,
            AppLocalizations.of(context)!.downloadSomething,
            23.0,
          )
        : Scrollbar(
            controller: _scrollController,
            thickness: 8,
            thumbVisibility: true,
            radius: const Radius.circular(10),
            interactive: true,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              controller: _scrollController,
              shrinkWrap: true,
              itemExtent: 70.0,
              itemCount: widget.albumsList.length,
              itemBuilder: (context, index) {
                String title = widget.albumsList[index];
                if (widget.isFolder && title.length > 35) {
                  final splits = title.split('/');
                  title = '${splits.first}/.../${splits.last}';
                }
                return ListTile(
                  leading: OfflineAudioQuery.offlineArtworkWidget(
                    id: widget.albums[widget.albumsList[index]]![0].id,
                    type: ArtworkType.AUDIO,
                    tempPath: widget.tempPath,
                    fileName: widget
                        .albums[widget.albumsList[index]]![0].displayNameWOExt,
                  ),
                  title: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${widget.albums[widget.albumsList[index]]!.length} ${AppLocalizations.of(context)!.songs}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DownloadedSongs(
                          title: widget.albumsList[index],
                          cachedSongs: widget.albums[widget.albumsList[index]],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
  }
}
