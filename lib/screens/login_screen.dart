import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: KinesentryCredentials.email);
  final pass = TextEditingController(text: KinesentryCredentials.password);

  bool isLoading = false;
  bool hidePassword = true;

  void login() async {
    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    final user = await AuthService().loginSingleHub(
      email.text.trim(),
      pass.text.trim(),
    );

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Hero(
                          tag: 'kinesentry-logo',
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'KineSentry',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF0D1117),
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Single hub access',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 34),
                        _LoginField(
                          controller: email,
                          icon: Icons.person_outline,
                          label: 'Firebase username',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _LoginField(
                          controller: pass,
                          icon: Icons.lock_outline,
                          label: 'Firebase password',
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
                              color: const Color(0xFF475467),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
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
                              backgroundColor: const Color(0xFF0D1117),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF344054),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF12B76A),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Only the registered hub account can continue',
                                style: TextStyle(
                                  color: Color(0xFF475467),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
      style: const TextStyle(
        color: Color(0xFF101828),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF475467)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        labelStyle: const TextStyle(color: Color(0xFF667085)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0D1117), width: 1.4),
        ),
      ),
    );
  }
}
