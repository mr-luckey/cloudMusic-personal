part of 'youtube_artist_bloc.dart';

class YouTubeArtistState extends Equatable {
  final bool fetched;
  final bool done;
  final Map<String, dynamic> data;
  final List<Map> searchedList;
  final String artistName;
  final String artistSubtitle;
  final String artistImage;

  const YouTubeArtistState({
    this.fetched = false,
    this.done = true,
    this.data = const {},
    this.searchedList = const [],
    this.artistName = '',
    this.artistSubtitle = '',
    this.artistImage = '',
  });

  YouTubeArtistState copyWith({
    bool? fetched,
    bool? done,
    Map<String, dynamic>? data,
    List<Map>? searchedList,
    String? artistName,
    String? artistSubtitle,
    String? artistImage,
  }) {
    return YouTubeArtistState(
      fetched: fetched ?? this.fetched,
      done: done ?? this.done,
      data: data ?? this.data,
      searchedList: searchedList ?? this.searchedList,
      artistName: artistName ?? this.artistName,
      artistSubtitle: artistSubtitle ?? this.artistSubtitle,
      artistImage: artistImage ?? this.artistImage,
    );
  }

  @override
  List<Object?> get props => [
        fetched,
        done,
        data,
        searchedList,
        artistName,
        artistSubtitle,
        artistImage,
      ];
}
