part of 'songs_list_view_bloc.dart';

class SongsListViewState extends Equatable {
  final int page;
  final bool loading;
  final List itemsList;
  final bool fetched;
  final bool isSharePopupShown;

  const SongsListViewState({
    this.page = 1,
    this.loading = false,
    this.itemsList = const [],
    this.fetched = false,
    this.isSharePopupShown = false,
  });

  SongsListViewState copyWith({
    int? page,
    bool? loading,
    List? itemsList,
    bool? fetched,
    bool? isSharePopupShown,
  }) {
    return SongsListViewState(
      page: page ?? this.page,
      loading: loading ?? this.loading,
      itemsList: itemsList ?? this.itemsList,
      fetched: fetched ?? this.fetched,
      isSharePopupShown: isSharePopupShown ?? this.isSharePopupShown,
    );
  }

  @override
  List<Object?> get props =>
      [page, loading, itemsList, fetched, isSharePopupShown];
}
