import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool allowNotification = false;
  bool allowSound = false;
  bool showPreviews = false;
  bool receiveUpdate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (sama seperti TrackingPage)
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

            const SizedBox(height: 12),

            // Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_ios, size: 16),
                    SizedBox(width: 4),
                  ],
                ),
              ),
            ),

            // List of Toggles
            _buildToggle("Allow Notifications", allowNotification, (val) {
              setState(() => allowNotification = val);
            }),
            const Divider(),

            _buildToggle("Allow Sound", allowSound, (val) {
              setState(() => allowSound = val);
            }),
            const Divider(),

            _buildToggle("Show Previews", showPreviews, (val) {
              setState(() => showPreviews = val);
            }),
            const Divider(),

            _buildToggle("Receive Update", receiveUpdate, (val) {
              setState(() => receiveUpdate = val);
            }),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(title),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
