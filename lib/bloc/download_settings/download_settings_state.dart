part of 'download_settings_bloc.dart';

class DownloadSettingsState extends Equatable {
  final String downloadPath;
  final String downloadQuality;
  final String ytDownloadQuality;
  final int downFilename;

  const DownloadSettingsState({
    required this.downloadPath,
    required this.downloadQuality,
    required this.ytDownloadQuality,
    required this.downFilename,
  });

  factory DownloadSettingsState.initial() {
    final box = Hive.box('settings');
    return DownloadSettingsState(
      downloadPath: box.get('downloadPath',
              defaultValue: '/storage/emulated/0/Music') as String,
      downloadQuality:
          box.get('downloadQuality', defaultValue: '320 kbps') as String,
      ytDownloadQuality:
          box.get('ytDownloadQuality', defaultValue: 'High') as String,
      downFilename: box.get('downFilename', defaultValue: 0) as int,
    );
  }

  DownloadSettingsState copyWith({
    String? downloadPath,
    String? downloadQuality,
    String? ytDownloadQuality,
    int? downFilename,
  }) {
    return DownloadSettingsState(
      downloadPath: downloadPath ?? this.downloadPath,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      ytDownloadQuality: ytDownloadQuality ?? this.ytDownloadQuality,
      downFilename: downFilename ?? this.downFilename,
    );
  }

  @override
  List<Object?> get props =>
      [downloadPath, downloadQuality, ytDownloadQuality, downFilename];
}
