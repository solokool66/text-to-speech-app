import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeEngine = settings['active_engine'] ?? 'edge';
    final elevenlabsKey = settings['elevenlabs_key'] ?? '';

    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: Text('Settings', style: GoogleFonts.outfit(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Engine', style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeEngine,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2C2C2E),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'edge', child: Text('Free (Microsoft Edge)')),
                    DropdownMenuItem(value: 'elevenlabs', child: Text('ElevenLabs')),
                    DropdownMenuItem(value: 'azure', child: Text('Microsoft Azure')),
                    DropdownMenuItem(value: 'google', child: Text('Google Cloud')),
                    DropdownMenuItem(value: 'gemini', child: Text('Google Gemini')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).updateKey('active_engine', val);
                    }
                  },
                ),
              ),
            ),
            if (activeEngine != 'edge') ...[
              const SizedBox(height: 20),
              Text(
                activeEngine == 'elevenlabs'
                    ? 'ElevenLabs API Key'
                    : activeEngine == 'azure'
                        ? 'Azure API Key'
                        : activeEngine == 'google'
                            ? 'Google Cloud API Key'
                            : 'Gemini API Key',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(
                  text: activeEngine == 'elevenlabs'
                      ? settings['elevenlabs_key'] ?? ''
                      : activeEngine == 'azure'
                          ? settings['azure_key'] ?? ''
                          : activeEngine == 'google'
                              ? settings['google_key'] ?? ''
                              : settings['gemini_key'] ?? '',
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter API Key',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  final keyName = activeEngine == 'elevenlabs'
                      ? 'elevenlabs_key'
                      : activeEngine == 'azure'
                          ? 'azure_key'
                          : activeEngine == 'google'
                              ? 'google_key'
                              : 'gemini_key';
                  ref.read(settingsProvider.notifier).updateKey(keyName, val);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Colors.purpleAccent)),
        ),
      ],
    );
  }
}
