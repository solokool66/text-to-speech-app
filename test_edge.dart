import 'package:edge_tts/edge_tts.dart';

void main() async {
  final voices = await listVoices();
  final englishVoices = voices.where((v) => v.locale.startsWith('en')).toList();
  for (var v in englishVoices) {
    print(v.shortName);
  }
}
