part of 'backup_and_restore_settings_bloc.dart';

class BackupAndRestoreSettingsState extends Equatable {
  final String autoBackPath;

  const BackupAndRestoreSettingsState({required this.autoBackPath});

  factory BackupAndRestoreSettingsState.initial() {
    return BackupAndRestoreSettingsState(
      autoBackPath: Hive.box('settings').get(
        'autoBackPath',
        defaultValue: '/storage/emulated/0/CloudSpot/Backups',
      ) as String,
    );
  }

  BackupAndRestoreSettingsState copyWith({String? autoBackPath}) {
    return BackupAndRestoreSettingsState(
      autoBackPath: autoBackPath ?? this.autoBackPath,
    );
  }

  @override
  List<Object?> get props => [autoBackPath];
}
