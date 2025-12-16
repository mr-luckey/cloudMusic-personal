// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/bouncy_sliver_scroll_view.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:blackhole/Services/yt_music.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';

// import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:logging/logging.dart';

class YouTubeArtistController extends GetxController {
  final String artistId;

  YouTubeArtistController({required this.artistId});

  final status = false.obs;
  final data = <String, dynamic>{}.obs;
  final fetched = false.obs;
  final done = true.obs;
  final ScrollController scrollController = ScrollController();
  final artistName = ''.obs;
  final artistSubtitle = ''.obs;
  final artistImage = ''.obs;
  final searchedList = <Map>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (!status.value) {
      status.value = true;
      YtMusicService().getArtistDetails(artistId).then((value) {
        try {
          data.value = value;
          searchedList.value = data['songs'] as List<Map>;
          artistName.value = value['name'] as String? ?? '';
          artistSubtitle.value = value['subtitle'] as String? ?? '';
          artistImage.value = value['images']?.last as String? ?? '';
          fetched.value = true;
        } catch (e) {
          Logger.root.severe('Error in fetching artist details', e);
          fetched.value = true;
        }
      });
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> handleSongTap(Map entry) async {
    done.value = false;
    
    try {
      final Map response = await YtMusicService().getSongData(
        videoId: entry['id'].toString(),
        data: entry,
      );
      
      done.value = true;
      
      if (response.isEmpty || response['url'] == null || response['url'].toString().isEmpty) {
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
}

class YouTubeArtist extends StatelessWidget {
  final String artistId;

  const YouTubeArtist({
    super.key,
    required this.artistId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      YouTubeArtistController(artistId: artistId),
      tag: artistId,
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
                  : BouncyImageSliverScrollView(
                      scrollController: controller.scrollController,
                      title: controller.artistName.value,
                      imageUrl: controller.artistImage.value,
                      fromYt: true,
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
                                    leading: imageCard(
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
