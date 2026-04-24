import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final player = AudioPlayer();

  static Future<void> playNotification() async {
    await player.play(AssetSource('sounds/ting.mp3'));
  }
}