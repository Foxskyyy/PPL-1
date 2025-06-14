import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:front_end/tracking/consumption_tracking/consumption_tracking_week_page.dart.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/tracking/tracking_page.dart';
import 'package:front_end/user_session.dart';

class ConsumptionTrackingMonthPage extends StatefulWidget {
  const ConsumptionTrackingMonthPage({Key? key}) : super(key: key);

  @override
  State<ConsumptionTrackingMonthPage> createState() =>
      _ConsumptionTrackingMonthPageState();
}

class _ConsumptionTrackingMonthPageState
    extends State<ConsumptionTrackingMonthPage> {
  final String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';
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
    fetchAllMonthlyData();
  }

  Future<void> fetchAllMonthlyData() async {
    final userId = await UserSession.getUserID();
    if (userId == null) {
      debugPrint("[ERROR] User ID not found");
      setState(() => isLoading = false);
      return;
    }

    debugPrint("[DEBUG] UserSession.userID: $userId");

    // ✅ Query tanpa parameter userId
    final queryGroups = '''
    query {
      userGroups {
        users {
          user {
            id
          }
        }
        devices {
          id
        }
      }
    }
    ''';

    try {
      final responseGroups = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': queryGroups}),
      );

      debugPrint("[DEBUG] Raw group response: ${responseGroups.body}");

      final groupResult = jsonDecode(responseGroups.body);
      final allGroups = groupResult['data']?['userGroups'];

      final devices = <String>[];

      if (allGroups != null) {
        for (var group in allGroups) {
          final groupUsers = group['users'] as List?;
          final groupDevices = group['devices'] as List?;

          final isUserInGroup =
              groupUsers?.any(
                (u) => int.tryParse(u['user']['id'].toString()) == userId,
              ) ??
              false;

          if (isUserInGroup && groupDevices != null) {
            for (var device in groupDevices) {
              devices.add(device['id']);
            }
          }
        }
      }

      debugPrint("[DEBUG] Final devices: $devices");

      if (devices.isEmpty) {
        debugPrint("[DEBUG] No devices found.");
        setState(() => isLoading = false);
        return;
      }

      // Gabungkan data dari semua device
      Map<String, double> aggregatedUsage = {
        for (var label in monthLabels) label: 0.0,
      };

      for (var deviceId in devices) {
        final usageQuery = '''
        query {
          waterUsagesData(deviceId: "$deviceId", timeFilter: "1y") {
            ... on YearlyData {
              months {
                month
                totalUsage
              }
            }
          }
        }
        ''';

        final usageResp = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': usageQuery}),
        );

        debugPrint("[DEBUG] Response for device $deviceId: ${usageResp.body}");

        final usageJson = jsonDecode(usageResp.body);
        final months = usageJson['data']?['waterUsagesData']?['months'];

        if (months != null) {
          for (var m in months) {
            final month = m['month'].toString();
            final usage = (m['totalUsage'] as num?)?.toDouble() ?? 0.0;
            if (aggregatedUsage.containsKey(month)) {
              aggregatedUsage[month] = aggregatedUsage[month]! + usage;
            }
          }
        }
      }

      List<BarChartGroupData> barGroups = List.generate(12, (index) {
        final value = aggregatedUsage[monthLabels[index]] ?? 0.0;
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
    } catch (e) {
      debugPrint("[ERROR] $e");
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
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 4,
                                        child: Text(
                                          monthLabels[value.toInt()].substring(
                                            0,
                                            3,
                                          ),
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
                                    interval: _getMaxY() / 5,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          value.toStringAsFixed(0),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
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
