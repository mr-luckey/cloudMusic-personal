part of 'downloads_bloc.dart';

class DownloadsState extends Equatable {
  final bool isLoaded;
  final List songs;
  final Map<String, List<Map>> albums;
  final Map<String, List<Map>> artists;
  final Map<String, List<Map>> genres;
  final List sortedAlbumKeysList;
  final List sortedArtistKeysList;
  final List sortedGenreKeysList;
  final int sortValue;
  final int orderValue;
  final int albumSortValue;
  final int currentTabIndex;
  final String? snackbarMessage;
  final bool snackbarIsError;

  const DownloadsState({
    this.isLoaded = false,
    this.songs = const [],
    this.albums = const {},
    this.artists = const {},
    this.genres = const {},
    this.sortedAlbumKeysList = const [],
    this.sortedArtistKeysList = const [],
    this.sortedGenreKeysList = const [],
    this.sortValue = 1,
    this.orderValue = 1,
    this.albumSortValue = 2,
    this.currentTabIndex = 0,
    this.snackbarMessage,
    this.snackbarIsError = false,
  });

  DownloadsState copyWith({
    bool? isLoaded,
    List? songs,
    Map<String, List<Map>>? albums,
    Map<String, List<Map>>? artists,
    Map<String, List<Map>>? genres,
    List? sortedAlbumKeysList,
    List? sortedArtistKeysList,
    List? sortedGenreKeysList,
    int? sortValue,
    int? orderValue,
    int? albumSortValue,
    int? currentTabIndex,
    String? snackbarMessage,
    bool? snackbarIsError,
    bool clearSnackbar = false,
  }) {
    return DownloadsState(
      isLoaded: isLoaded ?? this.isLoaded,
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      genres: genres ?? this.genres,
      sortedAlbumKeysList: sortedAlbumKeysList ?? this.sortedAlbumKeysList,
      sortedArtistKeysList: sortedArtistKeysList ?? this.sortedArtistKeysList,
      sortedGenreKeysList: sortedGenreKeysList ?? this.sortedGenreKeysList,
      sortValue: sortValue ?? this.sortValue,
      orderValue: orderValue ?? this.orderValue,
      albumSortValue: albumSortValue ?? this.albumSortValue,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      snackbarMessage:
          clearSnackbar ? null : (snackbarMessage ?? this.snackbarMessage),
      snackbarIsError: clearSnackbar
          ? false
          : (snackbarIsError ?? this.snackbarIsError),
    );
  }

  @override
  List<Object?> get props => [
        isLoaded,
        songs,
        albums,
        artists,
        genres,
        sortedAlbumKeysList,
        sortedArtistKeysList,
        sortedGenreKeysList,
        sortValue,
        orderValue,
        albumSortValue,
        currentTabIndex,
        snackbarMessage,
        snackbarIsError,
      ];
}
