import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'backup_and_restore_settings_event.dart';
part 'backup_and_restore_settings_state.dart';

class BackupAndRestoreSettingsBloc
    extends Bloc<BackupAndRestoreSettingsEvent, BackupAndRestoreSettingsState> {
  BackupAndRestoreSettingsBloc() : super(BackupAndRestoreSettingsState.initial()) {
    on<AutoBackPathChanged>(_onAutoBackPathChanged);
  }

  void _onAutoBackPathChanged(
    AutoBackPathChanged event,
    Emitter<BackupAndRestoreSettingsState> emit,
  ) {
    Hive.box('settings').put('autoBackPath', event.path);
    emit(state.copyWith(autoBackPath: event.path));
  }
}
