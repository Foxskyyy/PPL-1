import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';

class EditGroupPage extends StatefulWidget {
  final String groupName;
  final String groupDescription;
  final List<Map<String, String>> members;

  const EditGroupPage({
    super.key,
    required this.groupName,
    required this.groupDescription,
    required this.members,
  });

  @override
  _EditGroupPageState createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  late List<Map<String, String>> members;
  late TextEditingController groupNameController;
  late TextEditingController groupDescriptionController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller di sini
    groupNameController = TextEditingController(text: widget.groupName);
    groupDescriptionController = TextEditingController(
      text: widget.groupDescription,
    );
    members = List<Map<String, String>>.from(
      widget.members,
    ); // Create a copy to avoid modifying the original
  }

  @override
  void dispose() {
    groupNameController.dispose();
    groupDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan Logo dan Avatar
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
            // Divider di bawah header
            const Divider(color: Colors.black),

            // Tombol Kembali
            Padding(
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
            ),

            // Avatar and Text Fields side by side - like image 2
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar on the left
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.lightBlue,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 15),
                  // Text fields on the right
                  Expanded(
                    child: Column(
                      children: [
                        // Text field for Group Name
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: groupNameController,
                            decoration: const InputDecoration(
                              hintText: 'Group Name',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Text field for Group Description
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: groupDescriptionController,
                            decoration: const InputDecoration(
                              hintText: 'Group Description',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Daftar Anggota
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Members:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  bool isRemoved = members[index]['name'] == "Removed";
                  if (isRemoved) {
                    return const SizedBox.shrink(); // Don't show removed members
                  }
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(members[index]['name']!),
                    trailing: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          members[index]['name'] =
                              "Removed"; // Menandai anggota yang dihapus
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Tombol untuk Cancel dan Save
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Kembali ke halaman sebelumnya
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Return the updated data to GroupDetailPage
                      Navigator.pop(context, {
                        'members': members,
                        'groupName': groupNameController.text,
                        'groupDescription': groupDescriptionController.text,
                      });
                    },
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
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: 1,
      ), // Navbar di bawah
    );
  }
}
