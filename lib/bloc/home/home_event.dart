part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeTabSelected extends HomeEvent {
  final int index;

  const HomeTabSelected(this.index);

  @override
  List<Object?> get props => [index];
}

class HomeSettingsUpdated extends HomeEvent {
  const HomeSettingsUpdated();
}
