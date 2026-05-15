import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final FlutterTts tts = FlutterTts();

  static Future<void> speak(String text) async {
    await tts.setLanguage('en-US');
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.9);
    await tts.stop();
    await tts.speak(text);
  }

  static Future<void> stop() async {
    await tts.stop();
  }
}
