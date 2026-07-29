import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'theme_settings_event.dart';
part 'theme_settings_state.dart';

class ThemeSettingsBloc extends Bloc<ThemeSettingsEvent, ThemeSettingsState> {
  ThemeSettingsBloc() : super(ThemeSettingsState.initial()) {
    on<ThemeAccentColorUpdated>(_onAccentColorUpdated);
    on<ThemeCanvasColorUpdated>(_onCanvasColorUpdated);
    on<ThemeCardColorUpdated>(_onCardColorUpdated);
    on<ThemeSwitchToCustom>(_onSwitchToCustom);
    on<ThemeSelectionUpdated>(_onThemeSelectionUpdated);
    on<ThemeDeleted>(_onThemeDeleted);
    on<ThemeSaved>(_onThemeSaved);
    on<ThemeUiRefreshed>(_onUiRefreshed);
    on<ThemeAmoledApplied>(_onAmoledApplied);
  }

  void _onAccentColorUpdated(
    ThemeAccentColorUpdated event,
    Emitter<ThemeSettingsState> emit,
  ) {
    emit(state.copyWith(
      themeColor: event.themeColor,
      colorHue: event.colorHue,
    ));
  }

  void _onCanvasColorUpdated(
    ThemeCanvasColorUpdated event,
    Emitter<ThemeSettingsState> emit,
  ) {
    emit(state.copyWith(canvasColor: event.canvasColor));
  }

  void _onCardColorUpdated(
    ThemeCardColorUpdated event,
    Emitter<ThemeSettingsState> emit,
  ) {
    emit(state.copyWith(cardColor: event.cardColor));
  }

  void _onSwitchToCustom(
    ThemeSwitchToCustom event,
    Emitter<ThemeSettingsState> emit,
  ) {
    emit(state.copyWith(theme: 'Custom'));
  }

  void _onThemeSelectionUpdated(
    ThemeSelectionUpdated event,
    Emitter<ThemeSettingsState> emit,
  ) {
    emit(state.copyWith(
      theme: event.theme,
      canvasColor: event.canvasColor,
      cardColor: event.cardColor,
      themeColor: event.themeColor,
      colorHue: event.colorHue,
    ));
  }

  void _onThemeDeleted(
    ThemeDeleted event,
    Emitter<ThemeSettingsState> emit,
  ) {
    emit(state.copyWith(
      userThemes: event.userThemes,
      theme: event.theme,
    ));
  }

  void _onThemeSaved(
    ThemeSaved event,
    Emitter<ThemeSettingsState> emit,
  ) {
    emit(state.copyWith(
      userThemes: event.userThemes,
      theme: event.theme,
    ));
  }

  void _onUiRefreshed(
    ThemeUiRefreshed event,
    Emitter<ThemeSettingsState> emit,
  ) {
    emit(state.copyWith(refreshTick: state.refreshTick + 1));
  }

  void _onAmoledApplied(
    ThemeAmoledApplied event,
    Emitter<ThemeSettingsState> emit,
  ) {
    emit(state.copyWith(
      canvasColor: event.canvasColor,
      cardColor: event.cardColor,
      themeColor: event.themeColor,
      colorHue: event.colorHue,
    ));
  }
}
