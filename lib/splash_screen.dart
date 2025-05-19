import 'dart:async';
import 'package:flutter/material.dart';
import 'package:front_end/login/login.dart';
import 'package:front_end/homepage/homepage.dart';
import 'package:front_end/user_session.dart';
import 'package:front_end/settings/viewprofile/nickname_notifier.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _size = 10;
  bool _showLogo = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _loadSession();
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _size = 80;
      });
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _showLogo = true;
      });
    });
  }

  Future<void> _loadSession() async {
    await UserSession.loadSession(); // ⮕ Load dari SharedPreferences
    if (UserSession.displayName != null) {
      nicknameNotifier.value =
          UserSession.displayName!; // ⮕ Sinkronkan nickname!
    }

    Timer(const Duration(seconds: 3), () {
      if (UserSession.displayName != null && UserSession.email != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF66BB45),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!_showLogo)
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_size / 4),
                ),
                transform: Matrix4.rotationZ(0.785398),
              ),
            if (_showLogo)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      color: Color(0xFF66BB45),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/images/ecotrack_splash_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ecotrack',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
