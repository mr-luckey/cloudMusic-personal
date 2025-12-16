import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

/// GetX Controller for Library/Liked Songs
class LikedSongsController extends GetxController {
  final RxList<Map> likedSongs = <Map>[].obs;
  final RxBool isLoading = false.obs;
  final RxString sortType = 'dateAdded'.obs;
  final RxBool isReversed = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLikedSongs();
  }

  Future<void> loadLikedSongs() async {
    try {
      isLoading.value = true;
      final box = Hive.box('Favorite Songs');
      final List songs = box.values.toList();

      likedSongs.value = songs.map((e) => e as Map).toList();
      sortSongs();
    } catch (e) {
      Logger.root.severe('Error loading liked songs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void sortSongs() {
    switch (sortType.value) {
      case 'dateAdded':
        likedSongs.sort((a, b) {
          final aDate = a['dateAdded'] as int? ?? 0;
          final bDate = b['dateAdded'] as int? ?? 0;
          return bDate.compareTo(aDate);
        });
      case 'title':
        likedSongs.sort((a, b) => (a['title'] ?? '')
            .toString()
            .compareTo((b['title'] ?? '').toString()));
      case 'artist':
        likedSongs.sort((a, b) => (a['artist'] ?? '')
            .toString()
            .compareTo((b['artist'] ?? '').toString()));
    }

    if (isReversed.value) {
      likedSongs.value = likedSongs.reversed.toList();
    }
  }

  void updateSortType(String type) {
    sortType.value = type;
    sortSongs();
  }

  void toggleReverse() {
    isReversed.value = !isReversed.value;
    sortSongs();
  }

  Future<void> removeSong(Map song) async {
    try {
      final box = Hive.box('Favorite Songs');
      await box.delete(song['id']);
      likedSongs.remove(song);
    } catch (e) {
      Logger.root.severe('Error removing song: $e');
    }
  }
}
