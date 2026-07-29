part of 'downloaded_songs_desktop_bloc.dart';

abstract class DownloadedSongsDesktopEvent extends Equatable {
  const DownloadedSongsDesktopEvent();

  @override
  List<Object?> get props => [];
}

class DownloadedSongsDesktopLoadRequested extends DownloadedSongsDesktopEvent {
  final List<Map>? cachedSongs;

  const DownloadedSongsDesktopLoadRequested({this.cachedSongs});
}

class DownloadedSongsDesktopSongsLoaded extends DownloadedSongsDesktopEvent {
  final List<Map> songs;

  const DownloadedSongsDesktopSongsLoaded(this.songs);

  @override
  List<Object?> get props => [songs];
}
