// Coded by Naseer Ahmed

import 'dart:async';

import 'package:blackhole/CustomWidgets/bouncy_playlist_header_scroll_view.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/CustomWidgets/playlist_popupmenu.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:blackhole/Services/yt_music.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

class YouTubePlaylistController extends GetxController {
  final String playlistId;
  final String type;

  YouTubePlaylistController({
    required this.playlistId,
    required this.type,
  });

  final status = false.obs;
  final searchedList = <Map>[].obs;
  final fetched = false.obs;
  final done = true.obs;
  final ScrollController scrollController = ScrollController();
  final playlistName = ''.obs;
  final playlistSubtitle = ''.obs;
  final playlistSecondarySubtitle = Rx<String?>(null);
  final playlistImage = ''.obs;
  final isSharePopupShown = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!status.value) {
      status.value = true;
      if (type == 'playlist') {
        YtMusicService().getPlaylistDetails(playlistId).then((value) {
          try {
            searchedList.value = value['songs'] as List<Map>? ?? [];
            playlistName.value = value['name'] as String? ?? '';
            playlistSubtitle.value = value['subtitle'] as String? ?? '';
            playlistSecondarySubtitle.value = value['description'] as String?;
            playlistImage.value =
                (value['images'] as List?)?.last as String? ?? '';
            fetched.value = true;
          } catch (e) {
            Logger.root.severe('Error in fetching playlist details', e);
            fetched.value = true;
          }
        });
      } else if (type == 'album') {
        YtMusicService().getAlbumDetails(playlistId).then((value) {
          try {
            searchedList.value = value['songs'] as List<Map>? ?? [];
            playlistName.value = value['name'] as String? ?? '';
            playlistSubtitle.value = value['subtitle'] as String? ?? '';
            playlistSecondarySubtitle.value = value['description'] as String?;
            playlistImage.value =
                (value['images'] as List?)?.last as String? ?? '';
            fetched.value = true;
          } catch (e) {
            Logger.root.severe('Error in fetching playlist details', e);
            fetched.value = true;
          }
        });
      } else if (type == 'artist') {
        YtMusicService().getArtistDetails(playlistId).then((value) {
          try {
            searchedList.value = value['songs'] as List<Map>? ?? [];
            playlistName.value = value['name'] as String? ?? '';
            playlistSubtitle.value = value['subtitle'] as String? ?? '';
            playlistSecondarySubtitle.value = value['description'] as String?;
            playlistImage.value =
                (value['images'] as List?)?.last as String? ?? '';
            fetched.value = true;
          } catch (e) {
            Logger.root.severe('Error in fetching playlist details', e);
            fetched.value = true;
          }
        });
      }
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> handlePlayTap() async {
    done.value = false;

    try {
      final Map? response = await YouTubeServices.instance.formatVideoFromId(
        id: searchedList.first['id'].toString(),
        data: searchedList.first,
      );
      
      if (response == null || response.isEmpty) {
        Logger.root.warning(
          'Failed to get stream URL for video ${searchedList.first['id']} in handlePlayTap',
        );
        done.value = true;
        return;
      }
      
      final List<Map> playList = List.from(searchedList);
      playList[0] = response;
      done.value = true;
      PlayerInvoke.init(
        songsList: playList,
        index: 0,
        isOffline: false,
        recommend: false,
      );
    } catch (e, stackTrace) {
      Logger.root.severe(
        'Error in handlePlayTap for playlist $playlistId',
        e,
        stackTrace,
      );
      done.value = true;
    }
  }

  Future<void> handleShuffleTap() async {
    done.value = false;
    
    try {
      final List<Map> playList = List.from(searchedList);
      playList.shuffle();
      final Map? response = await YouTubeServices.instance.formatVideoFromId(
        id: playList.first['id'].toString(),
        data: playList.first,
      );
      
      if (response == null || response.isEmpty) {
        Logger.root.warning(
          'Failed to get stream URL for video ${playList.first['id']} in handleShuffleTap',
        );
        done.value = true;
        return;
      }
      
      playList[0] = response;
      done.value = true;
      PlayerInvoke.init(
        songsList: playList,
        index: 0,
        isOffline: false,
        recommend: false,
      );
    } catch (e, stackTrace) {
      Logger.root.severe(
        'Error in handleShuffleTap for playlist $playlistId',
        e,
        stackTrace,
      );
      done.value = true;
    }
  }

  Future<void> handleSongTap(Map entry) async {
    done.value = false;
    
    try {
      final Map? response = await YouTubeServices.instance.formatVideoFromId(
        id: entry['id'].toString(),
        data: entry,
      );
      
      done.value = true;
      
      if (response == null || response.isEmpty) {
        Logger.root.warning(
          'Failed to get stream URL for video ${entry['id']} in handleSongTap',
        );
        return;
      }
      
      PlayerInvoke.init(
        songsList: [response],
        index: 0,
        isOffline: false,
      );
    } catch (e, stackTrace) {
      Logger.root.severe(
        'Error in handleSongTap for video ${entry['id']}',
        e,
        stackTrace,
      );
      done.value = true;
    }
  }

  void handleShare() {
    if (!isSharePopupShown.value) {
      isSharePopupShown.value = true;

      Share.share(
        'https://youtube.com/playlist?list=$playlistId',
      ).whenComplete(() {
        Timer(const Duration(milliseconds: 500), () {
          isSharePopupShown.value = false;
        });
      });
    }
  }
}

class YouTubePlaylist extends StatelessWidget {
  final String playlistId;
  final String type;

  const YouTubePlaylist({
    super.key,
    required this.playlistId,
    this.type = 'playlist',
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      YouTubePlaylistController(
        playlistId: playlistId,
        type: type,
      ),
      tag: playlistId,
    );

    return GradientContainer(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Obx(
              () => !controller.fetched.value
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : BouncyPlaylistHeaderScrollView(
                      scrollController: controller.scrollController,
                      title: controller.playlistName.value,
                      subtitle: controller.playlistSubtitle.value,
                      secondarySubtitle:
                          controller.playlistSecondarySubtitle.value,
                      imageUrl: controller.playlistImage.value,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          tooltip: AppLocalizations.of(context)!.share,
                          onPressed: () {
                            controller.handleShare();
                          },
                        ),
                        PlaylistPopupMenu(
                          data: controller.searchedList,
                          title: controller.playlistName.value,
                        ),
                      ],
                      onPlayTap: () async {
                        await controller.handlePlayTap();
                      },
                      onShuffleTap: () async {
                        await controller.handleShuffleTap();
                      },
                      sliverList: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            if (controller.searchedList.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20.0,
                                  top: 5.0,
                                  bottom: 5.0,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.songs,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ...controller.searchedList.map(
                              (Map entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 5.0,
                                  ),
                                  child: ListTile(
                                    leading: type == 'album'
                                        ? null
                                        : imageCard(
                                            imageUrl: entry['image'].toString(),
                                          ),
                                    title: Text(
                                      entry['title'].toString(),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onLongPress: () {
                                      copyToClipboard(
                                        context: context,
                                        text: entry['title'].toString(),
                                      );
                                    },
                                    subtitle: entry['subtitle'] == ''
                                        ? null
                                        : Text(
                                            entry['subtitle'].toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    onTap: () async {
                                      await controller.handleSongTap(entry);
                                    },
                                    trailing:
                                        YtSongTileTrailingMenu(data: entry),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Obx(
              () => !controller.done.value
                  ? Center(
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).width / 2,
                        width: MediaQuery.sizeOf(context).width / 2,
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GradientContainer(
                            child: Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.useHome,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.secondary,
                                    ),
                                    strokeWidth: 5,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .fetchingStream,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
