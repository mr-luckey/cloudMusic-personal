import 'package:blackhole/Services/youtube_services.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

/// GetX Controller for YouTube Playlist
class YouTubePlaylistController extends GetxController {
  final RxList<Map> playlistSongs = <Map>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool fetched = false.obs;
  final RxString playlistName = ''.obs;
  final RxString playlistImage = ''.obs;
  final RxString playlistDescription = ''.obs;
  final RxInt songCount = 0.obs;

  Future<void> fetchPlaylist(String playlistId) async {
    try {
      isLoading.value = true;
      fetched.value = false;

      // Get playlist details
      final playlist =
          await YouTubeServices.instance.getPlaylistDetails(playlistId);
      playlistName.value = playlist.title;
      playlistDescription.value = playlist.description ?? '';

      // Get playlist videos
      final videos =
          await YouTubeServices.instance.getPlaylistSongs(playlistId);

      // Convert Video objects to Map format
      final List<Map> formattedSongs = [];
      for (final video in videos) {
        try {
          // Use formatVideo to convert Video to Map
          final formattedVideo = await YouTubeServices.instance.formatVideo(
            video: video,
            quality: 'Low',
            getUrl: false, // Don't fetch URL until user plays
          );

          if (formattedVideo != null) {
            formattedSongs.add(formattedVideo);
          }
        } catch (e) {
          Logger.root.warning('Error formatting video ${video.id}: $e');
          // Continue with other videos
        }
      }

      playlistSongs.value = formattedSongs;
      songCount.value = playlistSongs.length;

      // Set playlist image from first video if available
      if (formattedSongs.isNotEmpty) {
        playlistImage.value = formattedSongs.first['image']?.toString() ?? '';
      }

      fetched.value = true;
    } catch (e) {
      Logger.root.severe('Error fetching YouTube playlist: $e');
      fetched.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToQueue(Map song) async {
    Logger.root.info('Adding to queue: ${song['title']}');
  }

  Future<void> downloadSong(Map song) async {
    Logger.root.info('Downloading: ${song['title']}');
  }
}
