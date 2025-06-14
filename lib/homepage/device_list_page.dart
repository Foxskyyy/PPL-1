import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/homepage/add_device.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/user_session.dart';

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
    fetchGroupDevices();
  }

  Future<void> fetchGroupDevices() async {
    const String query = '''
    {
      userGroups {
        id
        name
        users {
          user {
            id
          }
        }
        devices {
          id
          name
        }
      }
    }
    ''';

    try {
      final int? userId = await UserSession.getUserID();
      if (userId == null) {
        print('❌ User ID null');
        setState(() => isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      final result = jsonDecode(response.body);
      print('📥 Full userGroups Response: $result');

      final List<dynamic> userGroups = result['data']['userGroups'];
      final List<Map<String, dynamic>> userDevices = [];

      for (var group in userGroups) {
        final List<dynamic> users = group['users'];
        final bool isMember = users.any(
          (u) => u['user']['id'].toString() == userId.toString(),
        );

        if (isMember) {
          final List<dynamic> groupDevices = group['devices'] ?? [];
          for (var device in groupDevices) {
            userDevices.add({
              'id': device['id'],
              'name': device['name'],
              'groupId': int.parse(group['id'].toString()), // ✅ as int
              'groupName': group['name'] ?? 'Unnamed Group',
            });
          }
        }
      }

      setState(() {
        devices = userDevices;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error ambil group devices: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> removeDevice(String deviceId, int groupId) async {
    final String mutation = '''
      mutation {
        removeDevice(groupId: $groupId, deviceId: "$deviceId")
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': mutation}),
      );

      final result = jsonDecode(response.body);
      print('📥 Remove response: $result');

      if (response.statusCode == 200 &&
          result['data'] != null &&
          result['data']['removeDevice'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perangkat berhasil dihapus')),
        );
        fetchGroupDevices();
      } else {
        final err = result['errors']?[0]?['message'] ?? 'Unknown error';
        print('❌ Gagal hapus device: $err');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $err')));
      }
    } catch (e) {
      print('❌ Exception hapus device: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _confirmDelete(String deviceId, int groupId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus Perangkat'),
            content: const Text('Yakin ingin menghapus perangkat ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  removeDevice(deviceId, groupId);
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: Column(
          children: [
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
                child:
                    devices.isEmpty
                        ? const Center(
                          child: Text('Tidak ada perangkat di grup ini.'),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: devices.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return ListTile(
                              title: Text(
                                device['name'] ?? 'Unnamed Device',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Grup: ${device['groupName'] ?? ''}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _confirmDelete(
                                      device['id'],
                                      device['groupId'],
                                    ),
                              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
