import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/tracking/waterbreakdown/add_new_place_page.dart';
import 'package:front_end/tracking/waterbreakdown/user_detail_page.dart';
import 'package:front_end/tracking/tracking_page.dart'; // Add this import for TrackingPage

class WaterBreakdownPage extends StatefulWidget {
  const WaterBreakdownPage({super.key});

  @override
  State<WaterBreakdownPage> createState() => _WaterBreakdownPageState();
}

class _WaterBreakdownPageState extends State<WaterBreakdownPage> {
  String? selectedPlace;
  String? selectedGroup;
  List<String> places = ['Place 1', 'Place 2', 'Place 3', 'Place 4'];
  List<String> defaultRooms = [];
  List<String> defaultGroups = [];
  bool showChart = false;
  bool showDetailedView = false;
  bool isPlaceExpanded = false;

  // Controller for the draggable scroll
  final ScrollController _scrollController = ScrollController();

  // Data model for water usage - prepared for backend integration
  List<WaterUsageData> waterUsageData = [];

  @override
  void initState() {
    super.initState();

    // Set default values for rooms and groups
    defaultRooms = List.generate(6, (index) => 'Room ${index + 1}');
    defaultGroups = List.generate(6, (index) => 'Group ${index + 1}');
    selectedGroup = 'Group 1';
    selectedPlace = 'Place 1';

    // Initialize with dummy data (will be replaced by backend data later)
    waterUsageData = [
      WaterUsageData(user: 'User A', usage: 120, color: Colors.blue),
      WaterUsageData(user: 'User B', usage: 200, color: Colors.green),
      WaterUsageData(user: 'User C', usage: 150, color: Colors.amber),
      WaterUsageData(user: 'User D', usage: 180, color: Colors.red),
      WaterUsageData(user: 'User E', usage: 230, color: Colors.purple),
    ];
  }

  @override
  void dispose() {
    // Dispose the scroll controller
    _scrollController.dispose();
    super.dispose();
  }

  // Method for future backend data fetching
  Future<void> fetchWaterUsageData() async {
    // This will be implemented when the backend is ready
    // For now, we'll use the dummy data initialized in initState
  }

  // Navigate directly to tracking page
  void navigateToTrackingPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TrackingPage()),
    );
  }

  // Toggle the place dropdown visibility
  void togglePlaceDropdown() {
    setState(() {
      isPlaceExpanded = !isPlaceExpanded;
    });
  }

  // Select a place from the dropdown
  void selectPlace(String place) {
    setState(() {
      selectedPlace = place;
      isPlaceExpanded = false;
      showChart = true;
      // You could also trigger data fetch here based on selected place
      // fetchWaterUsageData();
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

            // Back button with title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () {
                      // Navigate directly to tracking page when Back button is pressed
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrackingPage(),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),

            // Main scrollable content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Implement refresh logic here (e.g., fetch new data)
                  // For now, just wait a moment to simulate refresh
                  await Future.delayed(Duration(milliseconds: 800));
                  // Update state if needed
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Empty state - only show if no place selected and not in detailed view
                      if (!showChart && !showDetailedView)
                        const SizedBox(
                          height: 200,
                        ), // Spacer to center the button
                      // Chart State - show pie chart after saving
                      if (showChart && !showDetailedView)
                        Center(
                          child: Container(
                            height: 220,
                            width: 220,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 60,
                                sections: [
                                  PieChartSectionData(
                                    value: 40,
                                    color: Colors.blue,
                                    title: 'Room 1',
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    radius: 40,
                                  ),
                                  PieChartSectionData(
                                    value: 30,
                                    color: Colors.green,
                                    title: 'Room 2',
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    radius: 40,
                                  ),
                                  PieChartSectionData(
                                    value: 15,
                                    color: Colors.yellow,
                                    title: 'Room 3',
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    radius: 40,
                                  ),
                                  PieChartSectionData(
                                    value: 10,
                                    color: Colors.red,
                                    title: 'Room 4',
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    radius: 40,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Detailed View - Full page with charts and buttons
                      if (showDetailedView)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Breakdown Konsumsi Air',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Pie Chart
                            Container(
                              height: 200,
                              width: 200,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: 40,
                                      color: Colors.blue,
                                      title: '40.0%',
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      radius: 60,
                                    ),
                                    PieChartSectionData(
                                      value: 35,
                                      color: Colors.green,
                                      title: '35.0%',
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      radius: 60,
                                    ),
                                    PieChartSectionData(
                                      value: 15,
                                      color: Colors.yellow,
                                      title: '15.0%',
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      radius: 60,
                                    ),
                                    PieChartSectionData(
                                      value: 10,
                                      color: Colors.orange,
                                      title: '10.0%',
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      radius: 60,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Pie Chart Labels
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildPieChartLabel(
                                    'Kamar Mandi',
                                    Colors.blue,
                                  ),
                                  _buildPieChartLabel('Dapur', Colors.green),
                                  _buildPieChartLabel('Taman', Colors.yellow),
                                  _buildPieChartLabel('Laundry', Colors.orange),
                                ],
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Place Dropdown Button Group
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Main button that shows the selected place
                            GestureDetector(
                              onVerticalDragEnd: (details) {
                                // If dragging down with sufficient velocity, open dropdown
                                if (details.primaryVelocity != null &&
                                    details.primaryVelocity! > 50) {
                                  setState(() {
                                    isPlaceExpanded = true;
                                  });
                                }
                              },
                              child: InkWell(
                                onTap: togglePlaceDropdown,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(10),
                                      bottom:
                                          isPlaceExpanded
                                              ? Radius.zero
                                              : Radius.circular(10),
                                    ),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                    boxShadow: [
                                      if (!isPlaceExpanded)
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedPlace ?? 'Select Place',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      Icon(
                                        isPlaceExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Expanded dropdown options
                            if (isPlaceExpanded)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(10),
                                  ),
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                    right: BorderSide(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                    bottom: BorderSide(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    for (int i = 0; i < places.length; i++)
                                      if (places[i] != selectedPlace)
                                        InkWell(
                                          onTap: () => selectPlace(places[i]),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              border:
                                                  i < places.length - 1
                                                      ? Border(
                                                        bottom: BorderSide(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                        ),
                                                      )
                                                      : null,
                                            ),
                                            child: Text(
                                              places[i],
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Add New Place Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddNewPlacePage(
                                      rooms: defaultRooms,
                                      groups: defaultGroups,
                                    ),
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                String newPlace = result['place'];
                                places.add(newPlace);
                                selectedPlace = newPlace;
                                selectedGroup = 'Group 1';
                                showChart = true;
                                showDetailedView = false;
                                isPlaceExpanded = false;
                                // In the future, we would fetch data from backend here
                                // fetchWaterUsageData();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text(
                            'Add New Place',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // "See Details" button - show when place is selected and not in detailed view
                      if (showChart && !showDetailedView)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showDetailedView = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'See Details',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),

                      // Group and See User Buttons - show in detailed view
                      if (showDetailedView)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              // Group Dropdown Button
                              Expanded(
                                child: PopupMenuButton<String>(
                                  offset: const Offset(0, 40),
                                  onSelected: (String value) {
                                    setState(() {
                                      selectedGroup = value;
                                      // In the future, we would fetch data from backend here
                                      // fetchWaterUsageData();
                                    });
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return defaultGroups.map((String group) {
                                      return PopupMenuItem<String>(
                                        value: group,
                                        child: Text(group),
                                      );
                                    }).toList();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectedGroup ?? 'Group 1',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Icon(Icons.keyboard_arrow_up),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // See User Button (Clickable)
                              InkWell(
                                onTap: () {
                                  // Navigate to user details page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              UserDetailPage(), // Navigate to UserDetailPage
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'See User',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.arrow_forward, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Bar Chart - show in detailed view
                      if (showDetailedView)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Water Usage per User',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 250,
                                padding: const EdgeInsets.only(top: 10),
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: _calculateMaxYValue(),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        tooltipBgColor: Colors.blueGrey
                                            .withOpacity(0.8),
                                        getTooltipItem: (
                                          group,
                                          groupIndex,
                                          rod,
                                          rodIndex,
                                        ) {
                                          return BarTooltipItem(
                                            '${waterUsageData[groupIndex].user}: ${waterUsageData[groupIndex].usage}',
                                            const TextStyle(
                                              color: Colors.white,
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
                                            if (value.toInt() >=
                                                    waterUsageData.length ||
                                                value.toInt() < 0) {
                                              return const SizedBox.shrink();
                                            }
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                waterUsageData[value.toInt()]
                                                    .user,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value % 50 != 0) {
                                              return const SizedBox.shrink();
                                            }
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                '${value.toInt()}',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawHorizontalLine: true,
                                      drawVerticalLine: false,
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: const Border(
                                        left: BorderSide(color: Colors.black26),
                                        bottom: BorderSide(
                                          color: Colors.black26,
                                        ),
                                      ),
                                    ),
                                    barGroups: _generateBarGroups(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 50),
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

  // Generate bar groups dynamically from data
  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(
      waterUsageData.length,
      (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: waterUsageData[index].usage.toDouble(),
            color: waterUsageData[index].color,
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),
    );
  }

  // Calculate maximum Y value for the chart
  double _calculateMaxYValue() {
    // Find the max value in data and add 10% for padding
    if (waterUsageData.isEmpty) return 250; // Default if no data

    double maxUsage =
        waterUsageData
            .map((data) => data.usage)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

    return maxUsage * 1.1; // Add 10% padding
  }

  // Helper function to build pie chart labels
  Widget _buildPieChartLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}

// Data model for water usage data
class WaterUsageData {
  final String user;
  final int usage;
  final Color color;

  WaterUsageData({
    required this.user,
    required this.usage,
    required this.color,
  });

  // Factory constructor for future JSON conversion
  factory WaterUsageData.fromJson(Map<String, dynamic> json) {
    // This is a placeholder for future backend integration
    // Color will need special handling since it won't come directly from JSON
    return WaterUsageData(
      user: json['user'] ?? '',
      usage: json['usage'] ?? 0,
      color: Colors.blue, // Default color, adjust logic as needed
    );
  }
}
