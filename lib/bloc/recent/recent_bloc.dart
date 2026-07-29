import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'recent_event.dart';
part 'recent_state.dart';

class RecentBloc extends Bloc<RecentEvent, RecentState> {
  RecentBloc() : super(const RecentState()) {
    on<RecentLoadRequested>(_onLoadRequested);
    on<RecentClearAll>(_onClearAll);
    on<RecentSongDismissed>(_onSongDismissed);
  }

  void _onLoadRequested(
    RecentLoadRequested event,
    Emitter<RecentState> emit,
  ) {
    final songs =
        Hive.box('cache').get('recentSongs', defaultValue: []) as List;
    emit(state.copyWith(songs: List.from(songs), isLoaded: true));
  }

  void _onClearAll(RecentClearAll event, Emitter<RecentState> emit) {
    Hive.box('cache').put('recentSongs', []);
    emit(state.copyWith(songs: []));
  }

  void _onSongDismissed(
    RecentSongDismissed event,
    Emitter<RecentState> emit,
  ) {
    final songs = List.from(state.songs);
    songs.removeAt(event.index);
    Hive.box('cache').put('recentSongs', songs);
    emit(state.copyWith(songs: songs));
  }
}
