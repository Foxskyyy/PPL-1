import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/group/join_group_page.dart';
import 'package:front_end/group/new_group_page.dart';
import 'package:front_end/group/yourgroup/your_group_page.dart'; // Import halaman yang dimaksud
import 'package:front_end/user_session.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({
    super.key,
    required String groupId,
    required String groupDescription,
    required String groupName,
  });

  @override
  Widget build(BuildContext context) {
    final int userID = UserSession.userID ?? 0; // Ambil userID global

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

            const SizedBox(height: 72),

            // Group Options
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _GroupItem(
                      icon: Icons.groups,
                      title: 'Your Group',
                      onTap: () {
                        // Navigasi langsung ke halaman 'YourGroupPage'
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => YourGroupPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _GroupItem(
                      icon: Icons.group_add,
                      title: 'New Group',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewGroupPage(userID: userID),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // _GroupItem(
                    //   icon: Icons.group_outlined,
                    //   title: 'Join Group',
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const JoinGroupPage(),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}

class _GroupItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _GroupItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(icon, size: 28, color: Colors.black),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
