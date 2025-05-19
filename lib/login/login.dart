import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end/homepage/homepage.dart';
import 'package:front_end/login/forgot_password_page.dart';
import 'package:front_end/settings/viewprofile/nickname_notifier.dart';
import 'package:front_end/user_session.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'verification_code_page.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Email and Password cannot be empty.");
      return;
    }

    if (!_isValidEmail(email)) {
      _showError("Please enter a valid email address.");
      return;
    }

    setState(() => _isLoading = true);

    const loginMutation = '''
      mutation Login(\$email: String!, \$password: String!) {
        login(email: \$email, password: \$password) {
          token
          user {
            id
            displayName
            email
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': loginMutation,
          'variables': {'email': email, 'password': password},
        }),
      );

      setState(() => _isLoading = false);
      final result = jsonDecode(response.body);
      print("LOGIN RESULT: $result");

      if (response.statusCode == 200) {
        if (result['errors'] != null && result['errors'].isNotEmpty) {
          _showError(result['errors'][0]['message'] ?? 'Login failed.');
          return;
        }

        final user = result['data']['login']['user'];
        final username = user['displayName'] ?? '';
        final userId = int.tryParse(user['id'] ?? '') ?? 0;
        final userEmail = user['email'] ?? '';

        nicknameNotifier.updateNickname(username);
        UserSession.userID = userId;
        UserSession.displayName = username;
        UserSession.email = userEmail;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => VerificationCodePage(
                  email: email,
                  username: username,
                  password: password,
                ),
          ),
        );
      } else {
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Network error: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser =
          await GoogleSignIn(
            clientId:
                '147912338941-glpq5egdkjkmhe6k2quuc2jeadlnogfs.apps.googleusercontent.com',
          ).signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      const oauthLoginMutation = '''
        mutation OAuthLogin(\$provider: OAuthProvider!, \$token: String!) {
          oauthLogin(provider: \$provider, token: \$token) {
            token
            user {
              id
              displayName
              email
            }
          }
        }
      ''';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': oauthLoginMutation,
          'variables': {'provider': 'GOOGLE', 'token': googleAuth.idToken},
        }),
      );

      final result = jsonDecode(response.body);
      print("GOOGLE LOGIN RESULT: $result");

      if (response.statusCode == 200) {
        if (result['errors'] != null && result['errors'].isNotEmpty) {
          _showError(result['errors'][0]['message'] ?? 'Google Login failed.');
          return;
        }

        final user = result['data']['oauthLogin']['user'];
        final username = user['displayName'] ?? '';
        final userId = int.tryParse(user['id'] ?? '') ?? 0;
        final userEmail = user['email'] ?? '';

        nicknameNotifier.updateNickname(username);
        UserSession.userID = userId;
        UserSession.displayName = username;
        UserSession.email = userEmail;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Google sign-in failed: $e");
    }
  }

  Widget _buildLogoAndTitle() {
    return Column(
      children: [
        Image.asset('assets/images/ecotrack_logo.png', width: 100, height: 100),
        const SizedBox(height: 10),
        const Text(
          'Ecotrack',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    TextInputType type,
  ) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF32CD65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  Widget _buildAuthLinks() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Forgot Password? "),
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  ),
              child: const Text(
                "Click Here",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? "),
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  ),
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: signInWithGoogle,
          child: const Text(
            "Sign In With Google Instead",
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildLogoAndTitle(),
              const SizedBox(height: 40),
              _buildTextField(_emailController, 'Username', TextInputType.text),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 30),
              _buildSignInButton(),
              const SizedBox(height: 25),
              _buildAuthLinks(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
