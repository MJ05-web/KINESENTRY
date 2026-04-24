import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'alert_service.dart';
import 'health_rules.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final _controller = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get stream => _controller.stream;

  final _random = Random();
  final Map<String, DateTime> _lastAlertTime = {};

  Timer? _timer;
  Map<String, dynamic>? latestData;
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> sessionData = [];
  List<Map<String, dynamic>> alertHistory = [];

  bool isSessionActive = false;
  int _lastGesture = 0;

  void startSession() {
    sessionData.clear();
    isSessionActive = true;
  }

  void stopSession() {
    isSessionActive = false;
  }

  void addAlert(
    String message,
    String type, {
    String severity = 'warning',
    String detail = '',
    String key = '',
  }) {
    alertHistory.insert(0, {
      'message': message,
      'detail': detail,
      'type': type,
      'severity': severity,
      'key': key,
      'time': DateTime.now(),
    });

    if (alertHistory.length > 80) {
      alertHistory.removeLast();
    }
  }

  void updateData(Map<String, dynamic> data, BuildContext? context) {
    final entry = HealthRules.normalize({...data, 'time': DateTime.now()});

    latestData = entry;
    history.add(entry);

    if (history.length > 2000) {
      history.removeRange(0, history.length - 2000);
    }

    if (isSessionActive) {
      sessionData.add(entry);
    }

    _controller.add({
      'bpm': (entry['bpm'] as num).toDouble(),
      'spo2': (entry['spo2'] as num).toDouble(),
      'temp': (entry['temp'] as num).toDouble(),
      'gesture': (entry['gesture'] as num).toDouble(),
      'fall': (entry['fall'] as num).toDouble(),
      'battery': (entry['battery'] as num).toDouble(),
    });

    if (context != null) {
      checkAlerts(context, entry);
    }
  }

  void checkAlerts(BuildContext context, Map<String, dynamic> data) {
    final alertService = AlertService();
    final now = DateTime.now();

    for (final alert in HealthRules.evaluate(data)) {
      if (alert.category == HealthRules.categoryGesture) {
        final gesture = (data['gesture'] as num).toInt();
        if (gesture == 0 || gesture == _lastGesture) continue;
        _lastGesture = gesture;
      }

      if (!_shouldTrigger(alert.key, now)) continue;

      addAlert(
        alert.title,
        alert.category,
        severity: alert.severity,
        detail: alert.detail,
        key: alert.key,
      );

      alertService.triggerAlert(
        context,
        '${alert.title}: ${alert.detail}',
        type: alert.category,
        severity: alert.severity,
      );
    }

    if ((data['gesture'] as num).toInt() == 0) {
      _lastGesture = 0;
    }
  }

  bool _shouldTrigger(String key, DateTime now) {
    final last = _lastAlertTime[key];
    if (last != null && now.difference(last) < const Duration(seconds: 45)) {
      return false;
    }

    _lastAlertTime[key] = now;
    return true;
  }

  void startDummyData(BuildContext context) {
    stopDummy();
    startSession();

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      final data = {
        'bpm': 58 + _random.nextInt(58).toDouble(),
        'spo2': 90 + _random.nextInt(10).toDouble(),
        'temp': 36 + _random.nextDouble() * 2.3,
        'gesture': _random.nextInt(8) == 0
            ? 1 + _random.nextInt(6).toDouble()
            : 0.0,
        'fall': _random.nextInt(18) == 0 ? 5.0 : 0.0,
        'battery': 15 + _random.nextInt(85).toDouble(),
      };

      updateData(data, context);
    });
  }

  void stopDummy() {
    _timer?.cancel();
    _timer = null;
  }

  void clearAll() {
    history.clear();
    sessionData.clear();
    alertHistory.clear();
    latestData = null;
    _lastAlertTime.clear();
  }
}
