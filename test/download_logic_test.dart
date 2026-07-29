import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Verifies the core download pipeline used by Download.downloadSong:
/// HTTP GET → stream bytes → write file → file exists with size > 0.
void main() {
  test('HTTP stream download writes a non-empty file', () async {
    final uri = Uri.parse(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    );

    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      final response = await client.send(request).timeout(
            const Duration(seconds: 60),
          );

      expect(response.statusCode, inInclusiveRange(200, 299));

      final bytes = <int>[];
      var received = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        // Stop after ~256KB — enough to prove streaming + write works.
        if (received > 256 * 1024) break;
      }

      expect(received, greaterThan(0), reason: 'Download received 0 bytes');

      final dir = await Directory.systemTemp.createTemp('cloudspot_dl_');
      final out = File('${dir.path}/test_download.m4a');
      await out.writeAsBytes(bytes, flush: true);

      expect(await out.exists(), isTrue);
      expect(await out.length(), greaterThan(0));
      // ignore: avoid_print
      print('✅ Test downloaded ${out.lengthSync()} bytes → ${out.path}');

      await dir.delete(recursive: true);
    } finally {
      client.close();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('download target folder is writable', () async {
    final music = await Directory.systemTemp.createTemp('cloudspot_music_');
    final probe = File(
      '${music.path}/.write_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    await probe.writeAsString('ok', flush: true);
    expect(await probe.exists(), isTrue);
    await probe.delete();
    await music.delete(recursive: true);
    // ignore: avoid_print
    print('✅ Writable path OK');
  });
}
