import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalMusicPermissionState extends Equatable {
  final bool hasPermission;
  final int refreshToken;

  const LocalMusicPermissionState({
    this.hasPermission = false,
    this.refreshToken = 0,
  });

  LocalMusicPermissionState copyWith({
    bool? hasPermission,
    int? refreshToken,
  }) {
    return LocalMusicPermissionState(
      hasPermission: hasPermission ?? this.hasPermission,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  List<Object?> get props => [hasPermission, refreshToken];
}

class LocalMusicPermissionCubit extends Cubit<LocalMusicPermissionState> {
  LocalMusicPermissionCubit({OnAudioQuery? audioQuery})
      : _audioQuery = audioQuery ?? OnAudioQuery(),
        super(const LocalMusicPermissionState());

  final OnAudioQuery _audioQuery;

  Future<void> checkAndRequestPermissions({bool retry = false}) async {
    final hasPermission =
        await _audioQuery.checkAndRequest(retryRequest: retry);
    if (hasPermission) {
      emit(state.copyWith(hasPermission: true));
    }
  }

  void notifySongDeleted() {
    emit(state.copyWith(refreshToken: state.refreshToken + 1));
  }
}
