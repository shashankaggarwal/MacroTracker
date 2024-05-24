import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    if (!kIsWeb) {
      tz.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          _onSelectNotification(navigatorKey, response.payload);
        },
      );

      // Request permissions for iOS and Android
      await _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    if (!kIsWeb) {
      // Request Notification Permission
      if (await Permission.notification.request().isGranted) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
        return;
      }

      // Request Exact Alarm Permission for Android 12 and above
      if (await Permission.scheduleExactAlarm.request().isGranted) {
        print('Exact alarm permission granted');
      } else {
        print('Exact alarm permission denied');
      }
    }
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification.',
      platformChannelSpecifics,
    );
  }

  Future<void> _onSelectNotification(GlobalKey<NavigatorState> navigatorKey, String? payload) async {
    if (payload != null) {
      navigatorKey.currentState?.pushNamed('/foodLog');
    }
  }
}
