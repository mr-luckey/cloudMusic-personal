// Coded by Naseer Ahmed

import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/image_card.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Services/player_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MiniPlayer extends StatefulWidget {
  static const MiniPlayer _instance = MiniPlayer._internal();

  factory MiniPlayer() {
    return _instance;
  }

  const MiniPlayer._internal();

  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final bool rotated = screenHeight < screenWidth;
    return SafeArea(
      top: false,
      bottom: true,
      child: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final MediaItem? mediaItem = snapshot.data;

          final List preferredMiniButtons = Hive.box('settings').get(
            'preferredMiniButtons',
            defaultValue: ['Like', 'Play/Pause', 'Next'],
          )?.toList() as List;

          final bool isLocal =
              mediaItem?.artUri?.toString().startsWith('file:') ?? false;

          final bool useDense = Hive.box('settings').get(
                'useDenseMini',
                defaultValue: false,
              ) as bool ||
              rotated;

          return Dismissible(
            key: const Key('miniplayer'),
            direction: DismissDirection.vertical,
            confirmDismiss: (DismissDirection direction) {
              if (mediaItem != null) {
                if (direction == DismissDirection.down) {
                  audioHandler.stop();
                } else {
                  Navigator.pushNamed(context, '/player');
                }
              }
              return Future.value(false);
            },
            child: Dismissible(
              key: Key(mediaItem?.id ?? 'nothingPlaying'),
              confirmDismiss: (DismissDirection direction) {
                if (mediaItem != null) {
                  if (direction == DismissDirection.startToEnd) {
                    audioHandler.skipToPrevious();
                  } else {
                    audioHandler.skipToNext();
                  }
                }
                return Future.value(false);
              },
              child: Card(
                elevation: 5,
                child: SizedBox(
                  height: 76,
                  child: GradientContainer(
                    child: StreamBuilder<PlaybackState>(
                      stream: audioHandler.playbackState,
                      builder: (context, playbackSnapshot) {
                        final processingState =
                            playbackSnapshot.data?.processingState;
                        return ValueListenableBuilder<bool>(
                          valueListenable: PlayerInvoke.isPreparingSong,
                          builder: (context, isPreparing, _) {
                            final isLoading = isPreparing ||
                                processingState ==
                                    AudioProcessingState.loading ||
                                processingState ==
                                    AudioProcessingState.buffering;

                            return Column(
                              children: [
                                Expanded(
                                  child: miniplayerTile(
                                    context: context,
                                    preferredMiniButtons: preferredMiniButtons,
                                    useDense: useDense,
                                    title: mediaItem?.title ?? '',
                                    subtitle: mediaItem?.artist ?? '',
                                    imagePath: (isLocal
                                            ? mediaItem?.artUri?.toFilePath()
                                            : mediaItem?.artUri?.toString()) ??
                                        '',
                                    isLocalImage: isLocal,
                                    isDummy: mediaItem == null,
                                  ),
                                ),
                                if (isLoading)
                                  const _MiniPlayerShimmerLine()
                                else
                                  SizedBox(
                                    height: 12,
                                    child: positionSlider(
                                      mediaItem?.duration?.inSeconds
                                          .toDouble(),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ListTile miniplayerTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required List preferredMiniButtons,
    bool useDense = false,
    bool isLocalImage = false,
    bool isDummy = false,
  }) {
    return ListTile(
      dense: useDense,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 0,
      onTap: isDummy
          ? null
          : () {
              Navigator.pushNamed(context, '/player');
            },
      title: Text(
        isDummy ? 'Now Playing' : title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isDummy ? 'Unknown' : subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Hero(
        tag: 'currentArtwork',
        child: imageCard(
          elevation: 8,
          boxDimension: useDense ? 40.0 : 50.0,
          localImage: isLocalImage,
          imageUrl: isLocalImage ? imagePath : imagePath,
        ),
      ),
      trailing: isDummy
          ? null
          : ControlButtons(
              audioHandler,
              miniplayer: true,
              buttons: isLocalImage
                  ? ['Like', 'Play/Pause', 'Next']
                  : preferredMiniButtons,
            ),
    );
  }

  StreamBuilder<Duration> positionSlider(double? maxDuration) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data;
        return ((position?.inSeconds.toDouble() ?? 0) < 0.0 ||
                ((position?.inSeconds.toDouble() ?? 0) >
                    (maxDuration ?? 180.0)))
            ? const SizedBox()
            : SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).colorScheme.secondary,
                  inactiveTrackColor: Colors.transparent,
                  trackHeight: 0.5,
                  thumbColor: Theme.of(context).colorScheme.secondary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 1.0,
                  ),
                  overlayColor: Colors.transparent,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 2.0,
                  ),
                ),
                child: Center(
                  child: Slider(
                    inactiveColor: Colors.transparent,
                    // activeColor: Colors.white,
                    value: position?.inSeconds.toDouble() ?? 0,
                    max: maxDuration ?? 180.0,
                    onChanged: (newPosition) {
                      audioHandler.seek(
                        Duration(
                          seconds: newPosition.round(),
                        ),
                      );
                    },
                  ),
                ),
              );
      },
    );
  }
}

class _MiniPlayerShimmerLine extends StatefulWidget {
  const _MiniPlayerShimmerLine();

  @override
  State<_MiniPlayerShimmerLine> createState() => _MiniPlayerShimmerLineState();
}

class _MiniPlayerShimmerLineState extends State<_MiniPlayerShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 2,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (2 * _controller.value), 0),
              end: Alignment(1.0 + (2 * _controller.value), 0),
              colors: [
                Colors.transparent,
                accent.withOpacity(0.25),
                accent,
                accent.withOpacity(0.25),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ),
          ),
        );
      },
    );
  }
}
