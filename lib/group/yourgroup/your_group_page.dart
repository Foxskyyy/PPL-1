import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/group/yourgroup/group_member.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/user_session.dart';

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

  Future<void> fetchGroups() async {
    const String apiUrl =
        'http://api-ecotrack.interphaselabs.com/graphql/query';

    const String query = '''
    {
      userGroups {
        id
        name
        users {
          user {
            id
            email
          }
        }
      }
    }
    ''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      print('[DEBUG] Response status: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['data'] != null && result['data']['userGroups'] != null) {
          final List<dynamic> userGroups = result['data']['userGroups'];

          final int? currentUserId = await UserSession.getUserID();
          print('[DEBUG] Current User ID: $currentUserId');

          if (currentUserId == null) {
            setState(() {
              groups = [];
              isLoading = false;
            });
            return;
          }

          final filteredGroups =
              userGroups
                  .where((group) {
                    final List<dynamic> users = group['users'];
                    return users.any(
                      (ugm) =>
                          ugm['user']['id'].toString() ==
                          currentUserId.toString(),
                    );
                  })
                  .map((group) {
                    return {
                      'name': group['name'] ?? 'Unnamed Group',
                      'groupId': group['id'] ?? '',
                    };
                  })
                  .toList();

          print('[DEBUG] Filtered Groups: $filteredGroups');

          setState(() {
            groups = filteredGroups;
            isLoading = false;
          });
        } else {
          print('[ERROR] Invalid response structure');
          setState(() {
            groups = [];
            isLoading = false;
          });
        }
      } else {
        print('[ERROR] HTTP ${response.statusCode}: ${response.body}');
        setState(() {
          groups = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('[ERROR] Exception: $e');
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => GroupDetailPage(
                                        groupName: groups[index]['name'],
                                        groupDescription: 'Group description',
                                        groupId: groups[index]['groupId'],
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
