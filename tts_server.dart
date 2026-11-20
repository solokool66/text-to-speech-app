import 'dart:convert';
import 'dart:io';
import 'package:edge_tts/edge_tts.dart';

void main() async {
  final port = 5050;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('====================================================');
  print(' Text-to-Speech Web Server & Bridge is RUNNING');
  print(' Access in browser at: http://localhost:$port');
  print('====================================================');

  final webDir = Directory('build/web');
  final hasWebBuild = await webDir.exists();

  await for (HttpRequest request in server) {
    // Add CORS headers to all responses
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');
    request.response.headers.add('Cache-Control', 'no-cache, no-store, must-revalidate');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    final path = request.uri.path;

    if (path == '/synthesize') {
      try {
        String text = '';
        String voice = 'en-US-AriaNeural';
        String pitch = '+0Hz';
        String rate = '+0%';

        if (request.method == 'POST') {
          final body = await utf8.decodeStream(request);
          final data = jsonDecode(body) as Map<String, dynamic>;
          text = data['text'] ?? '';
          voice = data['voice'] ?? 'en-US-AriaNeural';
          pitch = data['pitch'] ?? '+0Hz';
          rate = data['rate'] ?? '+0%';
        } else if (request.method == 'GET') {
          text = request.uri.queryParameters['text'] ?? '';
          voice = request.uri.queryParameters['voice'] ?? 'en-US-AriaNeural';
          pitch = request.uri.queryParameters['pitch'] ?? '+0Hz';
          rate = request.uri.queryParameters['rate'] ?? '+0%';
        }

        if (text.trim().isEmpty) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write('Missing text parameter');
          await request.response.close();
          continue;
        }

        print('Synthesizing: "${text.length > 30 ? text.substring(0, 30) + '...' : text}" with voice $voice');
        final tts = Communicate(
          text: text,
          voice: voice,
          pitch: pitch,
          rate: rate,
        );

        final bytes = await tts.toBytes();
        print('Synthesized successfully: ${bytes.length} bytes');

        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType('audio', 'mpeg');
        request.response.add(bytes);
        await request.response.close();
      } catch (e) {
        print('Error in /synthesize: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Synthesis error: $e');
        await request.response.close();
      }
    } else if (path == '/save') {
      try {
        final body = await utf8.decodeStream(request);
        final data = jsonDecode(body) as Map<String, dynamic>;
        var filename = data['filename'] ?? 'tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
        if (!filename.endsWith('.mp3')) filename = '$filename.mp3';

        final dynamic rawBytes = data['bytes'];
        List<int> bytesList;
        if (rawBytes is String) {
          bytesList = base64Decode(rawBytes);
        } else if (rawBytes is List) {
          bytesList = rawBytes.cast<int>();
        } else {
          throw Exception('Invalid audio bytes format');
        }

        final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\GOOFCEE';
        final targetDir = Directory('$userProfile\\Downloads\\TextSpeech');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        final file = File('${targetDir.path}\\$filename');
        await file.writeAsBytes(bytesList);
        print('Saved audio file directly to: ${file.path} (${bytesList.length} bytes)');

        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'success': true, 'path': file.path}));
        await request.response.close();
      } catch (e) {
        print('Error in /save: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'success': false, 'error': e.toString()}));
        await request.response.close();
      }
    } else if (path == '/health') {
      request.response.statusCode = HttpStatus.ok;
      request.response.write('OK');
      await request.response.close();
    } else {
      // Serve static build/web files if available
      if (hasWebBuild) {
        var filePath = path == '/' ? '/index.html' : path;
        if (filePath.startsWith('/')) filePath = filePath.substring(1);
        final file = File('build/web/$filePath');
        if (await file.exists()) {
          final mime = _getMimeType(filePath);
          request.response.headers.set('Content-Type', mime);
          await file.openRead().pipe(request.response);
          continue;
        }
        // SPA fallback to index.html
        final indexFile = File('build/web/index.html');
        if (await indexFile.exists()) {
          request.response.headers.set('Content-Type', 'text/html; charset=utf-8');
          await indexFile.openRead().pipe(request.response);
          continue;
        }
      }

      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not Found');
      await request.response.close();
    }
  }
}

String _getMimeType(String path) {
  if (path.endsWith('.html')) return 'text/html; charset=utf-8';
  if (path.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (path.endsWith('.css')) return 'text/css; charset=utf-8';
  if (path.endsWith('.json')) return 'application/json';
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
  if (path.endsWith('.svg')) return 'image/svg+xml';
  if (path.endsWith('.wasm')) return 'application/wasm';
  if (path.endsWith('.mp3')) return 'audio/mpeg';
  return 'application/octet-stream';
}
