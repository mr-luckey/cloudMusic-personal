part of 'home_screen_bloc.dart';

abstract class HomeScreenEvent extends Equatable {
  const HomeScreenEvent();

  @override
  List<Object?> get props => [];
}

class HomeScreenNameUpdated extends HomeScreenEvent {
  final String name;

  const HomeScreenNameUpdated(this.name);

  @override
  List<Object?> get props => [name];
}
