part of 'youtube_playlist_bloc.dart';

enum YouTubePlaylistStatus { initial, loading, loaded }

class YouTubePlaylistState extends Equatable {
  final YouTubePlaylistStatus status;
  final List<Map> searchedList;
  final String playlistName;
  final String playlistSubtitle;
  final String? playlistSecondarySubtitle;
  final String playlistImage;
  final bool isProcessing;
  final Map? formattedResponse;
  final List<Map>? formattedPlayList;
  final bool playAllTriggered;
  final bool shuffleTriggered;

  const YouTubePlaylistState({
    this.status = YouTubePlaylistStatus.initial,
    this.searchedList = const [],
    this.playlistName = '',
    this.playlistSubtitle = '',
    this.playlistSecondarySubtitle,
    this.playlistImage = '',
    this.isProcessing = false,
    this.formattedResponse,
    this.formattedPlayList,
    this.playAllTriggered = false,
    this.shuffleTriggered = false,
  });

  YouTubePlaylistState copyWith({
    YouTubePlaylistStatus? status,
    List<Map>? searchedList,
    String? playlistName,
    String? playlistSubtitle,
    String? playlistSecondarySubtitle,
    String? playlistImage,
    bool? isProcessing,
    Map? formattedResponse,
    List<Map>? formattedPlayList,
    bool? playAllTriggered,
    bool? shuffleTriggered,
  }) {
    return YouTubePlaylistState(
      status: status ?? this.status,
      searchedList: searchedList ?? this.searchedList,
      playlistName: playlistName ?? this.playlistName,
      playlistSubtitle: playlistSubtitle ?? this.playlistSubtitle,
      playlistSecondarySubtitle:
          playlistSecondarySubtitle ?? this.playlistSecondarySubtitle,
      playlistImage: playlistImage ?? this.playlistImage,
      isProcessing: isProcessing ?? this.isProcessing,
      formattedResponse: formattedResponse,
      formattedPlayList: formattedPlayList,
      playAllTriggered: playAllTriggered ?? this.playAllTriggered,
      shuffleTriggered: shuffleTriggered ?? this.shuffleTriggered,
    );
  }

  @override
  List<Object?> get props => [
        status,
        searchedList,
        playlistName,
        playlistSubtitle,
        playlistSecondarySubtitle,
        playlistImage,
        isProcessing,
        formattedResponse,
        formattedPlayList,
        playAllTriggered,
        shuffleTriggered,
      ];
}
