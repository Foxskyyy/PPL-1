import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/user_session.dart';

class AddMemberPage extends StatefulWidget {
  final String groupId;

  const AddMemberPage({super.key, required this.groupId});

  @override
  _AddMemberPageState createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  int? _parsedGroupId;
  bool isCheckingGroupUsers = false;
  int currentUserCount = 0;

  @override
  void initState() {
    super.initState();
    UserSession.loadSession().then((_) {
      _parseAndValidateGroupId();
    });
  }

  void _parseAndValidateGroupId() {
    try {
      // Try to parse the groupId as an integer
      _parsedGroupId = int.tryParse(widget.groupId);

      print('Attempting to parse groupId: ${widget.groupId}');
      print('Parsed groupId: $_parsedGroupId');

      if (_parsedGroupId == null) {
        setState(() {
          errorMessage = "Invalid group ID: must be a number";
        });
      } else if (_parsedGroupId! <= 0) {
        setState(() {
          errorMessage = "Invalid group ID: must be a positive number";
        });
      } else {
        // Valid ID - clear any error message and check current user count
        setState(() {
          errorMessage = null;
        });
        _checkCurrentUserCount();
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error processing group ID: ${e.toString()}";
      });
      print('Error parsing groupId: $e');
    }
  }

  // Add this new method to check the current number of users in the group
  Future<void> _checkCurrentUserCount() async {
    if (_parsedGroupId == null) return;

    setState(() {
      isCheckingGroupUsers = true;
    });

    const String apiUrl =
        'http://api-ecotrack.interphaselabs.com/graphql/query';

    final String query = '''
      query {
        userGroup(id: $_parsedGroupId) {
          users {
            id
            displayName
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

      print('Group Users API Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result.containsKey('errors')) {
          print('Error checking user count: ${result['errors'][0]['message']}');
        } else if (result.containsKey('data') &&
            result['data']['userGroup'] != null &&
            result['data']['userGroup']['users'] != null) {
          final List<dynamic> users = result['data']['userGroup']['users'];
          setState(() {
            currentUserCount = users.length;
          });

          print('Current user count: $currentUserCount');

          if (currentUserCount >= 4) {
            setState(() {
              errorMessage = "Group already has maximum number of users (4)";
            });
          }
        }
      }
    } catch (e) {
      print('Error checking user count: $e');
    } finally {
      setState(() {
        isCheckingGroupUsers = false;
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
            // App Bar
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

            // Back Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

            // Title
            const Text(
              'Input email to add',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // User count info
            if (currentUserCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Current members: $currentUserCount of 4',
                  style: TextStyle(
                    color: currentUserCount >= 4 ? Colors.red : Colors.grey,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Email input TextField
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Enter email',
                  hintText: 'example@example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 20),

            // Loading indicator for user count check
            if (isCheckingGroupUsers)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),

            // Error message if any
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            // Buttons for Cancel and Save
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        isLoading ||
                                isCheckingGroupUsers ||
                                _parsedGroupId == null ||
                                _parsedGroupId! <= 0 ||
                                currentUserCount >= 4
                            ? null
                            : () async {
                              final email = _emailController.text.trim();
                              if (email.isNotEmpty) {
                                await _assignUserToGroup(email);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter an email'),
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
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  // Mutation to assign user to a group
  Future<void> _assignUserToGroup(String email) async {
    if (_parsedGroupId == null || _parsedGroupId! <= 0) {
      setState(() {
        errorMessage = "Invalid group ID";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null; // Clear previous error messages
    });

    const String apiUrl =
        'http://api-ecotrack.interphaselabs.com/graphql/query';

    final String query = '''
      mutation {
        assignUserToGroup(senderEmail: "${UserSession.email}", receiverEmail: "$email", userGroupID: $_parsedGroupId)
      }
    ''';

    print('Sending GraphQL mutation with userGroupID: $_parsedGroupId');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      print('API Response: ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (result.containsKey('errors')) {
          final String errorMsg = result['errors'][0]['message'];
          setState(() {
            errorMessage = errorMsg;
            isLoading = false;
          });

          // Special handling for user limit error
          if (errorMsg.contains("cannot have more than")) {
            // Force refresh the user count
            _checkCurrentUserCount();

            // Show a more user-friendly message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This group has reached the maximum limit of 4 users',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          } else {
            // Show other errors in a snackbar
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $errorMsg')));
          }
        } else if (result.containsKey('data') &&
            result['data']['assignUserToGroup'] != null) {
          // Success case
          setState(() {
            isLoading = false;
            // Increment the user count
            currentUserCount++;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member added successfully')),
          );

          Navigator.pop(context, email); // Navigate back with email
        } else {
          // Handle unexpected response format
          setState(() {
            errorMessage = 'Unexpected response from server';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection error: ${e.toString()}';
        isLoading = false;
      });
      print('Connection error: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
