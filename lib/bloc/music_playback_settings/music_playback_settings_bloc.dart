import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'music_playback_settings_event.dart';
part 'music_playback_settings_state.dart';

class MusicPlaybackSettingsBloc
    extends Bloc<MusicPlaybackSettingsEvent, MusicPlaybackSettingsState> {
  MusicPlaybackSettingsBloc() : super(MusicPlaybackSettingsState.initial()) {
    on<PreferredLanguageChanged>(_onPreferredLanguageChanged);
    on<RegionChanged>(_onRegionChanged);
    on<StreamingMobileQualityChanged>(_onStreamingMobileQualityChanged);
    on<StreamingWifiQualityChanged>(_onStreamingWifiQualityChanged);
    on<YtQualityChanged>(_onYtQualityChanged);
  }

  void _onPreferredLanguageChanged(
    PreferredLanguageChanged event,
    Emitter<MusicPlaybackSettingsState> emit,
  ) {
    Hive.box('settings').put('preferredLanguage', event.preferredLanguage);
    emit(state.copyWith(preferredLanguage: event.preferredLanguage));
  }

  void _onRegionChanged(
    RegionChanged event,
    Emitter<MusicPlaybackSettingsState> emit,
  ) {
    emit(state.copyWith(region: event.region));
  }

  void _onStreamingMobileQualityChanged(
    StreamingMobileQualityChanged event,
    Emitter<MusicPlaybackSettingsState> emit,
  ) {
    Hive.box('settings').put('streamingQuality', event.quality);
    emit(state.copyWith(streamingMobileQuality: event.quality));
  }

  void _onStreamingWifiQualityChanged(
    StreamingWifiQualityChanged event,
    Emitter<MusicPlaybackSettingsState> emit,
  ) {
    Hive.box('settings').put('streamingWifiQuality', event.quality);
    emit(state.copyWith(streamingWifiQuality: event.quality));
  }

  void _onYtQualityChanged(
    YtQualityChanged event,
    Emitter<MusicPlaybackSettingsState> emit,
  ) {
    Hive.box('settings').put('ytQuality', event.quality);
    emit(state.copyWith(ytQuality: event.quality));
  }
}
