import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_screen_event.dart';
part 'home_screen_state.dart';

class HomeScreenBloc extends Bloc<HomeScreenEvent, HomeScreenState> {
  HomeScreenBloc() : super(const HomeScreenState()) {
    on<HomeScreenNameUpdated>(_onNameUpdated);
  }

  void _onNameUpdated(
    HomeScreenNameUpdated event,
    Emitter<HomeScreenState> emit,
  ) {
    emit(HomeScreenState(name: event.name));
  }
}
