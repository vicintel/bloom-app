import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init(BuildContext context) async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings: settings);
    tz.initializeTimeZones();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('bloom_channel', 'Bloom Notifications', importance: Importance.max, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    int id = 1,
  }) async {
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('bloom_channel', 'Bloom Notifications', importance: Importance.max, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules a "late period" alert 2 days after the [expectedDate].
  /// This reminds the user to log their period if it hasn't been logged.
  static Future<void> scheduleLateperiodAlert(DateTime expectedDate) async {
    final alertDate = expectedDate.add(const Duration(days: 2));
    final now = DateTime.now();
    // Only schedule if the alert date is in the future
    if (alertDate.isBefore(now)) return;

    final tzAlertDate = tz.TZDateTime.from(alertDate, tz.local);

    await _notifications.zonedSchedule(
      id: 100,
      title: 'Period Check-in',
      body: 'Your period was expected 2 days ago. Have you logged it? Tap to update Bloom.',
      scheduledDate: tzAlertDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'bloom_period_alert',
          'Period Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
