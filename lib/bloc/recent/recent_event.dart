part of 'recent_bloc.dart';

abstract class RecentEvent extends Equatable {
  const RecentEvent();

  @override
  List<Object?> get props => [];
}

class RecentLoadRequested extends RecentEvent {
  const RecentLoadRequested();
}

class RecentClearAll extends RecentEvent {
  const RecentClearAll();
}

class RecentSongDismissed extends RecentEvent {
  final int index;

  const RecentSongDismissed({required this.index});

  @override
  List<Object?> get props => [index];
}
