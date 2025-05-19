import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/user_session.dart';
import 'package:front_end/group/group_page.dart';

class NewGroupPage extends StatefulWidget {
  const NewGroupPage({super.key, required int userID});

  @override
  _NewGroupPageState createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();

  Future<void> _createGroup() async {
    final String groupName = _groupNameController.text.trim();
    int? userID = await UserSession.getUserID();

    print('[DEBUG] userID: $userID');
    print('[DEBUG] groupName: $groupName');

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Group name is required")));
      return;
    }

    if (userID == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid User ID")));
      return;
    }

    final String apiUrl =
        'http://api-ecotrack.interphaselabs.com/graphql/query';

    final String mutation = '''
      mutation {
        createUserGroup(userID: $userID, groupName: "$groupName") {
          id
          name
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': mutation}),
    );

    print('[DEBUG] Response: ${response.body}');

    final data = jsonDecode(response.body);
    if (data['errors'] != null) {
      final error = data['errors'][0]['message'];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $error")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group created successfully!")),
      );

      final createdGroup = data['data']['createUserGroup'];
      final groupId = createdGroup['id'].toString();
      final groupName = createdGroup['name'];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => GroupPage(
                groupId: groupId,
                groupName: groupName,
                groupDescription: '',
              ),
        ),
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
              children: [_inputField(_groupNameController, 'Group Name')],
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

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }
}
