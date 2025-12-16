// Coded by Naseer Ahmed

import 'dart:async';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/bouncy_playlist_header_scroll_view.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/playlist_popupmenu.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
// import 'package:blackhole/G-Ads.dart/intersatail_ads.dart';
// import 'package:blackhole/G-Ads.dart/intersatail_ads.dart';
import 'package:blackhole/Helpers/extensions.dart';
import 'package:blackhole/Models/url_image_generator.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

class SongsListPageController extends GetxController {
  final Map listItem;

  SongsListPageController({required this.listItem});

  final page = 1.obs;
  final loading = false.obs;
  final songList = <dynamic>[].obs;
  final fetched = false.obs;
  final isSharePopupShown = false.obs;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _fetchSongs();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent &&
          listItem['type'].toString() == 'songs' &&
          !loading.value) {
        page.value += 1;
        _fetchSongs();
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _fetchSongs() {
    loading.value = true;
    try {
      switch (listItem['type'].toString()) {
        case 'songs':
          SaavnAPI()
              .fetchSongSearchResults(
            searchQuery: listItem['id'].toString(),
            page: page.value,
          )
              .then((value) {
            songList.addAll(value['songs'] as List);
            fetched.value = true;
            loading.value = false;
            if (value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                Get.context!,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        case 'album':
          SaavnAPI().fetchAlbumSongs(listItem['id'].toString()).then((value) {
            songList.value = value['songs'] as List;
            fetched.value = true;
            loading.value = false;
            if (value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                Get.context!,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        case 'playlist':
          SaavnAPI()
              .fetchPlaylistSongs(listItem['id'].toString())
              .then((value) {
            songList.value = value['songs'] as List;
            fetched.value = true;
            loading.value = false;
            if (value['error'] != null && value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                Get.context!,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        case 'mix':
          SaavnAPI()
              .getSongFromToken(
            listItem['perma_url'].toString().split('/').last,
            'mix',
          )
              .then((value) {
            songList.value = value['songs'] as List;
            fetched.value = true;
            loading.value = false;

            if (value['error'] != null && value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                Get.context!,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        case 'show':
          SaavnAPI()
              .getSongFromToken(
            listItem['perma_url'].toString().split('/').last,
            'show',
          )
              .then((value) {
            songList.value = value['songs'] as List;
            fetched.value = true;
            loading.value = false;

            if (value['error'] != null && value['error'].toString() != '') {
              ShowSnackBar().showSnackBar(
                Get.context!,
                'Error: ${value["error"]}',
                duration: const Duration(seconds: 3),
              );
            }
          });
        default:
          fetched.value = true;
          loading.value = false;
          ShowSnackBar().showSnackBar(
            Get.context!,
            'Error: Unsupported Type ${listItem['type']}',
            duration: const Duration(seconds: 3),
          );
          break;
      }
    } catch (e) {
      fetched.value = true;
      loading.value = false;
      Logger.root.severe(
        'Error in song_list with type ${listItem["type"]}: $e',
      );
    }
  }
}

class SongsListPage extends StatelessWidget {
  final Map listItem;

  const SongsListPage({
    super.key,
    required this.listItem,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SongsListPageController(listItem: listItem),
      tag: listItem['id'].toString(),
    );

    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Obx(
          () => !controller.fetched.value
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : BouncyPlaylistHeaderScrollView(
                  scrollController: controller.scrollController,
                  actions: [
                    if (controller.songList.isNotEmpty)
                      MultiDownloadButton(
                        //TODO: google Reward ads impementation here.
                        data: controller.songList,
                        playlistName: listItem['title']?.toString() ?? 'Songs',
                      ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded),
                      tooltip: AppLocalizations.of(context)!.share,
                      onPressed: () {
                        // AdManager.showInterstitialAd();
                        if (!controller.isSharePopupShown.value) {
                          controller.isSharePopupShown.value = true;

                          Share.share(
                            listItem['perma_url'].toString(),
                          ).whenComplete(() {
                            Timer(const Duration(milliseconds: 500), () {
                              controller.isSharePopupShown.value = false;
                            });
                          });
                        }
                      },
                    ),
                    PlaylistPopupMenu(
                      data: controller.songList,
                      title: listItem['title']?.toString() ?? 'Songs',
                    ),
                  ],
                  title: listItem['title']?.toString().unescape() ?? 'Songs',
                  subtitle: '${controller.songList.length} Songs',
                  secondarySubtitle: listItem['subTitle']?.toString() ??
                      listItem['subtitle']?.toString(),
                  onPlayTap: () {
                    PlayerInvoke.init(
                      songsList: controller.songList,
                      index: 0,
                      isOffline: false,
                    );
                  },
                  onShuffleTap: () => PlayerInvoke.init(
                    songsList: controller.songList,
                    index: 0,
                    isOffline: false,
                    shuffle: true,
                  ),
                  placeholderImage: 'assets/album.png',
                  imageUrl: UrlImageGetter([listItem['image']?.toString()])
                      .mediumQuality,
                  sliverList: SliverList(
                    delegate: SliverChildListDelegate([
                      if (controller.songList.isNotEmpty)
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
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ...controller.songList.map((entry) {
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 15.0),
                          title: Text(
                            '${entry["title"]}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onLongPress: () {
                            copyToClipboard(
                              context: context,
                              text: '${entry["title"]}',
                            );
                          },
                          subtitle: Text(
                            '${entry["subtitle"]}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading:
                              imageCard(imageUrl: entry['image'].toString()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DownloadButton(
                                // InterstitialAdWidget(),
                                //TODO: google intersatial ads implementation pending
                                data: entry as Map,
                                icon: 'download',
                              ),
                              LikeButton(
                                mediaItem: null,
                                data: entry,
                              ),
                              SongTileTrailingMenu(data: entry),
                            ],
                          ),
                          onTap: () {
                            // AdManager.showInterstitialAd();
                            PlayerInvoke.init(
                              songsList: controller.songList,
                              index: controller.songList.indexWhere(
                                (element) => element == entry,
                              ),
                              isOffline: false,
                            );
                          },
                        );
                      }),
                    ]),
                  ),
                ),
        ),
      ),
    );
  }
}
