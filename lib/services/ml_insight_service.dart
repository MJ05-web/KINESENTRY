class MlInsightResult {
  const MlInsightResult({
    required this.riskScore,
    required this.riskLabel,
    required this.summary,
    required this.predictedBpm,
    required this.predictedSpo2,
    required this.predictedTemp,
  });

  final double riskScore;
  final String riskLabel;
  final String summary;
  final double predictedBpm;
  final double predictedSpo2;
  final double predictedTemp;
}

class MlInsightService {
  const MlInsightService._();

  static MlInsightResult analyze(List<Map<String, dynamic>> samples) {
    if (samples.isEmpty) {
      return const MlInsightResult(
        riskScore: 0,
        riskLabel: 'Idle',
        summary: 'Waiting for sensor data to build a prediction profile.',
        predictedBpm: 0,
        predictedSpo2: 0,
        predictedTemp: 0,
      );
    }

    final recent = samples.length > 18
        ? samples.sublist(samples.length - 18)
        : samples;

    final bpmTrend = _predict(recent, 'bpm');
    final spo2Trend = _predict(recent, 'spo2');
    final tempTrend = _predict(recent, 'temp');

    double risk = 0;
    if (bpmTrend > 110 || bpmTrend < 50) risk += 35;
    if (spo2Trend < 92) risk += 35;
    if (tempTrend > 38 || tempTrend < 35) risk += 20;

    final last = recent.last;
    final fall = ((last['fall'] ?? 0) as num).toDouble();
    final battery = ((last['battery'] ?? 100) as num).toInt();

    if (fall > 0) risk += 20;
    if (battery < 30) risk += 15;

    risk = risk.clamp(0, 100);

    final label = risk >= 70
        ? 'High Risk'
        : risk >= 35
        ? 'Elevated'
        : 'Stable';

    final summary =
        'Predicted next vitals: BPM ${bpmTrend.toStringAsFixed(0)}, '
        'SpO2 ${spo2Trend.toStringAsFixed(0)}%, '
        'Temp ${tempTrend.toStringAsFixed(1)} C. '
        'Model sees $label condition based on recent trend and alert pattern.';

    return MlInsightResult(
      riskScore: risk,
      riskLabel: label,
      summary: summary,
      predictedBpm: bpmTrend,
      predictedSpo2: spo2Trend,
      predictedTemp: tempTrend,
    );
  }

  static double _predict(List<Map<String, dynamic>> samples, String key) {
    if (samples.isEmpty) return 0;
    if (samples.length == 1) return ((samples.first[key] ?? 0) as num).toDouble();

    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;

    for (var i = 0; i < samples.length; i++) {
      final x = i.toDouble();
      final y = ((samples[i][key] ?? 0) as num).toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final n = samples.length.toDouble();
    final denominator = (n * sumXX) - (sumX * sumX);
    if (denominator == 0) {
      return ((samples.last[key] ?? 0) as num).toDouble();
    }

    final slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    final intercept = (sumY - (slope * sumX)) / n;
    final nextX = n;
    return intercept + (slope * nextX);
  }
}
