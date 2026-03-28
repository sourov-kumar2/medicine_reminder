import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart'; // ✅ Only native plugin
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medicine.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // ✅ Initialize notifications
  static Future<void> init() async {
    debugPrint('🔔 [NOTIF] Initializing notification service...');

    tz.initializeTimeZones();

    final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final String localTimezone = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(localTimezone));

    debugPrint('🔔 [NOTIF] Timezone set to: $localTimezone');
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    final initialized = await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );
    debugPrint('🔔 [NOTIF] Plugin initialized: $initialized');

    // Create notification channel
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) {
        debugPrint('❌ [NOTIF] Android plugin is null!');
        return;
      }

      AndroidNotificationChannel channel;
      try {
        channel = AndroidNotificationChannel(
          'medicine_alarm_channel',
          'ওষুধের অ্যালার্ম',
          description: 'ওষুধ খাওয়ার সময় অ্যালার্ম বাজে',
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('alarm'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
          enableLights: true,
        );
        debugPrint('🔔 [NOTIF] Notification channel created with custom sound.');
      } catch (e) {
        debugPrint('⚠️ [NOTIF] Custom sound failed: $e');
        channel = const AndroidNotificationChannel(
          'medicine_alarm_channel',
          'ওষুধের অ্যালার্ম',
          description: 'ওষুধ খাওয়ার সময় অ্যালার্ম বাজে',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );
      }

      await androidPlugin.createNotificationChannel(channel);
      debugPrint('✅ [NOTIF] Notification channel created: medicine_alarm_channel');

      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('🔔 [NOTIF] Pending notifications on init: ${pending.length}');
    } catch (e, stack) {
      debugPrint('❌ [NOTIF] Initialization error: $e\n$stack');
    }
  }

  // Notification tapped
  @pragma('vm:entry-point')
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
        '🔔 [NOTIF] Notification tapped! ID: ${response.id}, Action: ${response.actionId}');
  }

  // Background notification
  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse response) {
    debugPrint('🔔 [NOTIF] Background notification! ID: ${response.id}');
  }

  // Request permissions
  static Future<void> requestPermission() async {
    debugPrint('🔔 [PERM] Requesting notification permissions...');
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) return;

      final notifGranted = await androidPlugin.requestNotificationsPermission();
      debugPrint('🔔 [PERM] Notification permission granted: $notifGranted');

      final exactGranted = await androidPlugin.requestExactAlarmsPermission();
      debugPrint('🔔 [PERM] Exact alarm permission granted: $exactGranted');
    } catch (e) {
      debugPrint('❌ [PERM] Permission error: $e');
    }
  }

  // Immediate test notification
  static Future<void> testImmediateNotification() async {
    debugPrint('🧪 [TEST] Firing immediate test notification...');
    try {
      await _plugin.show(
        9999,
        '✅ পরীক্ষামূলক নোটিফিকেশন',
        'নোটিফিকেশন সিস্টেম কাজ করছে! ⏰ Timezone: ${tz.local.name}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_alarm_channel',
            'ওষুধের অ্যালার্ম',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          ),
        ),
      );
      debugPrint(
          '✅ [TEST] Immediate notification sent. Timezone: ${tz.local.name}');
    } catch (e) {
      debugPrint('❌ [TEST] Immediate notification failed: $e');
    }
  }

  // Schedule medicine notifications
  static Future<void> scheduleMedicineNotifications(
      Medicine medicine, int medicineKey) async {
    debugPrint(
        '📅 [SCHEDULE] Scheduling for: ${medicine.name}, key: $medicineKey');
    debugPrint('📅 [SCHEDULE] Times: ${medicine.times}');

    await cancelMedicineNotifications(medicineKey);
    if (!medicine.isActive) return;

    for (int i = 0; i < medicine.times.length; i++) {
      try {
        final timeParts = medicine.times[i].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final notifId = medicineKey * 100 + i;

        final now = tz.TZDateTime.now(tz.local);
        var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

        if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

        debugPrint('⏰ [SCHEDULE] Slot $i → ID: $notifId, Scheduled: $scheduled');

        String body = '${medicine.name} খাওয়ার সময় হয়েছে।';
        if (medicine.instructions != null && medicine.instructions!.isNotEmpty) {
          body += '\n📝 ${medicine.instructions}';
        }

        await _plugin.zonedSchedule(
          notifId,
          '💊 ওষুধ খাওয়ার সময় হয়েছে!',
          body,
          scheduled,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'medicine_alarm_channel',
              'ওষুধের অ্যালার্ম',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              sound: const RawResourceAndroidNotificationSound('alarm'),
              enableVibration: true,
              vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
              autoCancel: false,
              actions: [
                const AndroidNotificationAction('TAKEN', '✅ খেয়েছি', cancelNotification: true),
                const AndroidNotificationAction('SNOOZE', '🔔 ১০ মিনিট পরে', cancelNotification: true),
              ],
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: medicine.durationType == 'forever' ? DateTimeComponents.time : null,
        );

        debugPrint('✅ [SCHEDULE] Scheduled notification ID: $notifId');
      } catch (e, stack) {
        debugPrint('❌ [SCHEDULE] Slot $i failed: $e\n$stack');
      }
    }

    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('📋 [SCHEDULE] Pending notifications: ${pending.length}');
    for (final p in pending) debugPrint('   → ID: ${p.id}, Title: ${p.title}');
  }

  // Cancel notifications
  static Future<void> cancelMedicineNotifications(int medicineKey) async {
    debugPrint('🗑️ [CANCEL] Cancelling notifications for key: $medicineKey');
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(medicineKey * 100 + i);
    }
  }

  // Snooze notification 10 min
  static Future<void> snoozeNotification(int id, String title, String body) async {
    final snoozeTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));
    await _plugin.zonedSchedule(
      id + 9999,
      title,
      body,
      snoozeTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_alarm_channel',
          'ওষুধের অ্যালার্ম',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('😴 [SNOOZE] Snoozed until: $snoozeTime');
  }
}