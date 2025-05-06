import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:fl_chart/fl_chart.dart';

class AddNewPlacePage extends StatefulWidget {
  const AddNewPlacePage({
    super.key,
    required List<String> rooms,
    required List<String> groups,
  });

  @override
  State<AddNewPlacePage> createState() => _AddNewPlacePageState();
}

class _AddNewPlacePageState extends State<AddNewPlacePage> {
  final TextEditingController _placeController = TextEditingController();
  bool room1 = false;
  bool room2 = false;
  bool room3 = false;
  bool room4 = false;
  bool room5 = false;
  bool room6 = false;

  bool group1 = false;
  bool group2 = false;
  bool group3 = false;
  bool group4 = false;
  bool group5 = false;
  bool group6 = false;

  get chartData => null;

  // Fungsi untuk menyimpan data tempat, ruangan, dan grup
  void _savePlace() {
    final newPlace = _placeController.text;
    final rooms =
        [
          room1 ? 'Room 1' : '',
          room2 ? 'Room 2' : '',
          room3 ? 'Room 3' : '',
          room4 ? 'Room 4' : '',
          room5 ? 'Room 5' : '',
          room6 ? 'Room 6' : '',
        ].where((room) => room.isNotEmpty).toList();

    final groups =
        [
          group1 ? 'Group 1' : '',
          group2 ? 'Group 2' : '',
          group3 ? 'Group 3' : '',
          group4 ? 'Group 4' : '',
          group5 ? 'Group 5' : '',
          group6 ? 'Group 6' : '',
        ].where((group) => group.isNotEmpty).toList();

    // Kembalikan ke halaman sebelumnya dengan data tempat, rooms, dan groups
    Navigator.pop(context, {
      'place': newPlace,
      'rooms': rooms,
      'groups': groups,
      'chartData': chartData, // Kirim data chart
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // Membuat halaman bisa digulir
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

              // Divider
              const Divider(color: Colors.black),

              // Back and Save buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Save button
                    TextButton(
                      onPressed: _savePlace,
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Place Name Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _placeController,
                  decoration: const InputDecoration(
                    labelText: 'Place Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Add Room Section (default 6 rooms)
              const Text(
                'Add Room',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              CheckboxListTile(
                title: const Text('Room 1'),
                value: room1,
                onChanged: (val) => setState(() => room1 = val!),
              ),
              CheckboxListTile(
                title: const Text('Room 2'),
                value: room2,
                onChanged: (val) => setState(() => room2 = val!),
              ),
              CheckboxListTile(
                title: const Text('Room 3'),
                value: room3,
                onChanged: (val) => setState(() => room3 = val!),
              ),
              CheckboxListTile(
                title: const Text('Room 4'),
                value: room4,
                onChanged: (val) => setState(() => room4 = val!),
              ),
              CheckboxListTile(
                title: const Text('Room 5'),
                value: room5,
                onChanged: (val) => setState(() => room5 = val!),
              ),
              CheckboxListTile(
                title: const Text('Room 6'),
                value: room6,
                onChanged: (val) => setState(() => room6 = val!),
              ),

              const SizedBox(height: 20),

              // Add Group Section (default 6 groups)
              const Text(
                'Add Group',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              CheckboxListTile(
                title: const Text('Group 1'),
                value: group1,
                onChanged: (val) => setState(() => group1 = val!),
              ),
              CheckboxListTile(
                title: const Text('Group 2'),
                value: group2,
                onChanged: (val) => setState(() => group2 = val!),
              ),
              CheckboxListTile(
                title: const Text('Group 3'),
                value: group3,
                onChanged: (val) => setState(() => group3 = val!),
              ),
              CheckboxListTile(
                title: const Text('Group 4'),
                value: group4,
                onChanged: (val) => setState(() => group4 = val!),
              ),
              CheckboxListTile(
                title: const Text('Group 5'),
                value: group5,
                onChanged: (val) => setState(() => group5 = val!),
              ),
              CheckboxListTile(
                title: const Text('Group 6'),
                value: group6,
                onChanged: (val) => setState(() => group6 = val!),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}
