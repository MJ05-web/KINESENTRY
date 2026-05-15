import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_footer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _initApp();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
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
      backgroundColor: Colors.transparent,
      body: AppChrome(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        safeBottom: true,
        child: AnimatedBuilder(
          animation: _introController,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_introController.value);
            return Column(
              children: [
                const Spacer(),
                Transform.scale(
                  scale: 0.86 + (t * .14),
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 26),
                    child: Hero(
                      tag: 'kinesentry-logo',
                      child: GlassPanel(
                        borderRadius: 36,
                        padding: const EdgeInsets.all(24),
                        glowColor: AppThemeColors.accent(context).withValues(alpha: .16),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: t,
                  child: const AccentHeadline(
                    title: 'KineSentry',
                    subtitle: 'Patient monitoring, ready the moment care needs it.',
                    center: true,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    color: AppThemeColors.accent(context),
                    strokeWidth: 3.2,
                  ),
                ),
                const SizedBox(height: 24),
                AppFooter(light: !AppThemeColors.isDark(context)),
              ],
            );
          },
        ),
      ),
    );
  }
}
