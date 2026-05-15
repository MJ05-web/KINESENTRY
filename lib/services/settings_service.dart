import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _notificationKey = 'notification_enabled';
  static const _voiceKey = 'voice_enabled';
  static const _speakerKey = 'speaker_enabled';
  static const _deepSleepKey = 'deep_sleep_enabled';
  static const _themeKey = 'dark_theme_enabled';
  static const _dummyDataKey = 'dummy_data_enabled';

  bool _loaded = false;
  bool notificationEnabled = true;
  bool soundEnabled = true;
  bool speakerEnabled = false;
  bool deepSleepEnabled = false;
  bool darkThemeEnabled = true;
  bool dummyDataEnabled = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    notificationEnabled = prefs.getBool(_notificationKey) ?? true;
    soundEnabled = prefs.getBool(_voiceKey) ?? true;
    speakerEnabled = prefs.getBool(_speakerKey) ?? false;
    deepSleepEnabled = prefs.getBool(_deepSleepKey) ?? false;
    darkThemeEnabled = prefs.getBool(_themeKey) ?? true;
    dummyDataEnabled = prefs.getBool(_dummyDataKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setNotificationEnabled(bool value) async {
    notificationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationKey, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceKey, value);
  }

  Future<void> setSpeakerEnabled(bool value) async {
    speakerEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_speakerKey, value);
  }

  Future<void> setDeepSleepEnabled(bool value) async {
    deepSleepEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deepSleepKey, value);
  }

  Future<void> setDarkThemeEnabled(bool value) async {
    darkThemeEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }

  Future<void> setDummyDataEnabled(bool value) async {
    dummyDataEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dummyDataKey, value);
  }
}
