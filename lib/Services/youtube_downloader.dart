import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

/// Service to download YouTube audio to temporary files for playback
/// This bypasses YouTube's 403 streaming restrictions
class YouTubeDownloader {
  static final Logger _logger = Logger('YouTubeDownloader');

  /// Downloads YouTube audio to a temporary file
  /// Returns the local file path if successful, null otherwise
  static Future<String?> downloadAudio({
    required String url,
    required String videoId,
    required String title,
  }) async {
    try {
      _logger.info('📥 [DOWNLOAD] Starting download for: $title');
      print('📥 [DOWNLOAD] Starting download for: $title');

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/yt_audio_$videoId.m4a';
      final file = File(filePath);

      // Check if already downloaded and valid
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 1024) {
          // File exists and is larger than 1KB
          _logger.info('✅ [DOWNLOAD] Using cached file: $filePath');
          print(
              '✅ [DOWNLOAD] Using cached file (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
          return filePath;
        } else {
          // File is corrupted, delete it
          await file.delete();
        }
      }

      print('🌐 [DOWNLOAD] Fetching audio from YouTube...');

      // Parse URL to check host
      final uri = Uri.parse(url);

      // Prepare headers - CRITICAL: googlevideo.com URLs reject Origin header
      // Based on yt-dlp research: ONLY send User-Agent, Accept, and Referer
      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': 'https://www.youtube.com/',
      };

      // Log API call details
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📡 [API CALL] HTTP GET Request');
      print('🌐 [HOST] ${uri.host}');
      print(
          '🔗 [URL] ${url.substring(0, url.length > 100 ? 100 : url.length)}...');
      print('📋 [HEADERS]');
      headers.forEach((key, value) {
        print('   $key: $value');
      });
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Download with YouTube-compatible headers
      final response = await http
          .get(
        Uri.parse(url),
        headers: headers,
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Download timeout after 60 seconds');
        },
      );

      // Log response details
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📨 [API RESPONSE]');
      print('📊 [STATUS] ${response.statusCode} ${response.reasonPhrase}');
      print('📋 [RESPONSE HEADERS]');
      response.headers.forEach((key, value) {
        print('   $key: $value');
      });
      print(
          '📦 [BODY SIZE] ${response.bodyBytes.length} bytes (${(response.bodyBytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final sizeInMB = (bytes.length / 1024 / 1024).toStringAsFixed(2);

        print('💾 [DOWNLOAD] Saving ${sizeInMB}MB to temp file...');
        await file.writeAsBytes(bytes);

        _logger.info('✅ [DOWNLOAD] Successfully downloaded: $filePath');
        print('✅ [DOWNLOAD] Download complete! File saved: ${sizeInMB}MB');

        return filePath;
      } else {
        _logger
            .severe('❌ [DOWNLOAD] Failed with status ${response.statusCode}');
        print(
            '❌ [DOWNLOAD] HTTP ${response.statusCode}: ${response.reasonPhrase}');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.severe('❌ [DOWNLOAD] Error downloading audio', e, stackTrace);
      print('❌ [DOWNLOAD] Error: $e');
      return null;
    }
  }

  /// Cleans up old temporary audio files to free space
  static Future<void> cleanupOldFiles({int maxAgeHours = 24}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      final now = DateTime.now();
      int deletedCount = 0;

      for (final file in files) {
        if (file is File && file.path.contains('yt_audio_')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          if (age.inHours > maxAgeHours) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        _logger.info('🗑️ [CLEANUP] Deleted $deletedCount old audio files');
        print('🗑️ [CLEANUP] Deleted $deletedCount old audio files');
      }
    } catch (e) {
      _logger.warning('⚠️ [CLEANUP] Error during cleanup', e);
    }
  }
}
