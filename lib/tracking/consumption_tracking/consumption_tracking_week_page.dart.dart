import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/tracking/tracking_page.dart';
import 'package:front_end/tracking/consumption_tracking/consumption_tracking_month_page.dart';
import 'package:front_end/user_session.dart';

class ConsumptionTrackingWeekPage extends StatefulWidget {
  const ConsumptionTrackingWeekPage({Key? key}) : super(key: key);

  @override
  State<ConsumptionTrackingWeekPage> createState() =>
      _ConsumptionTrackingWeekPageState();
}

class _ConsumptionTrackingWeekPageState
    extends State<ConsumptionTrackingWeekPage> {
  final String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';
  bool isLoading = true;
  List<BarChartGroupData> weekData = [];
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    fetchWeeklyDataFromAllDevices();
  }

  Future<void> fetchWeeklyDataFromAllDevices() async {
    final userId = await UserSession.getUserID();
    if (userId == null) {
      debugPrint("[ERROR] User ID not found");
      setState(() => isLoading = false);
      return;
    }

    debugPrint("[DEBUG] UserSession.userID: $userId");

    const queryGroups = '''
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

      debugPrint("[DEBUG] Devices: $devices");

      if (devices.isEmpty) {
        debugPrint("[DEBUG] No devices found.");
        setState(() => isLoading = false);
        return;
      }

      Map<String, double> usagePerDay = {for (var day in days) day: 0.0};

      for (var deviceId in devices) {
        final query = '''
        query {
          waterUsagesData(deviceId: "$deviceId", timeFilter: "1w") {
            ... on DailyDataList {
              data {
                date
                totalUsage
              }
            }
          }
        }
        ''';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': query}),
        );

        debugPrint("[DEBUG] Response for device $deviceId: ${response.body}");

        final result = jsonDecode(response.body);
        final daily = result['data']?['waterUsagesData']?['data'];

        if (daily != null && daily is List) {
          for (var entry in daily) {
            final rawDate = entry['date'] ?? '';
            final usage = (entry['totalUsage'] as num?)?.toDouble() ?? 0.0;

            DateTime? parsedDate;
            try {
              final parts = rawDate.split(',').map((e) => e.trim()).toList();
              if (parts.length == 2) {
                final day = int.tryParse(parts[1].split(' ')[0]);
                final monthName = parts[1].split(' ')[1];
                final month =
                    {
                      'Jan': 1,
                      'Feb': 2,
                      'Mar': 3,
                      'Apr': 4,
                      'May': 5,
                      'Jun': 6,
                      'Jul': 7,
                      'Aug': 8,
                      'Sep': 9,
                      'Oct': 10,
                      'Nov': 11,
                      'Dec': 12,
                    }[monthName];

                if (day != null && month != null) {
                  parsedDate = DateTime(DateTime.now().year, month, day);
                }
              }
            } catch (e) {
              debugPrint("[DEBUG] Failed to convert date: $rawDate");
            }

            if (parsedDate != null) {
              final weekdayIndex =
                  parsedDate.weekday - 1; // 0 = Mon ... 6 = Sun
              if (weekdayIndex >= 0 && weekdayIndex < 7) {
                final key = days[weekdayIndex];
                usagePerDay[key] = usagePerDay[key]! + usage;
              }
            } else {
              debugPrint("[DEBUG] Failed to parse date: $rawDate");
            }
          }
        }
      }

      setState(() {
        weekData = List.generate(7, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: usagePerDay[days[index]] ?? 0.0,
                width: 16,
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        });
        isLoading = false;
      });
    } catch (e) {
      debugPrint("[DEBUG] Exception: $e");
      setState(() => isLoading = false);
    }
  }

  double _getMaxY() {
    if (weekData.isEmpty) return 5;
    double maxY = weekData
        .map((e) => e.barRods[0].toY)
        .reduce((a, b) => a > b ? a : b);
    return (maxY < 5 ? 5 : maxY * 1.2).ceilToDouble();
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
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0A7D34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text("Week"),
                ),
                const SizedBox(width: 10),
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
                        builder: (_) => const ConsumptionTrackingMonthPage(),
                      ),
                    );
                  },
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
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
                                barGroups: weekData,
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < days.length) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                              days[index],
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      getTitlesWidget: (value, meta) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            value.toStringAsFixed(0),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}
