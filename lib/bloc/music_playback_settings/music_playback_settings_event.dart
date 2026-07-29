part of 'music_playback_settings_bloc.dart';

abstract class MusicPlaybackSettingsEvent extends Equatable {
  const MusicPlaybackSettingsEvent();

  @override
  List<Object?> get props => [];
}

class PreferredLanguageChanged extends MusicPlaybackSettingsEvent {
  final List preferredLanguage;

  const PreferredLanguageChanged(this.preferredLanguage);

  @override
  List<Object?> get props => [preferredLanguage];
}

class RegionChanged extends MusicPlaybackSettingsEvent {
  final String region;

  const RegionChanged(this.region);

  @override
  List<Object?> get props => [region];
}

class StreamingMobileQualityChanged extends MusicPlaybackSettingsEvent {
  final String quality;

  const StreamingMobileQualityChanged(this.quality);

  @override
  List<Object?> get props => [quality];
}

class StreamingWifiQualityChanged extends MusicPlaybackSettingsEvent {
  final String quality;

  const StreamingWifiQualityChanged(this.quality);

  @override
  List<Object?> get props => [quality];
}

class YtQualityChanged extends MusicPlaybackSettingsEvent {
  final String quality;

  const YtQualityChanged(this.quality);

  @override
  List<Object?> get props => [quality];
}
