import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

// import 'package:fl_fraud_detection/utils/logging.dart';
import 'package:fl_fraud_detection/utils/services/api.dart';
import 'package:fl_fraud_detection/utils/metrics_charts.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final ApiService _apiservice = ApiService();

  String _status = 'Idle';
  int _clientCount = 0;

  //dummy values to test chart
  Map<String, dynamic> dummyMetrics = {
    'Round': [1, 2, 3, 4, 5],
    'Accuracy': [
      0.9996253936293504,
      0.9996371000784332,
      0.9996371000784332,
      0.9996371000784332,
      0.9996019807311848,
    ],
    'Precision': [
      0.9222222222222223,
      0.963855421686747,
      0.963855421686747,
      0.9753086419753086,
      0.9625,
    ],
    'Recall': [
      0.7685185185185185,
      0.7407407407407407,
      0.7407407407407407,
      0.7314814814814815,
      0.7129629629629629,
    ],
    'F1 Score': [
      0.8383838383838383,
      0.837696335078534,
      0.837696335078534,
      0.8359788359788359,
      0.8191489361702128,
    ],
    'PR-AUC': [
      0.8143706899607026,
      0.8148017136970137,
      0.8129865319479077,
      0.8141647209252796,
      0.8107255416388911,
    ],
  };

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

  Set<String> _selectedSegment = {'All'};

  // The possible segments

  Timer? _metricsTimer;

  // @override
  // void initState() {
  //   super.initState();

  //   // Using the helper method to initialize all spots
  //   accuracySpots = _convertToSpots(
  //     dummyMetrics['Round'],
  //     dummyMetrics['Accuracy'],
  //   );
  //   prAucSpots = _convertToSpots(dummyMetrics['Round'], dummyMetrics['PR-AUC']);

  //   // Initializing the otherMetrics map using the same helper
  //   otherMetrics["Precision"] = _convertToSpots(
  //     dummyMetrics['Round'],
  //     dummyMetrics['Precision'],
  //   );
  //   otherMetrics["Recall"] = _convertToSpots(
  //     dummyMetrics['Round'],
  //     dummyMetrics['Recall'],
  //   );
  //   otherMetrics["F1 Score"] = _convertToSpots(
  //     dummyMetrics['Round'],
  //     dummyMetrics['F1 Score'],
  //   );
  // }

  // void _startServer() async {
  //   setState(() {
  //     _status = 'Starting server...';
  //   });
  // }
  List<FlSpot> _convertToSpots(List rounds, List values) {
    return rounds.asMap().entries.map((entry) {
      return FlSpot(entry.value.toDouble(), values[entry.key].toDouble());
    }).toList();
  }

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
          _stopFetchingMetrics();
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

  void _updateSelectedSegment(Set<String> newSelectedSegment) {
    setState(() {
      _selectedSegment = newSelectedSegment;
    });
  }

  // Helper to keep the code DRY (Don't Repeat Yourself)
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
                    child: const Text("Start Data fetch"),
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
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MetricsCharts.buildChart(
                      "Accuracy",
                      accuracySpots,
                      5,
                      Colors.blue,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MetricsCharts.buildChart(
                      "PR-AUC",
                      prAucSpots,
                      5,
                      Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MetricsCharts.buildCombinedChart(
                5,
                _selectedSegment.first,
                otherMetrics,
              ),
            ),
            SegmentedButton(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: "All",
                  label: const Text("All"),
                  icon: Icon(Icons.analytics_rounded),
                ),
                ButtonSegment<String>(
                  value: "Recall",
                  label: const Text("Recall"),
                ),
                ButtonSegment<String>(
                  value: "Precision",
                  label: const Text("Precision"),
                ),
                ButtonSegment<String>(
                  value: "F1 Score",
                  label: const Text("F1 Score"),
                ),
              ],
              selected: _selectedSegment,
              onSelectionChanged: _updateSelectedSegment,
            ),
          ],
        ),
      ),
    );
  }
}
