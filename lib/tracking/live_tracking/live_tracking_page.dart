import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/tracking/live_tracking/live_tracking_place_page.dart';
import 'package:front_end/user_session.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  List<Map<String, dynamic>> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    const String apiUrl = 'https://api.interphaselabs.com/graphql/query';
    const String query = '''
      {
        userGroups {
          id
          name
          devices {
            id
            name
          }
          users {
            id
          }
        }
      }
    '''; // Update query to get devices as well

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<dynamic> userGroups = result['data']['userGroups'];
        int? currentUserId = UserSession.userID;

        final filteredGroups =
            userGroups
                .where((group) {
                  final users = group['users'] as List<dynamic>;
                  return users.any(
                    (user) => user['id'].toString() == currentUserId.toString(),
                  );
                })
                .map(
                  (group) => {
                    'name': group['name'] ?? 'Unnamed Group',
                    'id': group['id'].toString(),
                    'devices': group['devices'] ?? [], // Get devices here
                  },
                )
                .toList();

        setState(() {
          groups = filteredGroups;
          isLoading = false;
        });
      } else {
        print('Failed to fetch: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching groups: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Divider(color: Colors.black),
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Select a group to see its live tracking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _GroupCard(
                              title: group['name'],
                              onTap: () {
                                // Get the deviceId from the first device in the group
                                final devices = group['devices'] ?? [];
                                if (devices.isNotEmpty) {
                                  final device =
                                      devices.first; // Get the first device
                                  final deviceId = device['id'];

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => LiveTrackingPlacePage(
                                            placeName: group['name'],
                                            room: '', // Set room if needed
                                            currentUsage:
                                                0.0, // Set currentUsage if needed
                                            groupId: int.parse(
                                              group['id'],
                                            ), // Group ID as int
                                            deviceId: deviceId, // Pass deviceId
                                          ),
                                    ),
                                  );
                                } else {
                                  // Handle case where there are no devices in the group
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "No devices available in this group",
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _GroupCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
