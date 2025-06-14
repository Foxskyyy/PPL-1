import 'package:flutter/material.dart';
import 'package:front_end/homepage/homepage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class VerificationCodePage extends StatefulWidget {
  final String email, username, password;

  const VerificationCodePage({
    super.key,
    required this.email,
    required this.username,
    required this.password,
  });

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final TextEditingController _codeController = TextEditingController();
  final String apiUrl = "https://api-ecotrack.interphaselabs.com/graphql/query";
  int _resendCountdown = 0;
  Timer? _timer;

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showError("Please enter the full 6-digit code.");
      return;
    }

    const mutation = '''
      mutation VerifyEmail(\$email: String!, \$token: String!) {
        verifyEmail(email: \$email, token: \$token)
      }
    ''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': mutation,
        'variables': {'email': widget.email, 'token': code},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['errors'] != null) {
        final msg = result['errors'][0]['message'] ?? "Verification failed.";
        _showError("Verification failed: $msg");
      } else {
        _showSuccess("Email verified successfully.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      _showError("Server error: ${response.statusCode}");
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    const mutation = '''
      mutation ResendVerification(\$email: String!) {
        ResendVerificationEmail(email: \$email)
      }
    ''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': mutation,
        'variables': {'email': widget.email},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['errors'] != null) {
        final msg = result['errors'][0]['message'] ?? "Unknown error";
        _showError("Resend failed: $msg");
      } else {
        _showSuccess("Verification code resent to ${widget.email}");
        _startResendCountdown();
      }
    } else {
      _showError("Server error: ${response.statusCode}");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String maskedEmail = widget.email.replaceRange(
      2,
      widget.email.indexOf("@"),
      "*****",
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Image.asset("assets/images/verification_icon.png", height: 100),
            const SizedBox(height: 24),
            const Text(
              "Verification Code",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Enter the verification code sent to\n$maskedEmail",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // OTP Field Style
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 32,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "------",
                counterText: "",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(width: 2, color: Colors.grey.shade400),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(width: 2, color: Colors.blue),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32CD65),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Verify",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendCountdown > 0 ? null : _resendCode,
              child: Text(
                _resendCountdown > 0
                    ? "Resend in $_resendCountdown seconds"
                    : "Resend Code",
                style: TextStyle(
                  color: _resendCountdown > 0 ? Colors.grey : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
