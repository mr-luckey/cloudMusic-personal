part of 'backup_and_restore_settings_bloc.dart';

abstract class BackupAndRestoreSettingsEvent extends Equatable {
  const BackupAndRestoreSettingsEvent();

  @override
  List<Object?> get props => [];
}

class AutoBackPathChanged extends BackupAndRestoreSettingsEvent {
  final String path;

  const AutoBackPathChanged(this.path);

  @override
  List<Object?> get props => [path];
}
