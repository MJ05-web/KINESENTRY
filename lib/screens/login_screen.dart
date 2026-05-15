import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_footer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  void login() async {
    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    final user = await AuthService().login(email.text.trim(), pass.text.trim());

    if (!mounted) return;
    setState(() => isLoading = false);

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Username or password does not match'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppChrome(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        safeBottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: GlassPanel(
                      borderRadius: 32,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                      glowColor: AppThemeColors.glow(context).withValues(alpha: .10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Hero(
                            tag: 'kinesentry-logo',
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 132,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const AccentHeadline(
                            title: 'Stay ahead of every vital',
                            subtitle:
                                'A calmer, clearer KineSentry experience for live care, alerts, and reports.',
                            center: true,
                          ),
                          const SizedBox(height: 24),
                          _LoginField(
                            controller: email,
                            icon: Icons.person_outline,
                            label: 'Username',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _LoginField(
                            controller: pass,
                            icon: Icons.lock_outline,
                            label: 'Password',
                            obscureText: hidePassword,
                            suffixIcon: IconButton(
                              tooltip: hidePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(() => hidePassword = !hidePassword);
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppThemeColors.textSecondary(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : login,
                              icon: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(isLoading ? 'Checking...' : 'Login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeColors.accent(context),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFF344054),
                                shadowColor: AppThemeColors.accent(context).withValues(alpha: .38),
                                elevation: 0,
                              ),
                            ),
                          ),
                          AppFooter(light: !AppThemeColors.isDark(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.icon,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        color: AppThemeColors.textPrimary(context),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppThemeColors.textSecondary(context)),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
