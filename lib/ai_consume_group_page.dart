import 'package:flutter/material.dart';
import 'package:front_end/ai_consume_user_page.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:front_end/user_session.dart';

class AIConsumeGroupPage extends StatefulWidget {
  const AIConsumeGroupPage({super.key});

  @override
  State<AIConsumeGroupPage> createState() => _AIConsumeGroupPageState();
}

class _AIConsumeGroupPageState extends State<AIConsumeGroupPage> {
  bool _isLoading = false;
  String _suggestion = "Gagal memuat data analisis. Silakan coba lagi nanti.";
  final String _apiUrl = "http://api-ecotrack.interphaselabs.com/graphql/query";

  @override
  void initState() {
    super.initState();
    _fetchGroupAnalysis();
  }

  Future<void> _fetchGroupAnalysis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final query = r'''
      query groupAiAnalysis($groupID: Int!) {
        groupAiAnalysis(groupID: $groupID) {
          analysis
        }
      }
      ''';

      final variables = {'groupID': UserSession.currentGroupID ?? 1};

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query, 'variables': variables}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final result = data?['groupAiAnalysis'];
        if (result != null) {
          setState(() {
            _suggestion = result['analysis'];
          });
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildToggleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AIConsumeUserPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Text(
              "User AI",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Text(
              "Group AI",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: Column(children: [_buildHeader(), _buildContent("Group")]),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/images/ecotrack_logo.png', width: 60),
              const CircleAvatar(
                backgroundColor: Colors.lightBlue,
                radius: 18,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.black),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Back",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildToggleButtons(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildContent(String title) {
    return Expanded(
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
            Text(
              "$title Analysis",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                        : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.smart_toy,
                              size: 36,
                              color: Colors.black,
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
          ],
        ),
      ),
    );
  }
}
