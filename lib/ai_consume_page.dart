import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:front_end/user_session.dart';

class AIConsumePage extends StatefulWidget {
  const AIConsumePage({super.key});

  @override
  State<AIConsumePage> createState() => _AIConsumePageState();
}

class _AIConsumePageState extends State<AIConsumePage> {
  bool _isLoading = false;
  String _suggestion = "Gagal memuat data analisis. Silakan coba lagi nanti.";

  final String _apiUrl = "https://api.interphaselabs.com/graphql/query";

  @override
  void initState() {
    super.initState();
    _fetchAIConsumeSuggestion();
  }

  Future<void> _fetchAIConsumeSuggestion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String query = '''
      query deepSeekAnalysis(\$userID: Int!) {
        deepSeekAnalysis(userID: \$userID) {
          analysis
        }
      }
      ''';

      int userID = UserSession.userID ?? 123;

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'variables': {'userID': userID},
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] != null &&
            jsonResponse['data']['deepSeekAnalysis'] != null) {
          setState(() {
            _suggestion = jsonResponse['data']['deepSeekAnalysis']['analysis'];
          });
        }
      }
    } catch (_) {
      // Ignore for now
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: Column(
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
            const Divider(color: Colors.black),

            // Back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context); // Kembali ke halaman sebelumnya
                    },
                  ),
                  const Text(
                    "Back",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF007A33),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Analysis",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // AI Suggestion Card with Icon and Text
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child:
                            _isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                  ),
                                )
                                : SingleChildScrollView(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Icon(
                                          Icons.smart_toy,
                                          size: 36,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _suggestion,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
