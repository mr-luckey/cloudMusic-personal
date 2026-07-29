part of 'youtube_artist_bloc.dart';

abstract class YouTubeArtistEvent extends Equatable {
  const YouTubeArtistEvent();

  @override
  List<Object?> get props => [];
}

class YouTubeArtistLoadRequested extends YouTubeArtistEvent {
  final String artistId;

  const YouTubeArtistLoadRequested(this.artistId);

  @override
  List<Object?> get props => [artistId];
}

class YouTubeArtistSongTapStarted extends YouTubeArtistEvent {
  const YouTubeArtistSongTapStarted();
}

class YouTubeArtistSongTapFinished extends YouTubeArtistEvent {
  const YouTubeArtistSongTapFinished();
}
