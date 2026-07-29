part of 'youtube_playlist_bloc.dart';

abstract class YouTubePlaylistEvent extends Equatable {
  const YouTubePlaylistEvent();

  @override
  List<Object?> get props => [];
}

class YouTubePlaylistLoadRequested extends YouTubePlaylistEvent {
  final String playlistId;
  final String type;

  const YouTubePlaylistLoadRequested({
    required this.playlistId,
    this.type = 'playlist',
  });

  @override
  List<Object?> get props => [playlistId, type];
}

class YouTubePlaylistSongTapped extends YouTubePlaylistEvent {
  final Map entry;

  const YouTubePlaylistSongTapped({required this.entry});

  @override
  List<Object?> get props => [entry];
}

class YouTubePlaylistPlayAllTapped extends YouTubePlaylistEvent {
  const YouTubePlaylistPlayAllTapped();
}

class YouTubePlaylistShuffleTapped extends YouTubePlaylistEvent {
  const YouTubePlaylistShuffleTapped();
}

class YouTubePlaylistLoadingFinished extends YouTubePlaylistEvent {
  const YouTubePlaylistLoadingFinished();
}
