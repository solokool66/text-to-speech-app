import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveAudioFile(List<int> bytes, String filename) async {
  Directory targetDir;
  final userProfile = Platform.environment['USERPROFILE'];

  if (Platform.isWindows && userProfile != null) {
    targetDir = Directory('$userProfile\\Downloads\\TextSpeech');
  } else if (Platform.isAndroid) {
    targetDir = Directory('/storage/emulated/0/Music/TextSpeech');
  } else {
    final baseDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    targetDir = Directory('${baseDir.path}/TextSpeech');
  }

  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final file = File('${targetDir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
