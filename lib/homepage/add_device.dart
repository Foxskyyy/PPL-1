import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_end/user_session.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  _AddDevicePageState createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  String deviceName = "";
  String? selectedLocation;
  int? selectedGroupId;
  bool isLoading = false;

  final String deviceId = "ET-d31e0e38-91bf-4b83-8439-1a7e72b1d8c4";
  final String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';

  List<Map<String, dynamic>> groups = [];

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    final int? currentUserId = UserSession.userID;
    if (currentUserId == null) {
      print("❌ User ID is null. Cannot fetch groups.");
      return;
    }

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
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      print('[DEBUG] Group Response: ${response.statusCode}');
      print('[DEBUG] Group Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<dynamic> userGroups = result['data']['userGroups'];

        final filteredGroups =
            userGroups
                .where((group) {
                  final users = group['users'] as List<dynamic>;
                  return users.any(
                    (userGroupMember) =>
                        userGroupMember['user']['id'].toString() ==
                        currentUserId.toString(),
                  );
                })
                .map((group) {
                  return {
                    'id': group['id'].toString(),
                    'name': group['name'] ?? 'Unnamed Group',
                  };
                })
                .toList();

        setState(() {
          groups = filteredGroups;
        });
      } else {
        print('Gagal ambil grup: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetchGroups: $e');
    }
  }

  Future<void> saveDevice() async {
    if (deviceName.isNotEmpty &&
        selectedGroupId != null &&
        selectedLocation != null &&
        selectedLocation!.isNotEmpty) {
      setState(() => isLoading = true);

      final String mutation = '''
        mutation AddDeviceToGroup {
          addDeviceToUserGroup(
            deviceId: "$deviceId",
            deviceName: "$deviceName",
            userGroupID: $selectedGroupId,
            location: "$selectedLocation"
          ) {
            id
            name
          }
        }
      ''';

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': mutation}),
        );

        final result = jsonDecode(response.body);
        print('Respons addDeviceToUserGroup: $result');

        if (response.statusCode == 200 && result['data'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perangkat berhasil ditambahkan')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menyimpan: ${result['errors']?[0]?['message'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } catch (e) {
        print('Error addDeviceToUserGroup: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harap isi semua kolom')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'Add Device',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              const SizedBox(height: 10),

              // Device Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => deviceName = value,
                ),
              ),
              const SizedBox(height: 20),

              // Pilih Grup
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: DropdownButtonFormField<int>(
                  value: selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Grup',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      groups
                          .map<DropdownMenuItem<int>>(
                            (group) => DropdownMenuItem<int>(
                              value: int.parse(group['id']),
                              child: Text(group['name']),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGroupId = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Lokasi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Masukkan Lokasi',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => selectedLocation = value,
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: saveDevice,
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
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
