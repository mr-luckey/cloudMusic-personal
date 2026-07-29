import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

part 'downloaded_songs_desktop_event.dart';
part 'downloaded_songs_desktop_state.dart';

class DownloadedSongsDesktopBloc
    extends Bloc<DownloadedSongsDesktopEvent, DownloadedSongsDesktopState> {
  DownloadedSongsDesktopBloc({
    OnAudioQuery? audioQuery,
    List<Map>? cachedSongs,
  })  : _audioQuery = audioQuery ?? OnAudioQuery(),
        super(DownloadedSongsDesktopState(
          tempPath:
              Hive.box('settings').get('tempDirPath')?.toString(),
        )) {
    on<DownloadedSongsDesktopLoadRequested>(_onLoadRequested);
    on<DownloadedSongsDesktopSongsLoaded>(_onSongsLoaded);
    add(DownloadedSongsDesktopLoadRequested(cachedSongs: cachedSongs));
  }

  final OnAudioQuery _audioQuery;

  Future<void> _onLoadRequested(
    DownloadedSongsDesktopLoadRequested event,
    Emitter<DownloadedSongsDesktopState> emit,
  ) async {
    var tempPath = state.tempPath;
    tempPath ??= (await getTemporaryDirectory()).path;

    if (event.cachedSongs == null) {
      emit(state.copyWith(tempPath: tempPath));
      final songModels = await _audioQuery.querySongs();
      final songs = songModels
          .map(
            (song) => {
              'id': song.id.toString(),
              'title': '',
              'artist': '',
              'album': '',
              'image': '',
              'year': '',
              'path': '',
            },
          )
          .toList();
      add(DownloadedSongsDesktopSongsLoaded(songs));
    } else {
      emit(state.copyWith(
        songs: event.cachedSongs!,
        added: true,
        tempPath: tempPath,
      ));
    }
  }

  void _onSongsLoaded(
    DownloadedSongsDesktopSongsLoaded event,
    Emitter<DownloadedSongsDesktopState> emit,
  ) {
    emit(state.copyWith(songs: event.songs, added: true));
  }
}
