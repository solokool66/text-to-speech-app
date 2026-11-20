import 'downloader_stub.dart'
    if (dart.library.html) 'downloader_web.dart' as impl;

Future<String> saveAudioFile(List<int> bytes, String filename) {
  return impl.saveAudioFile(bytes, filename);
}
