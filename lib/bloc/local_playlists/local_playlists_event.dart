part of 'local_playlists_bloc.dart';

abstract class LocalPlaylistsEvent extends Equatable {
  const LocalPlaylistsEvent();

  @override
  List<Object?> get props => [];
}

class LocalPlaylistsInitialized extends LocalPlaylistsEvent {
  final List<PlaylistModel> playlistDetails;

  const LocalPlaylistsInitialized(this.playlistDetails);

  @override
  List<Object?> get props => [playlistDetails];
}

class LocalPlaylistsRefreshed extends LocalPlaylistsEvent {
  final List<PlaylistModel> playlistDetails;

  const LocalPlaylistsRefreshed(this.playlistDetails);

  @override
  List<Object?> get props => [playlistDetails];
}

class LocalPlaylistRemoved extends LocalPlaylistsEvent {
  final int index;

  const LocalPlaylistRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

class LocalPlaylistsDialogOpened extends LocalPlaylistsEvent {
  const LocalPlaylistsDialogOpened();
}
