part of 'liked_bloc.dart';

abstract class LikedEvent extends Equatable {
  const LikedEvent();

  @override
  List<Object?> get props => [];
}

class LikedLoadRequested extends LikedEvent {
  const LikedLoadRequested();
}

class LikedSongDeleted extends LikedEvent {
  final Map song;

  const LikedSongDeleted({required this.song});

  @override
  List<Object?> get props => [song];
}

class LikedSongsSorted extends LikedEvent {
  final int? value;
  final int? sortVal;
  final int? orderVal;

  const LikedSongsSorted({this.value, this.sortVal, this.orderVal});

  @override
  List<Object?> get props => [value, sortVal, orderVal];
}

class LikedSongsReordered extends LikedEvent {
  final int oldIndex;
  final int newIndex;

  const LikedSongsReordered({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class LikedTabIndexChanged extends LikedEvent {
  final int index;

  const LikedTabIndexChanged({required this.index});

  @override
  List<Object?> get props => [index];
}

class LikedSelectionChanged extends LikedEvent {
  const LikedSelectionChanged();
}
