import "package:flutter/material.dart";

import '../utils/services/api.dart';
import 'package:fl_fraud_detection/utils/metrics_charts.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  // Use separate controllers for each search bar to prevent text syncing
  final SearchController _controller1 = SearchController();
  final SearchController _controller2 = SearchController();
  final ApiService _apiService = ApiService();

  // --- THEME VARIABLES ---
  // These pair beautifully with deep purple and black backgrounds
  final Color model1Color = const Color.fromARGB(255, 99, 187, 199); // Bright Cyan
  final Color model2Color = const Color.fromARGB(255, 241, 168, 51); // Soft Magenta/Purple Accent


  String? model1;
  String? model2;
  bool _isEvaluating = false;
  bool _showResults = false;
  bool _isDeploying = false;

  // Store metrics as single values for the bar charts
  Map<String, double> model1Metrics = {};
  Map<String, double> model2Metrics = {};

  void _handleEvaluation() async {
    setState(() {
      _isEvaluating = true;
      _showResults = false; // Reset results while loading
    });

    try {
      // 1. Fetch both models in parallel to save time
      final results = await Future.wait([
        _apiService.getEvaluationMetrics(model1!),
        _apiService.getEvaluationMetrics(model2!),
      ]);

      setState(() {
        // 2. Convert the EvaluationMetrics objects to the Map format
        model1Metrics = results[0].toMap();
        model2Metrics = results[1].toMap();

        _isEvaluating = false;
        _showResults = true;
      });
    } catch (e) {
      setState(() => _isEvaluating = false);
      // Show a snackbar or error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evaluation failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Updated to accept the dynamic colors
  Widget _buildDynamicComparisonCard(
    String name1,
    Map<String, double> metrics1,
    Color color1,
    String name2,
    Map<String, double> metrics2,
    Color color2,
  ) {
    final keysToCompare = ['PR_AUC', 'F1 Score', 'Precision', 'Accuracy'];

    // 1. Determine the winner based on the primary metric (PR-AUC)
    double score1 = metrics1['PR_AUC'] ?? 0.0;
    double score2 = metrics2['PR_AUC'] ?? 0.0;
    bool model2Wins = score2 >= score1;

    String winnerName = model2Wins ? name2 : name1;
    String loserName = model2Wins ? name1 : name2;
    double winnerScore = model2Wins ? score2 : score1;
    double loserScore = model2Wins ? score1 : score2;

    // 2. Calculate the "Overall" Consolidated Metric (Average of all tracked metrics)
    double avg1 =
        keysToCompare.map((k) => metrics1[k] ?? 0.0).reduce((a, b) => a + b) /
        keysToCompare.length;
    double avg2 =
        keysToCompare.map((k) => metrics2[k] ?? 0.0).reduce((a, b) => a + b) /
        keysToCompare.length;
    double winnerAvg = model2Wins ? avg2 : avg1;
    double loserAvg = model2Wins ? avg1 : avg2;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFF161616),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- HEADER: THE MATCHUP ---
            Text(
              'LEADING MODEL: ${winnerName.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),

            // --- THE DUAL HERO STATS ---
            Row(
              children: [
                Expanded(
                  child: _buildHeroStat(
                    "$winnerName PR-AUC",
                    winnerScore.toStringAsFixed(4),
                    winnerScore - loserScore,
                    "vs $loserName",
                  ),
                ),
                Container(
                  width: 1,
                  height: 80,
                  color: Colors.white10,
                ), // Sleek divider
                Expanded(
                  child: _buildHeroStat(
                    "OVERALL IMPROVEMENT",
                    "+${((winnerAvg - loserAvg) * 100).toStringAsFixed(2)}%",
                    winnerAvg - loserAvg,
                    "across all metrics",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Divider(color: Colors.grey[850]),
            const SizedBox(height: 16),

            // --- MODEL COLOR HELPER CHART (LEGEND) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 32),
                _buildLegendItem(name1, color1),
                const SizedBox(width: 32),
                const Text(
                  'VS',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 32),
                _buildLegendItem(name2, color2),
              ],
            ),
            const SizedBox(height: 24),

            // --- THE DIVERGING BARS ---
            ...keysToCompare.map((key) {
              double val1 = metrics1[key] ?? 0.0;
              double val2 = metrics2[key] ?? 0.0;
              double diff = val2 - val1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildDivergingBar(
                  key.toUpperCase(),
                  diff,
                  val1,
                  val2,
                  color1,
                  color2,
                ),
              );
            }),

            const SizedBox(height: 24),
            Divider(color: Colors.grey[850]),
            const SizedBox(height: 16),

            // --- THE SMART DEPLOY BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: null, //_isDeploying ? null : _deployModel,
                icon: _isDeploying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.rocket_launch, color: Colors.black),
                label: Text(
                  _isDeploying
                      ? 'DEPLOYING TO PRODUCTION...'
                      : 'DEPLOY WINNER: $winnerName',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "-- SELECT TWO MODELS TO EVALUATE --",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            // ... Header logic ...
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildModelSelector(
                    "First Model",
                    _controller1,
                    (val) => model1 = val,
                    model1Metrics,
                    model1Color, // Passing dynamic color
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildModelSelector(
                    "Second Model",
                    _controller2,
                    (val) => model2 = val,
                    model2Metrics,
                    model2Color, // Passing dynamic color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(280, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Button enabled only if BOTH models are selected
              onPressed: (model1 != null && model2 != null && !_isEvaluating)
                  ? _handleEvaluation
                  : null,
              icon: _isEvaluating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.compare_arrows),
              label: const Text(
                "Start Evaluation",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 32),
            if (_showResults)
              _buildDynamicComparisonCard(
                model1 ?? "Model 1",
                model1Metrics,
                model1Color, // Injecting color 1
                model2 ?? "Model 2",
                model2Metrics,
                model2Color, // Injecting color 2
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelector(
    String label,
    SearchController controller,
    Function(String?) onSelect,
    Map<String, double> metrics,
    Color themeColor,
  ) {
    return Card(
      elevation: 0,
      color: const Color(0xFF1A1A1A), // Deep dark background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
            ),
            const SizedBox(height: 16),

            SearchAnchor(
              searchController: controller,
              viewConstraints: const BoxConstraints(maxHeight: 250),
              viewBackgroundColor: const Color(0xFF1E1E1E),
              viewSurfaceTintColor: Colors.transparent,
              headerTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              viewLeading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => controller.closeView(controller.text),
              ),
              viewTrailing: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refetch Models',
                  onPressed: () {
                    controller.closeView(controller.text);
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted) controller.openView();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    controller.clear();
                    setState(() {
                      onSelect(null);
                    });
                  },
                ),
              ],
              builder: (context, controller) => SearchBar(
                controller: controller,
                hintText: "Choose model...",
                onTap: () => controller.openView(),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: const WidgetStatePropertyAll(
                  Color(0xFF252525),
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(color: Colors.white, fontSize: 15),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              suggestionsBuilder: (context, controller) async {
                try {
                  final models = await _apiService.getModels();
                  return models.map(
                    (model) => ListTile(
                      title: Text(
                        model,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          onSelect(model);
                          controller.closeView(model);
                        });
                      },
                    ),
                  );
                } catch (e) {
                  return [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load sequences.\nPlease check your API connection.\n\nClick the refresh button above to try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ];
                }
              },
            ),

            if (_showResults && metrics.isNotEmpty) ...[
              const Divider(height: 40, color: Colors.white10),
              MetricsCharts.buildModelSummaryChart(metrics, themeColor),
            ],
          ],
        ),
      ),
    );
  }
}

// --- REUSABLE HERO STAT WIDGET ---
Widget _buildHeroStat(
  String title,
  String mainValue,
  double delta,
  String subtitle,
) {
  bool isPositive = delta >= 0;
  Color trendColor = isPositive ? Colors.greenAccent : Colors.redAccent;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        mainValue,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: trendColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            "${(delta.abs() * 100).toStringAsFixed(2)}% $subtitle",
            style: TextStyle(
              color: trendColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );
}

// --- NEW Helper: COLOR LEGEND ITEM ---
Widget _buildLegendItem(String label, Color color) {
  return Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

// Updated to accept Color1 and Color2 dynamically
Widget _buildDivergingBar(
  String label,
  double diff,
  double val1,
  double val2,
  Color color1,
  Color color2,
) {
  // Determine who won this specific metric
  bool model2Wins = diff >= 0;

  double visualWidth = (diff.abs() * 5).clamp(0.01, 1.0);

  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            val1.toStringAsFixed(3),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            val2.toStringAsFixed(3),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          // LEFT SIDE: Model 1's territory (uses color1)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: model2Wins ? 0 : visualWidth,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color1, // Dynamic Color
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // THE ZERO CENTER LINE
          Container(width: 2, height: 16, color: Colors.white38),

          // RIGHT SIDE: Model 2's territory (uses color2)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: model2Wins ? visualWidth : 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color2, // Dynamic Color
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
