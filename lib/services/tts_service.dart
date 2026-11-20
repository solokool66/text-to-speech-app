import 'package:edge_tts/edge_tts.dart' hide Voice;
import '../models/voice.dart';

class TTSService {
  /// Fetches available voices from the device
  Future<List<Voice>> fetchVoices() async {
    try {
      final voicesDynamic = await listVoices();
      
      final premiumVoiceIds = [
        'en-US-AriaNeural',
        'en-US-GuyNeural',
        'en-US-JennyNeural',
        'en-US-ChristopherNeural',
        'en-US-EricNeural',
        'en-US-MichelleNeural',
        'en-US-RogerNeural',
        'en-US-SteffanNeural',
        'en-GB-SoniaNeural',
        'en-GB-RyanNeural',
        'en-GB-LibbyNeural',
        'en-AU-NatashaNeural',
        'en-AU-WilliamNeural',
      ];

      final englishVoices = voicesDynamic
          .where((v) => premiumVoiceIds.contains(v.shortName))
          .map((v) => Voice(
                id: v.shortName,
                name: v.shortName.split('-').last.replaceAll('Neural', ''),
                locale: v.locale,
              ))
          .toList();
          
      // Sort to match our preferred order
      englishVoices.sort((a, b) => premiumVoiceIds.indexOf(a.id).compareTo(premiumVoiceIds.indexOf(b.id)));
      
      return englishVoices;
    } catch (e) {
      print('Error fetching voices: $e');
      return [];
    }
  }

  /// Generates audio from text using a specific voice, pitch and rate
  Future<List<int>?> generateAudio(String text, Voice voice, {double pitch = 1.0, double rate = 1.0}) async {
    try {
      String toPercentage(double val) {
        int percent = ((val - 1.0) * 100).round();
        return percent >= 0 ? '+$percent%' : '$percent%';
      }

      final tts = Communicate(
        text: text,
        voice: voice.id,
        pitch: toPercentage(pitch),
        rate: toPercentage(rate),
      );
      
      final bytes = await tts.toBytes();
      return bytes;
    } catch (e) {
      print('Error speaking audio: $e');
      return null;
    }
  }
}
