import 'package:flutter/material.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/add_device.dart';
import 'package:front_end/group/yourgroup/your_group_page.dart';
import 'package:front_end/user_session.dart';
import 'package:front_end/ai_consume_page.dart'; // Import the new AI consume page
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Tidak perlu menyimpan data statis karena kita mengambil data dari API

  String? displayName;
  List<WaterUsageData> waterUsageData = [];
  String dateToday = DateTime.now().toString().split(' ')[0];
  double totalWaterUsage = 0.0;

  @override
  void initState() {
    super.initState();
    displayName = UserSession.displayName ?? "User";
    fetchWaterUsageData();
  }

  Future<void> fetchWaterUsageData() async {
    const String apiUrl = 'https://api.interphaselabs.com/graphql/query';

    final String query = '''
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
        if (result['data'] != null && result['data']['userGroups'] != null) {
          final userGroups = result['data']['userGroups'];

          if (userGroups.isNotEmpty) {
            List<WaterUsageData> fetchedData = [];
            double total = 0.0;

            for (var group in userGroups) {
              List<dynamic> devices = group['devices'] ?? [];

              for (var device in devices) {
                if (device['waterUsages'] != null) {
                  for (var usage in device['waterUsages']) {
                    String formattedTime = _formatTimestamp(
                      usage['recordedAt'],
                    );

                    fetchedData.add(
                      WaterUsageData(
                        time: formattedTime,
                        usage: usage['totalUsage'].toDouble(),
                      ),
                    );

                    total += usage['totalUsage'].toDouble();
                  }
                }
              }
            }

            // Sort data by time
            fetchedData.sort((a, b) => a.time.compareTo(b.time));

            // Take only the last 10 data points if there are more
            if (fetchedData.length > 10) {
              fetchedData = fetchedData.sublist(fetchedData.length - 10);
            }

            setState(() {
              waterUsageData = fetchedData;
              totalWaterUsage = total;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching water usage data: $e');
      // In case of error, use demo data
      setState(() {
        waterUsageData = [
          WaterUsageData(time: '15:34', usage: 30.0),
          WaterUsageData(time: '15:34', usage: 31.0),
          WaterUsageData(time: '15:34', usage: 31.5),
          WaterUsageData(time: '15:34', usage: 32.0),
          WaterUsageData(time: '15:35', usage: 32.0),
          WaterUsageData(time: '15:35', usage: 31.5),
          WaterUsageData(time: '15:35', usage: 31.0),
          WaterUsageData(time: '15:35', usage: 31.0),
        ];
      });
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
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
            const Divider(color: Colors.black),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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

            // Today's Usage Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      padding: const EdgeInsets.all(8.0),
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Text(
                                  "Total water usage: ",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w400,
                                  ),
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

            // AI Consume Suggestion Container (Changed from Chatbot)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AIConsumePage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12.0),
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

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          builder: (_) => const AddDevicePage(),
                        ),
                      );
                    },
                  ),
                  _QuickAction(
                    icon: Icons.timer,
                    label: 'Quick\nActions',
                    onTap: () {},
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

// Class untuk data penggunaan air
class WaterUsageData {
  final String time;
  final double usage;

  WaterUsageData({required this.time, required this.usage});
}

// Class untuk menggambar grafik
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

    double maxUsage = 40.0; // Default max value

    if (data.isNotEmpty) {
      // Calculate the max usage value with 20% margin
      maxUsage = data.map((d) => d.usage).reduce((a, b) => a > b ? a : b);
      if (maxUsage < 5) maxUsage = 5.0; // Minimum scale
      maxUsage = (maxUsage * 1.2).ceilToDouble(); // 20% margin

      final usageScale = size.height / maxUsage;
      final xStep = size.width / (data.length > 1 ? data.length - 1 : 1);

      for (int i = 0; i < data.length; i++) {
        final x = i * xStep;
        final y = size.height - (data[i].usage * usageScale);
        points.add(Offset(x, y));
      }

      timeLabels = data.map((d) => d.time).toList();
    } else {
      // Default points if no data
      points.addAll([
        Offset(0, size.height * 0.8),
        Offset(size.width, size.height * 0.2),
      ]);
      timeLabels = ['00:00', '03:00', '06:00', '09:00', '12:00', '15:00'];
    }

    if (points.isNotEmpty) {
      // Draw the line
      path.moveTo(points[0].dx, points[0].dy);

      // Create fill path for area under the line
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      // Complete the fill path
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.lineTo(points.first.dx, size.height);
      fillPath.close();
    }

    // Draw the fill area first, then the line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw Y-axis labels and grid lines
    final textStyle = TextStyle(color: Colors.black, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    int numDivisions = 5;
    double increment = maxUsage / numDivisions;

    for (int i = 0; i <= numDivisions; i++) {
      final y = size.height - (i * size.height / numDivisions);
      final value = (i * increment).toStringAsFixed(1);

      textPainter.text = TextSpan(text: value, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 5));

      final gridPaint =
          Paint()
            ..color = Colors.grey.withOpacity(0.3)
            ..strokeWidth = 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw X-axis labels and grid lines
    if (timeLabels.isNotEmpty) {
      final labelCount = timeLabels.length > 6 ? 6 : timeLabels.length;
      final step =
          timeLabels.length ~/ labelCount > 0
              ? timeLabels.length ~/ labelCount
              : 1;

      for (int i = 0; i < timeLabels.length; i += step) {
        if (i >= timeLabels.length) continue;

        final x = i * (size.width / (data.length > 1 ? data.length - 1 : 1));

        textPainter.text = TextSpan(text: timeLabels[i], style: textStyle);
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - 10, size.height + 5));

        final gridPaint =
            Paint()
              ..color = Colors.grey.withOpacity(0.2)
              ..strokeWidth = 0.5;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is UsageGraphPainter) {
      return oldDelegate.data != data;
    }
    return true;
  }
}
