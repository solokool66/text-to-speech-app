import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voice.dart';
import '../services/tts_engine.dart';
import '../services/engines/edge_engine.dart';
import '../services/engines/elevenlabs_engine.dart';
import '../services/engines/azure_engine.dart';
import '../services/engines/google_cloud_engine.dart';
import '../services/engines/gemini_engine.dart';
import 'settings_provider.dart';

// Available engines
final edgeEngine = EdgeTtsEngine();
final elevenLabsEngine = ElevenLabsEngine();
final azureEngine = AzureTtsEngine();
final googleEngine = GoogleCloudEngine();
final geminiEngine = GeminiTtsEngine();

// Providers
final ttsServiceProvider = Provider<TtsEngine>((ref) {
  final settings = ref.watch(settingsProvider);
  final active = settings['active_engine'];
  
  if (active == 'elevenlabs') return elevenLabsEngine;
  if (active == 'azure') return azureEngine;
  if (active == 'google') return googleEngine;
  if (active == 'gemini') return geminiEngine;
  
  return edgeEngine;
});

final voicesProvider = FutureProvider<List<Voice>>((ref) async {
  final service = ref.watch(ttsServiceProvider);
  final settings = ref.watch(settingsProvider);
  
  String? apiKey;
  if (service.id == 'elevenlabs') {
    apiKey = settings['elevenlabs_key'];
  } else if (service.id == 'azure') {
    apiKey = settings['azure_key'];
  } else if (service.id == 'google') {
    apiKey = settings['google_key'];
  } else if (service.id == 'gemini') {
    apiKey = settings['gemini_key'];
  }
  
  return service.fetchVoices(apiKey: apiKey);
});

final selectedVoiceProvider = StateProvider<Voice?>((ref) => null);
final textInputProvider = StateProvider<String>((ref) => '');
final isGeneratingProvider = StateProvider<bool>((ref) => false);
final audioBytesProvider = StateProvider<List<int>?>((ref) => null);

// Pitch and Rate (1.0 is default)
final pitchProvider = StateProvider<double>((ref) => 1.0);
final rateProvider = StateProvider<double>((ref) => 1.0);

// StateNotifier to manage generation flow
class TTSNotifier extends StateNotifier<void> {
  final Ref ref;

  TTSNotifier(this.ref) : super(null);

  Future<void> generateAudio() async {
    final text = ref.read(textInputProvider);
    final voice = ref.read(selectedVoiceProvider);
    
    if (text.isEmpty || voice == null) return;

    ref.read(isGeneratingProvider.notifier).state = true;
    ref.read(audioBytesProvider.notifier).state = null; // reset

    final pitch = ref.read(pitchProvider);
    final rate = ref.read(rateProvider);

    final service = ref.read(ttsServiceProvider);
    final settings = ref.read(settingsProvider);
    
    String? apiKey;
    if (service.id == 'elevenlabs') {
      apiKey = settings['elevenlabs_key'];
    } else if (service.id == 'azure') {
      apiKey = settings['azure_key'];
    } else if (service.id == 'google') {
      apiKey = settings['google_key'];
    } else if (service.id == 'gemini') {
      apiKey = settings['gemini_key'];
    }

    try {
      final bytes = await service.generateAudio(
        text, 
        voice, 
        pitch: pitch, 
        rate: rate,
        apiKey: apiKey,
      );

      ref.read(audioBytesProvider.notifier).state = bytes;
    } finally {
      ref.read(isGeneratingProvider.notifier).state = false;
    }
  }
}

final ttsNotifierProvider = StateNotifierProvider<TTSNotifier, void>((ref) {
  return TTSNotifier(ref);
});

