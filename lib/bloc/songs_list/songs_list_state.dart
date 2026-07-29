part of 'songs_list_bloc.dart';

class SongsListState extends Equatable {
  final int page;
  final bool loading;
  final List songList;
  final bool fetched;
  final bool isSharePopupShown;

  const SongsListState({
    this.page = 1,
    this.loading = false,
    this.songList = const [],
    this.fetched = false,
    this.isSharePopupShown = false,
  });

  SongsListState copyWith({
    int? page,
    bool? loading,
    List? songList,
    bool? fetched,
    bool? isSharePopupShown,
  }) {
    return SongsListState(
      page: page ?? this.page,
      loading: loading ?? this.loading,
      songList: songList ?? this.songList,
      fetched: fetched ?? this.fetched,
      isSharePopupShown: isSharePopupShown ?? this.isSharePopupShown,
    );
  }

  @override
  List<Object?> get props =>
      [page, loading, songList, fetched, isSharePopupShown];
}
