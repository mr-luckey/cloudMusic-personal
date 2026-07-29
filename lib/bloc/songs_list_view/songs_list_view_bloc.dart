import 'package:blackhole/Models/song_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

part 'songs_list_view_event.dart';
part 'songs_list_view_state.dart';

class SongsListViewBloc extends Bloc<SongsListViewEvent, SongsListViewState> {
  SongsListViewBloc({
    this.loadFunction,
    this.loadMoreFunction,
  }) : super(const SongsListViewState()) {
    on<SongsListViewLoadInitial>(_onLoadInitial);
    on<SongsListViewLoadMore>(_onLoadMore);
    on<SongsListViewSharePopupShown>(_onSharePopupShown);
    on<SongsListViewSharePopupHidden>(_onSharePopupHidden);
    add(const SongsListViewLoadInitial());
  }

  final Future<List> Function()? loadFunction;
  final Future<List> Function()? loadMoreFunction;

  Future<void> _onLoadInitial(
    SongsListViewLoadInitial event,
    Emitter<SongsListViewState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    try {
      if (loadFunction == null) {
        emit(state.copyWith(fetched: true, loading: false));
      } else {
        final value = await loadFunction!.call();
        emit(state.copyWith(
          itemsList: value as List<SongItem>,
          fetched: true,
          loading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(fetched: true, loading: false));
      Logger.root.severe('Error in song_list_view loadInitial: $e');
    }
  }

  Future<void> _onLoadMore(
    SongsListViewLoadMore event,
    Emitter<SongsListViewState> emit,
  ) async {
    if (loadMoreFunction == null) return;
    emit(state.copyWith(loading: true));
    try {
      final value = await loadMoreFunction!.call();
      emit(state.copyWith(
        itemsList: value as List<SongItem>,
        fetched: true,
        loading: false,
        page: state.page + 1,
      ));
    } catch (e) {
      emit(state.copyWith(fetched: true, loading: false));
      Logger.root.severe('Error in song_list_view loadMore: $e');
    }
  }

  void _onSharePopupShown(
    SongsListViewSharePopupShown event,
    Emitter<SongsListViewState> emit,
  ) {
    emit(state.copyWith(isSharePopupShown: true));
  }

  void _onSharePopupHidden(
    SongsListViewSharePopupHidden event,
    Emitter<SongsListViewState> emit,
  ) {
    emit(state.copyWith(isSharePopupShown: false));
  }
}
