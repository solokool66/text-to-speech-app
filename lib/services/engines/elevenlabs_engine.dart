import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/voice.dart';
import '../tts_engine.dart';

class ElevenLabsEngine implements TtsEngine {
  @override
  String get id => 'elevenlabs';

  @override
  String get name => 'ElevenLabs';

  @override
  bool get requiresApiKey => true;

  @override
  Future<List<Voice>> fetchVoices({String? apiKey}) async {
    if (apiKey == null || apiKey.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('https://api.elevenlabs.io/v1/voices'),
        headers: {
          'xi-api-key': apiKey.trim(),
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List voicesData = data['voices'];
        return voicesData.map((v) => Voice(
          id: v['voice_id'],
          name: v['name'],
          locale: v['labels']?['accent'] ?? 'en',
        )).toList();
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch ElevenLabs voices: $e');
    }
  }

  @override
  Future<List<int>?> generateAudio(
    String text,
    Voice voice, {
    double pitch = 1.0,
    double rate = 1.0,
    String? apiKey,
  }) async {
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/${voice.id}'),
        headers: {
          'xi-api-key': apiKey.trim(),
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
        },
        body: json.encode({
          'text': text,
          'model_id': 'eleven_multilingual_v2',
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('ElevenLabs API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error generating ElevenLabs audio: $e');
      return null;
    }
  }
}
