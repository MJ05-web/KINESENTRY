class SettingsService {

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  bool notificationEnabled = true; // 🔔
  bool soundEnabled = true;        // 🔊
  bool speakerEnabled = false;     // 🔈
}