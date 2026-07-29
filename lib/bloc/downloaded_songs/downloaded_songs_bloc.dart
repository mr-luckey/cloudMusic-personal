import 'dart:io';

import 'package:blackhole/Helpers/audio_query.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

part 'downloaded_songs_event.dart';
part 'downloaded_songs_state.dart';

class DownloadedSongsBloc
    extends Bloc<DownloadedSongsEvent, DownloadedSongsState> {
  DownloadedSongsBloc({
    OfflineAudioQuery? offlineAudioQuery,
    List<SongModel>? cachedSongs,
  })  : _offlineAudioQuery = offlineAudioQuery ?? OfflineAudioQuery(),
        super(DownloadedSongsState(
          sortValue:
              Hive.box('settings').get('sortValue', defaultValue: 1) as int,
          orderValue:
              Hive.box('settings').get('orderValue', defaultValue: 1) as int,
          tempPath:
              Hive.box('settings').get('tempDirPath')?.toString(),
        )) {
    on<DownloadedSongsLoadRequested>(_onLoadRequested);
    on<DownloadedSongsTabChanged>(_onTabChanged);
    on<DownloadedSongsSortChanged>(_onSortChanged);
    on<DownloadedSongsSongDeleted>(_onSongDeleted);
    add(DownloadedSongsLoadRequested(cachedSongs: cachedSongs));
  }

  final OfflineAudioQuery _offlineAudioQuery;

  final Map<int, SongSortType> _songSortTypes = {
    0: SongSortType.DISPLAY_NAME,
    1: SongSortType.DATE_ADDED,
    2: SongSortType.ALBUM,
    3: SongSortType.ARTIST,
    4: SongSortType.DURATION,
    5: SongSortType.SIZE,
  };

  final Map<int, OrderType> _songOrderTypes = {
    0: OrderType.ASC_OR_SMALLER,
    1: OrderType.DESC_OR_GREATER,
  };

  int get _minDuration =>
      Hive.box('settings').get('minDuration', defaultValue: 10) as int;

  bool get _includeOrExclude =>
      Hive.box('settings').get('includeOrExclude', defaultValue: false) as bool;

  List get _includedExcludedPaths => Hive.box('settings')
      .get('includedExcludedPaths', defaultValue: []) as List;

  bool _checkIncludedOrExcluded(SongModel song) {
    for (final path in _includedExcludedPaths) {
      if (song.data.contains(path.toString())) return true;
    }
    return false;
  }

  Future<void> _onLoadRequested(
    DownloadedSongsLoadRequested event,
    Emitter<DownloadedSongsState> emit,
  ) async {
    try {
      Logger.root.info('Requesting permission to access local songs');
      await _offlineAudioQuery.requestPermission();
      var tempPath = state.tempPath;
      tempPath ??= (await getTemporaryDirectory()).path;

      List<PlaylistModel> playlistDetails = [];
      if (Platform.isAndroid) {
        Logger.root.info('Getting local playlists');
        playlistDetails = await _offlineAudioQuery.getPlaylists();
      }

      List<SongModel> songs;
      if (event.cachedSongs == null) {
        Logger.root.info('Cache empty, calling audioQuery');
        final receivedSongs = await _offlineAudioQuery.getSongs(
          sortType: _songSortTypes[state.sortValue],
          orderType: _songOrderTypes[state.orderValue],
        );
        Logger.root.info('Received ${receivedSongs.length} songs, filtering');
        songs = receivedSongs
            .where(
              (i) =>
                  (i.duration ?? 60000) > 1000 * _minDuration &&
                  ((i.isMusic ?? true) ||
                      (i.isPodcast ?? false) ||
                      (i.isAudioBook ?? false)) &&
                  (_includeOrExclude
                      ? _checkIncludedOrExcluded(i)
                      : !_checkIncludedOrExcluded(i)),
            )
            .toList();
      } else {
        Logger.root.info('Setting songs to cached songs');
        songs = event.cachedSongs!;
      }

      emit(state.copyWith(
        songs: songs,
        added: true,
        tempPath: tempPath,
        playlistDetails: playlistDetails,
      ));

      Logger.root.info('got ${songs.length} songs');
      Logger.root.info('setting albums and artists');

      final albums = <String, List<SongModel>>{};
      final artists = <String, List<SongModel>>{};
      final genres = <String, List<SongModel>>{};
      final folders = <String, List<SongModel>>{};
      final sortedAlbumKeysList = <String>[];
      final sortedArtistKeysList = <String>[];
      final sortedGenreKeysList = <String>[];
      final sortedFolderKeysList = <String>[];

      for (final song in songs) {
        try {
          final albumKey = song.album ?? 'Unknown';
          if (albums.containsKey(albumKey)) {
            albums[albumKey]!.add(song);
          } else {
            albums[albumKey] = [song];
            sortedAlbumKeysList.add(albumKey);
          }

          final artistKey = song.artist ?? 'Unknown';
          if (artists.containsKey(artistKey)) {
            artists[artistKey]!.add(song);
          } else {
            artists[artistKey] = [song];
            sortedArtistKeysList.add(artistKey);
          }

          final genreKey = song.genre ?? 'Unknown';
          if (genres.containsKey(genreKey)) {
            genres[genreKey]!.add(song);
          } else {
            genres[genreKey] = [song];
            sortedGenreKeysList.add(genreKey);
          }

          final tempPathParts = song.data.split('/');
          tempPathParts.removeLast();
          final dirPath = tempPathParts.join('/');

          if (folders.containsKey(dirPath)) {
            folders[dirPath]!.add(song);
          } else {
            folders[dirPath] = [song];
            sortedFolderKeysList.add(dirPath);
          }
        } catch (e) {
          Logger.root.severe('Error in sorting songs', e);
        }
      }

      emit(state.copyWith(
        albums: albums,
        artists: artists,
        genres: genres,
        folders: folders,
        sortedAlbumKeysList: sortedAlbumKeysList,
        sortedArtistKeysList: sortedArtistKeysList,
        sortedGenreKeysList: sortedGenreKeysList,
        sortedFolderKeysList: sortedFolderKeysList,
      ));
      Logger.root.info('albums, artists, genre & folders set');
    } catch (e) {
      Logger.root.severe('Error in getData', e);
      emit(state.copyWith(added: true));
    }
  }

  void _onTabChanged(
    DownloadedSongsTabChanged event,
    Emitter<DownloadedSongsState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  Future<void> _onSortChanged(
    DownloadedSongsSortChanged event,
    Emitter<DownloadedSongsState> emit,
  ) async {
    Hive.box('settings').put('sortValue', event.sortValue);
    Hive.box('settings').put('orderValue', event.orderValue);
    final songs = List<SongModel>.from(state.songs);
    _sortSongs(songs, event.sortValue, event.orderValue);
    emit(state.copyWith(
      songs: songs,
      sortValue: event.sortValue,
      orderValue: event.orderValue,
    ));
  }

  void _sortSongs(List<SongModel> songs, int sortVal, int order) {
    Logger.root.info('Sorting songs');
    switch (sortVal) {
      case 0:
        songs.sort((a, b) => a.displayName.compareTo(b.displayName));
      case 1:
        songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
      case 2:
        songs.sort((a, b) => a.album.toString().compareTo(b.album.toString()));
      case 3:
        songs.sort(
          (a, b) => a.artist.toString().compareTo(b.artist.toString()),
        );
      case 4:
        songs.sort(
          (a, b) => a.duration.toString().compareTo(b.duration.toString()),
        );
      case 5:
        songs.sort((a, b) => a.size.toString().compareTo(b.size.toString()));
      default:
        songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
    }
    if (order == 1) {
      final reversed = songs.reversed.toList();
      songs
        ..clear()
        ..addAll(reversed);
    }
    Logger.root.info('Done Sorting songs');
  }

  Future<void> _onSongDeleted(
    DownloadedSongsSongDeleted event,
    Emitter<DownloadedSongsState> emit,
  ) async {
    final song = event.song;
    final audioFile = File(song.data);
    final albums = Map<String, List<SongModel>>.from(state.albums);
    final artists = Map<String, List<SongModel>>.from(state.artists);
    final genres = Map<String, List<SongModel>>.from(state.genres);
    final folders = Map<String, List<SongModel>>.from(state.folders);
    final sortedAlbumKeysList = List<String>.from(state.sortedAlbumKeysList);
    final sortedArtistKeysList = List<String>.from(state.sortedArtistKeysList);
    final sortedGenreKeysList = List<String>.from(state.sortedGenreKeysList);
    final sortedFolderKeysList = List<String>.from(state.sortedFolderKeysList);
    final songs = List<SongModel>.from(state.songs);

    if (albums[song.album]!.length == 1) {
      sortedAlbumKeysList.remove(song.album);
    }
    albums[song.album]!.remove(song);

    if (artists[song.artist]!.length == 1) {
      sortedArtistKeysList.remove(song.artist);
    }
    artists[song.artist]!.remove(song);

    if (genres[song.genre]!.length == 1) {
      sortedGenreKeysList.remove(song.genre);
    }
    genres[song.genre]!.remove(song);

    if (folders[audioFile.parent.path]!.length == 1) {
      sortedFolderKeysList.remove(audioFile.parent.path);
    }
    folders[audioFile.parent.path]!.remove(song);

    songs.remove(song);

    await audioFile.delete();
    emit(state.copyWith(
      songs: songs,
      albums: albums,
      artists: artists,
      genres: genres,
      folders: folders,
      sortedAlbumKeysList: sortedAlbumKeysList,
      sortedArtistKeysList: sortedArtistKeysList,
      sortedGenreKeysList: sortedGenreKeysList,
      sortedFolderKeysList: sortedFolderKeysList,
    ));
  }
}
