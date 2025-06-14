import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/group/yourgroup/add_member_page.dart';
import 'package:front_end/group/yourgroup/edit_group_page.dart';
import 'package:front_end/group/yourgroup/locations_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroupDetailPage extends StatefulWidget {
  final String groupName;
  final String groupId;

  const GroupDetailPage({
    super.key,
    required this.groupName,
    required this.groupId,
  });

  @override
  _GroupDetailPageState createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
  }

  Future<void> fetchGroupDetails() async {
    const String apiUrl =
        'http://api-ecotrack.interphaselabs.com/graphql/query';

    try {
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
                  user {
                    id
                    displayName
                  }
                  isAdmin
                  createdAt
                }
              }
            }
          ''',
        }),
      );

      print('Respons API: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result.containsKey('errors')) {
          setState(() {
            errorMessage = result['errors'][0]['message'];
            isLoading = false;
          });
          return;
        }

        final List<dynamic>? allGroups = result['data']?['userGroups'];
        if (allGroups != null) {
          dynamic groupData;

          for (var group in allGroups) {
            if (group['id'].toString() == widget.groupId) {
              groupData = group;
              break;
            }
          }

          if (groupData == null) {
            for (var group in allGroups) {
              if (group['name'] == widget.groupName) {
                groupData = group;
                break;
              }
            }
          }

          if (groupData != null) {
            final usersData = groupData['users'] ?? [];
            List<Map<String, dynamic>> allMembers = [];

            for (var member in usersData) {
              final user = member['user'];
              if (user != null) {
                allMembers.add({
                  'displayName': user['displayName']?.toString() ?? 'Anggota',
                  'id': user['id']?.toString() ?? '',
                  'isAdmin': member['isAdmin'] ?? false,
                });
              }
            }

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

  @override
  Widget build(BuildContext context) {
    final int memberCount = members.length;
    final bool isMaxMember = memberCount >= 4;

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
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => EditGroupPage(
                                groupName: widget.groupName,
                                members:
                                    members
                                        .map(
                                          (e) => {
                                            'displayName':
                                                e['displayName'].toString(),
                                            'id': e['id'].toString(),
                                            'isAdmin': e['isAdmin'] == true,
                                            'groupId': widget.groupId,
                                          },
                                        )
                                        .toList(),
                              ),
                        ),
                      );
                    },
                    child: const Icon(Icons.edit, size: 20),
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
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Text(
                    'Jumlah anggota: $memberCount / 4',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isMaxMember)
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        '(maksimal)',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
                          final member = members[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(member['displayName']),
                            subtitle:
                                member['isAdmin'] == true
                                    ? const Text(
                                      'Admin',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          );
                        },
                      ),
            ),
            GestureDetector(
              onTap:
                  isMaxMember
                      ? null
                      : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    AddMemberPage(groupId: widget.groupId),
                          ),
                        ).then((_) => fetchGroupDetails());
                      },
              child: Opacity(
                opacity: isMaxMember ? 0.4 : 1.0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.group_add, color: Colors.blue, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Tambah Anggota',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            LocationsPage(groupId: int.parse(widget.groupId)),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.location_on, color: Colors.blue, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Locations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}
