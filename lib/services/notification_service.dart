import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _fallChannel = AndroidNotificationChannel(
    'fall_alerts_v2',
    'Fall Alerts',
    description: 'Critical fall alerts from KineSentry',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('ting'),
  );

  static const _gestureChannel = AndroidNotificationChannel(
    'gesture_alerts_v2',
    'Gesture Alerts',
    description: 'Gesture requests from KineSentry',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('ting'),
  );

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_fallChannel);
    await android?.createNotificationChannel(_gestureChannel);
    await android?.requestNotificationsPermission();
  }

  Future<void> showFallAlert({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      1001,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _fallChannel.id,
          _fallChannel.name,
          icon: '@mipmap/ic_launcher',
          channelDescription: _fallChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('ting'),
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 280, 500, 280, 700]),
          ticker: 'KineSentry fall alert',
        ),
      ),
    );
  }

  Future<void> showGestureAlert({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      1002,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _gestureChannel.id,
          _gestureChannel.name,
          icon: '@mipmap/ic_launcher',
          channelDescription: _gestureChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('ting'),
          visibility: NotificationVisibility.public,
          enableVibration: true,
        ),
      ),
    );
  }

  Future<void> showSystemAlert({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      1003,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _fallChannel.id,
          _fallChannel.name,
          icon: '@mipmap/ic_launcher',
          channelDescription: _fallChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('ting'),
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
