// Coded by Naseer Ahmed

import 'dart:math';

import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:get/get.dart';

class SeekBarController extends GetxController {
  final dragValue = Rx<double?>(null);
  final dragging = false.obs;

  void updateDragValue(double? value) {
    dragValue.value = value;
  }

  void setDragging(bool value) {
    dragging.value = value;
  }
}

class SeekBar extends StatelessWidget {
  final AudioPlayerHandler audioHandler;
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final bool offline;
  // final double width;
  // final double height;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    required this.offline,
    required this.audioHandler,
    // required this.width,
    // required this.height,
    this.bufferedPosition = Duration.zero,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SeekBarController(), tag: 'seekbar');
    final sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 4.0,
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // if (offline)
                //   Text(
                //     'Offline',
                //     style: TextStyle(
                //       fontWeight: FontWeight.w500,
                //       color: Theme.of(context).disabledColor,
                //       fontSize: 14.0,
                //     ),
                //   )
                // else
                const SizedBox(),
                StreamBuilder<double>(
                  stream: audioHandler.speed,
                  builder: (context, snapshot) {
                    final String speedValue =
                        '${snapshot.data?.toStringAsFixed(1) ?? 1.0}x';
                    return GestureDetector(
                      child: Text(
                        speedValue,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: speedValue == '1.0x'
                              ? Theme.of(context).disabledColor
                              : null,
                        ),
                      ),
                      onTap: () {
                        showSliderDialog(
                          context: context,
                          title: AppLocalizations.of(context)!.adjustSpeed,
                          divisions: 25,
                          min: 0.5,
                          max: 3.0,
                          audioHandler: audioHandler,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 2.0,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  child: SliderTheme(
                    data: sliderThemeData.copyWith(
                      thumbShape: HiddenThumbComponentShape(),
                      overlayShape: SliderComponentShape.noThumb,
                      activeTrackColor:
                          Theme.of(context).iconTheme.color!.withOpacity(0.5),
                      inactiveTrackColor:
                          Theme.of(context).iconTheme.color!.withOpacity(0.3),
                      // trackShape: RoundedRectSliderTrackShape(),
                      trackShape: const RectangularSliderTrackShape(),
                    ),
                    child: ExcludeSemantics(
                      child: Slider(
                        max: duration.inMilliseconds.toDouble(),
                        value: min(
                          bufferedPosition.inMilliseconds.toDouble(),
                          duration.inMilliseconds.toDouble(),
                        ),
                        onChanged: (value) {},
                      ),
                    ),
                  ),
                ),
                Obx(
                  () {
                    final value = min(
                      controller.dragValue.value ??
                          position.inMilliseconds.toDouble(),
                      duration.inMilliseconds.toDouble(),
                    );
                    if (controller.dragValue.value != null &&
                        !controller.dragging.value) {
                      controller.updateDragValue(null);
                    }
                    return SliderTheme(
                      data: sliderThemeData.copyWith(
                        inactiveTrackColor: Colors.transparent,
                        activeTrackColor: Theme.of(context).iconTheme.color,
                        thumbColor: Theme.of(context).iconTheme.color,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                        ),
                        overlayShape: SliderComponentShape.noThumb,
                      ),
                      child: Slider(
                        max: duration.inMilliseconds.toDouble(),
                        value: value,
                        onChanged: (value) {
                          if (!controller.dragging.value) {
                            controller.setDragging(true);
                          }
                          controller.updateDragValue(value);
                          onChanged
                              ?.call(Duration(milliseconds: value.round()));
                        },
                        onChangeEnd: (value) {
                          onChangeEnd
                              ?.call(Duration(milliseconds: value.round()));
                          controller.setDragging(false);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                          .firstMatch('$position')
                          ?.group(1) ??
                      '$position',
                ),
                Text(
                  RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                          .firstMatch('$duration')
                          ?.group(1) ??
                      '$duration',
                  // style: Theme.of(context).textTheme.caption!.copyWith(
                  //       color: Theme.of(context).iconTheme.color,
                  //     ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

void showSliderDialog({
  required BuildContext context,
  required String title,
  required int divisions,
  required double min,
  required double max,
  required AudioPlayerHandler audioHandler,
  String valueSuffix = '',
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: StreamBuilder<double>(
        stream: audioHandler.speed,
        builder: (context, snapshot) {
          double value = snapshot.data ?? audioHandler.speed.value;
          if (value > max) {
            value = max;
          }
          if (value < min) {
            value = min;
          }
          return SizedBox(
            height: 100.0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.minus),
                      onPressed: audioHandler.speed.value > min
                          ? () {
                              audioHandler
                                  .setSpeed(audioHandler.speed.value - 0.1);
                            }
                          : null,
                    ),
                    Text(
                      '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                      style: const TextStyle(
                        fontFamily: 'Fixed',
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.plus),
                      onPressed: audioHandler.speed.value < max
                          ? () {
                              audioHandler
                                  .setSpeed(audioHandler.speed.value + 0.1);
                            }
                          : null,
                    ),
                  ],
                ),
                Slider(
                  inactiveColor:
                      Theme.of(context).iconTheme.color!.withOpacity(0.4),
                  activeColor: Theme.of(context).iconTheme.color,
                  divisions: divisions,
                  min: min,
                  max: max,
                  value: value,
                  onChanged: audioHandler.setSpeed,
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
