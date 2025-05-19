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
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final String apiUrl = "http://api-ecotrack.interphaselabs.com/graphql/query";

  int _resendCountdown = 0;
  Timer? _timer;

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCountdown--;
        });
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
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      _showError("Please enter the full 6-digit verification code.");
      return;
    }

    const mutation = '''
      mutation VerifyEmail(\$email: String!, \$token: String!) {
        verifyEmail(email: \$email, token: \$token)
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
        'variables': {'email': widget.email, 'token': code},
      }),
    );

    if (response.statusCode == 200) {
      try {
        final jsonData = jsonDecode(response.body);
        if (jsonData['errors'] != null) {
          final message = jsonData['errors'][0]['message'];
          _showError("Verification failed: $message");
        } else {
          _showSuccess("Verification successful!");
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      } catch (e) {
        _showError("Invalid response format.");
      }
    } else {
      _showError("Server error: ${response.statusCode}");
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    const mutation = '''
      mutation ResendVerificationEmail(\$email: String!) {
        ResendVerificationEmail(email: \$email)
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
        'variables': {'email': widget.email},
      }),
    );

    if (response.statusCode == 200) {
      try {
        final jsonData = jsonDecode(response.body);
        if (jsonData['errors'] != null) {
          final message = jsonData['errors'][0]['message'];
          _showError("Resend failed: $message");
        } else {
          _showSuccess("Verification code resent to ${widget.email}");
          _startResendCountdown();
        }
      } catch (e) {
        _showError("Failed to parse server response.");
      }
    } else {
      _showError("Server error: ${response.statusCode}");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String masked = widget.email.replaceRange(
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
              "Please type the verification code sent to\n$masked",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                      }
                    },
                  ),
                );
              }),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
