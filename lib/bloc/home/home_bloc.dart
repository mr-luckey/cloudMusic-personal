import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeState.initial()) {
    on<HomeTabSelected>(_onTabSelected);
    on<HomeSettingsUpdated>(_onSettingsUpdated);
  }

  void _onTabSelected(
    HomeTabSelected event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(selectedIndex: event.index));
  }

  void _onSettingsUpdated(
    HomeSettingsUpdated event,
    Emitter<HomeState> emit,
  ) {
    final sectionsToShow = Hive.box('settings').get(
      'sectionsToShow',
      defaultValue: ['Home', 'YouTube', 'Library', 'Settings'],
    ) as List;
    emit(
      state.copyWith(
        sectionsToShow: List.from(sectionsToShow),
        selectedIndex: 0,
      ),
    );
  }
}
