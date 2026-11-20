import '../models/voice.dart';

/// Abstract class representing a TTS Engine (e.g. Edge, ElevenLabs, Azure, Google)
abstract class TtsEngine {
  /// Unique identifier for the engine
  String get id;

  /// Display name for the engine
  String get name;

  /// Whether this engine requires an API key
  bool get requiresApiKey;

  /// Fetch available voices for this engine
  Future<List<Voice>> fetchVoices({String? apiKey});

  /// Generate audio bytes from text using a specific voice
  Future<List<int>?> generateAudio(
    String text,
    Voice voice, {
    double pitch = 1.0,
    double rate = 1.0,
    String? apiKey,
  });
}
