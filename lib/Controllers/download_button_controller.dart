import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// GetX Controller for Download Button
class DownloadButtonController extends GetxController {
  final RxBool isDownloading = false.obs;
  final Rx<double?> progress = Rx<double?>(null);
  final RxBool downloaded = false.obs;

  set updateProgress(double? value) {
    progress.value = value;
  }

  set setDownloading(bool value) {
    isDownloading.value = value;
  }

  set setDownloaded(bool value) {
    downloaded.value = value;
  }

  Future<void> checkDownloadStatus(Map data) async {
    final downloadsBox = Hive.box('downloads');
    final songId = data['id'].toString();

    if (downloadsBox.containsKey(songId)) {
      downloaded.value = true;
    } else {
      downloaded.value = false;
    }
  }
}
