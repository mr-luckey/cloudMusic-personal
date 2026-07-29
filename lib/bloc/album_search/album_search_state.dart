part of 'album_search_bloc.dart';

class AlbumSearchState extends Equatable {
  final int page;
  final bool loading;
  final List<Map>? searchedList;

  const AlbumSearchState({
    this.page = 1,
    this.loading = false,
    this.searchedList,
  });

  AlbumSearchState copyWith({
    int? page,
    bool? loading,
    List<Map>? searchedList,
  }) {
    return AlbumSearchState(
      page: page ?? this.page,
      loading: loading ?? this.loading,
      searchedList: searchedList ?? this.searchedList,
    );
  }

  @override
  List<Object?> get props => [page, loading, searchedList];
}
