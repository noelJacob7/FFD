import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';

// import 'package:fl_fraud_detection/utils/logging.dart';
import 'package:fl_fraud_detection/utils/services/api.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final ApiService _apiservice = ApiService();
  String _status = 'Idle';
  int _clientCount = 0;

  List<FlSpot> accuracySpots = [];
  List<FlSpot> prAucSpots = [];
  List<FlSpot> lossSpots = [];

  // Metric Selector Data
  String selectedMetric = "F1 Score";
  Map<String, List<FlSpot>> otherMetrics = {
    "Precision": [],
    "Recall": [],
    "F1 Score": [],
  };

  Timer? _metricsTimer;

  // void _startServer() async {
  //   setState(() {
  //     _status = 'Starting server...';
  //   });
  // }

  void _stopFetchingMetrics() {
    _metricsTimer?.cancel();
    setState(() {
      _status = 'Stopped fetching metrics';
    });
  }

  void _startTraining() async {
    setState(() {
      _status = 'Training started...';
    });

    _metricsTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchMetrics();
    });
  }

  void _fetchMetrics() {
    _apiservice.getTrainingMetrics().then((response) {
      if (response.containsKey("metrics")) {
        var metrics = response["metrics"];

        // 1. Check if we've reached the final round (5) to stop the timer
        List<dynamic> rounds = metrics["Round"];
        if (rounds.length >= 5) {
          _metricsTimer?.cancel();
          setState(() {
            _status = 'Training Complete';
          });
        }

        setState(() {
          accuracySpots = _convertToSpots(rounds, metrics["Accuracy"]);
          prAucSpots = _convertToSpots(rounds, metrics["PR-AUC"]);

          otherMetrics["Precision"] = _convertToSpots(
            rounds,
            metrics["Precision"],
          );
          otherMetrics["Recall"] = _convertToSpots(rounds, metrics["Recall"]);
          otherMetrics["F1 Score"] = _convertToSpots(
            rounds,
            metrics["F1 Score"],
          );

          // Assuming your API eventually provides loss history
          if (metrics.containsKey("Loss")) {
            lossSpots = _convertToSpots(rounds, metrics["Loss"]);
          }
        });
      }
    });
  }

  // Helper to keep the code DRY (Don't Repeat Yourself)
  List<FlSpot> _convertToSpots(List rounds, List values) {
    return rounds.asMap().entries.map((entry) {
      return FlSpot(entry.value.toDouble(), values[entry.key].toDouble());
    }).toList();
  }

  Widget _buildChart(String title, List<FlSpot> spots, Color color) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  color: color,
                  dotData: FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
              ),
            ),
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SelectionArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: Text("Training status: $_status")),
                  ElevatedButton(
                    onPressed: _startTraining,
                    child: const Text("Start Training"),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _stopFetchingMetrics,
                    child: const Text("Stop fetch"),
                  ),
                ],
              ),
            ),
            Text('Clients: $_clientCount'),
            _buildChart("Accuracy", accuracySpots, Colors.blue),
            _buildChart("PR-AUC", prAucSpots, Colors.green),
          ],
        ),
      ),
    );
  }
}
