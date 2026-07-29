part of 'youtube_home_bloc.dart';

enum YouTubeHomeStatus { initial, loading, loaded, error }

class YouTubeHomeState extends Equatable {
  final YouTubeHomeStatus status;
  final List searchedList;
  final List headList;

  const YouTubeHomeState({
    this.status = YouTubeHomeStatus.initial,
    this.searchedList = const [],
    this.headList = const [],
  });

  YouTubeHomeState copyWith({
    YouTubeHomeStatus? status,
    List? searchedList,
    List? headList,
  }) {
    return YouTubeHomeState(
      status: status ?? this.status,
      searchedList: searchedList ?? this.searchedList,
      headList: headList ?? this.headList,
    );
  }

  @override
  List<Object?> get props => [status, searchedList, headList];
}
