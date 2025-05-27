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
  String _suggestion = "";
  final String _apiUrl = "http://api-ecotrack.interphaselabs.com/graphql/query";

  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    setState(() {
      _isLoading = true;
    });

    final int? userID = await UserSession.getUserID();
    if (userID == null) {
      if (!mounted) return;
      setState(() {
        _suggestion = "User ID tidak ditemukan. Harap login ulang.";
        _isLoading = false;
      });
      return;
    }

    const queryGroups = '''
    query {
      userGroups {
        id
        name
        users {
          user {
            id
          }
        }
      }
    }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': queryGroups}),
      );

      final jsonData = json.decode(response.body);
      final List allGroups = jsonData['data']?['userGroups'] ?? [];

      final List<Map<String, dynamic>> userGroups =
          allGroups
              .where(
                (group) => (group['users'] as List).any(
                  (user) => user['user']['id'].toString() == userID.toString(),
                ),
              )
              .map(
                (group) => {
                  'id': int.parse(group['id'].toString()), // ✅ fix error type
                  'name': group['name'],
                },
              )
              .toList();

      if (!mounted) return;

      setState(() {
        _groups = userGroups;
        if (_groups.isNotEmpty) {
          _selectedGroup = _groups.first;
          _fetchGroupAnalysis(_selectedGroup!['id']);
        } else {
          _suggestion = "Kamu belum tergabung dalam grup manapun.";
        }
      });
    } catch (e) {
      print("❌ Error loading groups: $e");
      if (!mounted) return;
      setState(() {
        _suggestion = "Gagal memuat data grup.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchGroupAnalysis(int groupID) async {
    setState(() {
      _isLoading = true;
      _suggestion = "";
    });

    const query = '''
    query groupAiAnalysis(\$groupID: Int!) {
      groupAiAnalysis(groupID: \$groupID) {
        analysis
      }
    }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {'groupID': groupID},
        }),
      );

      final result = json.decode(response.body)['data']?['groupAiAnalysis'];
      if (!mounted) return;

      setState(() {
        _suggestion = result?['analysis'] ?? "Tidak ada analisis tersedia.";
      });
    } catch (e) {
      print("❌ Error fetching analysis: $e");
      if (!mounted) return;
      setState(() {
        _suggestion = "Terjadi kesalahan saat mengambil analisis.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        child: Column(children: [_buildHeader(), _buildContent()]),
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

  Widget _buildContent() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF007A33),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Group Analysis",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_groups.isNotEmpty)
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedGroup,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items:
                    _groups.map((group) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: group,
                        child: Text(group['name']),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value;
                    _fetchGroupAnalysis(value!['id']);
                  });
                },
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
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
