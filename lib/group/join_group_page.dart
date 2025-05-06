import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart'; // Pastikan mengimpor CustomBottomNavBar

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  _JoinGroupPageState createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final TextEditingController _invitationCodeController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section with Logo and Avatar
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
            // Divider below header
            const Divider(color: Colors.black),
            // Button back
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, size: 20),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),

            // Icon and Text for Join Group
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/join_group_icon.png', // Gambar yang Anda kirimkan
                    width: 200, // Ukuran gambar lebih kecil
                    height: 200,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 1),

            // Invitation Code Input Field (TextField lebih kecil)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
              ), // Menambahkan padding untuk memperkecil ukuran
              child: TextField(
                controller: _invitationCodeController,
                decoration: InputDecoration(
                  hintText: 'Invitation Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cancel and Join buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Kembali ke halaman sebelumnya
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle Join Group functionality
                    final invitationCode = _invitationCodeController.text;
                    if (invitationCode.isNotEmpty) {
                      print('Joining group with code: $invitationCode');
                      // Implement actual logic for joining the group with invitation code
                      Navigator.pop(
                        context,
                      ); // Kembali setelah bergabung dengan grup
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an invitation code'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Join',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}
