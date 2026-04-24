import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _initApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final auth = AuthService();

    if (!auth.hasAllowedCurrentUser && auth.currentUser != null) {
      await auth.logout();
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      auth.hasAllowedCurrentUser ? '/dashboard' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FB), Color(0xFFEAF7F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Hero(
                tag: 'kinesentry-logo',
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 210,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'KineSentry',
                style: TextStyle(
                  color: Color(0xFF0D1117),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Patient monitoring, ready when you are',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const SizedBox(
                height: 34,
                width: 34,
                child: CircularProgressIndicator(
                  color: Color(0xFF0D1117),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 42),
            ],
          ),
        ),
      ),
    );
  }
}
