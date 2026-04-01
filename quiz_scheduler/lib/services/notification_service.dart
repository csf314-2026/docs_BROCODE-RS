import 'package:flutter/material.dart'; // Required for TimeOfDay
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // --- NEW TIMEZONE SYNC LOGIC ---
    tz.initializeTimeZones();

    // FIX: Grab the new TimezoneInfo object, then extract its identifier string!
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    // -------------------------------

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // FIX 2: zonedSchedule() now requires ALL parameters to be named.
    // FIX 3: uiLocalNotificationDateInterpretation has been removed by the package authors.
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'quiz_alarms',
          'Quiz Alarms',
          channelDescription: 'Reminders for upcoming quizzes',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      // 👇 THE MAGIC FIX for Android 14 👇
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // --- NEW: CANCEL REMINDER ---
  Future<void> cancelReminder(int id) async {
    // FIX: Added the 'id:' label here to comply with the latest package version!
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  // --- NEW: RECURRING ROUTINE REMINDERS ---
  Future<void> scheduleRepeatingReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String frequency, // 'Daily' or 'Weekly'
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // 1. Create a base date with the chosen time
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 2. If the time has already passed today, push it to tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 3. If weekly, push the scheduled date forward until it hits Sunday (weekday 7)
    if (frequency == 'Weekly') {
      while (scheduledDate.weekday != DateTime.sunday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    // 4. Schedule the repeating alarm
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_reminders',
          'Routine Reminders',
          channelDescription: 'Daily or weekly schedule checks',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      // 👇 THE MAGIC FIX for Android 14 👇
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // This is the magic line that makes it repeat automatically!
      matchDateTimeComponents: frequency == 'Daily'
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
    );
  }
}