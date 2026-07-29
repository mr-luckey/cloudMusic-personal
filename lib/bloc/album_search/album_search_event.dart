part of 'album_search_bloc.dart';

abstract class AlbumSearchEvent extends Equatable {
  const AlbumSearchEvent();

  @override
  List<Object?> get props => [];
}

class AlbumSearchFetchRequested extends AlbumSearchEvent {
  const AlbumSearchFetchRequested();
}
