import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/ic_ecotrack_white');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse res) {
        if (res.payload == 'go_to_alert') {
          navigatorKey.currentState?.pushNamed('/alerts');
        }
      },
    );
  }

  static Future<void> showWaterAlertNotification({
    required String deviceName,
    required String location,
    required String message,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'water_alerts',
          'EcoTrack Alerts',
          channelDescription: 'Pemberitahuan dari aplikasi EcoTrack',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'EcoTrack Alert',
          styleInformation: BigTextStyleInformation(''),
          largeIcon: DrawableResourceAndroidBitmap('ic_ecotrack'),
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      0,
      'EcoTrack | Water Alert',
      '$deviceName | $location\n$message',
      notificationDetails,
      payload: 'go_to_alert',
    );
  }

  static Future<void> scheduleDailyWaterAlert() async {
    try {
      await _plugin.periodicallyShow(
        1,
        'EcoTrack | Water Alert',
        'Keran | Kamar Mandi\nPenggunaan air meningkat drastis!',
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_alerts',
            'EcoTrack Alerts',
            channelDescription: 'Pemberitahuan dari aplikasi EcoTrack',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
            largeIcon: DrawableResourceAndroidBitmap('ic_ecotrack'),
          ),
        ),
        payload: 'go_to_alert',
        androidAllowWhileIdle: true,
      );
    } catch (e) {
      print("❌ Gagal menjadwalkan notifikasi (periodic): $e");
    }
  }

  /// ✅ Fungsi untuk membuka pengaturan exact alarm permission (Android 12+)
  static Future<void> openExactAlarmSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }
}
