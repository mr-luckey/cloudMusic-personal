import 'package:blackhole/Services/yt_music.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

part 'youtube_artist_event.dart';
part 'youtube_artist_state.dart';

class YouTubeArtistBloc extends Bloc<YouTubeArtistEvent, YouTubeArtistState> {
  YouTubeArtistBloc() : super(const YouTubeArtistState()) {
    on<YouTubeArtistLoadRequested>(_onLoadRequested);
    on<YouTubeArtistSongTapStarted>(_onSongTapStarted);
    on<YouTubeArtistSongTapFinished>(_onSongTapFinished);
  }

  Future<void> _onLoadRequested(
    YouTubeArtistLoadRequested event,
    Emitter<YouTubeArtistState> emit,
  ) async {
    try {
      final value = await YtMusicService().getArtistDetails(event.artistId);
      emit(state.copyWith(
        data: value,
        searchedList: value['songs'] as List<Map>,
        artistName: value['name'] as String? ?? '',
        artistSubtitle: value['subtitle'] as String? ?? '',
        artistImage: value['images']?.last as String? ?? '',
        fetched: true,
      ));
    } catch (e) {
      Logger.root.severe('Error in fetching artist details', e);
      emit(state.copyWith(fetched: true));
    }
  }

  void _onSongTapStarted(
    YouTubeArtistSongTapStarted event,
    Emitter<YouTubeArtistState> emit,
  ) {
    emit(state.copyWith(done: false));
  }

  void _onSongTapFinished(
    YouTubeArtistSongTapFinished event,
    Emitter<YouTubeArtistState> emit,
  ) {
    emit(state.copyWith(done: true));
  }
}
