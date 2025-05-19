import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/homepage/device_list_page.dart'; // GANTI ke file tujuan
import 'package:front_end/group/yourgroup/your_group_page.dart';
import 'package:front_end/user_session.dart';
import 'package:front_end/ai_consume_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? displayName;
  List<WaterUsageData> waterUsageData = [];
  double totalWaterUsage = 0.0;

  @override
  void initState() {
    super.initState();
    displayName = UserSession.displayName ?? "User";
    fetchWaterUsageData();
  }

  Future<void> fetchWaterUsageData() async {
    const String apiUrl =
        'http://api-ecotrack.interphaselabs.com/graphql/query';

    const String query = '''
      {
        userGroups {
          id
          name
          createdAt
          devices {
            id
            location
            waterUsages {
              flowRate
              totalUsage
              recordedAt
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

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final userGroups = result['data']?['userGroups'];
        if (userGroups != null && userGroups.isNotEmpty) {
          List<WaterUsageData> fetchedData = [];
          double total = 0.0;

          for (var group in userGroups) {
            List<dynamic> devices = group['devices'] ?? [];
            for (var device in devices) {
              for (var usage in device['waterUsages'] ?? []) {
                fetchedData.add(
                  WaterUsageData(
                    time: _formatTimestamp(usage['recordedAt']),
                    usage: usage['totalUsage'].toDouble(),
                  ),
                );
                total += usage['totalUsage'].toDouble();
              }
            }
          }

          fetchedData.sort((a, b) => a.time.compareTo(b.time));
          if (fetchedData.length > 10) {
            fetchedData = fetchedData.sublist(fetchedData.length - 10);
          }

          setState(() {
            waterUsageData = fetchedData;
            totalWaterUsage = total;
          });
        }
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hello, $displayName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Today's Usage",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "LIVE TRACKING PENGGUNAAN AIR",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "LIVE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Penggunaan Air (Liter)",
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(height: 150, child: _buildUsageGraph()),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                "Total water usage: ",
                                style: TextStyle(fontSize: 9),
                              ),
                              Text(
                                "${totalWaterUsage.toStringAsFixed(2)} L",
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AIConsumePage()),
                    ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.green),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI Consumption Suggestion",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Get personalized suggestions to optimize your resource usage",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAction(
                    icon: Icons.group,
                    label: 'Group',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const YourGroupPage(),
                        ),
                      );
                    },
                  ),
                  _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Add Device',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  const DeviceListPage(), // << diarahkan ke DeviceListPage
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildUsageGraph() {
    return CustomPaint(
      size: const Size(double.infinity, 150),
      painter: UsageGraphPainter(data: waterUsageData),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 32),
          ),
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

class WaterUsageData {
  final String time;
  final double usage;

  WaterUsageData({required this.time, required this.usage});
}

class UsageGraphPainter extends CustomPainter {
  final List<WaterUsageData> data;

  UsageGraphPainter({this.data = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final fillPaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final List<Offset> points = [];
    List<String> timeLabels = [];

    double maxUsage = data
        .map((e) => e.usage)
        .fold(0.0, (a, b) => a > b ? a : b);
    if (maxUsage < 5) maxUsage = 5.0;
    maxUsage *= 1.2;

    final scaleY = size.height / maxUsage;
    final stepX = data.length > 1 ? size.width / (data.length - 1) : size.width;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i].usage * scaleY);
      points.add(Offset(x, y));
      timeLabels.add(data[i].time);
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, paint);
    }

    final textStyle = const TextStyle(color: Colors.black, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const ySteps = 5;
    for (int i = 0; i <= ySteps; i++) {
      final yValue = (maxUsage / ySteps) * i;
      final y = size.height - (yValue * scaleY);
      textPainter.text = TextSpan(
        text: yValue.toStringAsFixed(1),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));

      final line =
          Paint()
            ..color = Colors.grey.withOpacity(0.3)
            ..strokeWidth = 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
