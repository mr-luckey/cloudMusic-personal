part of 'songs_list_bloc.dart';

abstract class SongsListEvent extends Equatable {
  const SongsListEvent();

  @override
  List<Object?> get props => [];
}

class SongsListFetchRequested extends SongsListEvent {
  const SongsListFetchRequested();
}

class SongsListSharePopupShown extends SongsListEvent {
  const SongsListSharePopupShown();
}

class SongsListSharePopupHidden extends SongsListEvent {
  const SongsListSharePopupHidden();
}
