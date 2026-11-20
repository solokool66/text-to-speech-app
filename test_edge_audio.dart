import 'package:edge_tts/edge_tts.dart';

void main() async {
  try {
    print('Generating audio...');
    final tts = Communicate(text: 'Hello world', voice: 'en-US-AriaNeural', pitch: '+10Hz', rate: '+10%');
    final bytes = await tts.toBytes();
    print('Generated ${bytes.length} bytes.');
  } catch (e) {
    print('ERROR generating audio: $e');
  }
}
