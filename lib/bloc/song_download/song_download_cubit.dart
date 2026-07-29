import 'package:blackhole/Services/download.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class SongDownloadState extends Equatable {
  final String songId;
  final bool isDownloaded;
  final bool isDownloading;
  final double? progress;
  final bool showStopButton;

  const SongDownloadState({
    required this.songId,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.progress = 0.0,
    this.showStopButton = false,
  });

  SongDownloadState copyWith({
    String? songId,
    bool? isDownloaded,
    bool? isDownloading,
    double? progress,
    bool keepProgress = true,
    bool? showStopButton,
  }) {
    return SongDownloadState(
      songId: songId ?? this.songId,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      progress: keepProgress ? (progress ?? this.progress) : progress,
      showStopButton: showStopButton ?? this.showStopButton,
    );
  }

  @override
  List<Object?> get props =>
      [songId, isDownloaded, isDownloading, progress, showStopButton];
}

/// Wraps [Download] so the play-screen download button rebuilds via Bloc
/// instead of setState. UI and download behaviour stay the same.
class SongDownloadCubit extends Cubit<SongDownloadState> {
  SongDownloadCubit({
    required String songId,
    required Map data,
  })  : _data = Map<dynamic, dynamic>.from(data),
        _download = Download(songId),
        _downloadsBox = Hive.box('downloads'),
        super(
          SongDownloadState(
            songId: songId,
            isDownloaded: Hive.box('downloads').containsKey(songId),
          ),
        ) {
    _listener = _emitFromDownload;
    _download.addListener(_listener);
    _emitFromDownload();
  }

  Map _data;
  final Download _download;
  final Box _downloadsBox;
  late final VoidCallback _listener;

  void syncData(Map data) {
    _data = Map<dynamic, dynamic>.from(data);
  }

  void _emitFromDownload() {
    if (isClosed) return;
    final id = state.songId;
    emit(
      SongDownloadState(
        songId: id,
        isDownloaded: _downloadsBox.containsKey(id),
        isDownloading: _download.isDownloading,
        progress: _download.progress,
        showStopButton: state.showStopButton,
      ),
    );
  }

  Future<void> startDownload(BuildContext context) async {
    await _download.prepareDownload(context, _data);
    _emitFromDownload();
  }

  Future<void> cancelDownload() async {
    await _download.cancelDownload();
    if (!isClosed) {
      emit(state.copyWith(showStopButton: false));
    }
    _emitFromDownload();
  }

  void showStop() {
    if (!isClosed) emit(state.copyWith(showStopButton: true));
  }

  void hideStop() {
    if (!isClosed) emit(state.copyWith(showStopButton: false));
  }

  @override
  Future<void> close() {
    _download.removeListener(_listener);
    return super.close();
  }
}
