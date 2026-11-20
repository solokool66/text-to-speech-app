// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

Future<String> saveAudioFile(List<int> bytes, String filename) async {
  final uint8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  String savedPath = 'C:\\Users\\GOOFCEE\\Downloads\\TextSpeech\\$filename';

  // 1. Post to local server bridge to save directly into C:\Users\GOOFCEE\Downloads\TextSpeech\
  try {
    final response = await html.HttpRequest.request(
      'http://localhost:5050/save',
      method: 'POST',
      sendData: jsonEncode({
        'filename': filename,
        'bytes': base64Encode(uint8),
      }),
      requestHeaders: {'Content-Type': 'application/json'},
    );
    if (response.status == 200) {
      final data = jsonDecode(response.responseText ?? '{}');
      if (data['path'] != null) {
        savedPath = data['path'];
      }
    }
  } catch (e) {
    print('Failed to save via local bridge: $e');
  }

  // 2. Also trigger browser download anchor for redundancy
  final blob = html.Blob([uint8], 'audio/mpeg');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);

  return savedPath;
}
