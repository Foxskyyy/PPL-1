import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this dependency to pubspec.yaml

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // This would be fetched from backend
  Map<String, dynamic> usageData = {
    'water': 2148.0,
    'energy': 8352.0,
    'material': 11.0,
  };

  @override
  void initState() {
    super.initState();
    // Here you would fetch data from backend
    // fetchUsageData();
  }

  // Example method to fetch data from backend
  // Future<void> fetchUsageData() async {
  //   try {
  //     // final response = await apiService.getUsageData();
  //     // setState(() {
  //     //   usageData = response;
  //     // });
  //   } catch (e) {
  //     // Handle error
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                  // Ecotrack Logo and Text
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/ecotrack_logo.png',
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  // Avatar
                  const CircleAvatar(
                    backgroundColor: Colors.lightBlue,
                    radius: 18,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            // Header Divider Line
            Container(
              height: 1,
              color: Colors.black,
              margin: const EdgeInsets.symmetric(horizontal: 0),
            ),

            const SizedBox(height: 16),

            // Welcome Text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hello, User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Today's Usage Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF18833B),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Usage",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chart container
                    SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          // Left side - Chart
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                usageLineChart(),
                                // Value label for Water - moved closer to the point
                                Positioned(
                                  top: 55,
                                  left: 15, // Moved closer to the water dot
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${usageData['water'].toInt()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Value label for Energy - removed "Today's Usage" text
                                Positioned(
                                  top: 10,
                                  left:
                                      MediaQuery.of(context).size.width * 0.17,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${usageData['energy'].toInt()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Value label for Material - moved closer to the point
                                Positioned(
                                  top: 95,
                                  right: 15, // Moved closer to the material dot
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${usageData['material'].toInt()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right side - Data - shifted further right with more padding
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 24.0,
                              ), // Increased left padding
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  usageDataItem(
                                    'Water (L)',
                                    usageData['water'].toInt().toString(),
                                    Colors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  usageDataItem(
                                    'Energy (kWh)',
                                    usageData['energy'].toInt().toString(),
                                    Colors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  usageDataItem(
                                    'Material (ton)',
                                    usageData['material'].toInt().toString(),
                                    Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Legend
                    Row(
                      children: const [
                        _LegendDot(
                          color: Colors.lightBlueAccent,
                          label: "Water (L)",
                        ),
                        SizedBox(width: 16),
                        _LegendDot(
                          color: Colors.redAccent,
                          label: "Energy (kWh)",
                        ),
                        SizedBox(width: 16),
                        _LegendDot(
                          color: Colors.greenAccent,
                          label: "Material (ton)",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Chatbot Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 16,
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your usage consumption today bigger than yesterday ...',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions - ENLARGED
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _QuickAction(icon: Icons.group, label: 'Group'),
                  _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Add Device',
                  ),
                  _QuickAction(icon: Icons.timer, label: 'Quick\nActions'),
                ],
              ),
            ),

            const Spacer(), // Push navigation bar to bottom
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            currentIndex: 2, // Home as center
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.track_changes),
                label: 'Tracking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home, size: 28),
                label: 'Home',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Group'),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                label: 'Alert',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to create usage data item
  Widget usageDataItem(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Line chart for usage data
  Widget usageLineChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: 2000,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            // Removed "Today's Usage" text from chart top title
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '';
                if (value == 0) {
                  text = 'Water (L)';
                } else if (value == 1) {
                  text = 'Energy (kWh)';
                } else if (value == 2) {
                  text = 'Material (ton)';
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 2,
        minY: 0,
        maxY: 10000,
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, usageData['water'] ?? 0),
              FlSpot(1, usageData['energy'] ?? 0),
              FlSpot(2, usageData['material'] ?? 0),
            ],
            isCurved: false,
            color: Colors.white,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: true,
              getDotPainter: _getFlDotPainter,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  // Custom dot painter for the chart
  static FlDotPainter _getFlDotPainter(spot, percent, barData, index) {
    Color dotColor;
    if (index == 0) {
      dotColor = Colors.lightBlueAccent;
    } else if (index == 1) {
      dotColor = Colors.redAccent;
    } else {
      dotColor = Colors.greenAccent;
    }

    return FlDotCirclePainter(
      radius: 5,
      color: dotColor,
      strokeWidth: 1,
      strokeColor: Colors.white,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}
