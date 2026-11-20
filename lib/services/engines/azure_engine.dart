import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/voice.dart';
import '../tts_engine.dart';

class AzureTtsEngine implements TtsEngine {
  @override
  String get id => 'azure';

  @override
  String get name => 'Microsoft Azure TTS';

  @override
  bool get requiresApiKey => true;

  @override
  Future<List<Voice>> fetchVoices({String? apiKey}) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception('Azure API Key required');
    
    // We are hardcoding eastus here based on the user's setup, but this could be made dynamic in settings later
    final response = await http.get(
      Uri.parse('https://eastus.tts.speech.microsoft.com/cognitiveservices/voices/list'),
      headers: {
        'Ocp-Apim-Subscription-Key': apiKey.trim(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Azure TTS Error: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    
    final englishVoices = data.map((v) {
      return Voice(
        id: v['ShortName'] as String,
        name: (v['DisplayName'] as String) + (v['VoiceType'] == 'Neural' ? '' : ' (Standard)'),
        locale: v['Locale'] as String,
      );
    }).where((v) => v.locale.startsWith('en')).toList();

    englishVoices.sort((a, b) {
      int score(Voice v) {
        final n = v.name.toLowerCase();
        final id = v.id.toLowerCase();
        
        // Azure's absolute best voices
        if (id.contains('multilingual') || n.contains('multilingual')) return 100;
        if (n.contains('dragon hd') || n.contains('hd')) return 90;
        
        // Flagship US Voices
        if (id.contains('en-us-jenny')) return 85;
        if (id.contains('en-us-guy')) return 84;
        if (id.contains('en-us-aria')) return 83;
        if (id.contains('en-us-davis')) return 82;
        if (id.contains('en-us-jane')) return 81;
        if (id.contains('en-us-jason')) return 80;
        if (id.contains('en-us-sara')) return 79;
        if (id.contains('en-us-tony')) return 78;
        if (id.contains('en-us-steffan')) return 77;
        
        // General Neural preferences
        if (id.contains('en-us')) return 50;
        if (id.contains('en-gb')) return 40;
        
        // Penalize old standard voices
        if (n.contains('standard')) return -10;
        return 0;
      }
      
      final sA = score(a);
      final sB = score(b);
      
      if (sA != sB) {
        return sB.compareTo(sA); // Higher score first
      }
      return a.name.compareTo(b.name); // Alphabetical tie-breaker
    });

    return englishVoices;
  }

  @override
  Future<List<int>?> generateAudio(
    String text,
    Voice voice, {
    double pitch = 1.0,
    double rate = 1.0,
    String? apiKey,
  }) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception('Azure API Key required');

    String toPercentage(double val) {
      int percent = ((val - 1.0) * 100).round();
      return percent >= 0 ? '+$percent%' : '$percent%';
    }

    final ssml = '''
<speak version='1.0' xml:lang='${voice.locale}'>
  <voice name='${voice.id}'>
    <prosody rate='${toPercentage(rate)}' pitch='${toPercentage(pitch)}'>
      ${text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')}
    </prosody>
  </voice>
</speak>
''';

    final response = await http.post(
      Uri.parse('https://eastus.tts.speech.microsoft.com/cognitiveservices/v1'),
      headers: {
        'Ocp-Apim-Subscription-Key': apiKey.trim(),
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': 'audio-16khz-32kbitrate-mono-mp3',
        'User-Agent': 'TextSpeechApp',
      },
      body: ssml,
    );

    if (response.statusCode != 200) {
      throw Exception('Azure TTS Error: ${response.body}');
    }

    return response.bodyBytes;
  }
}
