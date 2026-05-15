import 'dart:async';

import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';

class AlertFeedbackHost extends StatefulWidget {
  const AlertFeedbackHost({super.key, required this.child});

  final Widget child;

  @override
  State<AlertFeedbackHost> createState() => _AlertFeedbackHostState();
}

class _AlertFeedbackHostState extends State<AlertFeedbackHost> {
  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = DataService().alertStream.listen(_showAlert);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _showAlert(Map<String, dynamic> alert) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final severity = alert['severity'] ?? 'warning';
    final color = severity == 'critical'
        ? const Color(0xFFEF4444)
        : severity == 'gesture'
        ? const Color(0xFF06B6D4)
        : severity == 'success'
        ? const Color(0xFF22C55E)
        : const Color(0xFFF59E0B);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: AppThemeColors.isDark(context)
            ? const Color(0xE6111C2F)
            : const Color(0xEE0F172A),
        content: Row(
          children: [
            Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['message'] ?? 'Alert',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((alert['detail'] ?? '').toString().trim().isNotEmpty)
                    Text(
                      alert['detail'],
                      style: const TextStyle(color: Colors.white70, height: 1.2),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
