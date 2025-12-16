// Coded by Naseer Ahmed

import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
// import 'package:blackhole/G-Ads.dart/intersatail_ads.dart';
import 'package:blackhole/Helpers/playlist.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:logging/logging.dart';

class LikeButtonController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final MediaItem? mediaItem;
  final Map? data;

  LikeButtonController({
    this.mediaItem,
    this.data,
  });

  final liked = false.obs;
  late AnimationController animationController;
  late Animation<double> scale;
  late Animation<double> curve;

  @override
  void onInit() {
    super.onInit();
    // AdManager.showInterstitialAd();

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
    try {
      if (mediaItem != null) {
        liked.value = checkPlaylist('Favorite Songs', mediaItem!.id);
      } else {
        liked.value = checkPlaylist('Favorite Songs', data!['id'].toString());
      }
    } catch (e) {
      Logger.root.severe('Error in likeButton: $e');
    }
  }

  void toggleLike() {
    liked.value
        ? removeLiked(
            mediaItem == null ? data!['id'].toString() : mediaItem!.id,
          )
        : mediaItem == null
            ? addMapToPlaylist('Favorite Songs', data!)
            : addItemToPlaylist('Favorite Songs', mediaItem!);

    if (!liked.value) {
      animationController.forward();
    } else {
      animationController.reverse();
    }
    liked.value = !liked.value;
  }

  void undoLike() {
    liked.value
        ? removeLiked(
            mediaItem == null ? data!['id'].toString() : mediaItem!.id,
          )
        : mediaItem == null
            ? addMapToPlaylist('Favorite Songs', data!)
            : addItemToPlaylist(
                'Favorite Songs',
                mediaItem!,
              );

    liked.value = !liked.value;
  }
}

class LikeButton extends StatelessWidget {
  final MediaItem? mediaItem;
  final double? size;
  final Map? data;
  final bool showSnack;

  const LikeButton({
    super.key,
    required this.mediaItem,
    this.size,
    this.data,
    this.showSnack = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      LikeButtonController(
        mediaItem: mediaItem,
        data: data,
      ),
      tag: mediaItem?.id ?? data?['id'].toString(),
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
                action: SnackBarAction(
                  textColor: Theme.of(context).colorScheme.secondary,
                  label: AppLocalizations.of(context)!.undo,
                  onPressed: () {
                    // AdManager.showInterstitialAd();

                    // InterstitialAdWidget();
                    controller.undoLike();
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
