part of 'local_playlists_bloc.dart';

class LocalPlaylistsState extends Equatable {
  final List<PlaylistModel> playlistDetails;
  final int dialogToken;

  const LocalPlaylistsState({
    this.playlistDetails = const [],
    this.dialogToken = 0,
  });

  LocalPlaylistsState copyWith({
    List<PlaylistModel>? playlistDetails,
    int? dialogToken,
  }) {
    return LocalPlaylistsState(
      playlistDetails: playlistDetails ?? this.playlistDetails,
      dialogToken: dialogToken ?? this.dialogToken,
    );
  }

  @override
  List<Object?> get props => [playlistDetails, dialogToken];
}
