import 'package:firebase_auth/firebase_auth.dart';

class KinesentryCredentials {
  static const allowedEmail = String.fromEnvironment(
    'KINESENTRY_FIREBASE_EMAIL',
    // Add your allowed Firebase login email here when restoring the project.
    defaultValue: '',
  );
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> login(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = res.user;
      if (user == null) return null;

      if (KinesentryCredentials.allowedEmail.isNotEmpty &&
          user.email?.toLowerCase() !=
              KinesentryCredentials.allowedEmail.toLowerCase()) {
        await _auth.signOut();
        return null;
      }

      return user;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _auth.currentUser;

  bool get hasAllowedCurrentUser {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) return false;

    if (KinesentryCredentials.allowedEmail.isEmpty) return true;
    return userEmail.toLowerCase() ==
        KinesentryCredentials.allowedEmail.toLowerCase();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
