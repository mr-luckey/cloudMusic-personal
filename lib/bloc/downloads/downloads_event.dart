part of 'downloads_bloc.dart';

abstract class DownloadsEvent extends Equatable {
  const DownloadsEvent();

  @override
  List<Object?> get props => [];
}

class DownloadsLoadRequested extends DownloadsEvent {
  const DownloadsLoadRequested();
}

class DownloadsSongsSorted extends DownloadsEvent {
  final int value;

  const DownloadsSongsSorted({required this.value});

  @override
  List<Object?> get props => [value];
}

class DownloadsSongDeleted extends DownloadsEvent {
  final Map song;

  const DownloadsSongDeleted({required this.song});

  @override
  List<Object?> get props => [song];
}

class DownloadsSongUpdated extends DownloadsEvent {
  final int index;
  final Map song;

  const DownloadsSongUpdated({required this.index, required this.song});

  @override
  List<Object?> get props => [index, song];
}

class DownloadsTabIndexChanged extends DownloadsEvent {
  final int index;

  const DownloadsTabIndexChanged({required this.index});

  @override
  List<Object?> get props => [index];
}

class DownloadsSnackbarShown extends DownloadsEvent {
  const DownloadsSnackbarShown();
}
