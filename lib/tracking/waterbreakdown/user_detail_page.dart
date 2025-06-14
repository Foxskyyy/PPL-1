import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:front_end/custom_button_navbar.dart';

class WaterUsageData {
  final String category;
  final double value;
  final Color color;

  WaterUsageData(this.category, this.value, this.color);
}

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({Key? key}) : super(key: key);

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  // Sample data - this will be replaced with dynamic data from backend
  late List<MapEntry<String, List<WaterUsageData>>> _usersDataList;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate fetching data from backend
    _fetchData();
  }

  Future<void> _fetchData() async {
    // This would be your actual API call
    await Future.delayed(const Duration(seconds: 1));

    // Sample data - replace with your backend data
    final Map<String, List<WaterUsageData>> usersData = {
      'User A': [
        WaterUsageData('Shower', 60, Colors.green),
        WaterUsageData('Toilet', 30, Colors.orange),
        WaterUsageData('Kitchen', 30, Colors.yellow),
        WaterUsageData('Laundry', 40, Colors.blue),
      ],
      'User B': [
        WaterUsageData('Shower', 80, Colors.green),
        WaterUsageData('Toilet', 20, Colors.orange),
        WaterUsageData('Kitchen', 40, Colors.yellow),
        WaterUsageData('Laundry', 90, Colors.blue),
      ],
      'User C': [
        WaterUsageData('Shower', 50, Colors.green),
        WaterUsageData('Toilet', 20, Colors.orange),
        WaterUsageData('Kitchen', 20, Colors.yellow),
        WaterUsageData('Laundry', 70, Colors.blue),
      ],
      'User D': [
        WaterUsageData('Shower', 70, Colors.green),
        WaterUsageData('Toilet', 30, Colors.orange),
        WaterUsageData('Kitchen', 30, Colors.yellow),
        WaterUsageData('Laundry', 60, Colors.blue),
      ],
      'User E': [
        WaterUsageData('Shower', 80, Colors.green),
        WaterUsageData('Toilet', 30, Colors.orange),
        WaterUsageData('Kitchen', 40, Colors.yellow),
        WaterUsageData('Laundry', 90, Colors.blue),
      ],
    };

    // For demo purposes, let's duplicate some users to show scrolling
    for (int i = 1; i <= 10; i++) {
      usersData['Additional User $i'] = [
        WaterUsageData('Shower', 50 + i.toDouble(), Colors.green),
        WaterUsageData('Toilet', 20 + i.toDouble(), Colors.orange),
        WaterUsageData('Kitchen', 30 + i.toDouble(), Colors.yellow),
        WaterUsageData('Laundry', 60 + i.toDouble(), Colors.blue),
      ];
    }

    setState(() {
      _usersDataList = usersData.entries.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Back button
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            _isLoading
                ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
                : Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                            child: Text(
                              'Water Usage by User',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: _buildUsersGridView()),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildUsersGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _usersDataList.length,
      itemBuilder: (context, index) {
        final userEntry = _usersDataList[index];
        return _buildUserChart(userEntry.key, userEntry.value);
      },
    );
  }

  Widget _buildUserChart(String userName, List<WaterUsageData> userData) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Expanded(child: _buildBarChart(userData)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<WaterUsageData> data) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, right: 15),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.grey.shade200,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[groupIndex].category}\n${rod.toY.round()} L',
                  const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Rotating the labels to match the screenshot
                  String text = '';
                  if (value < data.length) {
                    // Convert category names to shorter versions to fit
                    switch (data[value.toInt()].category) {
                      case 'Shower':
                        text = 'Shower';
                        break;
                      case 'Toilet':
                        text = 'Toilet';
                        break;
                      case 'Kitchen':
                        text = 'Kitchen';
                        break;
                      case 'Laundry':
                        text = 'Laundry';
                        break;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Transform.rotate(
                      angle: -0.8, // Rotate labels for better readability
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Only show some values to avoid crowding
                  if (value % 25 == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.black, fontSize: 8),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 20,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
            drawVerticalLine: false,
          ),
          barGroups: List.generate(data.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[index].value,
                  color: data[index].color,
                  width: 15,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// Service for backend integration
class WaterUsageService {
  // Real implementation would connect to your backend
  Future<Map<String, List<WaterUsageData>>> fetchUsersData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // This would be data from your backend
    return {
      'User A': [
        WaterUsageData('Shower', 60, Colors.green),
        WaterUsageData('Toilet', 30, Colors.orange),
        WaterUsageData('Kitchen', 30, Colors.yellow),
        WaterUsageData('Laundry', 40, Colors.blue),
      ],
      // ...other users
    };
  }
}
