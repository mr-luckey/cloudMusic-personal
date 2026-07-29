part of 'show_songs_bloc.dart';

abstract class ShowSongsEvent extends Equatable {
  const ShowSongsEvent();

  @override
  List<Object?> get props => [];
}

class ShowSongsLoadRequested extends ShowSongsEvent {
  final List data;
  final bool offline;

  const ShowSongsLoadRequested({
    required this.data,
    required this.offline,
  });

  @override
  List<Object?> get props => [data, offline];
}

class ShowSongsSortChanged extends ShowSongsEvent {
  final int value;

  const ShowSongsSortChanged({required this.value});

  @override
  List<Object?> get props => [value];
}
