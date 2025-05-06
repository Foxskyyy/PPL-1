import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:front_end/custom_button_navbar.dart';
import 'package:front_end/tracking/tracking_page.dart';

class ConsumptionTrackingPage extends StatefulWidget {
  const ConsumptionTrackingPage({Key? key}) : super(key: key);

  @override
  State<ConsumptionTrackingPage> createState() =>
      _ConsumptionTrackingPageState();
}

class _ConsumptionTrackingPageState extends State<ConsumptionTrackingPage> {
  final List<bool> _selectedPeriod = [true, false, false];
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // List of years that dynamically includes current year and previous years
  List<String> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(
      3,
      (index) => (currentYear - index).toString(),
    ).reversed.toList();
  }

  // Simulated future for fetching data from backend
  Future<List<FlSpot>> fetchData(String periodType, String label) async {
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Simulating delay for data fetching

    // Return appropriate data based on period type
    switch (periodType) {
      case 'week':
        return getDailyConsumptionData(label);
      case 'month':
        return getMonthlyConsumptionData(label);
      case 'year':
        return getYearlyConsumptionData(label);
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine current selected period type
    String periodType =
        _selectedPeriod[0] ? 'week' : (_selectedPeriod[1] ? 'month' : 'year');

    // Determine which list to use based on selected period
    List<String> currentList;
    if (_selectedPeriod[0]) {
      currentList = _days;
    } else if (_selectedPeriod[1]) {
      currentList = _months;
    } else {
      currentList = _years;
    }

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
            Container(height: 1, color: Colors.black),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
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

            // Toggle: Week / Month / Year with styling to make buttons separated
            const SizedBox(height: 0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        _selectedPeriod[0] ? Color(0xFF0A7D34) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < _selectedPeriod.length; i++) {
                        _selectedPeriod[i] = i == 0;
                      }
                    });
                  },
                  child: const Text("Week"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        _selectedPeriod[1] ? Color(0xFF0A7D34) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < _selectedPeriod.length; i++) {
                        _selectedPeriod[i] = i == 1;
                      }
                    });
                  },
                  child: const Text("Month"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        _selectedPeriod[2] ? Color(0xFF0A7D34) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < _selectedPeriod.length; i++) {
                        _selectedPeriod[i] = i == 2;
                      }
                    });
                  },
                  child: const Text("Year"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Chart content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0A7D34),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentList.length,
                  itemBuilder: (context, index) {
                    final String selected = currentList[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          selected,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 250,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: FutureBuilder<List<FlSpot>>(
                            future: fetchData(periodType, selected),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              } else if (snapshot.hasData) {
                                return buildChart(periodType, snapshot.data!);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  // Helper method to build appropriate chart based on period type
  Widget buildChart(String periodType, List<FlSpot> data) {
    // Define x-axis settings based on period type
    double minX = 0;
    double maxX = periodType == 'week' ? 23 : (periodType == 'month' ? 31 : 12);

    // Custom title function for x-axis based on period type
    Widget Function(double, TitleMeta) getTitleWidget = (value, meta) {
      final int xValue = value.toInt();
      String title = '';

      if (periodType == 'week') {
        // For week view, show hours
        if (xValue % 6 == 0 || xValue == 0 || xValue == 23) {
          title = xValue.toString();
        }
      } else if (periodType == 'month') {
        // For month view, show days
        if (xValue % 5 == 0 || xValue == 0 || xValue == 31) {
          title = xValue.toString();
        }
      } else {
        // For year view, show months
        if (xValue >= 0 && xValue < 12) {
          // Convert month number to abbreviated month name (Jan, Feb, etc.)
          final monthNames = [
            'J',
            'F',
            'M',
            'A',
            'M',
            'J',
            'J',
            'A',
            'S',
            'O',
            'N',
            'D',
          ];
          title = monthNames[xValue];
        }
      }

      if (title.isNotEmpty) {
        return SideTitleWidget(
          axisSide: meta.axisSide,
          child: Text(
            title,
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
        );
      }
      return const SizedBox.shrink();
    };

    // Define y-axis label based on period type
    String yAxisLabel = periodType == 'year' ? 'Annual Usage (kL)' : 'Liters';

    // Define threshold based on period type
    double thresholdValue =
        periodType == 'week' ? 140 : (periodType == 'month' ? 4000 : 40000);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: periodType == 'year' ? 10000 : 500,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: getTitleWidget,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: periodType == 'year' ? 10000 : 500,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    periodType == 'year'
                        ? '${(value / 1000).toInt()}k' // Format as 10k, 20k for year view
                        : '${value.toInt()}',
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  ),
                );
              },
            ),
            axisNameWidget: Text(
              yAxisLabel,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: minX,
        maxX: maxX,
        minY: periodType == 'year' ? 5000 : (periodType == 'week' ? 50 : 2500),
        maxY:
            periodType == 'year' ? 50000 : (periodType == 'week' ? 200 : 5500),
        lineBarsData: [
          // Consumption line
          LineChartBarData(
            spots: data,
            isCurved:
                periodType == 'year', // Make year view curved for better visual
            color: Colors.blue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
          // Overuse threshold line
          LineChartBarData(
            spots: [FlSpot(minX, thresholdValue), FlSpot(maxX, thresholdValue)],
            isCurved: false,
            color: Colors.red,
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }

  // Different data generators for each period type
  List<FlSpot> getDailyConsumptionData(String day) {
    // Simulated hourly data for daily consumption
    switch (day) {
      case 'Monday':
        return [
          const FlSpot(0, 135),
          const FlSpot(1, 65),
          const FlSpot(2, 80),
          const FlSpot(3, 110),
          const FlSpot(4, 140),
          const FlSpot(5, 130),
          const FlSpot(6, 60),
          const FlSpot(7, 80),
          const FlSpot(8, 85),
          const FlSpot(9, 130),
          const FlSpot(10, 140),
          const FlSpot(11, 110),
          const FlSpot(12, 135),
          const FlSpot(13, 130),
          const FlSpot(14, 60),
          const FlSpot(15, 80),
          const FlSpot(16, 95),
          const FlSpot(17, 80),
          const FlSpot(18, 110),
          const FlSpot(19, 105),
          const FlSpot(20, 135),
          const FlSpot(21, 90),
          const FlSpot(22, 145),
          const FlSpot(23, 55),
        ];
      case 'Tuesday':
        return [
          const FlSpot(0, 95),
          const FlSpot(1, 85),
          const FlSpot(2, 70),
          const FlSpot(3, 90),
          const FlSpot(4, 120),
          const FlSpot(5, 150),
          const FlSpot(6, 90),
          const FlSpot(7, 70),
          const FlSpot(8, 95),
          const FlSpot(9, 110),
          const FlSpot(10, 160),
          const FlSpot(11, 130),
          const FlSpot(12, 115),
          const FlSpot(13, 140),
          const FlSpot(14, 70),
          const FlSpot(15, 90),
          const FlSpot(16, 85),
          const FlSpot(17, 70),
          const FlSpot(18, 130),
          const FlSpot(19, 95),
          const FlSpot(20, 125),
          const FlSpot(21, 100),
          const FlSpot(22, 135),
          const FlSpot(23, 75),
        ];
      case 'Wednesday':
        return [
          const FlSpot(0, 115),
          const FlSpot(1, 75),
          const FlSpot(2, 90),
          const FlSpot(3, 100),
          const FlSpot(4, 130),
          const FlSpot(5, 140),
          const FlSpot(6, 70),
          const FlSpot(7, 90),
          const FlSpot(8, 75),
          const FlSpot(9, 120),
          const FlSpot(10, 150),
          const FlSpot(11, 120),
          const FlSpot(12, 125),
          const FlSpot(13, 140),
          const FlSpot(14, 70),
          const FlSpot(15, 90),
          const FlSpot(16, 105),
          const FlSpot(17, 90),
          const FlSpot(18, 120),
          const FlSpot(19, 115),
          const FlSpot(20, 145),
          const FlSpot(21, 100),
          const FlSpot(22, 155),
          const FlSpot(23, 65),
        ];
      // Add more cases for other days
      default:
        // Generate random data for other days
        return List.generate(
          24,
          (i) =>
              FlSpot(i.toDouble(), 50 + (150 * i / 24) * (0.7 + 0.6 * (i % 3))),
        );
    }
  }

  List<FlSpot> getMonthlyConsumptionData(String month) {
    // Simulated daily data for monthly consumption
    switch (month) {
      case 'January':
        return [
          const FlSpot(1, 3500),
          const FlSpot(2, 3600),
          const FlSpot(3, 3400),
          const FlSpot(4, 3800),
          const FlSpot(5, 4100),
          const FlSpot(6, 3900),
          const FlSpot(7, 3700),
          const FlSpot(8, 3500),
          const FlSpot(9, 3400),
          const FlSpot(10, 3600),
          const FlSpot(11, 3800),
          const FlSpot(12, 4000),
          const FlSpot(13, 4200),
          const FlSpot(14, 4100),
          const FlSpot(15, 3900),
          const FlSpot(16, 3800),
          const FlSpot(17, 3700),
          const FlSpot(18, 3600),
          const FlSpot(19, 3500),
          const FlSpot(20, 3400),
          const FlSpot(21, 3700),
          const FlSpot(22, 3900),
          const FlSpot(23, 4000),
          const FlSpot(24, 4100),
          const FlSpot(25, 4200),
          const FlSpot(26, 4100),
          const FlSpot(27, 3900),
          const FlSpot(28, 3800),
          const FlSpot(29, 3700),
          const FlSpot(30, 3600),
          const FlSpot(31, 3500),
        ];
      case 'February':
        return [
          const FlSpot(1, 3700),
          const FlSpot(2, 3800),
          const FlSpot(3, 3600),
          const FlSpot(4, 4000),
          const FlSpot(5, 4300),
          const FlSpot(6, 4100),
          const FlSpot(7, 3900),
          const FlSpot(8, 3700),
          const FlSpot(9, 3600),
          const FlSpot(10, 3800),
          const FlSpot(11, 4000),
          const FlSpot(12, 4200),
          const FlSpot(13, 4400),
          const FlSpot(14, 4300),
          const FlSpot(15, 4100),
          const FlSpot(16, 4000),
          const FlSpot(17, 3900),
          const FlSpot(18, 3800),
          const FlSpot(19, 3700),
          const FlSpot(20, 3600),
          const FlSpot(21, 3900),
          const FlSpot(22, 4100),
          const FlSpot(23, 4200),
          const FlSpot(24, 4300),
          const FlSpot(25, 4400),
          const FlSpot(26, 4300),
          const FlSpot(27, 4100),
          const FlSpot(28, 4000),
        ];
      // Add more cases for other months
      default:
        // Generate random data for other months with a 31-day pattern
        return List.generate(
          31,
          (i) => FlSpot(
            (i + 1).toDouble(),
            3000 + 1000 * (0.7 + 0.3 * (i % 7) / 7),
          ),
        );
    }
  }

  List<FlSpot> getYearlyConsumptionData(String year) {
    // Simulated monthly data for yearly consumption
    // This returns consumption data by month (0-11) for the selected year
    switch (year) {
      case '2023':
        return [
          const FlSpot(0, 31000), // January
          const FlSpot(1, 28000), // February
          const FlSpot(2, 33000), // March
          const FlSpot(3, 35000), // April
          const FlSpot(4, 38000), // May
          const FlSpot(5, 42000), // June
          const FlSpot(6, 45000), // July
          const FlSpot(7, 43000), // August
          const FlSpot(8, 40000), // September
          const FlSpot(9, 36000), // October
          const FlSpot(10, 32000), // November
          const FlSpot(11, 34000), // December
        ];
      case '2024':
        return [
          const FlSpot(0, 33000), // January
          const FlSpot(1, 30000), // February
          const FlSpot(2, 32000), // March
          const FlSpot(3, 36000), // April
          const FlSpot(4, 39000), // May
          const FlSpot(5, 43000), // June
          const FlSpot(6, 47000), // July
          const FlSpot(7, 44000), // August
          const FlSpot(8, 41000), // September
          const FlSpot(9, 37000), // October
          const FlSpot(10, 34000), // November
          const FlSpot(11, 36000), // December
        ];
      case '2025':
        return [
          const FlSpot(0, 32000), // January
          const FlSpot(1, 29000), // February
          const FlSpot(2, 31000), // March
          const FlSpot(3, 34000), // April
          const FlSpot(4, 36000), // May
          const FlSpot(5, 38000), // June
          const FlSpot(6, 40000), // July
          const FlSpot(7, 39000), // August
          const FlSpot(8, 36000), // September
          const FlSpot(9, 33000), // October
          const FlSpot(10, 30000), // November
          const FlSpot(11, 32000), // December
        ];
      default:
        // Generate sample data for any other year
        return List.generate(
          12,
          (i) => FlSpot(i.toDouble(), 30000 + 10000 * 0.5 * ((i % 6) / 6)),
        );
    }
  }
}
