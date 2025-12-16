// Coded by Naseer Ahmed

import 'dart:math';

import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/localization/app_localizations.dart';

import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

class EqualizerController extends GetxController {
  final enabled = false.obs;
  final AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();

  @override
  void onInit() {
    super.onInit();
    enabled.value =
        Hive.box('settings').get('setEqualizer', defaultValue: false) as bool;
  }

  void toggleEqualizer(bool value) {
    enabled.value = value;
    Hive.box('settings').put('setEqualizer', value);
    audioHandler.customAction('setEqualizer', {'value': value});
  }
}

class Equalizer extends StatelessWidget {
  const Equalizer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EqualizerController());

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      content: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => SwitchListTile(
                title: Text(AppLocalizations.of(context)!.equalizer),
                value: controller.enabled.value,
                activeThumbColor: Theme.of(context).colorScheme.secondary,
                onChanged: (value) {
                  controller.toggleEqualizer(value);
                },
              ),
            ),
            Obx(
              () => controller.enabled.value
                  ? SizedBox(
                      height: MediaQuery.sizeOf(context).height / 2,
                      child: EqualizerControls(
                        audioHandler: controller.audioHandler,
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

class EqualizerControls extends StatefulWidget {
  final AudioPlayerHandler audioHandler;
  const EqualizerControls({super.key, required this.audioHandler});
  @override
  _EqualizerControlsState createState() => _EqualizerControlsState();
}

class _EqualizerControlsState extends State<EqualizerControls> {
  Future<Map> getEq() async {
    final Map parameters =
        await widget.audioHandler.customAction('getEqualizerParams') as Map;
    return parameters;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map>(
      future: getEq(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox();
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox();
        return Row(
          children: [
            for (final band in data['bands'] as List<Map>)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: VerticalSlider(
                        min: data['minDecibels'] as double,
                        max: data['maxDecibels'] as double,
                        value: band['gain'] as double,
                        bandIndex: band['index'] as int,
                        audioHandler: widget.audioHandler,
                      ),
                    ),
                    Text(
                      '${band['centerFrequency'].round()}\nHz',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class VerticalSliderController extends GetxController {
  final sliderValue = Rx<double?>(null);

  void updateSliderValue(double value) {
    sliderValue.value = value;
  }
}

class VerticalSlider extends StatelessWidget {
  final double? value;
  final double? min;
  final double? max;
  final int bandIndex;
  final AudioPlayerHandler audioHandler;

  const VerticalSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.bandIndex,
    required this.audioHandler,
  });

  void setGain(int bandIndex, double gain) {
    Hive.box('settings').put('equalizerBand$bandIndex', gain);
    audioHandler.customAction('setBandGain', {'band': bandIndex, 'gain': gain});
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      VerticalSliderController(),
      tag: 'slider_$bandIndex',
    );

    return FittedBox(
      fit: BoxFit.fitHeight,
      alignment: Alignment.bottomCenter,
      child: Transform.rotate(
        angle: -pi / 2,
        child: Container(
          width: 400.0,
          height: 400.0,
          alignment: Alignment.center,
          child: Obx(
            () => Slider(
              activeColor: Theme.of(context).colorScheme.secondary,
              inactiveColor:
                  Theme.of(context).colorScheme.secondary.withOpacity(0.4),
              value: controller.sliderValue.value ?? value!,
              min: min!,
              max: max!,
              onChanged: (double newValue) {
                controller.updateSliderValue(newValue);
                setGain(bandIndex, newValue);
              },
            ),
          ),
        ),
      ),
    );
  }
}
