import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medicine.dart';
import '../main.dart' show navigatorKey, notificationTapBackground;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // ── Init ───────────────────────────────────────────────────
  static Future<void> init() async {
    tz.initializeTimeZones();
    final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // ✅ Fix: assign to typed variable first
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _plugin.resolvePlatformSpecificImplementation();
    if (androidPlugin == null) return;

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
        ledColor: const Color(0xFFF5C842),
      );
    } catch (_) {
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
  }

  // ── Foreground response (app is open) ─────────────────────
  @pragma('vm:entry-point')
  static void _onForegroundResponse(NotificationResponse response) async {
    final context = navigatorKey.currentContext;

    if (response.actionId == 'SNOOZE') {
      // Reschedule 10 min later using payload
      await NotificationService.snoozeNotification(
        response.id ?? 0,
        '💊 ওষুধ খাওয়ার সময় হয়েছে!',
        response.payload ?? '',
      );

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🔔', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '১০ মিনিট পরে আবার মনে করিয়ে দেওয়া হবে',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    if (response.actionId == 'TAKEN') {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('✅', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ওষুধ খাওয়া হয়েছে বলে চিহ্নিত করা হয়েছে',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF43A047),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  static Future<void> requestPermission() async {
    // ✅ Fix: assign to typed variable first
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _plugin.resolvePlatformSpecificImplementation();
    if (androidPlugin == null) return;
    await androidPlugin.requestNotificationsPermission();
    await androidPlugin.requestExactAlarmsPermission();
  }

  // ── Test immediate notification ────────────────────────────
  static Future<void> testImmediateNotification() async {
    await _plugin.show(
      9999,
      '⏰ ওষুধ খাওয়ার সময় হয়েছে!',
      '💊 এটি একটি পরীক্ষামূলক নোটিফিকেশন — সিস্টেম কাজ করছে 💛',
      NotificationDetails(
        android: _buildDetails(
          body: '💊 পরীক্ষামূলক — সিস্টেম কাজ করছে 💛',
          payload: 'test',
        ),
      ),
      payload: 'test',
    );
  }

  // ── Schedule medicine notifications ───────────────────────
  static Future<void> scheduleMedicineNotifications(
      Medicine medicine, int medicineKey) async {
    await cancelMedicineNotifications(medicineKey);
    if (!medicine.isActive) return;

    for (int i = 0; i < medicine.times.length; i++) {
      try {
        final timeParts = medicine.times[i].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final notifId = medicineKey * 100 + i;

        final now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(
          tz.local,
          now.year, now.month, now.day,
          hour, minute,
        );
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }

        final timeLabel = _timeLabel(hour);
        final title = '⏰ $timeLabel ওষুধ খাওয়ার সময় হয়েছে!';

        String body = '💊 ${medicine.name}';
        if (medicine.instructions != null &&
            medicine.instructions!.isNotEmpty) {
          body += '\n📋 ${medicine.instructions}';
        }

        // Store medicine name in payload for snooze use
        final payload = medicine.name;

        await _plugin.zonedSchedule(
          notifId,
          title,
          body,
          scheduled,
          NotificationDetails(
            android: _buildDetails(body: body, payload: payload),
          ),
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: medicine.durationType == 'forever'
              ? DateTimeComponents.time
              : null,
        );
      } catch (_) {}
    }
  }

  // ── Shared notification details builder ───────────────────
  static AndroidNotificationDetails _buildDetails({
    required String body,
    required String payload,
  }) {
    return AndroidNotificationDetails(
      'medicine_alarm_channel',
      'ওষুধের অ্যালার্ম',
      channelDescription: 'ওষুধ খাওয়ার সময় অ্যালার্ম বাজে',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 800, 300, 800, 300, 1200]),
      color: const Color(0xFFF5C842),
      ledColor: const Color(0xFFF5C842),
      ledOnMs: 500,
      ledOffMs: 500,
      enableLights: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: '⏰ ওষুধ খাওয়ার সময় হয়েছে!',
        summaryText: 'ওষুধ রিমাইন্ডার',
      ),
      actions: [
        const AndroidNotificationAction(
          'TAKEN',
          '✅  খেয়েছি',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'SNOOZE',
          '🔔  ১০ মিনিট পরে',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );
  }

  // ── Bengali time label ─────────────────────────────────────
  static String _timeLabel(int hour) {
    if (hour >= 4 && hour < 12) return '🌅 সকালের';
    if (hour >= 12 && hour < 15) return '☀️ দুপুরের';
    if (hour >= 15 && hour < 18) return '🌤️ বিকেলের';
    if (hour >= 18 && hour < 21) return '🌆 সন্ধ্যার';
    return '🌙 রাতের';
  }

  // ── Cancel notifications ───────────────────────────────────
  static Future<void> cancelMedicineNotifications(int medicineKey) async {
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(medicineKey * 100 + i);
    }
  }

  // ── Snooze ─────────────────────────────────────────────────
  static Future<void> snoozeNotification(
      int id, String title, String body) async {
    final snoozeTime =
    tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));

    final snoozeBody = body.isNotEmpty
        ? body
        : '💊 ওষুধ খেতে ভুলবেন না';

    await _plugin.zonedSchedule(
      id + 9999,
      title,
      snoozeBody,
      snoozeTime,
      NotificationDetails(
        android: _buildDetails(body: snoozeBody, payload: body),
      ),
      payload: body,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}