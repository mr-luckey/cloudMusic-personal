// Coded by Naseer Ahmed

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/artist_like_button.dart';
import 'package:blackhole/CustomWidgets/bouncy_sliver_scroll_view.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/horizontal_albumlist.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/playlist_popupmenu.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Models/url_image_generator.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class ArtistSearchController extends GetxController {
  final Map initialData;

  ArtistSearchController({required this.initialData});

  final status = false.obs;
  final category = ''.obs;
  final sortOrder = ''.obs;
  final data = <String, List>{}.obs;
  final fetched = false.obs;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchArtistSongs();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void fetchArtistSongs() {
    if (!status.value) {
      status.value = true;
      SaavnAPI()
          .fetchArtistSongs(
        artistToken: initialData['artistToken'].toString(),
        category: category.value,
        sortOrder: sortOrder.value,
      )
          .then((value) {
        data.value = value;
        fetched.value = true;
      });
    }
  }

  void updateCategory(String newCategory, String newSortOrder) {
    category.value = newCategory;
    sortOrder.value = newSortOrder;
    status.value = false;
    fetchArtistSongs();
  }
}

class ArtistSearchPage extends StatelessWidget {
  final Map data;

  const ArtistSearchPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ArtistSearchController(initialData: data),
      tag: data['artistToken'].toString(),
    );

    return GradientContainer(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Obx(
          () => !controller.fetched.value
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : controller.data.isEmpty
                  ? emptyScreen(
                      context,
                      0,
                      ':( ',
                      100,
                      AppLocalizations.of(context)!.sorry,
                      60,
                      AppLocalizations.of(context)!.resultsNotFound,
                      20,
                    )
                  : BouncyImageSliverScrollView(
                      scrollController: controller.scrollController,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          tooltip: AppLocalizations.of(context)!.share,
                          onPressed: () {
                            Share.share(
                              data['perma_url'].toString(),
                            );
                          },
                        ),
                        ArtistLikeButton(
                          data: data,
                          size: 27.0,
                        ),
                        if (controller.data['Top Songs'] != null)
                          PlaylistPopupMenu(
                            data: controller.data['Top Songs']!,
                            title: data['title']?.toString() ?? 'Songs',
                          ),
                      ],
                      title: data['title']?.toString() ??
                          AppLocalizations.of(context)!.songs,
                      placeholderImage: 'assets/artist.png',
                      imageUrl: UrlImageGetter([data['image'].toString()])
                          .mediumQuality,
                      sliverList: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        PlayerInvoke.init(
                                          songsList:
                                              controller.data['Top Songs']!,
                                          index: 0,
                                          isOffline: false,
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          top: 10,
                                          bottom: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(100.0),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 5.0,
                                              offset: Offset(0.0, 3.0),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.play_arrow_rounded,
                                                color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary ==
                                                        Colors.white
                                                    ? Colors.black
                                                    : Colors.white,
                                                size: 26.0,
                                              ),
                                              const SizedBox(width: 5.0),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .play,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18.0,
                                                  color: Theme.of(context)
                                                              .colorScheme
                                                              .secondary ==
                                                          Colors.white
                                                      ? Colors.black
                                                      : Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        ShowSnackBar().showSnackBar(
                                          context,
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .connectingRadio,
                                          duration: const Duration(
                                            seconds: 2,
                                          ),
                                        );
                                        SaavnAPI().createRadio(
                                          names: [
                                            data['title']?.toString() ?? '',
                                          ],
                                          language:
                                              data['language']?.toString() ??
                                                  'hindi',
                                          stationType: 'artist',
                                        ).then((value) {
                                          if (value != null) {
                                            SaavnAPI()
                                                .getRadioSongs(
                                              stationId: value,
                                            )
                                                .then((value) {
                                              PlayerInvoke.init(
                                                songsList: value,
                                                index: 0,
                                                isOffline: false,
                                              );
                                            });
                                          }
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(100.0),
                                          border: Border.all(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.podcasts_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                                size: 26.0,
                                              ),
                                              const SizedBox(width: 5.0),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .radio,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18.0,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 10,
                                      bottom: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(100.0),
                                      border: Border.all(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: GestureDetector(
                                        child: Icon(
                                          Icons.shuffle_rounded,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                          size: 24.0,
                                        ),
                                        onTap: () {
                                          PlayerInvoke.init(
                                            songsList:
                                                controller.data['Top Songs']!,
                                            index: 0,
                                            isOffline: false,
                                            shuffle: true,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...controller.data.entries.map(
                              (entry) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 25,
                                        top: 15,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          if (entry.key ==
                                              'Top Songs') ...<Widget>[
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            Obx(
                                              () => Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  ChoiceChip(
                                                    label: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .popularity,
                                                    ),
                                                    selectedColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withOpacity(0.2),
                                                    labelStyle: TextStyle(
                                                      color: controller.category
                                                                  .value ==
                                                              ''
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge!
                                                              .color,
                                                      fontWeight: controller
                                                                  .category
                                                                  .value ==
                                                              ''
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                    selected: controller
                                                            .category.value ==
                                                        '',
                                                    onSelected:
                                                        (bool selected) {
                                                      if (selected) {
                                                        controller
                                                            .updateCategory(
                                                                '', '');
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  ChoiceChip(
                                                    label: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .date,
                                                    ),
                                                    selectedColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withOpacity(0.2),
                                                    labelStyle: TextStyle(
                                                      color: controller.category
                                                                  .value ==
                                                              'latest'
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge!
                                                              .color,
                                                      fontWeight: controller
                                                                  .category
                                                                  .value ==
                                                              'latest'
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                    selected: controller
                                                            .category.value ==
                                                        'latest',
                                                    onSelected:
                                                        (bool selected) {
                                                      if (selected) {
                                                        controller
                                                            .updateCategory(
                                                                'latest',
                                                                'desc');
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  ChoiceChip(
                                                    label: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .alphabetical,
                                                    ),
                                                    selectedColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withOpacity(0.2),
                                                    labelStyle: TextStyle(
                                                      color: controller.category
                                                                  .value ==
                                                              'alphabetical'
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge!
                                                              .color,
                                                      fontWeight: controller
                                                                  .category
                                                                  .value ==
                                                              'alphabetical'
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                    selected: controller
                                                            .category.value ==
                                                        'alphabetical',
                                                    onSelected:
                                                        (bool selected) {
                                                      if (selected) {
                                                        controller
                                                            .updateCategory(
                                                                'alphabetical',
                                                                'asc');
                                                      }
                                                    },
                                                  ),
                                                  const Spacer(),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (entry.key != 'Top Songs')
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          5,
                                          10,
                                          5,
                                          0,
                                        ),
                                        child: HorizontalAlbumsList(
                                          songsList: entry.value,
                                          onTap: (int idx) {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                opaque: false,
                                                pageBuilder: (
                                                  _,
                                                  __,
                                                  ___,
                                                ) =>
                                                    entry.key ==
                                                            'Related Artists'
                                                        ? ArtistSearchPage(
                                                            data:
                                                                entry.value[idx]
                                                                    as Map,
                                                          )
                                                        : SongsListPage(
                                                            listItem:
                                                                entry.value[idx]
                                                                    as Map,
                                                          ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        itemCount: entry.value.length,
                                        padding: const EdgeInsets.fromLTRB(
                                          5,
                                          5,
                                          5,
                                          0,
                                        ),
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            contentPadding:
                                                const EdgeInsets.only(
                                              left: 15.0,
                                            ),
                                            title: Text(
                                              '${entry.value[index]["title"]}',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            onLongPress: () {
                                              copyToClipboard(
                                                context: context,
                                                text:
                                                    '${entry.value[index]["title"]}',
                                              );
                                            },
                                            subtitle: Text(
                                              '${entry.value[index]["subtitle"]}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            leading: imageCard(
                                              placeholderImage: AssetImage(
                                                (entry.key == 'Top Songs' ||
                                                        entry.key ==
                                                            'Latest Release')
                                                    ? 'assets/cover.jpg'
                                                    : 'assets/album.png',
                                              ),
                                              imageUrl: entry.value[index]
                                                      ['image']
                                                  .toString(),
                                            ),
                                            trailing: (entry.key ==
                                                        'Top Songs' ||
                                                    entry.key ==
                                                        'Latest Release' ||
                                                    entry.key == 'Singles')
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      DownloadButton(
                                                        data: entry.value[index]
                                                            as Map,
                                                        icon: 'download',
                                                      ),
                                                      LikeButton(
                                                        data: entry.value[index]
                                                            as Map,
                                                        mediaItem: null,
                                                      ),
                                                      SongTileTrailingMenu(
                                                        data: entry.value[index]
                                                            as Map,
                                                      ),
                                                    ],
                                                  )
                                                : null,
                                            onTap: () {
                                              if (entry.key == 'Top Songs' ||
                                                  entry.key ==
                                                      'Latest Release' ||
                                                  entry.key == 'Singles') {
                                                PlayerInvoke.init(
                                                  songsList: entry.value,
                                                  index: index,
                                                  isOffline: false,
                                                );
                                              }
                                              if (entry.key != 'Top Songs' &&
                                                  entry.key !=
                                                      'Latest Release' &&
                                                  entry.key != 'Singles') {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    pageBuilder: (
                                                      _,
                                                      __,
                                                      ___,
                                                    ) =>
                                                        SongsListPage(
                                                      listItem: entry
                                                          .value[index] as Map,
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
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
