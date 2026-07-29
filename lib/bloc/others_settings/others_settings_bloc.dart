import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'others_settings_event.dart';
part 'others_settings_state.dart';

class OthersSettingsBloc extends Bloc<OthersSettingsEvent, OthersSettingsState> {
  OthersSettingsBloc() : super(OthersSettingsState.initial()) {
    on<OthersLanguageChanged>(_onLanguageChanged);
    on<OthersUseProxyChanged>(_onUseProxyChanged);
    on<OthersProxySettingsUpdated>(_onProxySettingsUpdated);
    on<OthersCacheCleared>(_onCacheCleared);
  }

  void _onLanguageChanged(
    OthersLanguageChanged event,
    Emitter<OthersSettingsState> emit,
  ) {
    Hive.box('settings').put('lang', event.lang);
    emit(state.copyWith(lang: event.lang));
  }

  void _onUseProxyChanged(
    OthersUseProxyChanged event,
    Emitter<OthersSettingsState> emit,
  ) {
    emit(state.copyWith(useProxy: event.useProxy));
  }

  void _onProxySettingsUpdated(
    OthersProxySettingsUpdated event,
    Emitter<OthersSettingsState> emit,
  ) {
    emit(state.copyWith(refreshTick: state.refreshTick + 1));
  }

  void _onCacheCleared(
    OthersCacheCleared event,
    Emitter<OthersSettingsState> emit,
  ) {
    emit(state.copyWith(refreshTick: state.refreshTick + 1));
  }
}
