part of 'recent_bloc.dart';

class RecentState extends Equatable {
  final List songs;
  final bool isLoaded;

  const RecentState({
    this.songs = const [],
    this.isLoaded = false,
  });

  RecentState copyWith({
    List? songs,
    bool? isLoaded,
  }) {
    return RecentState(
      songs: songs ?? this.songs,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [songs, isLoaded];
}
