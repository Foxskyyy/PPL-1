import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/homepage/add_device.dart'; // GANTI SESUAI PATH ASLI
import 'package:front_end/custom_button_navbar.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  List<Map<String, dynamic>> devices = [];
  bool isLoading = true;

  final String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    const String query = '''
      {
        devices {
          id
          name
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      print('Raw response body: ${response.body}');

      final result = jsonDecode(response.body);

      if (result['data'] != null && result['data']['devices'] != null) {
        final List fetched = result['data']['devices'];
        setState(() {
          devices =
              fetched.map<Map<String, dynamic>>((item) {
                return {'id': item['id'], 'name': item['name']};
              }).toList();
          isLoading = false;
        });
      } else {
        print('No devices data found in response');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching devices: $e');
      setState(() => isLoading = false);
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
            // HEADER SESUAI TEMPLATE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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

            _buildBackButton(),
            _buildAddDeviceButton(),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(
                        device['name'] ?? 'Unnamed Device',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        print("Tapped Device ID: ${device['id']}");
                        // Tambahkan navigasi detail jika dibutuhkan
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new, size: 16),
              SizedBox(width: 4),
              Text("Back", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddDeviceButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDevicePage()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.add, color: Colors.black),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Add New Device",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
