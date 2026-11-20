import 'audio_helper_stub.dart'
    if (dart.library.html) 'audio_helper_web.dart' as impl;

abstract class AppAudioPlayer {
  bool get isPlaying;
  double get progress;
  Duration get position;
  Duration get duration;
  void Function()? onStateChanged;

  Future<void> play(List<int> bytes);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(double ratio);
  Future<void> stop();
  void dispose();
}

AppAudioPlayer createAudioPlayer() => impl.createPlayer();
