part of 'youtube_home_bloc.dart';

abstract class YouTubeHomeEvent extends Equatable {
  const YouTubeHomeEvent();

  @override
  List<Object?> get props => [];
}

class YouTubeHomeLoadRequested extends YouTubeHomeEvent {
  const YouTubeHomeLoadRequested();
}

class YouTubeHomeRefreshRequested extends YouTubeHomeEvent {
  const YouTubeHomeRefreshRequested();
}
