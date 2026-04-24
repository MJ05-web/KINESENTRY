import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// SCREENS
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alerts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const KinesentryApp());
}

class KinesentryApp extends StatelessWidget {
  const KinesentryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kinesentry',

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D1117),
          brightness: Brightness.light,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF0D1117),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/alerts': (context) => const AlertsScreen(),
      },
    );
  }
}
