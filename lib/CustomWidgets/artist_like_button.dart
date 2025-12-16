// Coded by Naseer Ahmed

import 'package:blackhole/CustomWidgets/snackbar.dart';
// import 'package:blackhole/G-Ads.dart/intersatail_ads.dart';
// import 'package:blackhole/G-Ads.dart/intersatail_ads.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

class ArtistLikeButtonController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final Map data;
  final bool showSnack;

  ArtistLikeButtonController({
    required this.data,
    this.showSnack = false,
  });

  final liked = false.obs;
  final likedArtists = <dynamic, dynamic>{}.obs;
  late AnimationController animationController;
  late Animation<double> scale;
  late Animation<double> curve;

  @override
  void onInit() {
    super.onInit();
    // AdManager.showInterstitialAd();

    likedArtists.value =
        Hive.box('settings').get('likedArtists', defaultValue: {}) as Map;

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    curve =
        CurvedAnimation(parent: animationController, curve: Curves.slowMiddle);

    scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(curve);

    checkLiked();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  void checkLiked() {
    liked.value = likedArtists.containsKey(data['id'].toString());
  }

  void toggleLike() {
    if (!liked.value) {
      animationController.forward();
      likedArtists.addEntries(
        [MapEntry(data['id'].toString(), data)],
      );
    } else {
      animationController.reverse();
      likedArtists.remove(data['id'].toString());
    }
    Hive.box('settings').put('likedArtists', likedArtists);
    liked.value = !liked.value;
  }
}

class ArtistLikeButton extends StatelessWidget {
  final double? size;
  final Map data;
  final bool showSnack;

  const ArtistLikeButton({
    super.key,
    this.size,
    required this.data,
    this.showSnack = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ArtistLikeButtonController(
        data: data,
        showSnack: showSnack,
      ),
      tag: data['id'].toString(),
    );

    return Obx(
      () => ScaleTransition(
        scale: controller.scale,
        child: IconButton(
          icon: Icon(
            controller.liked.value
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: controller.liked.value
                ? Colors.redAccent
                : Theme.of(context).iconTheme.color,
          ),
          iconSize: size ?? 24.0,
          tooltip: controller.liked.value
              ? AppLocalizations.of(context)!.unlike
              : AppLocalizations.of(context)!.like,
          onPressed: () async {
            // AdManager.showInterstitialAd();
            controller.toggleLike();
            if (showSnack) {
              ShowSnackBar().showSnackBar(
                context,
                controller.liked.value
                    ? AppLocalizations.of(context)!.addedToFav
                    : AppLocalizations.of(context)!.removedFromFav,
              );
            }
          },
        ),
      ),
    );
  }
}
