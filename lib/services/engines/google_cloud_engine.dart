import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/voice.dart';
import '../tts_engine.dart';

class GoogleCloudEngine implements TtsEngine {
  @override
  String get id => 'google';

  @override
  String get name => 'Google Cloud TTS';

  @override
  bool get requiresApiKey => true;

  @override
  Future<List<Voice>> fetchVoices({String? apiKey}) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception('Google API Key required');
    final response = await http.get(
      Uri.parse('https://texttospeech.googleapis.com/v1/voices?key=${apiKey.trim()}'),
    );
    if (response.statusCode != 200) {
      throw Exception('Google TTS Error: ${response.body}');
    }
    final data = jsonDecode(response.body);
    final List<dynamic> voicesData = data['voices'];
    return voicesData.map((v) {
      final name = v['name'] as String;
      final lang = (v['languageCodes'] as List).first as String;
      return Voice(id: name, name: name.replaceAll(lang + '-', ''), locale: lang);
    }).where((v) {
      // Only keep English voices
      if (!v.locale.startsWith('en')) return false;
      // Filter out experimental or unknown models that require special params
      final n = v.name.toLowerCase();
      return n.contains('journey') || n.contains('studio') || n.contains('neural2') || n.contains('wavenet') || n.contains('standard');
    }).toList()
      ..sort((a, b) {
        // Sort by quality: Journey > Studio > Neural2 > Wavenet > Standard
        int score(String n) {
          n = n.toLowerCase();
          if (n.contains('journey')) return 5;
          if (n.contains('studio')) return 4;
          if (n.contains('neural2')) return 3;
          if (n.contains('wavenet')) return 2;
          if (n.contains('standard')) return 1;
          return 0;
        }
        return score(b.name).compareTo(score(a.name));
      });
  }

  @override
  Future<List<int>?> generateAudio(
    String text,
    Voice voice, {
    double pitch = 1.0,
    double rate = 1.0,
    String? apiKey,
  }) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception('Google API Key required');
    
    // Map pitch 0.5-2.0 to Google's -20.0 to 20.0 semitones
    double googlePitch = (pitch - 1.0) * 20.0;
    
    final response = await http.post(
      Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=${apiKey.trim()}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'input': {'text': text},
        'voice': {
          'languageCode': voice.locale,
          'name': voice.id,
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'pitch': googlePitch,
          'speakingRate': rate,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Google TTS Error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final audioContent = data['audioContent'] as String;
    return base64Decode(audioContent);
  }
}
