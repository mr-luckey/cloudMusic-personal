import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class PipedService {
  static final PipedService _instance = PipedService._();
  static PipedService get instance => _instance;
  PipedService._();

  static const List<String> _pipedInstances = [
    'pipedapi.kavin.rocks',
    'pipedapi.adminforge.de',
    'api.piped.privacydev.net',
    'pipedapi.in.projectsegfau.lt',
    'pipedapi.leptons.xyz',
    'piped-api.lunar.icu',
    'pa.mint.lgbt',
    'api.piped.yt',
  ];

  int _currentInstance = 0;
  final _random = Random();

  String get _baseUrl => _pipedInstances[_currentInstance];

  void _rotateInstance() {
    _currentInstance = (_currentInstance + 1) % _pipedInstances.length;
  }

  void _randomizeInstance() {
    _currentInstance = _random.nextInt(_pipedInstances.length);
  }

  Future<List<Map>> getStreamUrls(String videoId) async {
    _randomizeInstance();

    for (int attempt = 0; attempt < _pipedInstances.length; attempt++) {
      try {
        final url = 'https://$_baseUrl/streams/$videoId';
        Logger.root.info('[PIPED] Trying instance: $_baseUrl for video $videoId');

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          Logger.root.warning('[PIPED] Instance $_baseUrl returned ${response.statusCode}');
          _rotateInstance();
          continue;
        }

        final data = json.decode(response.body) as Map;

        if (data.containsKey('error')) {
          Logger.root.warning('[PIPED] Error from $_baseUrl: ${data['error']}');
          _rotateInstance();
          continue;
        }

        final List audioStreams = (data['audioStreams'] as List?) ?? [];
        if (audioStreams.isEmpty) {
          Logger.root.warning('[PIPED] No audio streams from $_baseUrl');
          _rotateInstance();
          continue;
        }

        final List<Map> result = [];
        for (final stream in audioStreams) {
          final streamUrl = stream['url']?.toString();
          if (streamUrl == null || streamUrl.isEmpty) continue;

          final bitrate = stream['bitrate'] ?? 0;
          final mimeType = stream['mimeType']?.toString() ?? '';
          final codec = mimeType.contains('mp4')
              ? 'mp4a'
              : (mimeType.contains('webm') ? 'opus' : 'unknown');
          final quality = stream['quality']?.toString() ?? 'unknown';
          final contentLength = stream['contentLength'] ?? 0;
          final sizeMB = (contentLength is int ? contentLength : 0) / (1024 * 1024);

          String expireAt;
          try {
            expireAt = RegExp('expire=(.*?)&').firstMatch(streamUrl)?.group(1) ??
                (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600).toString();
          } catch (_) {
            expireAt = (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600).toString();
          }

          result.add({
            'bitrate': (bitrate ~/ 1000).toString(),
            'codec': codec,
            'qualityLabel': quality,
            'size': sizeMB.toStringAsFixed(2),
            'url': streamUrl,
            'expireAt': expireAt,
          });
        }

        result.sort((a, b) {
          final bitrateA = int.tryParse(a['bitrate'].toString()) ?? 0;
          final bitrateB = int.tryParse(b['bitrate'].toString()) ?? 0;
          return bitrateA.compareTo(bitrateB);
        });

        Logger.root.info('[PIPED] Got ${result.length} audio streams from $_baseUrl');
        return result;
      } catch (e) {
        Logger.root.warning('[PIPED] Instance $_baseUrl failed: $e');
        _rotateInstance();
        continue;
      }
    }

    Logger.root.severe('[PIPED] All instances failed for video $videoId');
    return [];
  }

  Future<Map?> getVideoInfo(String videoId) async {
    _randomizeInstance();

    for (int attempt = 0; attempt < _pipedInstances.length; attempt++) {
      try {
        final url = 'https://$_baseUrl/streams/$videoId';
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          _rotateInstance();
          continue;
        }

        final data = json.decode(response.body) as Map;
        if (data.containsKey('error')) {
          _rotateInstance();
          continue;
        }

        return data;
      } catch (e) {
        _rotateInstance();
        continue;
      }
    }
    return null;
  }
}
