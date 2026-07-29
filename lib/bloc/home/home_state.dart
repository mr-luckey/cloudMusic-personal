part of 'home_bloc.dart';

class HomeState extends Equatable {
  final int selectedIndex;
  final List sectionsToShow;

  const HomeState({
    this.selectedIndex = 0,
    this.sectionsToShow = const ['Home', 'YouTube', 'Library', 'Settings'],
  });

  factory HomeState.initial() {
    return HomeState(
      selectedIndex: 0,
      sectionsToShow: Hive.box('settings').get(
        'sectionsToShow',
        defaultValue: ['Home', 'YouTube', 'Library', 'Settings'],
      ) as List,
    );
  }

  HomeState copyWith({
    int? selectedIndex,
    List? sectionsToShow,
  }) {
    return HomeState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      sectionsToShow: sectionsToShow != null
          ? List.from(sectionsToShow)
          : this.sectionsToShow,
    );
  }

  @override
  List<Object?> get props => [selectedIndex, sectionsToShow];
}
