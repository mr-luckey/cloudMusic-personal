import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

/// GetX Controller for Downloads Screen
class DownloadsController extends GetxController {
  final RxList<Map> downloads = <Map>[].obs;
  final RxBool isLoading = false.obs;
  final RxString sortType = 'dateAdded'.obs;
  final RxBool isReversed = false.obs;
  final RxString viewType = 'list'.obs;

  @override
  void onInit() {
    super.onInit();
    loadDownloads();
  }

  Future<void> loadDownloads() async {
    try {
      isLoading.value = true;
      final box = Hive.box('downloads');
      final List downloadsList = box.values.toList();

      downloads.value = downloadsList.map((e) => e as Map).toList();
      sortDownloads();
    } catch (e) {
      Logger.root.severe('Error loading downloads: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void sortDownloads() {
    switch (sortType.value) {
      case 'dateAdded':
        downloads.sort((a, b) {
          final aDate = a['dateAdded'] as int? ?? 0;
          final bDate = b['dateAdded'] as int? ?? 0;
          return bDate.compareTo(aDate);
        });
      case 'title':
        downloads.sort((a, b) => (a['title'] ?? '')
            .toString()
            .compareTo((b['title'] ?? '').toString()));
      case 'artist':
        downloads.sort((a, b) => (a['artist'] ?? '')
            .toString()
            .compareTo((b['artist'] ?? '').toString()));
    }

    if (isReversed.value) {
      downloads.value = downloads.reversed.toList();
    }
  }

  void updateSortType(String type) {
    sortType.value = type;
    sortDownloads();
  }

  void toggleReverse() {
    isReversed.value = !isReversed.value;
    sortDownloads();
  }

  void updateViewType(String type) {
    viewType.value = type;
    Hive.box('settings').put('downloadsViewType', type);
  }

  Future<void> deleteDownload(Map download) async {
    try {
      final box = Hive.box('downloads');
      await box.delete(download['id']);
      downloads.remove(download);
    } catch (e) {
      Logger.root.severe('Error deleting download: $e');
    }
  }

  @override
  Future<void> refresh() async {
    await loadDownloads();
  }
}
