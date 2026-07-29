import 'package:blackhole/Services/youtube_services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'youtube_home_event.dart';
part 'youtube_home_state.dart';

class YouTubeHomeBloc extends Bloc<YouTubeHomeEvent, YouTubeHomeState> {
  static bool _hasLoaded = false;

  YouTubeHomeBloc() : super(YouTubeHomeState(
    searchedList: Hive.box('cache').get('ytHome', defaultValue: []) as List,
    headList: Hive.box('cache').get('ytHomeHead', defaultValue: []) as List,
    status: (Hive.box('cache').get('ytHome', defaultValue: []) as List).isNotEmpty
        ? YouTubeHomeStatus.loaded
        : YouTubeHomeStatus.initial,
  )) {
    on<YouTubeHomeLoadRequested>(_onLoadRequested);
    on<YouTubeHomeRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    YouTubeHomeLoadRequested event,
    Emitter<YouTubeHomeState> emit,
  ) async {
    if (_hasLoaded && state.searchedList.isNotEmpty) return;

    emit(state.copyWith(status: YouTubeHomeStatus.loading));
    await _fetchData(emit);
  }

  Future<void> _onRefreshRequested(
    YouTubeHomeRefreshRequested event,
    Emitter<YouTubeHomeState> emit,
  ) async {
    emit(state.copyWith(status: YouTubeHomeStatus.loading));
    _hasLoaded = false;
    await _fetchData(emit);
  }

  Future<void> _fetchData(Emitter<YouTubeHomeState> emit) async {
    try {
      final value = await YouTubeServices.instance.getMusicHome();
      if (value.isNotEmpty) {
        _hasLoaded = true;
        final body = value['body'] ?? [];
        final head = value['head'] ?? [];
        Hive.box('cache').put('ytHome', body);
        Hive.box('cache').put('ytHomeHead', head);
        emit(state.copyWith(
          status: YouTubeHomeStatus.loaded,
          searchedList: body,
          headList: head,
        ));
      } else {
        emit(state.copyWith(status: YouTubeHomeStatus.error));
      }
    } catch (e) {
      emit(state.copyWith(status: YouTubeHomeStatus.error));
    }
  }
}
