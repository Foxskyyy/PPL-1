import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/group/yourgroup/add_member_page.dart';
import 'package:front_end/group/yourgroup/edit_group_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroupDetailPage extends StatefulWidget {
  final String groupName;
  final String groupDescription;
  final String groupId;

  const GroupDetailPage({
    super.key,
    required this.groupName,
    required this.groupDescription,
    required this.groupId,
  });

  @override
  _GroupDetailPageState createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  List<Map<String, String>> members = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
  }

  // Mengambil detail grup dengan query yang sesuai
  Future<void> fetchGroupDetails() async {
    const String apiUrl = 'https://api.interphaselabs.com/graphql/query';

    try {
      // Print groupId yang sedang dicari untuk debugging
      print('Mencari grup dengan ID: ${widget.groupId}');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': '''
            query GetUserGroupDetails {
              userGroups {
                id
                name
                users {
                  id
                  displayName
                }
              }
            }
          ''',
        }),
      );

      print('Respons API: ${response.body}'); // Debugging respons

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Memeriksa apakah ada error dalam respons
        if (result.containsKey('errors')) {
          setState(() {
            errorMessage = result['errors'][0]['message'];
            isLoading = false;
          });
          return;
        }

        // Memeriksa apakah data grup ada
        if (result['data']?['userGroups'] != null) {
          final List<dynamic> allGroups = result['data']['userGroups'];

          print("Semua Grup: $allGroups"); // Debugging semua grup

          // Cetak grup ID yang sedang dicari untuk debugging
          print(
            "Mencari grup dengan ID: ${widget.groupId} (${widget.groupId.runtimeType})",
          );

          // Cetak semua ID grup untuk debugging
          allGroups.forEach((group) {
            print("ID grup: ${group['id']} (${group['id'].runtimeType})");
          });

          // Cari berdasarkan nama grup jika ID gagal
          dynamic groupData;

          // Pertama coba cari berdasarkan ID (dengan konversi ke string)
          for (var group in allGroups) {
            if (group['id'].toString() == widget.groupId) {
              groupData = group;
              print("Grup ditemukan berdasarkan ID: $groupData");
              break;
            }
          }

          // Jika tidak ditemukan berdasarkan ID, coba cari berdasarkan nama
          if (groupData == null) {
            for (var group in allGroups) {
              if (group['name'] == widget.groupName) {
                groupData = group;
                print("Grup ditemukan berdasarkan nama: $groupData");
                break;
              }
            }
          }

          if (groupData != null) {
            print("Grup ditemukan: $groupData");
            final usersData = groupData['users'] ?? [];
            print("Data pengguna: $usersData");

            if (usersData.isEmpty) {
              setState(() {
                members = [];
                isLoading = false;
                errorMessage = null;
              });
              return;
            }

            // Mengkombinasikan semua anggota ke dalam satu list
            List<Map<String, String>> allMembers = [];

            for (var user in usersData) {
              print("Memproses user: $user");
              if (user != null) {
                allMembers.add({
                  'displayName':
                      user['displayName'] != null &&
                              user['displayName'].toString().isNotEmpty
                          ? user['displayName'].toString()
                          : 'Anggota',
                  'id': user['id']?.toString() ?? '',
                });
              }
            }

            print("Semua anggota setelah pemrosesan: $allMembers");

            setState(() {
              members = allMembers;
              isLoading = false;
              errorMessage = null;
            });
          } else {
            setState(() {
              errorMessage = 'Grup tidak ditemukan';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = 'Tidak ada data grup yang tersedia';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Gagal memuat: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error dalam fetchGroupDetails: ${e.toString()}");
      setState(() {
        errorMessage = 'Error koneksi: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _addMember() async {
    print('Group ID yang diteruskan: ${widget.groupId}'); // Debug print

    // Extract just the numeric part if groupId contains non-numeric characters
    // or ensure it's a valid numeric format
    String numericGroupId = '';

    try {
      // First, try to parse it directly to check if it's already a valid number
      int.parse(widget.groupId);
      numericGroupId = widget.groupId;
    } catch (e) {
      // If parsing fails, try to extract numeric characters
      numericGroupId = widget.groupId.replaceAll(RegExp(r'[^0-9]'), '');

      // If still empty after extraction, search for the group again to get the correct ID
      if (numericGroupId.isEmpty) {
        // Use the same API endpoint to get the correct ID based on the group name
        const String apiUrl = 'https://api.interphaselabs.com/graphql/query';
        try {
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': '''
              query GetGroupIdByName {
                userGroups {
                  id
                  name
                }
              }
            ''',
            }),
          );

          if (response.statusCode == 200) {
            final result = jsonDecode(response.body);
            final List<dynamic> groups = result['data']['userGroups'];

            for (var group in groups) {
              if (group['name'] == widget.groupName) {
                numericGroupId = group['id'].toString();
                print('Numeric Group ID found: $numericGroupId');
                break;
              }
            }
          }
        } catch (e) {
          print('Error fetching group ID: $e');
        }
      }
    }

    print('Numeric Group ID to be passed: $numericGroupId'); // Debug print

    if (numericGroupId.isEmpty) {
      // Show error if we couldn't get a valid ID
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find a valid group ID')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberPage(groupId: numericGroupId),
      ),
    );

    if (result != null) {
      // Refresh group details to show new members
      fetchGroupDetails();
    }
  }

  void _editGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditGroupPage(
              groupName: widget.groupName,
              groupDescription: widget.groupDescription,
              members: members,
            ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (result.containsKey('members')) {
        setState(() {
          members = List<Map<String, String>>.from(result['members']);
        });
      }
    }
  }

  void _deleteGroup() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Grup?'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus grup ini? Tindakan ini tidak dapat dibatalkan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Konfirmasi'),
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
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, size: 20),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _editGroup,
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.black),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.group, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.groupDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Anggota Anda:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : members.isEmpty
                      ? const Center(
                        child: Text('Tidak ada anggota yang ditemukan'),
                      )
                      : ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(members[index]['displayName']!),
                          );
                        },
                      ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _addMember,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const [
                        Icon(Icons.group_add, size: 30, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Tambah Anggota',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _deleteGroup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const [
                        Icon(Icons.remove, size: 30, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Hapus Grup',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}
