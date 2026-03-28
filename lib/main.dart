import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: MedicineReminderApp(),
    ),
  );
}

class MedicineReminderApp extends StatefulWidget {
  const MedicineReminderApp({super.key});

  @override
  State<MedicineReminderApp> createState() => _MedicineReminderAppState();
}

class _MedicineReminderAppState extends State<MedicineReminderApp> {
  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
  }

  Future<void> _requestAllPermissions() async {
    // Notification permission
    await NotificationService.requestPermission();

    // Battery optimization bypass
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ওষুধ রিমাইন্ডার',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}