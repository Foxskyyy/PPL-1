import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';

class AlertPage extends StatefulWidget {
  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  int _currentIndex = 4;

  Future<List<Map<String, String>>> fetchAlertsFromBackend() async {
    await Future.delayed(Duration(seconds: 1)); // Simulasi loading
    return [
      {
        "title": "High Energy Consumption Alert!",
        "message":
            "Your energy usage has exceeded the safe limit. Consider reducing unnecessary usage to avoid waste and extra cost.",
        "time": "6:52 PM",
      },
      {
        "title": "Water Overuse Warning!",
        "message":
            "Your water consumption is above the recommended level. Please check for leaks and optimize usage to conserve resources.",
        "time": "4:08 PM",
      },
      {
        "title": "Material Usage Alert!",
        "message":
            "Your material consumption is exceeding the optimal threshold. Review your supply chain and consider waste reduction strategies.",
        "time": "11:23 AM",
      },
      {
        "title": "Material Consumption Warning!",
        "message":
            "Your resource usage is exceeding the optimal range. Review your processes to minimize waste and maintain efficiency.",
        "time": "9:41 AM",
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ecotrack Logo and Text
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/ecotrack_logo.png',
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  // Avatar
                  const CircleAvatar(
                    backgroundColor: Colors.lightBlue,
                    radius: 18,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: Colors.black),

            // Alert List
            Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: fetchAlertsFromBackend(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final alerts = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: alerts.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          top:
                              index == 0
                                  ? 16.0
                                  : 6.0, // 👉 jarak lebih besar hanya di atas item pertama
                          bottom: 6.0,
                        ),
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
                              Text(
                                alert['message'] ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
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

      // Custom Bottom Navigation
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }
}
