import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Test YouTube audio URL extraction + HTTP fetch (simulates YouTubeAudioSource).
Future<void> main() async {
  // 5+ minute song: "Bohemian Rhapsody" official (~6 min)
  const videoId = 'fJ9rUzIMcZQ';
  final yt = YoutubeExplode();

  print('=== YouTube Playback Pipeline Test ===');
  print('Video ID: $videoId');

  try {
    final manifest =
        await yt.videos.streamsClient.getManifest(VideoId(videoId));
    final audio = manifest.audioOnly.withHighestBitrate();
    final url = audio.url.toString();
    print('Got URL (${audio.bitrate.kiloBitsPerSecond}kbps ${audio.codec})');
    print('URL prefix: ${url.substring(0, 80)}...');

    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Referer': 'https://www.youtube.com/',
      'Origin': 'https://www.youtube.com',
      'Range': 'bytes=0-65535',
    };

    print('\nTesting Range request (first 64KB)...');
    final response = await http.get(Uri.parse(url), headers: headers);
    print('Status: ${response.statusCode}');
    print('Content-Type: ${response.headers['content-type']}');
    print('Bytes received: ${response.bodyBytes.length}');

    if (response.statusCode == 200 || response.statusCode == 206) {
      print('\n✅ PASS: Stream is accessible with proxy headers');
      exit(0);
    } else {
      print('\n❌ FAIL: HTTP ${response.statusCode}');
      exit(1);
    }
  } catch (e, st) {
    print('❌ ERROR: $e');
    print(st);
    exit(1);
  } finally {
    yt.close();
  }
}
