part of 'search_bloc.dart';

enum SearchStatus { initial, loading, loaded, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final String searchType;
  final bool fromHome;
  final List<Map<dynamic, dynamic>> searchedList;
  final List searchHistory;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.searchType = 'ytm',
    this.fromHome = true,
    this.searchedList = const [],
    this.searchHistory = const [],
  });

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    String? searchType,
    bool? fromHome,
    List<Map<dynamic, dynamic>>? searchedList,
    List? searchHistory,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      searchType: searchType ?? this.searchType,
      fromHome: fromHome ?? this.fromHome,
      searchedList: searchedList ?? this.searchedList,
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }

  @override
  List<Object?> get props => [status, query, searchType, fromHome, searchedList, searchHistory];
}
