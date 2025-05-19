import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:front_end/tracking/consumption_tracking/consumption_tracking_week_page.dart.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/tracking/tracking_page.dart';

class ConsumptionTrackingMonthPage extends StatefulWidget {
  const ConsumptionTrackingMonthPage({Key? key}) : super(key: key);

  @override
  State<ConsumptionTrackingMonthPage> createState() =>
      _ConsumptionTrackingMonthPageState();
}

class _ConsumptionTrackingMonthPageState
    extends State<ConsumptionTrackingMonthPage> {
  final String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';
  final String deviceId = "ET-d31e0e38-91bf-4b83-8439-1a7e72b1d8c4";
  bool isLoading = true;
  List<BarChartGroupData> monthData = [];

  final List<String> monthLabels = const [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  @override
  void initState() {
    super.initState();
    fetchMonthlyData();
  }

  Future<void> fetchMonthlyData() async {
    const String query = r'''
      query {
        waterUsagesData(deviceId: "ET-d31e0e38-91bf-4b83-8439-1a7e72b1d8c4", timeFilter: "1y") {
          ... on YearlyData {
            months {
              month
              totalUsage
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

      debugPrint("[DEBUG] Response: ${response.body}");
      final result = jsonDecode(response.body);
      final months = result['data']?['waterUsagesData']?['months'];

      if (months != null && months is List) {
        List<BarChartGroupData> barGroups = List.generate(12, (index) {
          final monthName = monthLabels[index];
          final found = months.firstWhere(
            (m) =>
                m['month'].toString().toLowerCase() == monthName.toLowerCase(),
            orElse: () => null,
          );

          final value =
              found != null
                  ? (found['totalUsage'] as num?)?.toDouble() ?? 0.0
                  : 0.0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                width: 14,
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        });

        setState(() {
          monthData = barGroups;
          isLoading = false;
        });
      } else {
        debugPrint("[DEBUG] No data in months");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("[DEBUG] Exception: $e");
      setState(() => isLoading = false);
    }
  }

  double _getMaxY() {
    if (monthData.isEmpty) return 5;
    final maxY = monthData
        .map((e) => e.barRods[0].toY)
        .reduce((a, b) => a > b ? a : b);
    return (maxY < 5 ? 5 : (maxY + 1)).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/ecotrack_logo.png', width: 60),
                  const CircleAvatar(
                    backgroundColor: Colors.lightBlue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.black),

            // Back Button
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TrackingPage()),
                    );
                  },
                ),
              ),
            ),

            // Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConsumptionTrackingWeekPage(),
                      ),
                    );
                  },
                  child: const Text("Week"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0A7D34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text("Month"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chart
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A7D34),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _getMaxY(),
                              barGroups: monthData,
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const labels = [
                                        "Jan",
                                        "Feb",
                                        "Mar",
                                        "Apr",
                                        "May",
                                        "Jun",
                                        "Jul",
                                        "Aug",
                                        "Sep",
                                        "Oct",
                                        "Nov",
                                        "Dec",
                                      ];
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 4,
                                        child: Text(
                                          labels[value.toInt()],
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          value.toStringAsFixed(0),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                    interval: _getMaxY() / 5, // make it dynamic
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                            ),
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
}
