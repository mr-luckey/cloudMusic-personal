part of 'download_settings_bloc.dart';

abstract class DownloadSettingsEvent extends Equatable {
  const DownloadSettingsEvent();

  @override
  List<Object?> get props => [];
}

class DownloadQualityChanged extends DownloadSettingsEvent {
  final String quality;

  const DownloadQualityChanged(this.quality);

  @override
  List<Object?> get props => [quality];
}

class YtDownloadQualityChanged extends DownloadSettingsEvent {
  final String quality;

  const YtDownloadQualityChanged(this.quality);

  @override
  List<Object?> get props => [quality];
}

class DownloadPathChanged extends DownloadSettingsEvent {
  final String path;

  const DownloadPathChanged(this.path);

  @override
  List<Object?> get props => [path];
}

class DownFilenameChanged extends DownloadSettingsEvent {
  final int filename;

  const DownFilenameChanged(this.filename);

  @override
  List<Object?> get props => [filename];
}
