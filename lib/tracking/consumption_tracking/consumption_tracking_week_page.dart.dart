import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/tracking/tracking_page.dart';
import 'package:front_end/tracking/consumption_tracking/consumption_tracking_month_page.dart';

class ConsumptionTrackingWeekPage extends StatefulWidget {
  const ConsumptionTrackingWeekPage({Key? key}) : super(key: key);

  @override
  State<ConsumptionTrackingWeekPage> createState() =>
      _ConsumptionTrackingWeekPageState();
}

class _ConsumptionTrackingWeekPageState
    extends State<ConsumptionTrackingWeekPage> {
  final String apiUrl = 'http://api-ecotrack.interphaselabs.com/graphql/query';
  final String deviceId = "ET-d31e0e38-91bf-4b83-8439-1a7e72b1d8c4";
  bool isLoading = true;
  List<BarChartGroupData> weekData = [];

  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    fetchWeeklyData();
  }

  Future<void> fetchWeeklyData() async {
    const String query = r'''
      query {
        waterUsagesData(deviceId: "ET-d31e0e38-91bf-4b83-8439-1a7e72b1d8c4", timeFilter: "1w") {
          ... on DailyDataList {
            data {
              date
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
      final daily = result['data']?['waterUsagesData']?['data'];

      if (daily != null && daily is List) {
        List<double> values = List.filled(7, 0.0);

        for (var entry in daily) {
          final rawDate = entry['date'] ?? '';
          final usage = (entry['totalUsage'] as num?)?.toDouble() ?? 0.0;
          final dayAbbrev = rawDate.split(',').first.trim();
          final index = days.indexOf(dayAbbrev);
          if (index != -1) {
            values[index] = usage;
          }
        }

        setState(() {
          weekData = List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index],
                  width: 16,
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          });
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("[DEBUG] Exception: $e");
      setState(() => isLoading = false);
    }
  }

  double _getMaxY() {
    double maxY = weekData
        .map((e) => e.barRods[0].toY)
        .fold(0.0, (a, b) => a > b ? a : b);
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 5,
              ),
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
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TrackingPage(),
                      ),
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
                        builder:
                            (context) => const ConsumptionTrackingMonthPage(),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}
