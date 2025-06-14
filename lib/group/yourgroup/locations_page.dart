import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/custom_button_navbar.dart';

class LocationsPage extends StatefulWidget {
  final int groupId;

  const LocationsPage({super.key, required this.groupId});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';
  final TextEditingController _locationController = TextEditingController();
  bool isLoading = true;
  List<String> locations = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': '''
          query GetGroupLocations {
            userGroups {
              id
              location
            }
          }
        ''',
      }),
    );

    print('[DEBUG] Group locations response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] != null && data['data']['userGroups'] != null) {
        final groups = data['data']['userGroups'] as List<dynamic>;
        final group = groups.firstWhere(
          (g) => g['id'].toString() == widget.groupId.toString(),
          orElse: () => null,
        );

        if (group != null) {
          setState(() {
            locations = List<String>.from(group['location'] ?? []);
            errorMessage = null;
          });
        } else {
          setState(() {
            errorMessage = 'Group not found.';
          });
        }
      }
    } else {
      setState(() {
        errorMessage = 'Failed to load locations.';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> addLocation() async {
    final String locationName = _locationController.text.trim();
    if (locationName.isEmpty) return;

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': '''
          mutation AddLocation(\$groupId: Int!, \$locationName: String!) {
            addLocation(groupId: \$groupId, locationName: \$locationName)
          }
        ''',
        'variables': {'groupId': widget.groupId, 'locationName': locationName},
      }),
    );

    print('[DEBUG] Add location response: ${response.body}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final successMessage = result['data']?['addLocation'];
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi berhasil ditambahkan')),
        );
        _locationController.clear();
        fetchLocations();
      }
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/ecotrack_logo.png', width: 60, height: 60),
          const CircleAvatar(
            backgroundColor: Colors.lightBlue,
            radius: 18,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, size: 20),
                SizedBox(width: 4),
                Text('Back'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    _buildHeader(),
                    const Divider(color: Colors.black),
                    _buildBackButton(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daftar Lokasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (errorMessage != null)
                              Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              )
                            else if (locations.isEmpty)
                              const Text(
                                'Belum ada lokasi.',
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              ...locations.map(
                                (loc) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          loc,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            const Text(
                              'Tambah Lokasi Baru',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                hintText: 'Nama lokasi',
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: addLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Tambah Lokasi',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),

      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}
