import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:blackhole/Services/yt_music.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    String initialQuery = '',
    String? initialSearchType,
    bool initialFromHome = true,
  }) : super(SearchState(
    query: initialQuery,
    searchType: initialSearchType ??
        Hive.box('settings').get('searchType', defaultValue: 'youtube').toString(),
    fromHome: initialFromHome,
    searchHistory:
        List.from(Hive.box('settings').get('search', defaultValue: []) as List),
  )) {
    on<SearchQuerySubmitted>(_onQuerySubmitted);
    on<SearchTypeChanged>(_onTypeChanged);
    on<SearchHistoryItemRemoved>(_onHistoryItemRemoved);
    on<SearchHistoryItemTapped>(_onHistoryItemTapped);
    on<SearchNavigatedHome>(_onNavigatedHome);
    on<SearchNavigatedToResults>(_onNavigatedToResults);
  }

  Future<void> _onQuerySubmitted(
    SearchQuerySubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    _addToHistory(query);
    emit(state.copyWith(
      status: SearchStatus.loading,
      query: query,
      searchType: event.searchType,
      fromHome: false,
      searchedList: [],
      searchHistory: List.from(
          Hive.box('settings').get('search', defaultValue: []) as List),
    ));

    try {
      final results = await _fetchResults(query, event.searchType);
      emit(state.copyWith(
        status: SearchStatus.loaded,
        searchedList: results,
      ));
    } catch (e) {
      Logger.root.severe('Search error: $e');
      emit(state.copyWith(status: SearchStatus.loaded, searchedList: []));
    }
  }

  Future<void> _onTypeChanged(
    SearchTypeChanged event,
    Emitter<SearchState> emit,
  ) async {
    Hive.box('settings').put('searchType', event.searchType);
    if (event.searchType == 'ytm' || event.searchType == 'yt') {
      Hive.box('settings').put('searchYtMusic', event.searchType == 'ytm');
    }

    if (state.query.isNotEmpty) {
      emit(state.copyWith(
        status: SearchStatus.loading,
        searchType: event.searchType,
        searchedList: [],
      ));

      try {
        final results = await _fetchResults(state.query, event.searchType);
        emit(state.copyWith(
          status: SearchStatus.loaded,
          searchedList: results,
        ));
      } catch (e) {
        emit(state.copyWith(status: SearchStatus.loaded, searchedList: []));
      }
    } else {
      emit(state.copyWith(searchType: event.searchType));
    }
  }

  void _onHistoryItemRemoved(
    SearchHistoryItemRemoved event,
    Emitter<SearchState> emit,
  ) {
    final history = List.from(state.searchHistory);
    history.removeAt(event.index);
    Hive.box('settings').put('search', history);
    emit(state.copyWith(searchHistory: history));
  }

  void _onHistoryItemTapped(
    SearchHistoryItemTapped event,
    Emitter<SearchState> emit,
  ) {
    final history = List.from(state.searchHistory);
    final query = history.removeAt(event.index).toString().trim();
    _addToHistory(query);
    add(SearchQuerySubmitted(query: query, searchType: state.searchType));
  }

  void _onNavigatedHome(
    SearchNavigatedHome event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(fromHome: true, query: ''));
  }

  void _onNavigatedToResults(
    SearchNavigatedToResults event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(fromHome: false));
  }

  void _addToHistory(String query) {
    List searchHistory =
        List.from(Hive.box('settings').get('search', defaultValue: []) as List);
    final idx = searchHistory.indexOf(query);
    if (idx != -1) searchHistory.removeAt(idx);
    searchHistory.insert(0, query);
    if (searchHistory.length > 10) {
      searchHistory = searchHistory.sublist(0, 10);
    }
    Hive.box('settings').put('search', searchHistory);
  }

  Future<List<Map<dynamic, dynamic>>> _fetchResults(
      String query, String searchType) async {
    switch (searchType) {
      case 'ytm':
        final value = await YtMusicService().search(query);
        try {
          final songSection =
              value.firstWhere((element) => element['title'] == 'Songs');
          songSection['allowViewAll'] = true;
        } catch (_) {}
        return value;
      case 'yt':
        return await YouTubeServices.instance.fetchSearchResults(query);
      default:
        final results = await SaavnAPI().fetchSearchResults(query);
        for (final element in results) {
          if (element['title'] != 'Top Result') {
            element['allowViewAll'] = true;
          }
        }
        return results;
    }
  }
}
