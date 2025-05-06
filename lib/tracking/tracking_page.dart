import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/tracking/waterbreakdown/water_breakdown_page.dart';
import 'package:front_end/tracking/consumption_tracking_page.dart';
import 'package:front_end/tracking/live_tracking/live_tracking_page.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

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
                  Image.asset(
                    'assets/images/ecotrack_logo.png',
                    width: 60,
                    height: 60,
                  ),
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
            const SizedBox(height: 70),

            // Tracking Options
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _TrackingCard(
                    icon: Icons.access_time,
                    title: 'Live Tracking',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LiveTrackingPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 90),
                  _TrackingCard(
                    icon: Icons.show_chart,
                    title: 'Consumption Tracking',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConsumptionTrackingPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 90),
                  _TrackingCard(
                    icon: Icons.opacity,
                    title: 'Water Breakdown',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WaterBreakdownPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Nav
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _TrackingCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(icon, size: 40, color: Colors.black),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
