part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQuerySubmitted extends SearchEvent {
  final String query;
  final String searchType;

  const SearchQuerySubmitted({required this.query, required this.searchType});

  @override
  List<Object?> get props => [query, searchType];
}

class SearchTypeChanged extends SearchEvent {
  final String searchType;

  const SearchTypeChanged({required this.searchType});

  @override
  List<Object?> get props => [searchType];
}

class SearchHistoryItemRemoved extends SearchEvent {
  final int index;

  const SearchHistoryItemRemoved({required this.index});

  @override
  List<Object?> get props => [index];
}

class SearchHistoryItemTapped extends SearchEvent {
  final int index;

  const SearchHistoryItemTapped({required this.index});

  @override
  List<Object?> get props => [index];
}

class SearchNavigatedHome extends SearchEvent {
  const SearchNavigatedHome();
}

class SearchNavigatedToResults extends SearchEvent {
  const SearchNavigatedToResults();
}
