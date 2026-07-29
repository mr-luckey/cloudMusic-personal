import 'dart:convert';
import 'package:http/http.dart' as http;

const instances = [
  'pipedapi.kavin.rocks',
  'pipedapi.adminforge.de',
  'api.piped.privacydev.net',
  'pipedapi.in.projectsegfau.lt',
  'pipedapi.leptons.xyz',
  'piped-api.lunar.icu',
  'api.piped.yt',
];

Future<void> main() async {
  const videoId = 'jNQXAC9IVRw'; // short test video
  for (final host in instances) {
    try {
      final resp = await http
          .get(
            Uri.parse('https://$host/streams/$videoId'),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          )
          .timeout(const Duration(seconds: 12));
      print('$host => ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map;
        final streams = (data['audioStreams'] as List?) ?? [];
        print('  streams: ${streams.length}');
        if (streams.isNotEmpty) {
          final url = streams.last['url'].toString();
          final head = await http.head(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Referer': 'https://www.youtube.com/',
            },
          );
          print('  stream HEAD: ${head.statusCode}');
        }
        break;
      }
    } catch (e) {
      print('$host => error: $e');
    }
  }
}
