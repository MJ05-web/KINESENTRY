import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/audio_device_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'widgets/alert_feedback_host.dart';

// SCREENS
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/team_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SettingsService().load();
  await NotificationService().initialize();
  await AudioDeviceService().initialize();

  runApp(const KinesentryApp());
}

class KinesentryApp extends StatelessWidget {
  const KinesentryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kinesentry',
          theme: AppThemes.light(),
          darkTheme: AppThemes.dark(),
          themeMode: settings.darkThemeEnabled ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return AlertFeedbackHost(child: child ?? const SizedBox.shrink());
          },
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/alerts': (context) => const AlertsScreen(),
            '/team': (context) => const TeamScreen(),
          },
        );
      },
    );
  }
}
