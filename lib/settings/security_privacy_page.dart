import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';

class SecurityPrivacyPage extends StatelessWidget {
  const SecurityPrivacyPage({super.key});

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

            _PolicyItem(
              title: "Cookies Policy",
              onTap: () {
                // Tampilkan isi kebijakan cookie
              },
            ),
            const Divider(),

            _PolicyItem(
              title: "Privacy Policy",
              onTap: () {
                // Tampilkan isi privasi
              },
            ),
            const Divider(),

            _PolicyItem(
              title: "Terms and Conditions",
              onTap: () {
                // Tampilkan isi syarat dan ketentuan
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _PolicyItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
