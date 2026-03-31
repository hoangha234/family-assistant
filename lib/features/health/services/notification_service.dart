import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notificationsPlugin.initialize(settings: initSettings);
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> scheduleHydrationReminders(List<DateTime> sessions) async {
    try {
      // Cancel previous scheduled reminders for hydration (using a specific ID range, e.g., 100 to 104)
      for (int i = 0; i < 5; i++) {
        await _notificationsPlugin.cancel(id: 100 + i);
      }

      for (int i = 0; i < sessions.length; i++) {
        final sessionTime = sessions[i];
        if (sessionTime.isBefore(DateTime.now())) continue; // Skip past times

        final tzDateTime = tz.TZDateTime.from(sessionTime, tz.local);

        await _notificationsPlugin.zonedSchedule(
          id: 100 + i,
          title: 'Time to Hydrate! 💧',
          body: 'Drink your 400ml for the upcoming session.',
          scheduledDate: tzDateTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'hydration_channel',
              'Hydration Reminders',
              channelDescription: 'Reminders to drink water periodically',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('Scheduled reminder ID: ${100 + i} at ${tzDateTime.toString()}');
      }

      await debugPrintScheduledNotifications();
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling reminders: $e');
    }
  }

  static Future<void> debugPrintScheduledNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint('\n=== PENDING NOTIFICATIONS ===');
    for (var req in pending) {
      debugPrint('ID: ${req.id}, Title: ${req.title}, Body: ${req.body}');
    }
    debugPrint('=============================\n');
  }

  static Future<void> showInstantNotification() async {
    await _notificationsPlugin.show(
      id: 999,
      title: 'Test Hydration! 💧',
      body: 'This is an instant notification test. Tap to open.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_channel',
          'Hydration Reminders',
          channelDescription: 'Reminders to drink water periodically',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
