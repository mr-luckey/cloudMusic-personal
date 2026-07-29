import 'package:blackhole/APIs/api.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

part 'songs_list_event.dart';
part 'songs_list_state.dart';

class SongsListBloc extends Bloc<SongsListEvent, SongsListState> {
  SongsListBloc({required this.listItem})
      : super(const SongsListState()) {
    on<SongsListFetchRequested>(_onFetchRequested);
    on<SongsListSharePopupShown>(_onSharePopupShown);
    on<SongsListSharePopupHidden>(_onSharePopupHidden);
    add(const SongsListFetchRequested());
  }

  final Map listItem;

  Future<void> _onFetchRequested(
    SongsListFetchRequested event,
    Emitter<SongsListState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    try {
      switch (listItem['type'].toString()) {
        case 'songs':
          final value = await SaavnAPI().fetchSongSearchResults(
            searchQuery: listItem['id'].toString(),
            page: state.page,
          );
          final songList = List.from(state.songList)
            ..addAll(value['songs'] as List);
          emit(state.copyWith(
            songList: songList,
            fetched: true,
            loading: false,
          ));
        case 'album':
          final value =
              await SaavnAPI().fetchAlbumSongs(listItem['id'].toString());
          emit(state.copyWith(
            songList: value['songs'] as List,
            fetched: true,
            loading: false,
          ));
        case 'playlist':
          final value =
              await SaavnAPI().fetchPlaylistSongs(listItem['id'].toString());
          emit(state.copyWith(
            songList: value['songs'] as List,
            fetched: true,
            loading: false,
          ));
        case 'mix':
          final value = await SaavnAPI().getSongFromToken(
            listItem['perma_url'].toString().split('/').last,
            'mix',
          );
          emit(state.copyWith(
            songList: value['songs'] as List,
            fetched: true,
            loading: false,
          ));
        case 'show':
          final value = await SaavnAPI().getSongFromToken(
            listItem['perma_url'].toString().split('/').last,
            'show',
          );
          emit(state.copyWith(
            songList: value['songs'] as List,
            fetched: true,
            loading: false,
          ));
        default:
          emit(state.copyWith(fetched: true, loading: false));
      }
    } catch (e) {
      emit(state.copyWith(fetched: true, loading: false));
      Logger.root.severe(
        'Error in song_list with type ${listItem["type"]}: $e',
      );
    }
  }

  void _onSharePopupShown(
    SongsListSharePopupShown event,
    Emitter<SongsListState> emit,
  ) {
    emit(state.copyWith(isSharePopupShown: true));
  }

  void _onSharePopupHidden(
    SongsListSharePopupHidden event,
    Emitter<SongsListState> emit,
  ) {
    emit(state.copyWith(isSharePopupShown: false));
  }

  void incrementPage() {
    emit(state.copyWith(page: state.page + 1));
    add(const SongsListFetchRequested());
  }
}
