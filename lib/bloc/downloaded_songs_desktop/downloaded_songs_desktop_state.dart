part of 'downloaded_songs_desktop_bloc.dart';

class DownloadedSongsDesktopState extends Equatable {
  final List<Map> songs;
  final Map<String, List<Map>> albums;
  final Map<String, List<Map>> artists;
  final Map<String, List<Map>> genres;
  final List<String> sortedAlbumKeysList;
  final List<String> sortedArtistKeysList;
  final List<String> sortedGenreKeysList;
  final bool added;
  final String? tempPath;

  const DownloadedSongsDesktopState({
    this.songs = const [],
    this.albums = const {},
    this.artists = const {},
    this.genres = const {},
    this.sortedAlbumKeysList = const [],
    this.sortedArtistKeysList = const [],
    this.sortedGenreKeysList = const [],
    this.added = false,
    this.tempPath,
  });

  DownloadedSongsDesktopState copyWith({
    List<Map>? songs,
    Map<String, List<Map>>? albums,
    Map<String, List<Map>>? artists,
    Map<String, List<Map>>? genres,
    List<String>? sortedAlbumKeysList,
    List<String>? sortedArtistKeysList,
    List<String>? sortedGenreKeysList,
    bool? added,
    String? tempPath,
  }) {
    return DownloadedSongsDesktopState(
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      genres: genres ?? this.genres,
      sortedAlbumKeysList: sortedAlbumKeysList ?? this.sortedAlbumKeysList,
      sortedArtistKeysList: sortedArtistKeysList ?? this.sortedArtistKeysList,
      sortedGenreKeysList: sortedGenreKeysList ?? this.sortedGenreKeysList,
      added: added ?? this.added,
      tempPath: tempPath ?? this.tempPath,
    );
  }

  @override
  List<Object?> get props => [
        songs,
        albums,
        artists,
        genres,
        sortedAlbumKeysList,
        sortedArtistKeysList,
        sortedGenreKeysList,
        added,
        tempPath,
      ];
}
