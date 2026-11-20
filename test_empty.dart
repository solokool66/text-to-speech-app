import 'package:edge_tts/edge_tts.dart'; void main() async { var t = Communicate(text: 'a'*5000, voice: 'en-US-AriaNeural'); var b = await t.toBytes(); print(b.length); }
