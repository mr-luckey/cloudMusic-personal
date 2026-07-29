part of 'songs_list_view_bloc.dart';

abstract class SongsListViewEvent extends Equatable {
  const SongsListViewEvent();

  @override
  List<Object?> get props => [];
}

class SongsListViewLoadInitial extends SongsListViewEvent {
  const SongsListViewLoadInitial();
}

class SongsListViewLoadMore extends SongsListViewEvent {
  const SongsListViewLoadMore();
}

class SongsListViewSharePopupShown extends SongsListViewEvent {
  const SongsListViewSharePopupShown();
}

class SongsListViewSharePopupHidden extends SongsListViewEvent {
  const SongsListViewSharePopupHidden();
}
