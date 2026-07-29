part of 'downloaded_songs_bloc.dart';

class DownloadedSongsState extends Equatable {
  final List<SongModel> songs;
  final Map<String, List<SongModel>> albums;
  final Map<String, List<SongModel>> artists;
  final Map<String, List<SongModel>> genres;
  final Map<String, List<SongModel>> folders;
  final List<String> sortedAlbumKeysList;
  final List<String> sortedArtistKeysList;
  final List<String> sortedGenreKeysList;
  final List<String> sortedFolderKeysList;
  final bool added;
  final int currentTabIndex;
  final int sortValue;
  final int orderValue;
  final String? tempPath;
  final List<PlaylistModel> playlistDetails;

  const DownloadedSongsState({
    this.songs = const [],
    this.albums = const {},
    this.artists = const {},
    this.genres = const {},
    this.folders = const {},
    this.sortedAlbumKeysList = const [],
    this.sortedArtistKeysList = const [],
    this.sortedGenreKeysList = const [],
    this.sortedFolderKeysList = const [],
    this.added = false,
    this.currentTabIndex = 0,
    this.sortValue = 1,
    this.orderValue = 1,
    this.tempPath,
    this.playlistDetails = const [],
  });

  DownloadedSongsState copyWith({
    List<SongModel>? songs,
    Map<String, List<SongModel>>? albums,
    Map<String, List<SongModel>>? artists,
    Map<String, List<SongModel>>? genres,
    Map<String, List<SongModel>>? folders,
    List<String>? sortedAlbumKeysList,
    List<String>? sortedArtistKeysList,
    List<String>? sortedGenreKeysList,
    List<String>? sortedFolderKeysList,
    bool? added,
    int? currentTabIndex,
    int? sortValue,
    int? orderValue,
    String? tempPath,
    List<PlaylistModel>? playlistDetails,
  }) {
    return DownloadedSongsState(
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      genres: genres ?? this.genres,
      folders: folders ?? this.folders,
      sortedAlbumKeysList: sortedAlbumKeysList ?? this.sortedAlbumKeysList,
      sortedArtistKeysList: sortedArtistKeysList ?? this.sortedArtistKeysList,
      sortedGenreKeysList: sortedGenreKeysList ?? this.sortedGenreKeysList,
      sortedFolderKeysList: sortedFolderKeysList ?? this.sortedFolderKeysList,
      added: added ?? this.added,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      sortValue: sortValue ?? this.sortValue,
      orderValue: orderValue ?? this.orderValue,
      tempPath: tempPath ?? this.tempPath,
      playlistDetails: playlistDetails ?? this.playlistDetails,
    );
  }

  @override
  List<Object?> get props => [
        songs,
        albums,
        artists,
        genres,
        folders,
        sortedAlbumKeysList,
        sortedArtistKeysList,
        sortedGenreKeysList,
        sortedFolderKeysList,
        added,
        currentTabIndex,
        sortValue,
        orderValue,
        tempPath,
        playlistDetails,
      ];
}
