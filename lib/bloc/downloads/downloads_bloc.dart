import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

part 'downloads_event.dart';
part 'downloads_state.dart';

class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  DownloadsBloc()
      : _downloadsBox = Hive.box('downloads'),
        super(DownloadsState(
          sortValue:
              Hive.box('settings').get('sortValue', defaultValue: 1) as int,
          orderValue:
              Hive.box('settings').get('orderValue', defaultValue: 1) as int,
          albumSortValue: Hive.box('settings')
              .get('albumSortValue', defaultValue: 2) as int,
        )) {
    on<DownloadsLoadRequested>(_onLoadRequested);
    on<DownloadsSongsSorted>(_onSongsSorted);
    on<DownloadsSongDeleted>(_onSongDeleted);
    on<DownloadsSongUpdated>(_onSongUpdated);
    on<DownloadsTabIndexChanged>(_onTabIndexChanged);
    on<DownloadsSnackbarShown>(_onSnackbarShown);

    add(const DownloadsLoadRequested());
  }

  final Box _downloadsBox;

  Future<void> _onLoadRequested(
    DownloadsLoadRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    final songs = List.from(_downloadsBox.values.toList());
    emit(_buildLoadedState(songs));
  }

  void _onSongsSorted(
    DownloadsSongsSorted event,
    Emitter<DownloadsState> emit,
  ) {
    var sortValue = state.sortValue;
    var orderValue = state.orderValue;

    if (event.value < 5) {
      sortValue = event.value;
      Hive.box('settings').put('sortValue', sortValue);
    } else {
      orderValue = event.value - 5;
      Hive.box('settings').put('orderValue', orderValue);
    }

    final songs = _sortSongs(
      songs: List.from(state.songs),
      sortVal: sortValue,
      order: orderValue,
    );

    emit(state.copyWith(
      songs: songs,
      sortValue: sortValue,
      orderValue: orderValue,
    ));
  }

  Future<void> _onSongDeleted(
    DownloadsSongDeleted event,
    Emitter<DownloadsState> emit,
  ) async {
    final song = event.song;
    await _downloadsBox.delete(song['id']);
    final audioFile = File(song['path'].toString());
    final imageFile = File(song['image'].toString());

    final albums = Map<String, List<Map>>.from(
      state.albums.map((key, value) => MapEntry(key, List<Map>.from(value))),
    );
    final artists = Map<String, List<Map>>.from(
      state.artists.map((key, value) => MapEntry(key, List<Map>.from(value))),
    );
    final genres = Map<String, List<Map>>.from(
      state.genres.map((key, value) => MapEntry(key, List<Map>.from(value))),
    );
    final sortedAlbumKeysList = List.from(state.sortedAlbumKeysList);
    final sortedArtistKeysList = List.from(state.sortedArtistKeysList);
    final sortedGenreKeysList = List.from(state.sortedGenreKeysList);
    final songs = List.from(state.songs);

    if (albums[song['album']]!.length == 1) {
      sortedAlbumKeysList.remove(song['album']);
    }
    albums[song['album']]!.remove(song);

    if (artists[song['artist']]!.length == 1) {
      sortedArtistKeysList.remove(song['artist']);
    }
    artists[song['artist']]!.remove(song);

    if (genres[song['genre']]!.length == 1) {
      sortedGenreKeysList.remove(song['genre']);
    }
    genres[song['genre']]!.remove(song);

    songs.remove(song);

    String? snackbarMessage;
    bool snackbarIsError = false;

    try {
      await audioFile.delete();
      if (await imageFile.exists()) {
        imageFile.delete();
      }
      snackbarMessage = 'deleted:${song['title']}';
    } catch (e) {
      Logger.root.severe('Failed to delete $audioFile.path', e);
      snackbarMessage = 'failed:${audioFile.path}:$e';
      snackbarIsError = true;
    }

    emit(state.copyWith(
      songs: songs,
      albums: albums,
      artists: artists,
      genres: genres,
      sortedAlbumKeysList: sortedAlbumKeysList,
      sortedArtistKeysList: sortedArtistKeysList,
      sortedGenreKeysList: sortedGenreKeysList,
      snackbarMessage: snackbarMessage,
      snackbarIsError: snackbarIsError,
    ));
  }

  void _onSongUpdated(
    DownloadsSongUpdated event,
    Emitter<DownloadsState> emit,
  ) {
    final songs = List.from(state.songs);
    songs[event.index] = event.song;
    emit(state.copyWith(songs: songs));
  }

  void _onTabIndexChanged(
    DownloadsTabIndexChanged event,
    Emitter<DownloadsState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.index));
  }

  void _onSnackbarShown(
    DownloadsSnackbarShown event,
    Emitter<DownloadsState> emit,
  ) {
    emit(state.copyWith(clearSnackbar: true));
  }

  DownloadsState _buildLoadedState(List songs) {
    final albums = <String, List<Map>>{};
    final artists = <String, List<Map>>{};
    final genres = <String, List<Map>>{};

    for (final element in songs) {
      try {
        if (albums.containsKey(element['album'])) {
          final List<Map> tempAlbum = albums[element['album']]!;
          tempAlbum.add(element as Map);
          albums.addEntries([MapEntry(element['album'].toString(), tempAlbum)]);
        } else {
          albums.addEntries([
            MapEntry(element['album'].toString(), [element as Map]),
          ]);
        }

        if (artists.containsKey(element['artist'])) {
          final List<Map> tempArtist = artists[element['artist']]!;
          tempArtist.add(element);
          artists
              .addEntries([MapEntry(element['artist'].toString(), tempArtist)]);
        } else {
          artists.addEntries([
            MapEntry(element['artist'].toString(), [element]),
          ]);
        }

        if (genres.containsKey(element['genre'])) {
          final List<Map> tempGenre = genres[element['genre']]!;
          tempGenre.add(element);
          genres
              .addEntries([MapEntry(element['genre'].toString(), tempGenre)]);
        } else {
          genres.addEntries([
            MapEntry(element['genre'].toString(), [element]),
          ]);
        }
      } catch (e) {
        Logger.root.severe('Error while setting artist and album: $e');
      }
    }

    final sortedSongs = _sortSongs(
      songs: List.from(songs),
      sortVal: state.sortValue,
      order: state.orderValue,
    );

    var sortedAlbumKeysList = albums.keys.cast<String>().toList();
    var sortedArtistKeysList = artists.keys.cast<String>().toList();
    var sortedGenreKeysList = genres.keys.cast<String>().toList();

    sortedAlbumKeysList = _sortAlbumKeys(
      sortedAlbumKeysList,
      albums,
      artists,
      genres,
      state.albumSortValue,
      type: 'album',
    );
    sortedArtistKeysList = _sortAlbumKeys(
      sortedArtistKeysList,
      albums,
      artists,
      genres,
      state.albumSortValue,
      type: 'artist',
    );
    sortedGenreKeysList = _sortAlbumKeys(
      sortedGenreKeysList,
      albums,
      artists,
      genres,
      state.albumSortValue,
      type: 'genre',
    );

    return state.copyWith(
      isLoaded: true,
      songs: sortedSongs,
      albums: albums,
      artists: artists,
      genres: genres,
      sortedAlbumKeysList: sortedAlbumKeysList,
      sortedArtistKeysList: sortedArtistKeysList,
      sortedGenreKeysList: sortedGenreKeysList,
    );
  }

  List _sortSongs({
    required List songs,
    required int sortVal,
    required int order,
  }) {
    switch (sortVal) {
      case 0:
        songs.sort(
          (a, b) => a['title']
              .toString()
              .toUpperCase()
              .compareTo(b['title'].toString().toUpperCase()),
        );
      case 1:
        songs.sort(
          (a, b) => a['dateAdded']
              .toString()
              .toUpperCase()
              .compareTo(b['dateAdded'].toString().toUpperCase()),
        );
      case 2:
        songs.sort(
          (a, b) => a['album']
              .toString()
              .toUpperCase()
              .compareTo(b['album'].toString().toUpperCase()),
        );
      case 3:
        songs.sort(
          (a, b) => a['artist']
              .toString()
              .toUpperCase()
              .compareTo(b['artist'].toString().toUpperCase()),
        );
      case 4:
        songs.sort(
          (a, b) => a['duration']
              .toString()
              .toUpperCase()
              .compareTo(b['duration'].toString().toUpperCase()),
        );
      default:
        songs.sort(
          (b, a) => a['dateAdded']
              .toString()
              .toUpperCase()
              .compareTo(b['dateAdded'].toString().toUpperCase()),
        );
        break;
    }

    if (order == 1) {
      return songs.reversed.toList();
    }
    return songs;
  }

  List<String> _sortAlbumKeys(
    List<String> keys,
    Map<String, List<Map>> albums,
    Map<String, List<Map>> artists,
    Map<String, List<Map>> genres,
    int albumSortValue, {
    required String type,
  }) {
    final sortedKeys = List.from(keys);
    final map = type == 'album'
        ? albums
        : type == 'artist'
            ? artists
            : genres;

    switch (albumSortValue) {
      case 0:
        sortedKeys.sort(
          (a, b) =>
              a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
        );
      case 1:
        sortedKeys.sort(
          (b, a) =>
              a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
        );
      case 2:
        sortedKeys
            .sort((b, a) => map[a]!.length.compareTo(map[b]!.length));
      case 3:
        sortedKeys
            .sort((a, b) => map[a]!.length.compareTo(map[b]!.length));
      default:
        sortedKeys
            .sort((b, a) => map[a]!.length.compareTo(map[b]!.length));
        break;
    }
    return sortedKeys.cast<String>();
  }
}
