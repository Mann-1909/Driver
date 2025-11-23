import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sensor_graph_screen.dart'; // Add this line
void main() => runApp(const DriverMonitorApp());

class DriverMonitorApp extends StatelessWidget {
  const DriverMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- CONFIGURATION ---
  // REPLACE THIS with your Raspberry Pi's IP Address!
  final String apiUrl = "http://10.94.145.106:5000/api/sensors";

  // Variables to hold sensor data
  int alcoholLevel = 0;
  int heartRateRaw = 0;
  String status = "Connecting...";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start polling the server every 500 milliseconds
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      fetchSensorData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer when screen is closed
    super.dispose();
  }

  Future<void> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          alcoholLevel = data['alcohol_level'];
          heartRateRaw = data['heart_rate'];
          status = data['status'];
        });
      }
    } catch (e) {
      // Handle errors (e.g., Pi is offline)
      debugPrint("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine color based on safety status
    Color statusColor = status == "SAFE" ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text("Driver Safety System")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 30),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    "SYSTEM STATUS",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSensorCard(
                "Alcohol Level",
                alcoholLevel.toString(),
                Icons.local_drink,
                "alcohol_level",
                Colors.orange
            ),

            const SizedBox(height: 20),
            _buildSensorCard(
                "Heart Sensor",
                heartRateRaw.toString(),
                Icons.favorite,
                "heart_rate",
                Colors.red
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon, String jsonKey, Color color) {
    return GestureDetector(
      // NAVIGATION LOGIC
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SensorGraphScreen(
              sensorName: title,
              jsonKey: jsonKey,     // Pass 'alcohol' or 'heart'
              apiUrl: apiUrl,       // Pass your IP
              lineColor: color,
            ),
          ),
        );
      },
      // UI DESIGN
      child: Card(
        elevation: 4,
        child: ListTile(
          leading: Icon(icon, size: 40, color: color),
          title: Text(title, style: const TextStyle(fontSize: 18)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
            ],
          ),
        ),
      ),
    );
  }
}
