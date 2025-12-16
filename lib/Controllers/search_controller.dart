import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:blackhole/Services/yt_music.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

/// GetX Controller for Search functionality
/// Replaces setState with reactive state management for better performance
class SearchController extends GetxController {
  // Reactive state variables
  final RxString query = ''.obs;
  final RxBool fetched = false.obs;
  final RxBool fetchResultCalled = false.obs;
  final RxList<Map<dynamic, dynamic>> searchedList =
      <Map<dynamic, dynamic>>[].obs;
  final RxList<Map<dynamic, dynamic>> allSearchResults =
      <Map<dynamic, dynamic>>[].obs;
  final RxString searchType = 'youtube'.obs;
  final RxList searchHistory = [].obs;
  final RxList<String> topSearch = <String>[].obs;
  final RxString selectedFilter = 'all'.obs;
  final RxnString loadingSongId = RxnString(null);
  final RxBool fromHome = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Load settings from Hive
    searchType.value = Hive.box('settings')
        .get('searchType', defaultValue: 'youtube')
        .toString();
    searchHistory.value =
        Hive.box('settings').get('search', defaultValue: []) as List;
  }

  /// Fetch search results based on search type
  Future<void> fetchResults(String searchQuery) async {
    Logger.root.info('fetching search results for $searchQuery');

    query.value = searchQuery;
    fetched.value = false;

    switch (searchType.value) {
      case 'ytm':
        await _fetchYtMusicResults(searchQuery);
        break;
      case 'yt':
        await _fetchYouTubeResults(searchQuery);
        break;
      default:
        await _fetchSaavnResults(searchQuery);
    }

    fetched.value = true;
  }

  Future<void> _fetchYtMusicResults(String searchQuery) async {
    try {
      Logger.root.info('calling yt music search');
      final value = await YtMusicService().search(searchQuery);

      allSearchResults.value = List<Map<dynamic, dynamic>>.from(value);

      // Collect only videos and songs
      final List<Map<dynamic, dynamic>> allVideosAndSongs = [];

      for (final section in value) {
        final String title = section['title'].toString().toLowerCase().trim();

        if ((title.contains('song') ||
                title == 'songs' ||
                title.contains('video') ||
                title == 'videos') &&
            section['items'] != null &&
            (section['items'] as List).isNotEmpty) {
          final List<Map> filteredItems = [];
          for (final item in section['items'] as List) {
            final itemType =
                (item as Map)['type']?.toString().toLowerCase() ?? '';
            if (itemType == 'song' || itemType == 'video') {
              filteredItems.add(item);
            }
          }

          if (filteredItems.isNotEmpty) {
            allVideosAndSongs.addAll(filteredItems);
          }
        }
      }

      if (allVideosAndSongs.isNotEmpty) {
        searchedList.value = [
          {
            'title': '',
            'items': allVideosAndSongs,
            'allowViewAll': false,
          }
        ];
      } else {
        searchedList.value = [];
      }
    } catch (e) {
      Logger.root.severe('Unable to reach youtube music service: $e');
      searchedList.value = [];
    }
  }

  Future<void> _fetchYouTubeResults(String searchQuery) async {
    try {
      Logger.root.info('calling youtube search');
      final value =
          await YouTubeServices.instance.fetchSearchResults(searchQuery);

      allSearchResults.value = List<Map<dynamic, dynamic>>.from(value);

      final List<Map<dynamic, dynamic>> allVideos = [];

      for (final section in value) {
        if (section['items'] != null && (section['items'] as List).isNotEmpty) {
          final List<Map> filteredItems = [];
          for (final item in section['items'] as List) {
            final itemType =
                (item as Map)['type']?.toString().toLowerCase() ?? '';
            if (itemType == 'video' || itemType.isEmpty) {
              filteredItems.add(item);
            }
          }

          if (filteredItems.isNotEmpty) {
            allVideos.addAll(filteredItems);
          }
        }
      }

      if (allVideos.isNotEmpty) {
        searchedList.value = [
          {
            'title': '',
            'items': allVideos,
            'allowViewAll': false,
          }
        ];
      } else {
        searchedList.value = [];
      }
    } catch (e) {
      Logger.root.severe('Unable to reach youtube service: $e');
      searchedList.value = [];
    }
  }

  Future<void> _fetchSaavnResults(String searchQuery) async {
    try {
      Logger.root.info('calling saavn search');
      final results = await SaavnAPI().fetchSearchResults(searchQuery);

      allSearchResults.value = List<Map<dynamic, dynamic>>.from(results);

      final List<Map<dynamic, dynamic>> topResults = [];
      final List<Map<dynamic, dynamic>> songs = [];
      final List<Map<dynamic, dynamic>> albums = [];
      final List<Map<dynamic, dynamic>> artists = [];
      final List<Map<dynamic, dynamic>> playlists = [];
      final List<Map<dynamic, dynamic>> other = [];

      for (final element in results) {
        final String title = element['title'].toString();
        if (title != 'Top Result') {
          element['allowViewAll'] = true;
        }

        if (element['title'] == null || element['title'].toString().isEmpty) {
          element['title'] = 'Results';
        }

        final titleLower = title.toLowerCase().trim();
        if (title == 'Top Result') {
          topResults.add(element);
        } else if (titleLower.contains('song') || titleLower == 'songs') {
          songs.add(element);
        } else if (titleLower.contains('album') || titleLower == 'albums') {
          albums.add(element);
        } else if (titleLower.contains('artist') || titleLower == 'artists') {
          artists.add(element);
        } else if (titleLower.contains('playlist') ||
            titleLower == 'playlists') {
          playlists.add(element);
        } else {
          other.add(element);
        }
      }

      final List<Map<dynamic, dynamic>> reorderedList = [];
      reorderedList.addAll(topResults);
      reorderedList.addAll(songs);
      reorderedList.addAll(albums);
      reorderedList.addAll(artists);
      reorderedList.addAll(playlists);
      reorderedList.addAll(other);

      searchedList.value = _applyFilter(reorderedList);
    } catch (e) {
      Logger.root.severe('Error fetching Saavn results: $e');
      searchedList.value = [];
    }
  }

  List<Map<dynamic, dynamic>> _applyFilter(
      List<Map<dynamic, dynamic>> results) {
    if (selectedFilter.value == 'all') {
      return results;
    }

    final filtered = <Map<dynamic, dynamic>>[];

    for (final section in results) {
      final String sectionTitle = section['title'].toString().toLowerCase();

      if (selectedFilter.value == 'songs' &&
          (sectionTitle.contains('song') || sectionTitle.contains('video'))) {
        filtered.add(section);
      } else if (selectedFilter.value == 'albums' &&
          sectionTitle.contains('album')) {
        filtered.add(section);
      } else if (selectedFilter.value == 'artists' &&
          sectionTitle.contains('artist')) {
        filtered.add(section);
      } else if (selectedFilter.value == 'playlists' &&
          sectionTitle.contains('playlist')) {
        filtered.add(section);
      }
    }

    return filtered;
  }

  Future<void> getTrendingSearch() async {
    topSearch.value = await SaavnAPI().getTopSearches();
  }

  void addToHistory(String title) {
    final tempquery = title.trim();
    if (tempquery == '') {
      return;
    }
    final idx = searchHistory.indexOf(tempquery);
    if (idx != -1) {
      searchHistory.removeAt(idx);
    }
    searchHistory.insert(0, tempquery);
    if (searchHistory.length > 10) {
      searchHistory.value = searchHistory.sublist(0, 10);
    }
    Hive.box('settings').put('search', searchHistory);
  }

  void changeSearchType(String newType) {
    searchType.value = newType;
    fetched.value = false;
    fetchResultCalled.value = false;
    Hive.box('settings').put('searchType', newType);
    if (newType == 'ytm' || newType == 'yt') {
      Hive.box('settings').put('searchYtMusic', newType == 'ytm');
    }
  }

  void setLoadingSong(String? songId) {
    loadingSongId.value = songId;
  }

  void clearSearch() {
    query.value = '';
    searchedList.value = [];
    fetched.value = false;
    fetchResultCalled.value = false;
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}
