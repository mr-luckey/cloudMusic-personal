// Coded by Naseer Ahmed

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/bouncy_sliver_scroll_view.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Search/artists.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';

class AlbumSearchController extends GetxController {
  final String query;
  final String type;

  AlbumSearchController({
    required this.query,
    required this.type,
  });

  final page = 1.obs;
  final loading = false.obs;
  final searchedList = Rx<List<Map>?>(null);
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchData();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent &&
          !loading.value) {
        page.value += 1;
        fetchData();
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void fetchData() {
    loading.value = true;
    switch (type) {
      case 'Playlists':
        SaavnAPI()
            .fetchAlbums(
          searchQuery: query,
          type: 'playlist',
          page: page.value,
        )
            .then((value) {
          final temp = searchedList.value ?? [];
          temp.addAll(value);
          searchedList.value = temp;
          loading.value = false;
        });
      case 'Albums':
        SaavnAPI()
            .fetchAlbums(
          searchQuery: query,
          type: 'album',
          page: page.value,
        )
            .then((value) {
          final temp = searchedList.value ?? [];
          temp.addAll(value);
          searchedList.value = temp;
          loading.value = false;
        });
      case 'Artists':
        SaavnAPI()
            .fetchAlbums(
          searchQuery: query,
          type: 'artist',
          page: page.value,
        )
            .then((value) {
          final temp = searchedList.value ?? [];
          temp.addAll(value);
          searchedList.value = temp;
          loading.value = false;
        });
      default:
        break;
    }
  }
}

class AlbumSearchPage extends StatelessWidget {
  final String query;
  final String type;

  const AlbumSearchPage({
    super.key,
    required this.query,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AlbumSearchController(
        query: query,
        type: type,
      ),
      tag: '$query-$type',
    );

    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Obx(
          () => controller.searchedList.value == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : controller.searchedList.value!.isEmpty
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
                      title: type,
                      placeholderImage: type == 'Artists'
                          ? 'assets/artist.png'
                          : 'assets/album.png',
                      sliverList: SliverList(
                        delegate: SliverChildListDelegate(
                          controller.searchedList.value!.map(
                            (Map entry) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: ListTile(
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
                                  subtitle: entry['subtitle'] == ''
                                      ? null
                                      : Text(
                                          '${entry["subtitle"]}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  leading: imageCard(
                                    elevation: 8,
                                    borderRadius:
                                        type == 'Artists' ? 50.0 : 7.0,
                                    placeholderImage: AssetImage(
                                      type == 'Artists'
                                          ? 'assets/artist.png'
                                          : 'assets/album.png',
                                    ),
                                    imageUrl: entry['image'].toString(),
                                  ),
                                  trailing: type != 'Albums'
                                      ? null
                                      : AlbumDownloadButton(
                                          albumName: entry['title'].toString(),
                                          albumId: entry['id'].toString(),
                                        ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        opaque: false,
                                        pageBuilder: (_, __, ___) =>
                                            type == 'Artists'
                                                ? ArtistSearchPage(
                                                    data: entry,
                                                  )
                                                : SongsListPage(
                                                    listItem: entry,
                                                  ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
