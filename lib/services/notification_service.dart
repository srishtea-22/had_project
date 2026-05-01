import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/timetable_entry.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings:  InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    _initialized = true;
  }

  static Future<void> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleClassReminder(TimetableEntry entry) async {
    await _plugin.cancel(id: _notifId(entry.id));

    final now = tz.TZDateTime.now(tz.local);

    int daysUntil = entry.weekday - now.weekday;
    if (daysUntil < 0) daysUntil += 7;

    if (daysUntil == 0) {
      final reminderTime = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, entry.hour, entry.minute,
      ).subtract(const Duration(minutes: 15));
      if (reminderTime.isBefore(now)) daysUntil = 7;
    }

    final scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day + daysUntil,
      entry.hour, entry.minute,
    ).subtract(const Duration(minutes: 15));

    await _plugin.zonedSchedule(
      id: _notifId(entry.id),
      title: '📚 Class in 15 minutes',
      body: '${entry.subjectName} at ${entry.timeLabel} — are you going?',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_reminders',
          'Class Reminders',
          channelDescription: 'Reminder 15 minutes before each class',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> scheduleDailySummary(
      List<TimetableEntry> entries) async {
    await _plugin.cancel(id: 9999);
    if (entries.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final names = entries.map((e) => e.subjectName).join(', ');

    await _plugin.zonedSchedule(
      id: 9999,
      title: '🎓 Today\'s Classes',
      body:
          '${entries.length} class${entries.length == 1 ? '' : 'es'}: $names',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Daily Summary',
          channelDescription: 'Morning summary of today\'s classes',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder(String entryId) =>
      _plugin.cancel(id: _notifId(entryId));

  static Future<void> cancelAll() => _plugin.cancelAll();

  static int _notifId(String id) => id.hashCode.abs() % 100000;
}