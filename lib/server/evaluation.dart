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

  String? model1;
  String? model2;
  bool _isEvaluating = false;
  bool _showResults = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evaluation failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select TWO Models To Evaluate"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ... Header logic ...
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildModelSelector(
                    "First Model",
                    _controller1,
                    (val) => model1 = val,
                    model1Metrics, // Pass metrics to the card
                    Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildModelSelector(
                    "Second Model",
                    _controller2,
                    (val) => model2 = val,
                    model2Metrics, // Pass metrics to the card
                    Colors.greenAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(280, 56),
                backgroundColor: Colors.indigoAccent,
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.compare_arrows),
              label: const Text(
                "Start Evaluation",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
              // 1. Smaller size constraints
              viewConstraints: const BoxConstraints(maxHeight: 200),
              // 2. The dark color for the expanded list background
              viewBackgroundColor: const Color(0xFF1E1E1E),
              viewSurfaceTintColor: Colors.transparent,
              headerTextStyle: TextStyle(color: Colors.white, fontSize: 15),
              viewLeading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => controller.closeView(controller.text),
              ),
              viewTrailing: [
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
                // 3. The dark color for the search bar itself
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
                    dense: true, // Makes the rows more compact
                    onTap: () {
                      setState(() {
                        onSelect(model);
                        controller.closeView(model);
                      });
                    },
                  ),
                );
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
