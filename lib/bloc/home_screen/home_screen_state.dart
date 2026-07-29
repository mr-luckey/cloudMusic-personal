part of 'home_screen_bloc.dart';

class HomeScreenState extends Equatable {
  final String name;

  const HomeScreenState({this.name = ''});

  HomeScreenState copyWith({String? name}) {
    return HomeScreenState(name: name ?? this.name);
  }

  @override
  List<Object?> get props => [name];
}
