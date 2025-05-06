import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/login/login.dart';
import 'package:front_end/user_session.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'nickname_notifier.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: nicknameNotifier.value);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text('Back', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Profile Photo
            ListTile(
              leading: const Text("Profile Photo"),
              trailing: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.lightBlue,
                child: Icon(Icons.face, color: Colors.white),
              ),
              onTap: () {},
            ),
            const Divider(),

            // Nickname
            ListTile(
              leading: const Text("Nickname"),
              trailing: ValueListenableBuilder<String>(
                valueListenable: nicknameNotifier,
                builder: (context, nickname, _) {
                  return Text(
                    nickname,
                    style: const TextStyle(color: Colors.grey),
                  );
                },
              ),
              onTap: _showEditNicknameDialog,
            ),
            const Divider(),

            // Logout
            ListTile(
              leading: const Text("Logout"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _confirmLogoutDialog,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }

  // Dialog Edit Nickname
  void _showEditNicknameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Edit Nickname"),
          content: TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              hintText: "Enter new nickname",
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                String newNickname = _nicknameController.text.trim();
                if (newNickname.isNotEmpty) {
                  nicknameNotifier.updateNickname(newNickname);
                  UserSession.displayName = newNickname;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nickname updated successfully!'),
                    ),
                  );
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog Confirm Logout
  void _confirmLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to logout?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.pop(context); // Close dialog first
                await _logout(); // Then logout
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi Logout
  Future<void> _logout() async {
    try {
      await GoogleSignIn().signOut(); // Logout Google
    } catch (_) {
      // ignore
    }

    try {
      await FirebaseAuth.instance.signOut(); // Logout Firebase
    } catch (_) {
      // ignore
    }

    await UserSession.clearSession(); // Clear session SharedPreferences

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
