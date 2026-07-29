import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'download_settings_event.dart';
part 'download_settings_state.dart';

class DownloadSettingsBloc
    extends Bloc<DownloadSettingsEvent, DownloadSettingsState> {
  DownloadSettingsBloc() : super(DownloadSettingsState.initial()) {
    on<DownloadQualityChanged>(_onDownloadQualityChanged);
    on<YtDownloadQualityChanged>(_onYtDownloadQualityChanged);
    on<DownloadPathChanged>(_onDownloadPathChanged);
    on<DownFilenameChanged>(_onDownFilenameChanged);
  }

  void _onDownloadQualityChanged(
    DownloadQualityChanged event,
    Emitter<DownloadSettingsState> emit,
  ) {
    Hive.box('settings').put('downloadQuality', event.quality);
    emit(state.copyWith(downloadQuality: event.quality));
  }

  void _onYtDownloadQualityChanged(
    YtDownloadQualityChanged event,
    Emitter<DownloadSettingsState> emit,
  ) {
    Hive.box('settings').put('ytDownloadQuality', event.quality);
    emit(state.copyWith(ytDownloadQuality: event.quality));
  }

  void _onDownloadPathChanged(
    DownloadPathChanged event,
    Emitter<DownloadSettingsState> emit,
  ) {
    Hive.box('settings').put('downloadPath', event.path);
    emit(state.copyWith(downloadPath: event.path));
  }

  void _onDownFilenameChanged(
    DownFilenameChanged event,
    Emitter<DownloadSettingsState> emit,
  ) {
    Hive.box('settings').put('downFilename', event.filename);
    emit(state.copyWith(downFilename: event.filename));
  }
}
