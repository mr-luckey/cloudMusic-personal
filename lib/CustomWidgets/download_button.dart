// Coded by Naseer Ahmed

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Services/download.dart';
import 'package:blackhole/bloc/song_download/song_download_cubit.dart';
import 'package:blackhole/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadButton extends StatelessWidget {
  final Map data;
  final String? icon;
  final double? size;
  const DownloadButton({
    super.key,
    required this.data,
    this.icon,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final songId = data['id'].toString();
    return BlocProvider(
      key: ValueKey('song_download_$songId'),
      create: (_) => SongDownloadCubit(songId: songId, data: data),
      child: _DownloadButtonView(
        data: data,
        icon: icon,
        size: size,
      ),
    );
  }
}

class _DownloadButtonView extends StatefulWidget {
  final Map data;
  final String? icon;
  final double? size;

  const _DownloadButtonView({
    required this.data,
    this.icon,
    this.size,
  });

  @override
  State<_DownloadButtonView> createState() => _DownloadButtonViewState();
}

class _DownloadButtonViewState extends State<_DownloadButtonView> {
  @override
  void didUpdateWidget(covariant _DownloadButtonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data['id']?.toString() != widget.data['id']?.toString() ||
        oldWidget.data['url']?.toString() != widget.data['url']?.toString()) {
      context.read<SongDownloadCubit>().syncData(widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 50,
      child: Center(
        child: BlocBuilder<SongDownloadCubit, SongDownloadState>(
          builder: (context, state) {
            if (state.isDownloaded) {
              return IconButton(
                icon: const Icon(Icons.download_done_rounded),
                tooltip: 'Download Done',
                color: Theme.of(context).colorScheme.secondary,
                iconSize: widget.size ?? 24.0,
                onPressed: () {
                  context.read<SongDownloadCubit>().startDownload(context);
                },
              );
            }

            if (!state.isDownloading) {
              return IconButton(
                icon: Icon(
                  widget.icon == 'download'
                      ? Icons.download_rounded
                      : Icons.save_alt,
                ),
                iconSize: widget.size ?? 24.0,
                color: Theme.of(context).iconTheme.color,
                tooltip: 'Download',
                onPressed: () {
                  context.read<SongDownloadCubit>().startDownload(context);
                },
              );
            }

            final progress = state.progress;
            return GestureDetector(
              onTap: () {
                final cubit = context.read<SongDownloadCubit>();
                cubit.showStop();
                Future.delayed(const Duration(seconds: 2), () {
                  cubit.hideStop();
                });
              },
              child: Stack(
                children: [
                  Center(
                    child: CircularProgressIndicator(
                      // Indeterminate until first real progress bytes arrive.
                      value: (progress == null || progress <= 0)
                          ? null
                          : (progress >= 1 ? null : progress),
                    ),
                  ),
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Visibility(
                            visible: !state.showStopButton,
                            child: Center(
                              child: Text(
                                progress == null || progress <= 0
                                    ? '0%'
                                    : '${(100 * progress).round()}%',
                              ),
                            ),
                          ),
                          Visibility(
                            visible: state.showStopButton,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded),
                                iconSize: 25.0,
                                color: Theme.of(context).iconTheme.color,
                                tooltip:
                                    AppLocalizations.of(context)!.stopDown,
                                onPressed: () {
                                  context
                                      .read<SongDownloadCubit>()
                                      .cancelDownload();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MultiDownloadButton extends StatefulWidget {
  final List data;
  final String playlistName;
  const MultiDownloadButton({
    super.key,
    required this.data,
    required this.playlistName,
  });

  @override
  _MultiDownloadButtonState createState() => _MultiDownloadButtonState();
}

class _MultiDownloadButtonState extends State<MultiDownloadButton> {
  late Download down;
  int done = 0;

  @override
  void initState() {
    super.initState();
    down = Download(widget.data.first['id'].toString());
    down.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox();
    }
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: (down.lastDownloadId == widget.data.last['id'])
            ? IconButton(
                icon: const Icon(
                  Icons.download_done_rounded,
                ),
                color: Theme.of(context).colorScheme.secondary,
                iconSize: 25.0,
                tooltip: AppLocalizations.of(context)!.downDone,
                onPressed: () {},
              )
            : !down.isDownloading && down.progress == 0
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                      ),
                      iconSize: 25.0,
                      tooltip: AppLocalizations.of(context)!.down,
                      onPressed: () async {
                        for (final items in widget.data) {
                          down.prepareDownload(
                            context,
                            items as Map,
                            createFolder: true,
                            folderName: widget.playlistName,
                          );
                          await _waitUntilDone(items['id'].toString());
                          setState(() {
                            done++;
                          });
                        }
                      },
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%',
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            value: down.progress == null || down.progress == 0
                                ? null
                                : (down.progress == 1 ? null : down.progress),
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: done / widget.data.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class AlbumDownloadButton extends StatefulWidget {
  final String albumId;
  final String albumName;
  const AlbumDownloadButton({
    super.key,
    required this.albumId,
    required this.albumName,
  });

  @override
  _AlbumDownloadButtonState createState() => _AlbumDownloadButtonState();
}

class _AlbumDownloadButtonState extends State<AlbumDownloadButton> {
  late Download down;
  int done = 0;
  List data = [];
  bool finished = false;

  @override
  void initState() {
    super.initState();
    down = Download(widget.albumId);
    down.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: finished
            ? IconButton(
                icon: const Icon(
                  Icons.download_done_rounded,
                ),
                color: Theme.of(context).colorScheme.secondary,
                iconSize: 25.0,
                tooltip: AppLocalizations.of(context)!.downDone,
                onPressed: () {},
              )
            : !down.isDownloading && down.progress == 0
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                      ),
                      iconSize: 25.0,
                      color: Theme.of(context).iconTheme.color,
                      tooltip: AppLocalizations.of(context)!.down,
                      onPressed: () async {
                        ShowSnackBar().showSnackBar(
                          context,
                          '${AppLocalizations.of(context)!.downingAlbum} "${widget.albumName}"',
                        );

                        data = (await SaavnAPI()
                            .fetchAlbumSongs(widget.albumId))['songs'] as List;
                        for (final items in data) {
                          down.prepareDownload(
                            context,
                            items as Map,
                            createFolder: true,
                            folderName: widget.albumName,
                          );
                          await _waitUntilDone(items['id'].toString());
                          setState(() {
                            done++;
                          });
                        }
                        finished = true;
                      },
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%',
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            value: down.progress == null || down.progress == 0
                                ? null
                                : (down.progress == 1 ? null : down.progress),
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: data.isEmpty ? 0 : done / data.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
