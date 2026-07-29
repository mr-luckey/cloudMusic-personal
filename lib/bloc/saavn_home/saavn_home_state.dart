part of 'saavn_home_bloc.dart';

enum SaavnHomeStatus { initial, loading, loaded }

class SaavnHomeState extends Equatable {
  final SaavnHomeStatus status;
  final Map data;
  final List lists;
  final List recentList;
  final Map likedArtists;
  final List blacklistedHomeSections;
  final List playlistNames;
  final Map playlistDetails;
  final List likedRadio;

  const SaavnHomeState({
    this.status = SaavnHomeStatus.initial,
    this.data = const {},
    this.lists = const [],
    this.recentList = const [],
    this.likedArtists = const {},
    this.blacklistedHomeSections = const [],
    this.playlistNames = const ['Favorite Songs'],
    this.playlistDetails = const {},
    this.likedRadio = const [],
  });

  factory SaavnHomeState.initial() {
    final data =
        Hive.box('cache').get('homepage', defaultValue: {}) as Map;
    final lists = ['recent', 'playlist', ...?data['collections'] as List?];
    if (lists.isNotEmpty) {
      lists.insert((lists.length / 2).round(), 'likedArtists');
    }
    return SaavnHomeState(
      status: data.isEmpty
          ? SaavnHomeStatus.initial
          : SaavnHomeStatus.loaded,
      data: Map.from(data),
      lists: lists,
      recentList: List.from(
        Hive.box('cache').get('recentSongs', defaultValue: []) as List,
      ),
      likedArtists: Map.from(
        Hive.box('settings').get('likedArtists', defaultValue: {}) as Map,
      ),
      blacklistedHomeSections: List.from(
        Hive.box('settings')
            .get('blacklistedHomeSections', defaultValue: []) as List,
      ),
      playlistNames: List<String>.from(
        (Hive.box('settings').get('playlistNames') as List?)?.cast<String>() ??
            ['Favorite Songs'],
      ),
      playlistDetails: Map.from(
        Hive.box('settings').get('playlistDetails', defaultValue: {}) as Map,
      ),
      likedRadio: List.from(
        Hive.box('settings').get('likedRadio', defaultValue: []) as List,
      ),
    );
  }

  SaavnHomeState copyWith({
    SaavnHomeStatus? status,
    Map? data,
    List? lists,
    List? recentList,
    Map? likedArtists,
    List? blacklistedHomeSections,
    List? playlistNames,
    Map? playlistDetails,
    List? likedRadio,
  }) {
    return SaavnHomeState(
      status: status ?? this.status,
      data: data != null ? Map.from(data) : this.data,
      lists: lists != null ? List.from(lists) : this.lists,
      recentList: recentList != null ? List.from(recentList) : this.recentList,
      likedArtists:
          likedArtists != null ? Map.from(likedArtists) : this.likedArtists,
      blacklistedHomeSections: blacklistedHomeSections != null
          ? List.from(blacklistedHomeSections)
          : this.blacklistedHomeSections,
      playlistNames: playlistNames != null
          ? List.from(playlistNames)
          : this.playlistNames,
      playlistDetails: playlistDetails != null
          ? Map.from(playlistDetails)
          : this.playlistDetails,
      likedRadio:
          likedRadio != null ? List.from(likedRadio) : this.likedRadio,
    );
  }

  @override
  List<Object?> get props => [
        status,
        data,
        lists,
        recentList,
        likedArtists,
        blacklistedHomeSections,
        playlistNames,
        playlistDetails,
        likedRadio,
      ];
}
