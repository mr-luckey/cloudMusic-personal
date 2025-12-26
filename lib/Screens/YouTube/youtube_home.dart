// import 'package:blackhole/CustomWidgets/drawer.dart';
import 'package:blackhole/CustomWidgets/on_hover.dart';
// import 'package:blackhole/G-Ads.dart/banner-ads.dart';
// import 'package:blackhole/G-Ads.dart/intersatail_ads.dart';
import 'package:blackhole/Screens/Search/search.dart';
// import 'package:blackhole/Screens/YouTube/youtube_playlist.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
// import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:gif/gif.dart';
import 'package:hive/hive.dart';

class YouTubeController extends GetxController
    with GetTickerProviderStateMixin {
  final status = false.obs;
  final searchedList =
      (Hive.box('cache').get('ytHome', defaultValue: []) as List).obs;
  final headList =
      (Hive.box('cache').get('ytHomeHead', defaultValue: []) as List).obs;
  final TextEditingController controller = TextEditingController();
  late final GifController gifController;

  @override
  void onInit() {
    super.onInit();
    if (!status.value) {
      YouTubeServices.instance.getMusicHome().then((value) {
        status.value = true;
        if (value.isNotEmpty) {
          searchedList.value = value['body'] ?? [];
          headList.value = value['head'] ?? [];

          Hive.box('cache').put('ytHome', value['body']);
          Hive.box('cache').put('ytHomeHead', value['head']);
        } else {
          status.value = false;
        }
      });
    }
    gifController = GifController(vsync: this);
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}

class YouTube extends StatelessWidget {
  const YouTube({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(YouTubeController());
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool rotated = MediaQuery.sizeOf(context).height < screenWidth;
    double boxSize = !rotated
        ? MediaQuery.sizeOf(context).width / 2
        : MediaQuery.sizeOf(context).height / 2.5;
    if (boxSize > 250) boxSize = 250;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Obx(
              () => controller.searchedList.isEmpty
                  ? Center(
                      // child: CircularProgressIndicator(),
                      //TODO:add gif here
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Gif(
                          image: AssetImage('assets/search1.gif'),
                          autostart: Autostart.loop,
                          controller: controller.gifController,
                          color: Theme.of(context).colorScheme.secondary,

                          width: 100,
                          height: 100,
                          // controller: AnimationController(TikerProvider()).repeat(),
                        ),
                        Text(
                          'Search Music on Youtube',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(10, 70, 10, 0),
                      child: Column(
                        children: [
                          if (controller.headList.isNotEmpty)
                            CarouselSlider.builder(
                              itemCount: controller.headList.length,
                              options: CarouselOptions(
                                height: boxSize + 20,
                                viewportFraction: rotated ? 0.36 : 1.0,
                                autoPlay: true,
                                enlargeCenterPage: true,
                              ),
                              itemBuilder: (
                                BuildContext context,
                                int index,
                                int pageViewIndex,
                              ) =>
                                  GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (_, __, ___) => SearchPage(
                                        query: controller.headList[index]
                                                ['title']
                                            .toString(),
                                        searchType: Hive.box('settings').get(
                                          'searchYtMusic',
                                          defaultValue: true,
                                        ) as bool
                                            ? 'ytm'
                                            : 'yt',
                                        fromDirectSearch: true,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: CachedNetworkImage(
                                    fit: BoxFit.cover,
                                    errorWidget: (context, _, __) =>
                                        const Image(
                                      fit: BoxFit.cover,
                                      image: AssetImage(
                                        'assets/ytCover.png',
                                      ),
                                    ),
                                    imageUrl: controller.headList[index]
                                            ['image']
                                        .toString(),
                                    placeholder: (context, url) => const Image(
                                      fit: BoxFit.cover,
                                      image: AssetImage('assets/ytCover.png'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          //TODO: banner ads
                          ListView.builder(
                            itemCount: controller.searchedList.length,
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(bottom: 10),
                            itemBuilder: (context, index) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 10, 0, 5),
                                          child: Text(
                                            '${controller.searchedList[index]["title"]}',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // BannerAdWidget(index: 4),
                                  // TODO: banner ads
                                  Container(
                                    height: 10,
                                    width: double.infinity,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(
                                    height: boxSize + 10,
                                    width: double.infinity,
                                    child: ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      itemCount: (controller.searchedList[index]
                                              ['playlists'] as List)
                                          .length,
                                      itemBuilder: (context, idx) {
                                        final item =
                                            controller.searchedList[index]
                                                ['playlists'][idx];
                                        item['subtitle'] = item['type'] !=
                                                'video'
                                            ? '${item["count"]} Tracks | ${item["description"]}'
                                            : '${item["count"]} | ${item["description"]}';
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                opaque: false,
                                                pageBuilder: (_, __, ___) =>
                                                    SearchPage(
                                                  query:
                                                      item['title'].toString(),
                                                  searchType:
                                                      Hive.box('settings').get(
                                                    'searchYtMusic',
                                                    defaultValue: true,
                                                  ) as bool
                                                          ? 'ytm'
                                                          : 'yt',
                                                  fromDirectSearch: true,
                                                ),
                                              ),
                                            );
                                          },
                                          child: SizedBox(
                                            width: item['type'] != 'playlist'
                                                ? (boxSize - 30) * (16 / 9)
                                                : boxSize - 30,
                                            child: HoverBox(
                                              child: Column(
                                                children: [
                                                  //TODO: check
                                                  // Container(
                                                  //   height: 10,
                                                  //   width: double.infinity,
                                                  //   color: Colors.blue,
                                                  // ),
                                                  Expanded(
                                                    child: Stack(
                                                      children: [
                                                        Positioned.fill(
                                                          child: Card(
                                                            elevation: 5,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                10.0,
                                                              ),
                                                            ),
                                                            clipBehavior:
                                                                Clip.antiAlias,
                                                            child:
                                                                CachedNetworkImage(
                                                              fit: BoxFit.cover,
                                                              errorWidget:
                                                                  (context, _,
                                                                          __) =>
                                                                      Image(
                                                                fit: BoxFit
                                                                    .cover,
                                                                image: item['type'] !=
                                                                        'playlist'
                                                                    ? const AssetImage(
                                                                        'assets/ytCover.png',
                                                                      )
                                                                    : const AssetImage(
                                                                        'assets/cover.jpg',
                                                                      ),
                                                              ),
                                                              imageUrl: item[
                                                                      'image']
                                                                  .toString(),
                                                              placeholder:
                                                                  (context,
                                                                          url) =>
                                                                      Image(
                                                                fit: BoxFit
                                                                    .cover,
                                                                image: item['type'] !=
                                                                        'playlist'
                                                                    ? const AssetImage(
                                                                        'assets/ytCover.png',
                                                                      )
                                                                    : const AssetImage(
                                                                        'assets/cover.jpg',
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        if (item['type'] ==
                                                            'chart')
                                                          Align(
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child: Container(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.75),
                                                              width: (boxSize -
                                                                      30) *
                                                                  (16 / 9) /
                                                                  2.5,
                                                              margin:
                                                                  const EdgeInsets
                                                                      .all(
                                                                4.0,
                                                              ),
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    item['count']
                                                                        .toString(),
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  const IconButton(
                                                                    onPressed:
                                                                        null,
                                                                    color: Colors
                                                                        .white,
                                                                    disabledColor:
                                                                        Colors
                                                                            .white,
                                                                    icon: Icon(
                                                                      Icons
                                                                          .playlist_play_rounded,
                                                                      size: 40,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10.0,
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          '${item["title"]}',
                                                          textAlign:
                                                              TextAlign.center,
                                                          softWrap: false,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        Text(
                                                          item['subtitle']
                                                              .toString(),
                                                          textAlign:
                                                              TextAlign.center,
                                                          softWrap: false,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall!
                                                                .color,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 5.0,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              builder: ({
                                                required BuildContext context,
                                                required bool isHover,
                                                Widget? child,
                                              }) {
                                                return Card(
                                                  color: isHover
                                                      ? null
                                                      : Colors.transparent,
                                                  elevation: 0,
                                                  margin: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10.0,
                                                    ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: child,
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ), // YouTube search bar
            Container(
              width: MediaQuery.sizeOf(context).width,
              height: 55.0,
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              margin:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).colorScheme.secondary),
                borderRadius: BorderRadius.circular(
                  10.0,
                ),
                color: Theme.of(context).cardColor,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5.0,
                    offset: Offset(1.5, 1.5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: controller.controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  hintText: AppLocalizations.of(
                    context,
                  )!
                      .searchYt,
                  hintStyle: TextStyle(
                    fontSize: 18.0,
                    color: Theme.of(context).textTheme.bodySmall!.color,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isEmpty) return;

                  FocusManager.instance.primaryFocus?.unfocus();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchPage(
                        query: trimmed,
                        fromHome: false,
                        fromDirectSearch: true,
                        searchType: Hive.box('settings').get('searchYtMusic',
                                defaultValue: true) as bool
                            ? 'ytm'
                            : 'yt',
                        autofocus: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
