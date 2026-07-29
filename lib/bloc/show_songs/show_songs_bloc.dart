import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'show_songs_event.dart';
part 'show_songs_state.dart';

class ShowSongsBloc extends Bloc<ShowSongsEvent, ShowSongsState> {
  ShowSongsBloc()
      : super(ShowSongsState(
          sortValue:
              Hive.box('settings').get('sortValue', defaultValue: 1) as int,
          orderValue:
              Hive.box('settings').get('orderValue', defaultValue: 1) as int,
        )) {
    on<ShowSongsLoadRequested>(_onLoadRequested);
    on<ShowSongsSortChanged>(_onSortChanged);
  }

  void _onLoadRequested(
    ShowSongsLoadRequested event,
    Emitter<ShowSongsState> emit,
  ) {
    final songs = List.from(event.data);
    final original = event.offline ? <dynamic>[] : List.from(songs);
    final sortedSongs = _sortSongs(
      songs: songs,
      sortVal: state.sortValue,
      order: state.orderValue,
    );
    emit(state.copyWith(
      songs: sortedSongs,
      original: original,
      offline: event.offline,
      isProcessed: true,
    ));
  }

  void _onSortChanged(
    ShowSongsSortChanged event,
    Emitter<ShowSongsState> emit,
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

    emit(state.copyWith(
      sortValue: sortValue,
      orderValue: orderValue,
      songs: _sortSongs(
        songs: List.from(state.songs),
        sortVal: sortValue,
        order: orderValue,
      ),
    ));
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
}
