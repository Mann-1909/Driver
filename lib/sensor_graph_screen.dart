import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class SensorGraphScreen extends StatefulWidget {
  final String sensorName; // e.g., "Heart Rate"
  final String jsonKey;    // e.g., "heart" (must match Python key)
  final String apiUrl;     // e.g., "http://192.168.1.15:5000/api/sensors"
  final Color lineColor;

  const SensorGraphScreen({
    super.key,
    required this.sensorName,
    required this.jsonKey,
    required this.apiUrl,
    this.lineColor = Colors.blue,
  });

  @override
  State<SensorGraphScreen> createState() => _SensorGraphScreenState();
}

class _SensorGraphScreenState extends State<SensorGraphScreen> {
  // Store graph points here (X = time, Y = value)
  List<FlSpot> spots = [];
  Timer? _timer;
  double xValue = 0; // Counter for X-axis

  @override
  void initState() {
    super.initState();
    // Fill with empty data initially so the graph isn't blank
    spots = List.generate(50, (index) => FlSpot(index.toDouble(), 0));
    xValue = 50;

    // Update graph every 100ms (fast for heart rate)
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop timer when leaving page
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse(widget.apiUrl)).timeout(const Duration(seconds: 1));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Use the safety check we learned earlier!
        // We use widget.jsonKey to grab the specific sensor we want
        int value = data[widget.jsonKey] ?? 0;

        if (mounted) {
          setState(() {
            // 1. Add new point
            spots.add(FlSpot(xValue, value.toDouble()));
            xValue++;

            // 2. Remove old point to keep the "moving window" effect
            // Keep only last 50 points
            if (spots.length > 50) {
              spots.removeAt(0);
            }
          });
        }
      }
    } catch (e) {
      // Ignore errors here to keep graph smooth, or log them
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.sensorName} Live")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Show big current number
            Text(
              spots.isNotEmpty ? spots.last.y.toInt().toString() : "0",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: widget.lineColor),
            ),
            const Text("Current Value"),
            const SizedBox(height: 40),

            // The Graph
            Expanded(
              child: LineChart(
                duration: Duration.zero,
                LineChartData(
                  // --- FIX 1: PREVENT OVERFLOW ---
                  // This acts like scissors. It cuts off any part of the line
                  // that tries to draw outside the grey border box.
                  clipData: const FlClipData.all(),

                  gridData: const FlGridData(show: true, drawVerticalLine: true,drawHorizontalLine: true,horizontalInterval: 50,
                    verticalInterval: 5,),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey)),
                  // --- FIX 2: SCROLLING EFFECT ---
                  // These two lines force the graph camera to "follow" your data.
                  // Without this, the line might push off the screen to the right.
                  minX: spots.isNotEmpty ? spots.first.x : 0,
                  maxX: spots.isNotEmpty ? spots.last.x : 10,

                  // Dynamic Range: Y-Axis scales automatically
                  minY: 0,
                  maxY: 1024,
                  // You might want to fix maxY for Alcohol (e.g. 1024)
                  // but leave it null for Heart to auto-scale

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 1,// Makes the wave look smooth
                      color: widget.lineColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: widget.lineColor.withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}