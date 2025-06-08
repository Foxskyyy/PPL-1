import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/user_session.dart';
import 'package:front_end/login/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _isSaving = false;

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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Email Setting
            ListTile(
              title: const Text(
                "Email Address",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "This email address is associated with your account",
              ),
              trailing: Text(
                "Change",
                style: TextStyle(color: Colors.green.shade700),
              ),
              onTap: _showChangeEmailDialog,
            ),
            const Divider(),

            // Password Setting
            ListTile(
              title: const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Set a unique password to protect your account",
              ),
              trailing: Text(
                "Change",
                style: TextStyle(color: Colors.green.shade700),
              ),
              onTap: _showChangePasswordDialog,
            ),
            const Divider(),

            // Delete Account
            ListTile(
              title: const Text(
                "Delete Account",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("This will permanently delete your account"),
              trailing: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // Future: Delete Account
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }

  // ------------------------------- CHANGE EMAIL -------------------------------

  void _showChangeEmailDialog() {
    TextEditingController newEmailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Change Email"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newEmailController,
                    decoration: const InputDecoration(
                      labelText: "New Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      _isSaving
                          ? null
                          : () async {
                            final newEmail = newEmailController.text.trim();
                            final password = passwordController.text.trim();
                            final currentEmail = UserSession.email ?? '';

                            if (newEmail.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all fields'),
                                ),
                              );
                              return;
                            }

                            if (currentEmail.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Current email missing. Please re-login.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setStateDialog(() {
                              _isSaving = true;
                            });

                            try {
                              await changeEmailMutation(
                                currentEmail: currentEmail,
                                password: password,
                                newEmail: newEmail,
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Email changed successfully! Logging out...',
                                    ),
                                  ),
                                );
                                await _logout();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to change email: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setStateDialog(() {
                                  _isSaving = false;
                                });
                              }
                            }
                          },
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> changeEmailMutation({
    required String currentEmail,
    required String password,
    required String newEmail,
  }) async {
    const String apiUrl =
        'http://api-ecotrack.interphaselabs.com/graphql/query';

    const String mutation = '''
      mutation ChangeEmail(\$email: String!, \$password: String!, \$newemail: String!) {
        changeEmail(email: \$email, password: \$password, newemail: \$newemail)
      }
    ''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': mutation,
        'variables': {
          'email': currentEmail,
          'password': password,
          'newemail': newEmail,
        },
      }),
    );

    final result = jsonDecode(response.body);
    if (response.statusCode != 200 || result['errors'] != null) {
      throw Exception(
        result['errors']?[0]['message'] ?? 'Failed to change email.',
      );
    }
  }

  // ------------------------------- CHANGE PASSWORD -------------------------------

  void _showChangePasswordDialog() {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Change Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Old Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "New Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      _isSaving
                          ? null
                          : () async {
                            final oldPassword =
                                oldPasswordController.text.trim();
                            final newPassword =
                                newPasswordController.text.trim();
                            final confirmPassword =
                                confirmPasswordController.text.trim();
                            final email = UserSession.email ?? '';

                            if (oldPassword.isEmpty ||
                                newPassword.isEmpty ||
                                confirmPassword.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all fields'),
                                ),
                              );
                              return;
                            }

                            if (newPassword != confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'New password and confirmation do not match',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Email missing. Please re-login.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setStateDialog(() {
                              _isSaving = true;
                            });

                            try {
                              await requestForgotPassword(email);
                              await forgotPasswordHandler(email, newPassword);

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password changed successfully! Logging out...',
                                    ),
                                  ),
                                );
                                await _logout();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to change password: $e',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setStateDialog(() {
                                  _isSaving = false;
                                });
                              }
                            }
                          },
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> requestForgotPassword(String email) async {
    const String apiUrl =
        'http://api-ecotrack.interphaselabs.com/graphql/query';

    const String mutation = '''
      mutation RequestForgotPassword(\$email: String!) {
        RequestForgotPassword(email: \$email)
      }
    ''';

    await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': mutation,
        'variables': {'email': email},
      }),
    );
  }

  Future<void> forgotPasswordHandler(String email, String newPassword) async {
    const String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';

    const String mutation = '''
      mutation ForgotPasswordHandler(\$email: String!, \$password: String!) {
        ForgotPasswordHandler(email: \$email, password: \$password)
      }
    ''';

    await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': mutation,
        'variables': {'email': email, 'password': newPassword},
      }),
    );
  }

  // ------------------------------- LOGOUT -------------------------------

  Future<void> _logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
