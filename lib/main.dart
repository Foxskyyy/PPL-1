import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:front_end/settings/theme_notifier.dart';
import 'package:front_end/splash_screen.dart';
import 'package:front_end/user_session.dart';
import 'package:front_end/alert_page.dart';
import 'package:front_end/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  await Firebase.initializeApp();
  await UserSession.loadSession();

  // ✅ Minta izin notifikasi (Android 13+)
  final status = await Permission.notification.request();
  if (status.isDenied || status.isPermanentlyDenied) {
    print("❌ Izin notifikasi tidak diberikan");
  }

  // ✅ Inisialisasi notifikasi
  await NotificationService.init(navigatorKey);

  // ✅ Jalankan aplikasi dulu
  runApp(const MyApp());

  // ✅ Setelah UI tampil, buka pengaturan exact alarm (Android 12+)
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      await NotificationService.openExactAlarmSettings();
    } catch (e) {
      print("❌ Gagal membuka pengaturan exact alarm: $e");
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          home: const SplashScreen(),
          routes: {'/alerts': (_) => const AlertPage()},
        );
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
