import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:edge_tts/edge_tts.dart' hide Voice;
import '../../models/voice.dart';
import '../tts_engine.dart';

class EdgeTtsEngine implements TtsEngine {
  @override
  String get id => 'edge';

  @override
  String get name => 'Free (Microsoft Edge)';

  @override
  bool get requiresApiKey => false;

  static const _premiumVoiceIds = [
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
    'en-NG-EzinneNeural',
    'en-NG-AbeoNeural',
    'en-ZA-LeahNeural',
    'en-ZA-LukeNeural',
    'en-KE-AsyaNeural',
    'en-KE-ChilembaNeural',
  ];

  static List<Voice> _getFallbackVoices() {
    return _premiumVoiceIds.map((id) {
      final parts = id.split('-');
      final locale = parts.length >= 2 ? '${parts[0]}-${parts[1]}' : 'en-US';
      final name = parts.last.replaceAll('Neural', '');
      return Voice(id: id, name: name, locale: locale);
    }).toList();
  }

  @override
  Future<List<Voice>> fetchVoices({String? apiKey}) async {
    if (kIsWeb) {
      return _getFallbackVoices();
    }
    try {
      final voicesDynamic = await listVoices();

      final englishVoices = voicesDynamic
          .where((v) => _premiumVoiceIds.contains(v.shortName))
          .map((v) => Voice(
                id: v.shortName,
                name: v.shortName.split('-').last.replaceAll('Neural', ''),
                locale: v.locale,
              ))
          .toList();

      englishVoices.sort((a, b) =>
          _premiumVoiceIds.indexOf(a.id).compareTo(_premiumVoiceIds.indexOf(b.id)));

      return englishVoices.isNotEmpty ? englishVoices : _getFallbackVoices();
    } catch (e) {
      return _getFallbackVoices();
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
    String toPercentage(double val) {
      int percent = ((val - 1.0) * 100).round();
      return percent >= 0 ? '+$percent%' : '$percent%';
    }

    String toHz(double val) {
      int hz = ((val - 1.0) * 50).round();
      return hz >= 0 ? '+$hz' 'Hz' : '$hz' 'Hz';
    }

    if (kIsWeb) {
      try {
        final uri = Uri.parse('http://localhost:5050/synthesize');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'text': text,
            'voice': voice.id,
            'pitch': toHz(pitch),
            'rate': toPercentage(rate),
          }),
        );

        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          throw Exception(
            'TTS Server error (${response.statusCode}): ${response.body}\n'
            'Ensure the local TTS server is running: dart run tts_server.dart',
          );
        }
      } catch (e) {
        print('Error generating Edge audio on web: $e');
        rethrow;
      }
    }

    try {
      final tts = Communicate(
        text: text,
        voice: voice.id,
        pitch: toHz(pitch),
        rate: toPercentage(rate),
      );

      final bytes = await tts.toBytes();
      return bytes;
    } catch (e) {
      print('Error speaking Edge audio: $e');
      return null;
    }
  }
}
