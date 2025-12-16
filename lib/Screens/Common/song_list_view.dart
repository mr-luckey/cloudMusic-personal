// Coded by Naseer Ahmed

import 'dart:async';

import 'package:blackhole/CustomWidgets/bouncy_playlist_header_scroll_view.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/Models/song_item.dart';
import 'package:blackhole/Models/url_image_generator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

class SongsListViewPageController extends GetxController {
  final Future<List> Function()? loadFunction;
  final Future<List> Function()? loadMoreFunction;

  SongsListViewPageController({
    this.loadFunction,
    this.loadMoreFunction,
  });

  final page = 1.obs;
  final loading = false.obs;
  final itemsList = <SongItem>[].obs;
  final fetched = false.obs;
  final isSharePopupShown = false.obs;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _loadInitial();
    if (loadMoreFunction != null) {
      scrollController.addListener(() {
        if (scrollController.position.pixels >=
                scrollController.position.maxScrollExtent &&
            !loading.value) {
          page.value += 1;
          _loadMore();
        }
      });
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _loadInitial() async {
    loading.value = true;
    try {
      if (loadFunction == null) {
        fetched.value = true;
        loading.value = false;
      } else {
        final value = await loadFunction!.call();
        itemsList.value = value as List<SongItem>;
        fetched.value = true;
        loading.value = false;
      }
    } catch (e) {
      fetched.value = true;
      loading.value = false;
      Logger.root.severe(
        'Error in song_list_view loadInitial: $e',
      );
    }
  }

  Future<void> _loadMore() async {
    try {
      if (loadMoreFunction != null) {
        loading.value = true;
        final value = await loadMoreFunction!.call();
        itemsList.value = value as List<SongItem>;
        fetched.value = true;
        loading.value = false;
      }
    } catch (e) {
      fetched.value = true;
      loading.value = false;
      Logger.root.severe(
        'Error in song_list_view loadMore: $e',
      );
    }
  }
}

class SongsListViewPage extends StatelessWidget {
  final String? imageUrl;
  final String? placeholderImageUrl;
  final String title;
  final String? subtitle;
  final String? secondarySubtitle;
  final Function(int, List)? onTap;
  final Function? onPlay;
  final Function? onShuffle;
  final String? listItemsTitle;
  final EdgeInsetsGeometry? listItemsPadding;
  final List<SongItem> listItems;
  final List<Widget>? actions;
  final List<Widget>? dropDownActions;
  final Future<List> Function()? loadFunction;
  final Future<List> Function()? loadMoreFunction;

  const SongsListViewPage({
    super.key,
    this.imageUrl,
    this.placeholderImageUrl,
    required this.title,
    this.subtitle,
    this.secondarySubtitle,
    this.onTap,
    this.onPlay,
    this.onShuffle,
    this.listItemsTitle,
    this.listItemsPadding,
    this.listItems = const [],
    this.actions,
    this.dropDownActions,
    this.loadFunction,
    this.loadMoreFunction,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SongsListViewPageController(
        loadFunction: loadFunction,
        loadMoreFunction: loadMoreFunction,
      ),
      tag: title,
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
                  actions: actions,
                  title: title,
                  subtitle: subtitle,
                  secondarySubtitle: secondarySubtitle,
                  onPlayTap: onPlay,
                  onShuffleTap: onShuffle,
                  placeholderImage: placeholderImageUrl ?? 'assets/cover.jpg',
                  imageUrl: UrlImageGetter([imageUrl]).mediumQuality,
                  sliverList: SliverList(
                    delegate: SliverChildListDelegate([
                      if (controller.itemsList.isNotEmpty &&
                          listItemsTitle != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20.0,
                            top: 5.0,
                            bottom: 5.0,
                          ),
                          child: Text(
                            listItemsTitle!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ...controller.itemsList.map((entry) {
                        return ListTile(
                          contentPadding: listItemsPadding ??
                              const EdgeInsets.symmetric(horizontal: 20.0),
                          title: Text(
                            entry.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onLongPress: () {
                            copyToClipboard(
                              context: context,
                              text: entry.title,
                            );
                          },
                          subtitle: entry.subtitle != null
                              ? Text(
                                  entry.subtitle!,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          leading: imageCard(
                            elevation: 8,
                            imageUrl: entry.image,
                          ),

                          // trailing: Row(
                          //   mainAxisSize: MainAxisSize.min,
                          //   children: [
                          //     DownloadButton(
                          //       data: entry as Map,
                          //       icon: 'download',
                          //     ),
                          //     LikeButton(
                          //       mediaItem: null,
                          //       data: entry.mapData,
                          //     ),
                          //     if (entry.mapData != null)
                          //       SongTileTrailingMenu(data: entry.mapData!),
                          //   ],
                          // ),
                          onTap: () {
                            final idx = controller.itemsList.indexWhere(
                              (element) => element == entry,
                            );
                            onTap?.call(idx, controller.itemsList);
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
