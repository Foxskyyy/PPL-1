import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/user_session.dart';

class EditGroupPage extends StatefulWidget {
  final String groupName;
  final List<Map<String, dynamic>> members;

  const EditGroupPage({
    super.key,
    required this.groupName,
    required this.members,
  });

  @override
  _EditGroupPageState createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  late List<Map<String, dynamic>> members;
  late TextEditingController groupNameController;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    groupNameController = TextEditingController(text: widget.groupName);
    members =
        widget.members.map((m) {
          return {
            'id': m['id'],
            'displayName': m['displayName'],
            'isAdmin': m['isAdmin'] == 'true' || m['isAdmin'] == true,
            'groupId': m['groupId'],
          };
        }).toList();

    UserSession.loadSession().then((_) async {
      final id = await UserSession.getUserID();
      setState(() {
        currentUserId = id;
        print('[DEBUG] Current User ID: $currentUserId');
      });
    });
  }

  Future<void> _editMember(String userId, String action) async {
    final int? groupId = int.tryParse(widget.members.first['groupId'] ?? '');
    if (groupId == null) return;

    const apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';
    final mutation = '''
      mutation {
        editMember(groupId: $groupId, changedUserID: $userId, action: "$action")
      }
    ''';

    print('[DEBUG] Sending mutation: $mutation');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': mutation}),
      );

      print('[DEBUG] Mutation Response: ${response.body}');

      final result = jsonDecode(response.body);
      if (result['errors'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['errors'][0]['message']}')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action "$action" applied.')));
        setState(() {
          if (action == 'REMOVE') {
            members.removeWhere((m) => m['id'] == userId);
          } else {
            members =
                members.map((m) {
                  if (m['id'] == userId) {
                    m['isAdmin'] = (action == 'ADMIN_PERMS');
                  }
                  return m;
                }).toList();
          }
        });
      }
    } catch (e) {
      print('[DEBUG] Exception: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to apply action: $e')));
    }
  }

  bool isCurrentUserAdmin() {
    final user = members.firstWhere(
      (m) => m['id'] == currentUserId?.toString(),
      orElse: () {
        print('[DEBUG] isAdmin check for user null => false');
        return {'isAdmin': false};
      },
    );
    print(
      '[DEBUG] isAdmin check for user $currentUserId => ${user['isAdmin']}',
    );
    return user['isAdmin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(color: Colors.black),
            _buildBackButton(),
            _buildGroupInfoInput(),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Members:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isSelf = member['id'] == currentUserId?.toString();
                  final isAdmin = member['isAdmin'] == true;

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(member['displayName'] ?? 'User'),
                    subtitle:
                        isAdmin
                            ? const Text(
                              'Admin',
                              style: TextStyle(color: Colors.green),
                            )
                            : null,
                    trailing:
                        isCurrentUserAdmin() && !isSelf
                            ? PopupMenuButton<String>(
                              onSelected: (value) {
                                _editMember(member['id'], value);
                              },
                              itemBuilder:
                                  (context) => [
                                    if (!isAdmin)
                                      const PopupMenuItem(
                                        value: 'ADMIN_PERMS',
                                        child: Text('Make Admin'),
                                      ),
                                    if (isAdmin)
                                      const PopupMenuItem(
                                        value: 'MEMBER_PERMS',
                                        child: Text('Remove Admin'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'REMOVE',
                                      child: Text('Kick from Group'),
                                    ),
                                  ],
                            )
                            : null,
                  );
                },
              ),
            ),
            _buildSaveButtons(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/ecotrack_logo.png', width: 60, height: 60),
          const CircleAvatar(
            backgroundColor: Colors.lightBlue,
            radius: 18,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, size: 20),
                SizedBox(width: 4),
                Text('Back'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.lightBlue,
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 15),
          Expanded(child: _textField(groupNameController, 'Group Name')),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSaveButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'members': members,
                'groupName': groupNameController.text,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
