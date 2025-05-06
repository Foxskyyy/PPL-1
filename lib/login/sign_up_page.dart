import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/login/verification_code_page.dart';
import 'package:front_end/settings/viewprofile/nickname_notifier.dart';
import 'package:front_end/login/login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _handleNextStep() async {
    final displayName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (displayName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _showError("Please fill in all fields.");
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _showError("Invalid email format.");
      return;
    }

    if (password.length < 8) {
      _showError("Password must be at least 8 characters.");
      return;
    }

    if (password != confirm) {
      _showError("Passwords do not match.");
      return;
    }

    _showLoading(true);

    try {
      const String apiUrl = 'https://api.interphaselabs.com/graphql/query';

      final mutation = '''
        mutation Register(\$displayName: String!, \$email: String!, \$password: String!) {
          register(displayName: \$displayName, email: \$email, password: \$password)
        }
      ''';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': mutation,
          'variables': {
            'displayName': displayName,
            'email': email,
            'password': password,
          },
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      print("DEBUG REGISTER RESPONSE: $jsonResponse");

      if (response.statusCode == 200) {
        if (jsonResponse['errors'] != null) {
          final errorMsg = jsonResponse['errors'][0]['message'];
          _showLoading(false);
          _showError("Registration failed: $errorMsg");
          return;
        }

        final message = jsonResponse['data']?['register'] ?? '';
        if (message.toLowerCase().contains("failed")) {
          _showLoading(false);
          _showError("Registration failed: $message");
          return;
        }

        nicknameNotifier.updateNickname(displayName);

        _showLoading(false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => VerificationCodePage(
                  email: email,
                  username: displayName,
                  password: password,
                ),
          ),
        );
      } else {
        _showLoading(false);
        _showError(
          "Server error: ${response.statusCode}. Please try again later.",
        );
      }
    } catch (e) {
      _showLoading(false);
      _showError("Connection error: $e");
    }
  }

  Future<void> _handleGoogleSignUp() async {
    try {
      _showLoading(true);
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _showLoading(false);
        _showError("Google sign-in canceled.");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      _showLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Successfully signed up with Google!")),
      );
    } catch (e) {
      _showLoading(false);
      _showError("Google Sign-In failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/ecotrack_logo.png',
                    width: 260,
                    height: 260,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fullNameController,
                    decoration: _inputDecoration("Full Name"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: _inputDecoration("Email Address"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration("Password").copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: _inputDecoration(
                      "Password Confirmation",
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () => setState(
                              () =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Must be at least 8 characters.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF32CD65),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "Get Verification Code",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Color(0xFFFF6347),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _handleGoogleSignUp,
                        child: Image.asset(
                          'assets/images/google_logo.png',
                          width: 36,
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Icon(Icons.apple, size: 36, color: Colors.black),
                    ],
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
