import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/group/yourgroup/group_member.dart'; // Ensure importing GroupMemberPage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/user_session.dart'; // For accessing userID

class YourGroupPage extends StatefulWidget {
  const YourGroupPage({super.key});

  @override
  State<YourGroupPage> createState() => _YourGroupPageState();
}

class _YourGroupPageState extends State<YourGroupPage> {
  List<Map<String, dynamic>> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  // Function to fetch groups from API
  Future<void> fetchGroups() async {
    const String apiUrl =
        'https://api.interphaselabs.com/graphql/query'; // Use /query for GraphQL

    // Query that fetches group name and associated users
    const String query = '''
      { 
        userGroups {
          id
          name
          users {
            id
          }
        }
      }
    ''';

    final Uri url = Uri.parse('$apiUrl?query=${Uri.encodeComponent(query)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // If authentication is needed
          // 'Authorization': 'Bearer ${UserSession.token}',
        },
        body: jsonEncode({'query': query}),
      );

      // Debugging: check statusCode and response.body
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Check if the response contains valid data
        if (result.containsKey('data') &&
            result['data'].containsKey('userGroups')) {
          final List<dynamic> userGroups = result['data']['userGroups'];

          // Get userID from session
          int? currentUserId =
              UserSession.userID; // Ensure the userID is available

          // Check if currentUserId is available
          if (currentUserId == null) {
            setState(() {
              groups = [];
              isLoading = false;
            });
            return; // Exit early if userID is not found
          }

          // Filter groups based on userID
          final filteredGroups =
              userGroups
                  .where((group) {
                    final users = group['users'] as List<dynamic>;
                    return users.any(
                      (user) =>
                          user['id'].toString() == currentUserId.toString(),
                    );
                  })
                  .map((group) {
                    return {
                      'name': group['name'] ?? 'Unnamed Group',
                      'groupId': group['id'] ?? '',
                    };
                  })
                  .toList();

          print(
            'Filtered Groups: $filteredGroups',
          ); // Debugging: check the filtered data

          setState(() {
            groups = filteredGroups;
            isLoading = false;
          });
        } else {
          print('Invalid response structure: $result');
          setState(() {
            groups = [];
            isLoading = false;
          });
        }
      } else {
        print('Error fetching data: ${response.statusCode}, ${response.body}');
        setState(() {
          groups = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        groups = [];
        isLoading = false;
      });
    }
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
            const Divider(color: Colors.black),
            // Title and Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Remove the 'Create Group' button if not needed
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Groups',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Group List
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : groups.isEmpty
                      ? const Center(child: Text('No groups available'))
                      : ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          return _GroupItem(
                            name: groups[index]['name'],
                            onTap: () {
                              // Navigate to GroupDetailPage when group is tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => GroupDetailPage(
                                        groupName: groups[index]['name'],
                                        groupDescription:
                                            'Group description', // Adjust description if needed
                                        groupId:
                                            groups[index]['groupId'], // Pass groupId for the detail page
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
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}

class _GroupItem extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _GroupItem({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          color: Colors.white,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.group, color: Colors.white),
          ),
          title: Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
