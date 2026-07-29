import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({required Locale initialLocale})
      : super(AppState(locale: initialLocale)) {
    on<AppLocaleChanged>(_onLocaleChanged);
    on<AppThemeChanged>(_onThemeChanged);
  }

  void _onLocaleChanged(AppLocaleChanged event, Emitter<AppState> emit) {
    emit(state.copyWith(locale: event.locale));
  }

  void _onThemeChanged(AppThemeChanged event, Emitter<AppState> emit) {
    emit(state.copyWith(themeRevision: state.themeRevision + 1));
  }
}
