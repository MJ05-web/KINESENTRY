import 'package:flutter_test/flutter_test.dart';
import 'package:kinesentry1_app/services/health_rules.dart';

void main() {
  test('gesture labels remain stable for known gesture values', () {
    expect(HealthRules.gestureText(1), 'Need water');
    expect(HealthRules.gestureText(6), 'Emergency help needed');
    expect(HealthRules.gestureText(0), 'Stable');
  });
}
