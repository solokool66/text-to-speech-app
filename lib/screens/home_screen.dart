import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tts_provider.dart';
import '../utils/audio_helper.dart';
import 'dart:typed_data';
import 'package:toastification/toastification.dart';
import '../utils/downloader.dart';
import 'settings_dialog.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AppAudioPlayer _audioPlayer;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioPlayer = createAudioPlayer();
    _audioPlayer.onStateChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  double? _dragValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleAudio(List<int> bytes) async {
    if (_audioPlayer.isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.progress > 0 && _audioPlayer.progress < 1.0) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.play(bytes);
      }
    }
  }

  Future<void> _saveAudio(List<int> bytes) async {
    try {
      var title = _titleController.text.trim();
      title = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final filename = title.isNotEmpty ? '$title.mp3' : 'tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

      final savedLocation = await saveAudioFile(bytes, filename);

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flat,
        title: const Text('Saved successfully'),
        description: Text('Audio saved: $savedLocation'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        icon: const Icon(Icons.check_circle_outline),
        primaryColor: Colors.green,
        backgroundColor: const Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        title: const Text('Failed to save audio'),
        description: Text(e.toString()),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 5),
        icon: const Icon(Icons.error_outline),
        primaryColor: Colors.red,
        backgroundColor: const Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final text = ref.watch(textInputProvider);
    final voicesAsync = ref.watch(voicesProvider);
    final selectedVoice = ref.watch(selectedVoiceProvider);
    final isGenerating = ref.watch(isGeneratingProvider);
    final audioBytes = ref.watch(audioBytesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Text Speech',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SettingsDialog(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------- TOP BUTTONS -----------------
              // Audio Player (Visible only when audio is ready)
              if (audioBytes != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _audioPlayer.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                              color: Colors.purpleAccent,
                              size: 44,
                            ),
                            onPressed: () => _toggleAudio(audioBytes),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                activeTrackColor: Colors.purpleAccent,
                                inactiveTrackColor: Colors.white12,
                                thumbColor: Colors.purpleAccent,
                                overlayColor: const Color(0x33E040FB),
                              ),
                              child: Slider(
                                value: (_dragValue ?? _audioPlayer.progress).clamp(0.0, 1.0),
                                onChanged: (val) {
                                  setState(() {
                                    _dragValue = val;
                                  });
                                },
                                onChangeEnd: (val) async {
                                  await _audioPlayer.seek(val);
                                  setState(() {
                                    _dragValue = null;
                                  });
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_rounded, color: Colors.white),
                            tooltip: 'Download MP3',
                            onPressed: () => _saveAudio(audioBytes),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_audioPlayer.position),
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            Text(
                              _formatDuration(_audioPlayer.duration),
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (text.isEmpty || selectedVoice == null || isGenerating)
                      ? null
                      : () async {
                          try {
                            await ref.read(ttsNotifierProvider.notifier).generateAudio();
                          } catch (e) {
                            if (!mounted) return;
                            toastification.show(
                              context: context,
                              type: ToastificationType.error,
                              style: ToastificationStyle.flatColored,
                              title: const Text('Generation Failed'),
                              description: Text(e.toString()),
                              alignment: Alignment.topCenter,
                              autoCloseDuration: const Duration(seconds: 5),
                              icon: const Icon(Icons.error_outline),
                              primaryColor: Colors.red,
                              backgroundColor: const Color(0xFF1C1C1E),
                              foregroundColor: Colors.white,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    disabledBackgroundColor: Colors.grey.shade800,
                  ),
                  child: isGenerating
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(
                          'Generate Audio',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // -----------------------------------------------

              // Voice Selector Label
              Text(
                'Select Voice',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),

              // Voice Selector Horizontal List
              SizedBox(
                height: 75,
                child: voicesAsync.when(
                  data: (voices) {
                    if (voices.isEmpty) {
                      return const Center(
                          child: Text("No voices found.",
                              style: TextStyle(color: Colors.white)));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: voices.length,
                      itemBuilder: (context, index) {
                        final voice = voices[index];
                        final isSelected = selectedVoice?.id == voice.id;

                        return GestureDetector(
                          onTap: () {
                            ref.read(selectedVoiceProvider.notifier).state = voice;
                          },
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.purpleAccent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.purple.withOpacity(0.2),
                                    child: Text(
                                      voice.name.isNotEmpty ? voice.name[0] : '?',
                                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    voice.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text(
                                  voice.locale,
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
                  error: (e, st) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Error: ${e.toString()}', style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Voice Settings (Pitch & Speed)
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text('Spd: ${ref.watch(rateProvider).toStringAsFixed(1)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: ref.watch(rateProvider),
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            activeColor: Colors.purpleAccent,
                            onChanged: (val) => ref.read(rateProvider.notifier).state = val,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Text('Ptch: ${ref.watch(pitchProvider).toStringAsFixed(1)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: ref.watch(pitchProvider),
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            activeColor: Colors.blueAccent,
                            onChanged: (val) => ref.read(pitchProvider.notifier).state = val,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title Input Label
              Text(
                'Audio Title',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),

              // Title Input Field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                child: TextField(
                  controller: _titleController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Enter title for file (e.g. MyVoice)',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              
              const SizedBox(height: 15),

              // Text Input Label
              Text(
                'What should they say?',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),

              // Text Input Field (Glassmorphism inspired)
              Container(
                height: 250, // Fixed height to prevent keyboard overflow
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(15),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Enter text here...',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    ref.read(textInputProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(height: 10),

            // Character count
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${text.length} / 5000',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),

          ],
        ),
      ),
      ),
    );
  }
}

