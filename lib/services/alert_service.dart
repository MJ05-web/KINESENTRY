import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../screens/alerts_screen.dart';
import 'settings_service.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final player = AudioPlayer();
  final settings = SettingsService();

  void triggerAlert(
    BuildContext context,
    String message, {
    String type = 'general',
    String severity = 'warning',
  }) {
    if (settings.soundEnabled) {
      player.play(AssetSource('sounds/ting.mp3'));
    }

    if (settings.notificationEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: severity == 'critical' ? Colors.red : Colors.orange,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AlertsScreen()));
            },
          ),
        ),
      );
    }
  }
}
