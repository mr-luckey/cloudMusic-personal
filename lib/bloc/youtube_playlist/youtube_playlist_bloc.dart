import 'package:blackhole/Services/player_service.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:blackhole/Services/yt_music.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

part 'youtube_playlist_event.dart';
part 'youtube_playlist_state.dart';

class YouTubePlaylistBloc
    extends Bloc<YouTubePlaylistEvent, YouTubePlaylistState> {
  YouTubePlaylistBloc() : super(const YouTubePlaylistState()) {
    on<YouTubePlaylistLoadRequested>(_onLoadRequested);
    on<YouTubePlaylistSongTapped>(_onSongTapped);
    on<YouTubePlaylistPlayAllTapped>(_onPlayAllTapped);
    on<YouTubePlaylistShuffleTapped>(_onShuffleTapped);
    on<YouTubePlaylistLoadingFinished>(_onLoadingFinished);
  }

  Future<void> _onLoadRequested(
    YouTubePlaylistLoadRequested event,
    Emitter<YouTubePlaylistState> emit,
  ) async {
    emit(state.copyWith(status: YouTubePlaylistStatus.loading));
    try {
      Map value;
      switch (event.type) {
        case 'album':
          value = await YtMusicService().getAlbumDetails(event.playlistId);
        case 'artist':
          value = await YtMusicService().getArtistDetails(event.playlistId);
        default:
          value = await YtMusicService().getPlaylistDetails(event.playlistId);
      }
      emit(state.copyWith(
        status: YouTubePlaylistStatus.loaded,
        searchedList: (value['songs'] as List<Map>?) ?? [],
        playlistName: (value['name'] as String?) ?? '',
        playlistSubtitle: (value['subtitle'] as String?) ?? '',
        playlistSecondarySubtitle: value['description'] as String?,
        playlistImage: ((value['images'] as List?)?.last as String?) ?? '',
      ));
    } catch (e) {
      Logger.root.severe('Error fetching playlist details', e);
      emit(state.copyWith(status: YouTubePlaylistStatus.loaded));
    }
  }

  Future<void> _onSongTapped(
    YouTubePlaylistSongTapped event,
    Emitter<YouTubePlaylistState> emit,
  ) async {
    PlayerInvoke.beginPreparing();
    emit(state.copyWith(isProcessing: true));
    try {
      final response = await YouTubeServices.instance.formatVideoFromId(
        id: event.entry['id'].toString(),
        data: event.entry,
      );
      if (response == null) {
        PlayerInvoke.endPreparing();
      }
      emit(state.copyWith(
        isProcessing: false,
        formattedResponse: response,
      ));
    } catch (e) {
      PlayerInvoke.endPreparing();
      emit(state.copyWith(isProcessing: false));
    }
  }

  Future<void> _onPlayAllTapped(
    YouTubePlaylistPlayAllTapped event,
    Emitter<YouTubePlaylistState> emit,
  ) async {
    PlayerInvoke.beginPreparing();
    emit(state.copyWith(isProcessing: true));
    try {
      final response = await YouTubeServices.instance.formatVideoFromId(
        id: state.searchedList.first['id'].toString(),
        data: state.searchedList.first,
      );
      final List<Map> playList = List.from(state.searchedList);
      if (response != null) playList[0] = response;
      emit(state.copyWith(
        isProcessing: false,
        formattedPlayList: playList,
        playAllTriggered: true,
      ));
    } catch (e) {
      PlayerInvoke.endPreparing();
      emit(state.copyWith(isProcessing: false));
    }
  }

  Future<void> _onShuffleTapped(
    YouTubePlaylistShuffleTapped event,
    Emitter<YouTubePlaylistState> emit,
  ) async {
    PlayerInvoke.beginPreparing();
    emit(state.copyWith(isProcessing: true));
    try {
      final List<Map> playList = List.from(state.searchedList);
      playList.shuffle();
      final response = await YouTubeServices.instance.formatVideoFromId(
        id: playList.first['id'].toString(),
        data: playList.first,
      );
      if (response != null) playList[0] = response;
      emit(state.copyWith(
        isProcessing: false,
        formattedPlayList: playList,
        shuffleTriggered: true,
      ));
    } catch (e) {
      PlayerInvoke.endPreparing();
      emit(state.copyWith(isProcessing: false));
    }
  }

  void _onLoadingFinished(
    YouTubePlaylistLoadingFinished event,
    Emitter<YouTubePlaylistState> emit,
  ) {
    emit(state.copyWith(
      playAllTriggered: false,
      shuffleTriggered: false,
      formattedResponse: null,
      formattedPlayList: null,
    ));
  }
}
