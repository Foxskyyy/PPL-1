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

  try {
    // ✅ Inisialisasi Firebase
    await Firebase.initializeApp();
    print("✅ Firebase initialized");
  } catch (e) {
    print("❌ Firebase init error: $e");
  }

  try {
    // ✅ Load session user
    await UserSession.loadSession();
    print("✅ User session loaded");
  } catch (e) {
    print("❌ User session error: $e");
  }

  try {
    // ✅ Minta izin notifikasi
    final status = await Permission.notification.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      print("❌ Izin notifikasi tidak diberikan");
    } else {
      print("✅ Izin notifikasi diberikan");
    }
  } catch (e) {
    print("❌ Permission error: $e");
  }

  try {
    // ✅ Inisialisasi notifikasi lokal
    await NotificationService.init(navigatorKey);
    print("✅ Notifikasi diinisialisasi");
  } catch (e) {
    print("❌ Inisialisasi notifikasi gagal: $e");
  }

  // ✅ Jalankan aplikasi
  runApp(const MyApp());

  // ✅ Buka pengaturan exact alarm (jika tersedia)
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
          routes: {
            '/alerts': (_) => const AlertPage(),
          },
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
