import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final FlutterTts tts = FlutterTts();

  static Future speak(String text) async {
    await tts.setLanguage("en-US");

    await tts.setPitch(1.0);       // normal
    await tts.setSpeechRate(0.9);  // 🔥 FAST & NATURAL

    await tts.speak(text);
  }
}