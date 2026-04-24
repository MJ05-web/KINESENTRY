class HealthAlert {
  const HealthAlert({
    required this.key,
    required this.title,
    required this.detail,
    required this.category,
    required this.severity,
  });

  final String key;
  final String title;
  final String detail;
  final String category;
  final String severity;
}

class HealthRules {
  static const categoryCritical = 'critical';
  static const categoryWarning = 'warning';
  static const categoryGesture = 'gesture';
  static const categoryBattery = 'battery';

  static Map<String, dynamic> normalize(Map<String, dynamic> data) {
    return {
      'bpm': _number(data['bpm']),
      'spo2': _number(data['spo2']),
      'temp': _number(data['temp']),
      'gesture': _number(data['gesture']),
      'fall': _number(data['fall']),
      'battery': _number(data['battery'], fallback: 100),
      'time': data['time'] is DateTime ? data['time'] : DateTime.now(),
    };
  }

  static List<HealthAlert> evaluate(Map<String, dynamic>? rawData) {
    if (rawData == null) return const [];

    final data = normalize(rawData);
    final bpm = (data['bpm'] as num).toDouble();
    final spo2 = (data['spo2'] as num).toDouble();
    final temp = (data['temp'] as num).toDouble();
    final fall = (data['fall'] as num).toDouble();
    final gesture = (data['gesture'] as num).toInt();
    final battery = (data['battery'] as num).toInt();

    final alerts = <HealthAlert>[];

    if (fall >= 5) {
      alerts.add(
        const HealthAlert(
          key: 'fall',
          title: 'Fall detected',
          detail: 'Immediate attention may be required.',
          category: categoryCritical,
          severity: 'critical',
        ),
      );
    }

    if (spo2 < 92) {
      alerts.add(
        HealthAlert(
          key: 'spo2-critical',
          title: 'Low SpO2',
          detail: '${spo2.toStringAsFixed(0)}% oxygen saturation.',
          category: categoryCritical,
          severity: 'critical',
        ),
      );
    } else if (spo2 < 95) {
      alerts.add(
        HealthAlert(
          key: 'spo2-warning',
          title: 'SpO2 slightly low',
          detail: '${spo2.toStringAsFixed(0)}% oxygen saturation.',
          category: categoryWarning,
          severity: 'warning',
        ),
      );
    }

    if (bpm > 110 || bpm < 50) {
      alerts.add(
        HealthAlert(
          key: bpm > 110 ? 'bpm-high-critical' : 'bpm-low-critical',
          title: bpm > 110 ? 'High heart rate' : 'Low heart rate',
          detail: '${bpm.toStringAsFixed(0)} BPM recorded.',
          category: categoryCritical,
          severity: 'critical',
        ),
      );
    } else if (bpm > 100 || bpm < 55) {
      alerts.add(
        HealthAlert(
          key: bpm > 100 ? 'bpm-high-warning' : 'bpm-low-warning',
          title: bpm > 100 ? 'Elevated heart rate' : 'Heart rate below range',
          detail: '${bpm.toStringAsFixed(0)} BPM recorded.',
          category: categoryWarning,
          severity: 'warning',
        ),
      );
    }

    if (temp > 38 || temp < 35) {
      alerts.add(
        HealthAlert(
          key: temp > 38 ? 'temp-high-critical' : 'temp-low-critical',
          title: temp > 38 ? 'High temperature' : 'Low temperature',
          detail: '${temp.toStringAsFixed(1)} C recorded.',
          category: categoryCritical,
          severity: 'critical',
        ),
      );
    } else if (temp > 37.5) {
      alerts.add(
        HealthAlert(
          key: 'temp-high-warning',
          title: 'Temperature elevated',
          detail: '${temp.toStringAsFixed(1)} C recorded.',
          category: categoryWarning,
          severity: 'warning',
        ),
      );
    }

    if (gesture > 0) {
      final text = gestureText(gesture);
      alerts.add(
        HealthAlert(
          key: 'gesture-$gesture',
          title: text,
          detail: 'Gesture command received.',
          category: categoryGesture,
          severity: gesture >= 6 ? 'critical' : 'gesture',
        ),
      );
    }

    if (battery < 20) {
      alerts.add(
        HealthAlert(
          key: 'battery-critical',
          title: 'Battery critical',
          detail: '$battery% remaining. Charge now.',
          category: categoryBattery,
          severity: 'critical',
        ),
      );
    } else if (battery < 50) {
      alerts.add(
        HealthAlert(
          key: 'battery-warning',
          title: 'Battery low',
          detail: '$battery% remaining.',
          category: categoryBattery,
          severity: 'warning',
        ),
      );
    }

    return alerts;
  }

  static String gestureText(int gesture) {
    switch (gesture) {
      case 1:
        return 'Need water';
      case 2:
        return 'Need washroom';
      case 3:
        return 'Need food';
      case 4:
        return 'Need medicine';
      case 5:
        return 'In pain';
      case 6:
        return 'Emergency help needed';
      default:
        return 'Stable';
    }
  }

  static String overallStatus(Map<String, dynamic>? data) {
    final alerts = evaluate(data);
    if (alerts.any((alert) => alert.severity == 'critical')) {
      return 'Critical';
    }
    if (alerts.any((alert) => alert.severity == 'warning')) {
      return 'Warning';
    }
    return 'Stable';
  }

  static double _number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return fallback;
  }
}
