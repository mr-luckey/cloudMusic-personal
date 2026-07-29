import 'package:blackhole/APIs/api.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'album_search_event.dart';
part 'album_search_state.dart';

class AlbumSearchBloc extends Bloc<AlbumSearchEvent, AlbumSearchState> {
  AlbumSearchBloc({
    required this.query,
    required this.type,
  }) : super(const AlbumSearchState()) {
    on<AlbumSearchFetchRequested>(_onFetchRequested);
    add(const AlbumSearchFetchRequested());
  }

  final String query;
  final String type;

  Future<void> _onFetchRequested(
    AlbumSearchFetchRequested event,
    Emitter<AlbumSearchState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    List<Map> results;
    switch (type) {
      case 'Playlists':
        results = await SaavnAPI().fetchAlbums(
          searchQuery: query,
          type: 'playlist',
          page: state.page,
        );
      case 'Albums':
        results = await SaavnAPI().fetchAlbums(
          searchQuery: query,
          type: 'album',
          page: state.page,
        );
      case 'Artists':
        results = await SaavnAPI().fetchAlbums(
          searchQuery: query,
          type: 'artist',
          page: state.page,
        );
      default:
        results = [];
    }
    final temp = List<Map>.from(state.searchedList ?? []);
    temp.addAll(results);
    emit(state.copyWith(searchedList: temp, loading: false));
  }

  void incrementPage() {
    emit(state.copyWith(page: state.page + 1));
    add(const AlbumSearchFetchRequested());
  }
}
