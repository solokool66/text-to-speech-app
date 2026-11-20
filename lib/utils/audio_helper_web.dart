// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'audio_helper.dart';

class WebAppAudioPlayer implements AppAudioPlayer {
  html.AudioElement? _audio;
  String? _blobUrl;
  bool _isPlaying = false;
  double _progress = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void Function()? onStateChanged;

  StreamSubscription? _endedSub;
  StreamSubscription? _timeSub;
  StreamSubscription? _metaSub;

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
    await stop();

    final uint8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final blob = html.Blob([uint8], 'audio/mpeg');
    _blobUrl = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(_blobUrl);
    _audio = audio;
    _isPlaying = true;
    _progress = 0.0;
    _position = Duration.zero;
    onStateChanged?.call();

    _metaSub = audio.onLoadedMetadata.listen((_) {
      if (audio.duration != null && !audio.duration.isNaN && audio.duration > 0) {
        _duration = Duration(milliseconds: (audio.duration * 1000).round());
        onStateChanged?.call();
      }
    });

    _endedSub = audio.onEnded.listen((_) {
      _isPlaying = false;
      _progress = 0.0;
      _position = Duration.zero;
      onStateChanged?.call();
    });

    _timeSub = audio.onTimeUpdate.listen((_) {
      final currentSec = audio.currentTime ?? 0;
      _position = Duration(milliseconds: (currentSec * 1000).round());

      final durSec = audio.duration ?? 0;
      if (!durSec.isNaN && durSec > 0) {
        _duration = Duration(milliseconds: (durSec * 1000).round());
        _progress = (currentSec / durSec).clamp(0.0, 1.0);
      }
      onStateChanged?.call();
    });

    try {
      await audio.play();
    } catch (e) {
      print('Web audio play error: $e');
      _isPlaying = false;
      onStateChanged?.call();
    }
  }

  @override
  Future<void> pause() async {
    _audio?.pause();
    _isPlaying = false;
    onStateChanged?.call();
  }

  @override
  Future<void> resume() async {
    if (_audio != null) {
      try {
        await _audio!.play();
        _isPlaying = true;
        onStateChanged?.call();
      } catch (e) {
        print('Web audio resume error: $e');
      }
    }
  }

  @override
  Future<void> seek(double ratio) async {
    if (_audio != null) {
      final durSec = _audio!.duration ?? 0;
      if (!durSec.isNaN && durSec > 0) {
        final targetSec = (ratio.clamp(0.0, 1.0) * durSec);
        _audio!.currentTime = targetSec;
        _position = Duration(milliseconds: (targetSec * 1000).round());
        _progress = ratio.clamp(0.0, 1.0);
        onStateChanged?.call();
      }
    }
  }

  @override
  Future<void> stop() async {
    _endedSub?.cancel();
    _timeSub?.cancel();
    _metaSub?.cancel();
    if (_audio != null) {
      _audio?.pause();
      _audio?.currentTime = 0;
      _audio = null;
    }
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
      _blobUrl = null;
    }
    _isPlaying = false;
    _progress = 0.0;
    _position = Duration.zero;
    _duration = Duration.zero;
    onStateChanged?.call();
  }

  @override
  void dispose() {
    stop();
  }
}

AppAudioPlayer createPlayer() => WebAppAudioPlayer();
