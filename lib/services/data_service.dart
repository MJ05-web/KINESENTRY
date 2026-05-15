import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'alert_service.dart';
import 'health_rules.dart';

class DataService extends ChangeNotifier {
  static const _fallAlertCooldown = Duration(seconds: 12);

  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final _controller = StreamController<Map<String, double>>.broadcast();
  final _alertController = StreamController<Map<String, dynamic>>.broadcast();
  final _random = Random();
  final Map<String, DateTime> _lastAlertTime = {};

  Stream<Map<String, double>> get stream => _controller.stream;
  Stream<Map<String, dynamic>> get alertStream => _alertController.stream;

  Timer? _timer;
  Map<String, dynamic>? latestData;
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> sessionData = [];
  List<Map<String, dynamic>> alertHistory = [];

  List<Map<String, dynamic>> get recordedVitalHistory =>
      _recordedVitals(history);

  List<Map<String, dynamic>> get recordedSessionData =>
      _recordedVitals(sessionData);

  bool isSessionActive = false;
  int _lastGesture = 0;
  bool _lastFallActive = false;
  double _dummyBattery = 85;
  int _dummyTick = 0;

  void startSession() {
    sessionData.clear();
    isSessionActive = true;
    notifyListeners();
  }

  void stopSession() {
    isSessionActive = false;
    notifyListeners();
  }

  void addAlert(
    String message,
    String type, {
    String severity = 'warning',
    String detail = '',
    String key = '',
  }) {
    final alert = {
      'message': message,
      'detail': detail,
      'type': type,
      'severity': severity,
      'key': key,
      'time': DateTime.now(),
    };

    alertHistory.insert(0, alert);

    if (alertHistory.length > 80) {
      alertHistory.removeLast();
    }

    notifyListeners();
    _alertController.add(alert);
  }

  void updateData(Map<String, dynamic> data) {
    final entry = HealthRules.normalize({...data, 'time': DateTime.now()});

    latestData = entry;
    history.add(entry);
    if (history.length > 2000) {
      history.removeRange(0, history.length - 2000);
    }

    if (isSessionActive) {
      sessionData.add(entry);
    }

    notifyListeners();

    _controller.add({
      'bpm': (entry['bpm'] as num).toDouble(),
      'spo2': (entry['spo2'] as num).toDouble(),
      'temp': (entry['temp'] as num).toDouble(),
      'gesture': (entry['gesture'] as num).toDouble(),
      'fall': (entry['fall'] as num).toDouble(),
      'battery': (entry['battery'] as num).toDouble(),
    });

    _checkAlerts(entry);
  }

  Future<void> _checkAlerts(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final gesture = (data['gesture'] as num).toInt();
    final fall = (data['fall'] as num).toDouble();
    final battery = (data['battery'] as num).toInt();
    final fallActive = fall > 0;

    if (fallActive &&
        !_lastFallActive &&
        _shouldTrigger('fall', now, cooldown: _fallAlertCooldown)) {
      addAlert(
        'Fall detected',
        HealthRules.categoryCritical,
        severity: 'critical',
        detail: 'Immediate attention may be required.',
        key: 'fall',
      );
      await AlertService().notifyFall(data);
    }
    _lastFallActive = fallActive;

    if (gesture > 0 && gesture != _lastGesture) {
      _lastGesture = gesture;
      final text = HealthRules.gestureText(gesture);
      addAlert(
        text,
        HealthRules.categoryGesture,
        severity: 'gesture',
        detail: 'Gesture command received.',
        key: 'gesture-$gesture',
      );
      await AlertService().notifyGesture(data);
    }

    if (gesture == 0) {
      _lastGesture = 0;
    }

    if (battery < 30 && _shouldTrigger('battery', now)) {
      addAlert(
        'Battery critical',
        HealthRules.categoryBattery,
        severity: 'critical',
        detail: '$battery% remaining.',
        key: 'battery',
      );
      await AlertService().notifyBatteryLow(data);
    }
  }

  bool _shouldTrigger(
    String key,
    DateTime now, {
    Duration cooldown = const Duration(seconds: 45),
  }) {
    final last = _lastAlertTime[key];
    if (last != null && now.difference(last) < cooldown) {
      return false;
    }
    _lastAlertTime[key] = now;
    return true;
  }

  void startDummyData() {
    stopDummy();
    startSession();
    _dummyBattery = 85;
    _dummyTick = 0;

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _dummyTick++;
      if (_dummyTick % 90 == 0 && _dummyBattery > 0) {
        _dummyBattery = max(0, _dummyBattery - 1);
      }

      final data = {
        'bpm': 58 + _random.nextInt(58).toDouble(),
        'spo2': 90 + _random.nextInt(10).toDouble(),
        'temp': 36 + _random.nextDouble() * 2.3,
        'gesture': _random.nextInt(8) == 0
            ? 1 + _random.nextInt(3).toDouble()
            : 0.0,
        'fall': _random.nextInt(18) == 0 ? 1.0 : 0.0,
        'battery': _dummyBattery,
      };

      updateData(data);
    });
  }

  void stopDummy() {
    _timer?.cancel();
    _timer = null;
  }

  void clearAll() {
    stopDummy();
    stopSession();
    history.clear();
    sessionData.clear();
    alertHistory.clear();
    latestData = null;
    _lastGesture = 0;
    _lastFallActive = false;
    _lastAlertTime.clear();
    notifyListeners();
    _controller.add({});
  }

  List<Map<String, dynamic>> recordedVitalsFrom(
    List<Map<String, dynamic>> source,
  ) {
    return _recordedVitals(source);
  }

  List<Map<String, dynamic>> _recordedVitals(List<Map<String, dynamic>> source) {
    return source.where(_hasRecordedVitals).toList(growable: false);
  }

  bool _hasRecordedVitals(Map<String, dynamic> entry) {
    final bpm = (entry['bpm'] as num?)?.toDouble() ?? 0;
    final spo2 = (entry['spo2'] as num?)?.toDouble() ?? 0;
    final temp = (entry['temp'] as num?)?.toDouble() ?? 0;
    return bpm > 0 && spo2 > 0 && temp > 0;
  }
}
