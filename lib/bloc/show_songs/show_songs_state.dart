part of 'show_songs_bloc.dart';

class ShowSongsState extends Equatable {
  final List songs;
  final List original;
  final bool offline;
  final bool isProcessed;
  final int sortValue;
  final int orderValue;

  const ShowSongsState({
    this.songs = const [],
    this.original = const [],
    this.offline = false,
    this.isProcessed = false,
    this.sortValue = 1,
    this.orderValue = 1,
  });

  ShowSongsState copyWith({
    List? songs,
    List? original,
    bool? offline,
    bool? isProcessed,
    int? sortValue,
    int? orderValue,
  }) {
    return ShowSongsState(
      songs: songs ?? this.songs,
      original: original ?? this.original,
      offline: offline ?? this.offline,
      isProcessed: isProcessed ?? this.isProcessed,
      sortValue: sortValue ?? this.sortValue,
      orderValue: orderValue ?? this.orderValue,
    );
  }

  @override
  List<Object?> get props =>
      [songs, original, offline, isProcessed, sortValue, orderValue];
}
