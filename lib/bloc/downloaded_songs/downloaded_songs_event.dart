part of 'downloaded_songs_bloc.dart';

abstract class DownloadedSongsEvent extends Equatable {
  const DownloadedSongsEvent();

  @override
  List<Object?> get props => [];
}

class DownloadedSongsLoadRequested extends DownloadedSongsEvent {
  final List<SongModel>? cachedSongs;

  const DownloadedSongsLoadRequested({this.cachedSongs});
}

class DownloadedSongsTabChanged extends DownloadedSongsEvent {
  final int tabIndex;

  const DownloadedSongsTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class DownloadedSongsSortChanged extends DownloadedSongsEvent {
  final int sortValue;
  final int orderValue;

  const DownloadedSongsSortChanged({
    required this.sortValue,
    required this.orderValue,
  });

  @override
  List<Object?> get props => [sortValue, orderValue];
}

class DownloadedSongsSongDeleted extends DownloadedSongsEvent {
  final SongModel song;

  const DownloadedSongsSongDeleted(this.song);

  @override
  List<Object?> get props => [song];
}
