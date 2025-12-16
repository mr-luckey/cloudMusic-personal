// import 'dart:io';

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

import 'package:get/get.dart';
import 'package:hive/hive.dart';
// import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class DownloadedSongsDesktopController extends GetxController
    with GetTickerProviderStateMixin {
  final List<Map>? cachedSongs;
  final String? title;
  final int? playlistId;

  DownloadedSongsDesktopController({
    this.cachedSongs,
    this.title,
    this.playlistId,
  });

  final songs = <Map>[].obs;
  final tempPath =
      Rx<String?>(Hive.box('settings').get('tempDirPath')?.toString());
  final albums = <String, List<Map>>{}.obs;
  final artists = <String, List<Map>>{}.obs;
  final genres = <String, List<Map>>{}.obs;
  final sortedAlbumKeysList = <String>[].obs;
  final sortedArtistKeysList = <String>[].obs;
  final sortedGenreKeysList = <String>[].obs;
  final added = false.obs;

  late TabController tcontroller;
  final OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  final OnAudioQuery audioQuery = OnAudioQuery();

  @override
  void onInit() {
    super.onInit();
    tcontroller = TabController(length: 4, vsync: this);
    requestPermission();
  }

  @override
  void onClose() {
    tcontroller.dispose();
    super.onClose();
  }

  void requestPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      getData();
    }
  }

  Future<void> getData() async {
    if (tempPath.value == null) {
      tempPath.value = (await getTemporaryDirectory()).path;
    }
    if (cachedSongs == null) {
      loadSongs();
    } else {
      songs.value = cachedSongs!;
    }
    added.value = true;
  }

  void loadSongs() async {
    List<SongModel> songModels = await audioQuery.querySongs();
    songs.value = songModels
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
  }
}

class DownloadedSongsDesktop extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = Get.put(
      DownloadedSongsDesktopController(
        cachedSongs: cachedSongs,
        title: title,
        playlistId: playlistId,
      ),
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    return GradientContainer(
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              title ?? AppLocalizations.of(context)!.myMusic,
            ),
            bottom: TabBar(
              controller: controller.tcontroller,
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
          body: Obx(
            () => !controller.added.value
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    physics: const CustomPhysics(),
                    controller: controller.tcontroller,
                    children: [
                      SongsTab(
                        songs: controller.songs,
                        playlistId: playlistId,
                        playlistName: title,
                        tempPath: controller.tempPath.value!,
                      ),
                      AlbumsTabDesktop(
                        albums: controller.albums,
                        albumsList: controller.sortedAlbumKeysList,
                        tempPath: controller.tempPath.value!,
                      ),
                      AlbumsTabDesktop(
                        albums: controller.artists,
                        albumsList: controller.sortedArtistKeysList,
                        tempPath: controller.tempPath.value!,
                      ),
                      AlbumsTabDesktop(
                        albums: controller.genres,
                        albumsList: controller.sortedGenreKeysList,
                        tempPath: controller.tempPath.value!,
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
