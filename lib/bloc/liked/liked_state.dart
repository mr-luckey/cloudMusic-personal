part of 'liked_bloc.dart';

class LikedState extends Equatable {
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
  final int selectionRevision;

  const LikedState({
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
    this.selectionRevision = 0,
  });

  LikedState copyWith({
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
    int? selectionRevision,
  }) {
    return LikedState(
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
      selectionRevision: selectionRevision ?? this.selectionRevision,
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
        selectionRevision,
      ];
}
