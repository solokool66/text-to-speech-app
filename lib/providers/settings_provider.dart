import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main()');
});

class SettingsNotifier extends StateNotifier<Map<String, String>> {
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs) : super({
    'elevenlabs_key': prefs.getString('elevenlabs_key') ?? '',
    'azure_key': prefs.getString('azure_key') ?? '',
    'google_key': prefs.getString('google_key') ?? '',
    'gemini_key': prefs.getString('gemini_key') ?? '',
    'active_engine': prefs.getString('active_engine') ?? 'edge',
  });

  void updateKey(String key, String value) {
    prefs.setString(key, value);
    state = {...state, key: value};
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
