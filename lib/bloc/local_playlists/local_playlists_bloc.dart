import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

part 'local_playlists_event.dart';
part 'local_playlists_state.dart';

class LocalPlaylistsBloc extends Bloc<LocalPlaylistsEvent, LocalPlaylistsState> {
  LocalPlaylistsBloc({List<PlaylistModel>? initialPlaylists})
      : super(LocalPlaylistsState(
          playlistDetails: initialPlaylists ?? const [],
        )) {
    on<LocalPlaylistsInitialized>(_onInitialized);
    on<LocalPlaylistsRefreshed>(_onRefreshed);
    on<LocalPlaylistRemoved>(_onRemoved);
    on<LocalPlaylistsDialogOpened>(_onDialogOpened);
    if (initialPlaylists != null) {
      add(LocalPlaylistsInitialized(initialPlaylists));
    }
  }

  void _onInitialized(
    LocalPlaylistsInitialized event,
    Emitter<LocalPlaylistsState> emit,
  ) {
    emit(state.copyWith(playlistDetails: event.playlistDetails));
  }

  void _onRefreshed(
    LocalPlaylistsRefreshed event,
    Emitter<LocalPlaylistsState> emit,
  ) {
    emit(state.copyWith(playlistDetails: event.playlistDetails));
  }

  void _onRemoved(
    LocalPlaylistRemoved event,
    Emitter<LocalPlaylistsState> emit,
  ) {
    final playlists = List<PlaylistModel>.from(state.playlistDetails);
    playlists.removeAt(event.index);
    emit(state.copyWith(playlistDetails: playlists));
  }

  void _onDialogOpened(
    LocalPlaylistsDialogOpened event,
    Emitter<LocalPlaylistsState> emit,
  ) {
    emit(state.copyWith(dialogToken: state.dialogToken + 1));
  }
}
