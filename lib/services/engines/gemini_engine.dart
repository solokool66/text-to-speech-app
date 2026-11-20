import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/voice.dart';
import '../tts_engine.dart';

class GeminiTtsEngine implements TtsEngine {
  @override
  String get id => 'gemini';

  @override
  String get name => 'Google Gemini (Emotional)';

  @override
  bool get requiresApiKey => true;

  @override
  Future<List<Voice>> fetchVoices({String? apiKey}) async {
    // Gemini API does not have an endpoint to list audio voices yet,
    // so we hardcode the 5 beautiful prebuilt voices available in gemini-2.5-flash.
    return [
      Voice(id: 'Aoede', name: 'Aoede (Female - Expressive & Melodic)', locale: 'en-US'),
      Voice(id: 'Charon', name: 'Charon (Male - Cinematic & Reflective)', locale: 'en-US'),
      Voice(id: 'Kore', name: 'Kore (Female - Warm & Inspiring)', locale: 'en-US'),
      Voice(id: 'Fenrir', name: 'Fenrir (Male - Deep & Resonant)', locale: 'en-US'),
      Voice(id: 'Puck', name: 'Puck (Male - Warm & Compassionate)', locale: 'en-US'),
    ];
  }

  Uint8List _addWavHeader(Uint8List pcmBytes, int sampleRate) {
    final channels = 1;
    final byteRate = sampleRate * channels * 2; // 16-bit = 2 bytes

    final header = ByteData(44);
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, 36 + pcmBytes.length, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    header.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little); // Subchunk1Size
    header.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
    header.setUint16(22, channels, Endian.little); // NumChannels
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, byteRate, Endian.little); // ByteRate
    header.setUint16(32, channels * 2, Endian.little); // BlockAlign
    header.setUint16(34, 16, Endian.little); // BitsPerSample
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, pcmBytes.length, Endian.little);

    final wavBytes = BytesBuilder();
    wavBytes.add(header.buffer.asUint8List());
    wavBytes.add(pcmBytes);
    return wavBytes.toBytes();
  }

  @override
  Future<List<int>?> generateAudio(
    String text,
    Voice voice, {
    double pitch = 1.0, 
    double rate = 1.0,
    String? apiKey,
  }) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception('Gemini API Key required');

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/interactions');

    final payload = {
      'model': 'gemini-3.1-flash-tts-preview',
      'input': text,
      'response_format': {
        'type': 'audio'
      },
      'generation_config': {
        'speech_config': [
          {
            'voice': voice.id
          }
        ]
      }
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey.trim(),
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini TTS Error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    
    try {
      final steps = data['steps'] as List;
      if (steps.isEmpty) throw Exception('No steps returned from Gemini');
      
      final content = steps.first['content'];
      String base64Audio;
      
      if (content is List) {
        base64Audio = content.first['data'] as String;
      } else if (content is Map) {
        base64Audio = content['data'] as String;
      } else {
        throw Exception('Unexpected content format in response.');
      }
      
      final pcmBytes = base64Decode(base64Audio);
      return _addWavHeader(pcmBytes, 24000); // Wrap PCM inside standard WAV format
    } catch (e) {
      throw Exception('Failed to parse Gemini audio response: $e\nResponse: ${response.body}');
    }
  }
}
