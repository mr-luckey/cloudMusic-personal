import 'package:blackhole/Helpers/songs_count.dart' as songs_count;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'liked_event.dart';
part 'liked_state.dart';

class LikedBloc extends Bloc<LikedEvent, LikedState> {
  LikedBloc({
    required String playlistName,
    bool fromPlaylist = false,
    List? songs,
  })  : _playlistName = playlistName,
        _fromPlaylist = fromPlaylist,
        _initialSongs = songs,
        super(LikedState(
          sortValue:
              Hive.box('settings').get('sortValue', defaultValue: 1) as int,
          orderValue:
              Hive.box('settings').get('orderValue', defaultValue: 1) as int,
          albumSortValue: Hive.box('settings')
              .get('albumSortValue', defaultValue: 2) as int,
        )) {
    on<LikedLoadRequested>(_onLoadRequested);
    on<LikedSongDeleted>(_onSongDeleted);
    on<LikedSongsSorted>(_onSongsSorted);
    on<LikedSongsReordered>(_onSongsReordered);
    on<LikedTabIndexChanged>(_onTabIndexChanged);
    on<LikedSelectionChanged>(_onSelectionChanged);

    add(const LikedLoadRequested());
  }

  final String _playlistName;
  final bool _fromPlaylist;
  final List? _initialSongs;
  Box? _likedBox;

  void _onLoadRequested(
    LikedLoadRequested event,
    Emitter<LikedState> emit,
  ) {
    _likedBox = Hive.box(_playlistName);
    List songs;
    if (_fromPlaylist) {
      songs = List.from(_initialSongs!);
    } else {
      songs = List.from(_likedBox?.values.toList() ?? []);
      songs_count.addSongsCount(
        _playlistName,
        songs.length,
        songs.length >= 4 ? songs.sublist(0, 4) : songs.sublist(0, songs.length),
      );
    }
    emit(_buildLoadedState(songs));
  }

  void _onSongDeleted(LikedSongDeleted event, Emitter<LikedState> emit) {
    final song = event.song;
    _likedBox!.delete(song['id']);

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

    song['artist'].toString().split(', ').forEach((singleArtist) {
      if (artists[singleArtist]!.length == 1) {
        sortedArtistKeysList.remove(singleArtist);
      }
      artists[singleArtist]!.remove(song);
    });

    if (genres[song['genre']]!.length == 1) {
      sortedGenreKeysList.remove(song['genre']);
    }
    genres[song['genre']]!.remove(song);

    songs.remove(song);
    songs_count.addSongsCount(
      _playlistName,
      songs.length,
      songs.length >= 4 ? songs.sublist(0, 4) : songs.sublist(0, songs.length),
    );

    emit(state.copyWith(
      songs: songs,
      albums: albums,
      artists: artists,
      genres: genres,
      sortedAlbumKeysList: sortedAlbumKeysList,
      sortedArtistKeysList: sortedArtistKeysList,
      sortedGenreKeysList: sortedGenreKeysList,
    ));
  }

  void _onSongsSorted(LikedSongsSorted event, Emitter<LikedState> emit) {
    var sortValue = state.sortValue;
    var orderValue = state.orderValue;

    if (event.sortVal != null) {
      sortValue = event.sortVal!;
      Hive.box('settings').put('sortValue', sortValue);
    }
    if (event.orderVal != null) {
      orderValue = event.orderVal!;
      Hive.box('settings').put('orderValue', orderValue);
    } else if (event.value != null) {
      if (event.value! < 5) {
        sortValue = event.value!;
        Hive.box('settings').put('sortValue', sortValue);
      } else {
        orderValue = event.value! - 5;
        Hive.box('settings').put('orderValue', orderValue);
      }
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

  void _onSongsReordered(
    LikedSongsReordered event,
    Emitter<LikedState> emit,
  ) {
    final songs = List.from(state.songs);
    var newIndex = event.newIndex;
    if (newIndex > event.oldIndex) {
      newIndex -= 1;
    }
    final item = songs.removeAt(event.oldIndex);
    songs.insert(newIndex, item);

    final newOrder = songs.map((e) => e['id']).toList();
    Hive.box('settings').put('order_$_playlistName', newOrder);

    final sortedSongs = _sortSongs(songs: songs, sortVal: -1, order: 0);
    emit(state.copyWith(
      songs: sortedSongs,
      sortValue: -1,
      orderValue: 0,
    ));
  }

  void _onTabIndexChanged(
    LikedTabIndexChanged event,
    Emitter<LikedState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.index));
  }

  void _onSelectionChanged(
    LikedSelectionChanged event,
    Emitter<LikedState> emit,
  ) {
    emit(state.copyWith(selectionRevision: state.selectionRevision + 1));
  }

  LikedState _buildLoadedState(List songs) {
    final albums = <String, List<Map>>{};
    final artists = <String, List<Map>>{};
    final genres = <String, List<Map>>{};

    for (final element in songs) {
      if (albums.containsKey(element['album'])) {
        final List<Map> tempAlbum = albums[element['album']]!;
        tempAlbum.add(element as Map);
        albums.addEntries([MapEntry(element['album'].toString(), tempAlbum)]);
      } else {
        albums.addEntries([
          MapEntry(element['album'].toString(), [element as Map]),
        ]);
      }

      element['artist'].toString().split(', ').forEach((singleArtist) {
        if (artists.containsKey(singleArtist)) {
          final List<Map> tempArtist = artists[singleArtist]!;
          tempArtist.add(element);
          artists.addEntries([MapEntry(singleArtist, tempArtist)]);
        } else {
          artists.addEntries([
            MapEntry(singleArtist, [element]),
          ]);
        }
      });

      if (genres.containsKey(element['genre'])) {
        final List<Map> tempGenre = genres[element['genre']]!;
        tempGenre.add(element);
        genres.addEntries([MapEntry(element['genre'].toString(), tempGenre)]);
      } else {
        genres.addEntries([
          MapEntry(element['genre'].toString(), [element]),
        ]);
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
      case -1:
        final List orderList = Hive.box('settings')
            .get('order_$_playlistName', defaultValue: []) as List;
        final keyIndices = Map.fromIterables(
          orderList,
          List.generate(orderList.length, (index) => index),
        );

        songs.sort((a, b) {
          final aIndex = keyIndices[a['id']];
          final bIndex = keyIndices[b['id']];

          if (aIndex != null && bIndex != null) {
            return aIndex.compareTo(bIndex);
          } else if (aIndex != null) {
            return 1;
          } else if (bIndex != null) {
            return -1;
          } else {
            return 0;
          }
        });
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

    if (albumSortValue == 0) {
      sortedKeys.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
    }
    if (albumSortValue == 1) {
      sortedKeys.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
    }
    if (albumSortValue == 2) {
      sortedKeys.sort((b, a) => map[a]!.length.compareTo(map[b]!.length));
    }
    if (albumSortValue == 3) {
      sortedKeys.sort((a, b) => map[a]!.length.compareTo(map[b]!.length));
    }
    if (albumSortValue == 4) {
      sortedKeys.shuffle();
    }
    return sortedKeys.cast<String>();
  }
}
