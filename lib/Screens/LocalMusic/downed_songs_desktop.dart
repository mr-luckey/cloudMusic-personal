import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/playlist_head.dart';
import 'package:blackhole/Helpers/audio_query.dart';
import 'package:blackhole/Services/player_service.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class DownloadedSongsDesktop extends StatefulWidget {
  final List<Map>? cachedSongs;
  final String? title;
  final int? playlistId;
  const DownloadedSongsDesktop({
    super.key,
    this.cachedSongs,
    this.title,
    this.playlistId,
  });
  @override
  _DownloadedSongsDesktopState createState() => _DownloadedSongsDesktopState();
}

class _DownloadedSongsDesktopState extends State<DownloadedSongsDesktop>
    with TickerProviderStateMixin {
  List<Map> _songs = [];
  String? tempPath = Hive.box('settings').get('tempDirPath')?.toString();
  final Map<String, List<Map>> _albums = {};
  final Map<String, List<Map>> _artists = {};
  final Map<String, List<Map>> _genres = {};
  final List<String> _sortedAlbumKeysList = [];
  final List<String> _sortedArtistKeysList = [];
  final List<String> _sortedGenreKeysList = [];

  bool added = false;
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
  TabController? _tcontroller;
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  List<Map> playlistDetails = [];
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  void initState() {
    _tcontroller = TabController(length: 4, vsync: this);
    _requestPermission();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tcontroller!.dispose();
  }

  void _requestPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      getData();
    } else {
      // Handle permission denied
    }
  }

  Future<void> getData() async {
    tempPath ??= (await getTemporaryDirectory()).path;
    if (widget.cachedSongs == null) {
      _loadSongs();
    } else {
      _songs = widget.cachedSongs!;
    }
    added = true;
    setState(() {});
  }

  void _loadSongs() async {
    List<SongModel> songs = await _audioQuery.querySongs();
    setState(() {
      _songs = songs
          .map((song) => {
                'id': song.id.toString(),
                'title': '',
                'artist': '',
                'album': '',
                'image': '',
                'year': '',
                'path': '',
              })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.title ?? AppLocalizations.of(context)!.myMusic,
            ),
            bottom: TabBar(
              controller: _tcontroller,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: AppLocalizations.of(context)!.songs),
                Tab(text: AppLocalizations.of(context)!.albums),
                Tab(text: AppLocalizations.of(context)!.artists),
                Tab(text: AppLocalizations.of(context)!.genres),
              ],
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Theme.of(context).colorScheme.secondary,
            elevation: 0,
          ),
          body: !added
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  physics: const CustomPhysics(),
                  controller: _tcontroller,
                  children: [
                    SongsTab(
                      songs: _songs,
                      playlistId: widget.playlistId,
                      playlistName: widget.title,
                      tempPath: tempPath!,
                    ),
                    AlbumsTabDesktop(
                      albums: _albums,
                      albumsList: _sortedAlbumKeysList,
                      tempPath: tempPath!,
                    ),
                    AlbumsTabDesktop(
                      albums: _artists,
                      albumsList: _sortedArtistKeysList,
                      tempPath: tempPath!,
                    ),
                    AlbumsTabDesktop(
                      albums: _genres,
                      albumsList: _sortedGenreKeysList,
                      tempPath: tempPath!,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SongsTab extends StatefulWidget {
  final List<Map> songs;
  final int? playlistId;
  final String? playlistName;
  final String tempPath;
  const SongsTab({
    super.key,
    required this.songs,
    required this.tempPath,
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
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10),
                  shrinkWrap: true,
                  itemExtent: 70.0,
                  itemCount: widget.songs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: const Image(
                          fit: BoxFit.cover,
                          height: 50,
                          width: 50,
                          image: AssetImage('assets/cover.jpg'),
                        ),
                      ),
                      title: Text(
                        widget.songs[index]['title'].toString(),
                        overflow: TextOverflow.ellipsis,
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
            ],
          );
  }
}

class AlbumsTabDesktop extends StatefulWidget {
  final Map<String, List<Map>> albums;
  final List<String> albumsList;
  final String tempPath;
  const AlbumsTabDesktop({
    super.key,
    required this.albums,
    required this.albumsList,
    required this.tempPath,
  });

  @override
  State<AlbumsTabDesktop> createState() => _AlbumsTabDesktopState();
}

class _AlbumsTabDesktopState extends State<AlbumsTabDesktop>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      shrinkWrap: true,
      itemExtent: 70.0,
      itemCount: widget.albumsList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            widget.albumsList[index],
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {},
        );
      },
    );
  }
}
