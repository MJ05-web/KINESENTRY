import 'auth_service.dart';
import 'health_rules.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'sound_service.dart';
import 'voice_service.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final SettingsService _settings = SettingsService();

  Future<void> notifyFall(Map<String, dynamic> data) async {
    if (AuthService().currentUser == null) {
      return;
    }

    Future<void> notificationFuture = Future.value();
    if (_settings.notificationEnabled) {
      notificationFuture = NotificationService().showFallAlert(
        title: 'Fall detected',
        body: _vitalsSummary(data),
      );
    }

    if (_settings.soundEnabled) {
      await SoundService.playFallAlert();
      await VoiceService.speak('Fall detected. Please check immediately.');
    }

    await notificationFuture;
  }

  Future<void> notifyGesture(Map<String, dynamic> data) async {
    if (AuthService().currentUser == null) {
      return;
    }

    final gesture = (data['gesture'] as num).toInt();
    final text = HealthRules.gestureText(gesture);

    Future<void> notificationFuture = Future.value();
    if (_settings.notificationEnabled) {
      notificationFuture = NotificationService().showGestureAlert(
        title: text,
        body: _vitalsSummary(data),
      );
    }

    if (_settings.soundEnabled) {
      await SoundService.playGestureAlert();
      await VoiceService.speak(text);
    }

    await notificationFuture;
  }

  Future<void> notifyBatteryLow(Map<String, dynamic> data) async {
    if (AuthService().currentUser == null) {
      return;
    }

    Future<void> notificationFuture = Future.value();
    if (_settings.notificationEnabled) {
      notificationFuture = NotificationService().showSystemAlert(
        title: 'Battery low',
        body: _vitalsSummary(data),
      );
    }

    if (_settings.soundEnabled) {
      await SoundService.playGestureAlert();
      await VoiceService.speak('Battery low. Please charge the device.');
    }

    await notificationFuture;
  }

  Future<void> stopAll() async {
    await SoundService.stop();
    await VoiceService.stop();
    await NotificationService().cancelAll();
  }

  String _vitalsSummary(Map<String, dynamic> data) {
    final bpm = ((data['bpm'] ?? 0) as num).toStringAsFixed(0);
    final spo2 = ((data['spo2'] ?? 0) as num).toStringAsFixed(0);
    final temp = ((data['temp'] ?? 0) as num).toStringAsFixed(1);
    final time = data['time'] is DateTime
        ? data['time'] as DateTime
        : DateTime.now();

    final clock =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return 'Time $clock | BPM $bpm | SpO2 $spo2% | Temp $temp C';
  }
}
