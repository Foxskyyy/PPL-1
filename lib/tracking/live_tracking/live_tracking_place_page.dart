import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:front_end/custom_button_navbar.dart';

class LiveTrackingPlacePage extends StatefulWidget {
  final String placeName;
  final String room;
  final double currentUsage;
  final int groupId;
  final String deviceId;

  const LiveTrackingPlacePage({
    super.key,
    required this.placeName,
    required this.room,
    required this.currentUsage,
    required this.groupId,
    required this.deviceId,
  });

  @override
  State<LiveTrackingPlacePage> createState() => _LiveTrackingPlacePageState();
}

class _LiveTrackingPlacePageState extends State<LiveTrackingPlacePage> {
  bool showUsageLogs = false;
  List<WaterUsageData> waterUsageData = [];
  List<UsageLog> usageLogs = [];
  double totalWaterUsage = 0.0;
  List<String> groupLocations = [];
  String location = "";
  String? selectedDropdownLocation;
  String dateToday = DateTime.now().toString().split(' ')[0];

  @override
  void initState() {
    super.initState();
    fetchWaterUsageData();
  }

  Future<void> fetchWaterUsageData() async {
    const String apiUrl =
        'http://api-ecotrack.interphaselabs.com/graphql/query';

    final String query = '''
    {
      userGroups {
        id
        name
        location
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
        final userGroups = result['data']['userGroups'];

        final group = userGroups.firstWhere(
          (g) => g['id'].toString() == widget.groupId.toString(),
          orElse: () => null,
        );

        if (group != null) {
          final List<dynamic> devices = group['devices'] ?? [];
          final List<String> allLocations =
              group['location'] != null
                  ? List<String>.from(group['location'])
                  : [];

          setState(() {
            groupLocations = allLocations;
            if (selectedDropdownLocation == null && allLocations.isNotEmpty) {
              selectedDropdownLocation = allLocations.first;
            }
          });

          final today =
              DateTime.now().toLocal().toIso8601String().split('T')[0];

          List<WaterUsageData> fetchedData = [];
          List<UsageLog> fetchedLogs = [];
          double total = 0.0;

          for (var device in devices) {
            if (selectedDropdownLocation != null &&
                device['location'] != selectedDropdownLocation)
              continue;

            if (device['id'] == widget.deviceId && device['location'] != null) {
              location = device['location'];
            }

            final usages = device['waterUsages'] ?? [];
            for (var usage in usages) {
              String recordedDate =
                  usage['recordedAt'].toString().split('T')[0];
              if (recordedDate != today) continue;

              String formattedTime = _formatTimestamp(usage['recordedAt']);
              double usageValue = usage['totalUsage'].toDouble();

              fetchedData.add(
                WaterUsageData(time: formattedTime, usage: usageValue),
              );
              fetchedLogs.add(UsageLog(time: formattedTime, usage: usageValue));
              total += usageValue;
            }
          }

          setState(() {
            waterUsageData = fetchedData;
            usageLogs = fetchedLogs;
            totalWaterUsage = total;
          });
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp).toLocal();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 16),
                      SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  widget.placeName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (groupLocations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedDropdownLocation,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Lokasi',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        groupLocations.map((loc) {
                          return DropdownMenuItem<String>(
                            value: loc,
                            child: Text(loc),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDropdownLocation = value;
                        fetchWaterUsageData();
                      });
                    },
                  ),
                ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text(
                      "LIVE TRACKING PENGGUNAAN AIR",
                      style: TextStyle(fontWeight: FontWeight.bold),
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
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    size: const Size(double.infinity, 150),
                    painter: UsageGraphPainter(data: waterUsageData),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text(
                      "Total water usage: ",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "${totalWaterUsage.toStringAsFixed(2)} L",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text(
                      "Location: ",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      location,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showUsageLogs = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Track"),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (showUsageLogs)
                SizedBox(
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        const Text(
                          "Usage Logs:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateToday,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child:
                              usageLogs.isEmpty
                                  ? const Center(
                                    child: Text("No data available"),
                                  )
                                  : ListView.builder(
                                    itemCount: usageLogs.length,
                                    itemBuilder: (context, index) {
                                      final log = usageLogs[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              log.time,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "${log.usage.toStringAsFixed(2)}L/s",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

class WaterUsageData {
  final String time;
  final double usage;

  WaterUsageData({required this.time, required this.usage});
}

class UsageLog {
  final String time;
  final double usage;

  UsageLog({required this.time, required this.usage});
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

    double maxUsage = 40.0;

    if (data.isNotEmpty) {
      maxUsage = data.map((d) => d.usage).reduce((a, b) => a > b ? a : b);
      if (maxUsage < 5) maxUsage = 5.0;
      maxUsage = (maxUsage * 1.2).ceilToDouble();

      final usageScale = size.height / maxUsage;
      final xStep = size.width / (data.length > 1 ? data.length - 1 : 1);

      for (int i = 0; i < data.length; i++) {
        final x = i * xStep;
        final y = size.height - (data[i].usage * usageScale);
        points.add(Offset(x, y));
      }

      timeLabels = data.map((d) => d.time).toList();
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.lineTo(points.first.dx, size.height);
      fillPath.close();
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final textStyle = TextStyle(color: Colors.black, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    int numDivisions = 5;
    double increment = maxUsage / numDivisions;

    for (int i = 0; i <= numDivisions; i++) {
      final y = size.height - (i * size.height / numDivisions);
      final value = (i * increment).toStringAsFixed(1);
      textPainter.text = TextSpan(text: value, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(-15, y - 5));
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..strokeWidth = 0.5,
      );
    }

    if (timeLabels.isNotEmpty) {
      final labelCount = timeLabels.length > 6 ? 6 : timeLabels.length;
      final step =
          timeLabels.length ~/ labelCount > 0
              ? timeLabels.length ~/ labelCount
              : 1;

      for (int i = 0; i < timeLabels.length; i += step) {
        final x = i * (size.width / (data.length > 1 ? data.length - 1 : 1));
        textPainter.text = TextSpan(text: timeLabels[i], style: textStyle);
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - 10, size.height + 5));
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = Colors.grey.withOpacity(0.2)
            ..strokeWidth = 0.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is UsageGraphPainter && oldDelegate.data != data;
  }
}
