import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/user_session.dart';
import 'package:front_end/notification_service.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  final String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';
  String? _lastFetchedId;

  Future<List<Map<String, String>>> fetchAlertsFromBackend() async {
    final int? userId = await UserSession.getUserID();

    if (userId == null) {
      print("❌ userID null, tidak bisa ambil notifikasi.");
      return [];
    }

    final query = '''
      {
        notifications(userID: $userId) {
          id
          title
          message
          createdAt
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      print("📤 Query sent:\n$query");
      print("📥 Raw response:\n${response.body}");

      final jsonData = json.decode(response.body);

      if (jsonData['errors'] != null) {
        print("❌ GraphQL Errors: ${jsonData['errors']}");
        return [];
      }

      final notifications = jsonData['data']['notifications'] as List;
      print("✅ Total Notifications: ${notifications.length}");

      if (notifications.isNotEmpty) {
        final latest = notifications.first;
        final latestId = latest['id'];

        if (_lastFetchedId != latestId) {
          _lastFetchedId = latestId;
          final titleParts = (latest['title'] ?? '').split(' | ');
          final deviceName = titleParts.length > 1 ? titleParts[1] : 'Device';
          final location = titleParts.length > 2 ? titleParts[2] : 'Lokasi';

          await NotificationService.showWaterAlertNotification(
            deviceName: deviceName,
            location: location,
            message: latest['message'] ?? 'Ada notifikasi baru.',
          );
        }
      }

      return notifications.map<Map<String, String>>((notif) {
        return {
          "title": notif['title'] ?? 'Notifikasi',
          "message": notif['message'] ?? '',
          "time": formatTime(notif['createdAt']),
        };
      }).toList();
    } catch (e) {
      print("🚨 Exception: $e");
      return [];
    }
  }

  String formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/ecotrack_logo.png', width: 60),
                  const CircleAvatar(
                    backgroundColor: Colors.lightBlue,
                    radius: 18,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.black),

            Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: fetchAlertsFromBackend(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final alerts = snapshot.data ?? [];

                  if (alerts.isEmpty) {
                    return const Center(
                      child: Text("Tidak ada notifikasi tersedia."),
                    );
                  }

                  return ListView.builder(
                    itemCount: alerts.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    alert['time'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(alert['message'] ?? ''),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }
}
