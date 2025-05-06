import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/user_session.dart'; // For accessing userID

class NewGroupPage extends StatefulWidget {
  const NewGroupPage({super.key, required int userID});

  @override
  _NewGroupPageState createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> members = [
    {'name': 'M. Is\'Ad Prabaswara', 'status': ''},
    {'name': 'Daffa Burane Nugraha', 'status': ''},
    {'name': 'Tabina Adelia Rafa', 'status': ''},
    {'name': 'Shervina Ananda H.', 'status': ''},
  ];

  // Toggle the add member status
  void _toggleAddMember(int index) {
    setState(() {
      members[index]['status'] =
          members[index]['status'] == 'Added' ? '' : 'Added';
    });
  }

  // Create a new group
  Future<void> _createGroup() async {
    final String groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Group name is required")));
      return;
    }

    // Get the userID from UserSession
    int? userID = UserSession.userID; // Getting from UserSession directly
    // Check if the userID is valid
    if (userID == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid User ID")));
      return;
    }

    const String apiUrl = 'https://api.interphaselabs.com/graphql/query';
    const String mutation = '''
      mutation CreateGroup(\$userID: Int!, \$groupName: String!) {
        createUserGroup(userID: \$userID, groupName: \$groupName) {
          id
          name
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': mutation,
        'variables': {
          'userID': userID, // Pass the userID here from UserSession
          'groupName': groupName,
        },
      }),
    );

    final data = jsonDecode(response.body);
    if (data['errors'] != null) {
      final error = data['errors'][0]['message'];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $error")));
    } else {
      final groupId = data['data']['createUserGroup']['id'];
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group created successfully!")),
      );

      // Now, add members to the group
      List<String> memberIds = [];
      for (var member in members) {
        if (member['status'] == 'Added') {
          memberIds.add(member['name']!); // Assuming you have the user IDs
        }
      }

      _addMembersToGroup(groupId, memberIds);

      Navigator.pop(context);
    }
  }

  // Function to add members to the group
  Future<void> _addMembersToGroup(
    String groupId,
    List<String> memberIds,
  ) async {
    const String apiUrl = 'https://api.interphaselabs.com/graphql/query';
    const String mutation = '''
      mutation AddMembersToGroup(\$groupId: String!, \$memberIds: [String!]!) {
        addMembersToGroup(groupId: \$groupId, memberIds: \$memberIds) {
          id
          name
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': mutation,
        'variables': {'groupId': groupId, 'memberIds': memberIds},
      }),
    );

    final data = jsonDecode(response.body);
    if (data['errors'] != null) {
      final error = data['errors'][0]['message'];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $error")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Members added successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Container(height: 1, color: Colors.black),
            _buildBackButton(),
            _buildGroupInfoInput(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _inputField(
                _searchController,
                'Search for people to add',
                isSearch: true,
              ),
            ),
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Members:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  return _buildMemberRow(index);
                },
              ),
            ),
            _buildActionButtons(),
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
            child: const Icon(Icons.arrow_back, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputField(_groupNameController, 'Group Name'),
                const SizedBox(height: 12),
                _inputField(_groupDescController, 'Desc'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _createGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String hintText, {
    bool isSearch = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon:
              isSearch ? const Icon(Icons.search, color: Colors.grey) : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 15,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMemberRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 22,
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              members[index]['name']!,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => _toggleAddMember(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              members[index]['status'] == 'Added' ? 'Added' : 'Add',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
