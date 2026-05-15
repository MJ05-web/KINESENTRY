import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static Future<void> _queue = Future.value();

  static Future<void> playGestureAlert() async {
    await _enqueue(_playOnce);
  }

  static Future<void> playFallAlert() async {
    await _enqueue(() async {
      for (var i = 0; i < 3; i++) {
        await _playOnce();
        if (i < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 180));
        }
      }
    });
  }

  static Future<void> stop() async {
    _queue = Future.value();
    await _player.stop();
  }

  static Future<void> _playOnce() async {
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(AssetSource('sounds/ting.mp3'));
    await _player.onPlayerComplete.first;
  }

  static Future<void> _enqueue(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.catchError((_) {});
    return next;
  }
}
