import 'package:flutter_test/flutter_test.dart';
import 'package:kinesentry1_app/services/auth_service.dart';

void main() {
  test('single hub credentials match only the configured account', () {
    expect(
      KinesentryCredentials.matches(
        KinesentryCredentials.email,
        KinesentryCredentials.password,
      ),
      isTrue,
    );

    expect(
      KinesentryCredentials.matches(
        KinesentryCredentials.email,
        'wrong-password',
      ),
      isFalse,
    );
  });
}
