import 'package:firebase_auth/firebase_auth.dart';

class KinesentryCredentials {
  static const email = String.fromEnvironment(
    'KINESENTRY_FIREBASE_EMAIL',
    defaultValue: 'kinesentryhub@gmail.com',
  );

  static const password = String.fromEnvironment(
    'KINESENTRY_FIREBASE_PASSWORD',
    defaultValue: 'KineSentry@123',
  );

  static bool matches(String inputEmail, String inputPassword) {
    return inputEmail.trim().toLowerCase() == email.toLowerCase() &&
        inputPassword.trim() == password;
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> login(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return res.user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> loginSingleHub(String email, String password) async {
    if (!KinesentryCredentials.matches(email, password)) {
      return null;
    }

    return login(KinesentryCredentials.email, KinesentryCredentials.password);
  }

  User? get currentUser => _auth.currentUser;

  bool get hasAllowedCurrentUser {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) return false;

    return userEmail.toLowerCase() == KinesentryCredentials.email.toLowerCase();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
