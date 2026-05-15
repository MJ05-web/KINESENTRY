import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light
        ? const Color(0xFF7B8798)
        : AppThemeColors.textTertiary(context);

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        'Version 1.0.0  |  KineSentry monitoring suite',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
