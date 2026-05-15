import 'package:flutter/material.dart';

import 'alert_service.dart';
import 'auth_service.dart';
import 'bluetooth_service.dart';
import 'data_service.dart';

class SessionService {
  const SessionService._();

  static Future<void> logout(BuildContext context) async {
    final ble = MyBluetoothService();
    final dataService = DataService();
    final navigator = Navigator.of(context, rootNavigator: true);

    _showLogoutCard(navigator.context);

    if (ble.isEsp32Connected) {
      await ble
          .writeCommand('APP_LOGOUT:1')
          .timeout(const Duration(milliseconds: 900), onTimeout: () {});
    }

    await Future.delayed(const Duration(milliseconds: 2100));

    await ble.disconnect().timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
    dataService.clearAll();
    await AlertService().stopAll().timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
    await AuthService().logout().timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );

    if (!context.mounted) return;

    if (navigator.canPop()) {
      navigator.pop();
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  static void _showLogoutCard(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Have a good Time',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try login again',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
