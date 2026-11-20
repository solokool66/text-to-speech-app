import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'audio_helper.dart';

class NativeAppAudioPlayer implements AppAudioPlayer {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void Function()? onStateChanged;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _completeSub;

  NativeAppAudioPlayer() {
    _completeSub = _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _progress = 0.0;
      _position = Duration.zero;
      onStateChanged?.call();
    });
    _durSub = _player.onDurationChanged.listen((dur) {
      _duration = dur;
      onStateChanged?.call();
    });
    _posSub = _player.onPositionChanged.listen((pos) {
      _position = pos;
      if (_duration.inMilliseconds > 0) {
        _progress = (pos.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
        onStateChanged?.call();
      }
    });
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  double get progress => _progress;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  Future<void> play(List<int> bytes) async {
    _isPlaying = true;
    _progress = 0.0;
    _position = Duration.zero;
    onStateChanged?.call();
    await _player.stop();
    await _player.play(BytesSource(Uint8List.fromList(bytes)));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    onStateChanged?.call();
  }

  @override
  Future<void> resume() async {
    await _player.resume();
    _isPlaying = true;
    onStateChanged?.call();
  }

  @override
  Future<void> seek(double ratio) async {
    if (_duration.inMilliseconds > 0) {
      final targetMs = (ratio.clamp(0.0, 1.0) * _duration.inMilliseconds).round();
      final target = Duration(milliseconds: targetMs);
      await _player.seek(target);
      _position = target;
      _progress = ratio.clamp(0.0, 1.0);
      onStateChanged?.call();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _progress = 0.0;
    _position = Duration.zero;
    onStateChanged?.call();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
  }
}

AppAudioPlayer createPlayer() => NativeAppAudioPlayer();
