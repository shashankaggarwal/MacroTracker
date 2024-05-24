import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationControllerProvider = Provider<NotificationController>((ref) {
  final service = ref.read(notificationServiceProvider);
  return NotificationController(service);
});

class NotificationController {
  final NotificationService _service;

  NotificationController(this._service);

  Future<void> initializeNotifications(GlobalKey<NavigatorState> navigatorKey) async {
    print('Initializing notifications');
    await _service.init(navigatorKey);
  }

  Future<void> showTestNotification() async {
    print('Showing test notification');
    await _service.showNotification();
  }
}
