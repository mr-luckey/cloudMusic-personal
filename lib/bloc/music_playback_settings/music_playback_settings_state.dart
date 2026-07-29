part of 'music_playback_settings_bloc.dart';

class MusicPlaybackSettingsState extends Equatable {
  final String streamingMobileQuality;
  final String streamingWifiQuality;
  final String ytQuality;
  final String region;
  final List preferredLanguage;

  const MusicPlaybackSettingsState({
    required this.streamingMobileQuality,
    required this.streamingWifiQuality,
    required this.ytQuality,
    required this.region,
    required this.preferredLanguage,
  });

  factory MusicPlaybackSettingsState.initial() {
    final box = Hive.box('settings');
    return MusicPlaybackSettingsState(
      streamingMobileQuality:
          box.get('streamingQuality', defaultValue: '96 kbps') as String,
      streamingWifiQuality:
          box.get('streamingWifiQuality', defaultValue: '320 kbps') as String,
      ytQuality: box.get('ytQuality', defaultValue: 'Low') as String,
      region: box.get('region', defaultValue: 'India') as String,
      preferredLanguage: box
          .get('preferredLanguage', defaultValue: ['Hindi'])
          ?.toList() as List,
    );
  }

  MusicPlaybackSettingsState copyWith({
    String? streamingMobileQuality,
    String? streamingWifiQuality,
    String? ytQuality,
    String? region,
    List? preferredLanguage,
  }) {
    return MusicPlaybackSettingsState(
      streamingMobileQuality:
          streamingMobileQuality ?? this.streamingMobileQuality,
      streamingWifiQuality:
          streamingWifiQuality ?? this.streamingWifiQuality,
      ytQuality: ytQuality ?? this.ytQuality,
      region: region ?? this.region,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  @override
  List<Object?> get props => [
        streamingMobileQuality,
        streamingWifiQuality,
        ytQuality,
        region,
        preferredLanguage,
      ];
}
