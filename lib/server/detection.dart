import "package:flutter/material.dart";
import '../utils/services/api.dart';
import '../utils/services/data_manager.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  final SearchController _searchController = SearchController();
  final ApiService _apiService = ApiService();

  SequenceData? _selectedSequence; // Store the selected sequence data
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;

  void _handleDetection() async {
    if (_selectedSequence == null) return;

    setState(() {
      _isLoading = true;
      _predictionResult = null; // Clear previous results
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Detecting fraud for sequence ${_selectedSequence!.id}',
          ),
        ),
      );

      final result = await _apiService.runPrediction(_selectedSequence!.id);

      setState(() {
        _predictionResult = result;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Detection Complete')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  } // To show a loading indicator during detection

  Widget _buildResultCard() {
    final double prob = _predictionResult!['predicted_probability'] ?? 0.0;
    final Color color = prob > 0.5 ? Colors.redAccent : Colors.greenAccent;

    return Card(
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  "Actual",
                  _predictionResult!['actual_label'].toString(),
                  Colors.white70,
                ),
                _buildStat(
                  "Predicted",
                  _predictionResult!['predicted_label'].toString(),
                  color,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Text(
            //   "Probability: ${(prob * 100).toStringAsFixed(2)}%",
            //   style: const TextStyle(fontSize: 16),
            // ),
            const SizedBox(height: 12),
            // Custom Linear Graph
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: prob,
                minHeight: 12,
                backgroundColor: const Color.fromARGB(26, 35, 35, 35),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: valColor,
          ),
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchAnchor(
                    viewShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    viewConstraints: BoxConstraints.loose(
                      Size(double.infinity, 300),
                    ),
                    searchController: _searchController,
                    builder: (context, controller) {
                      return SearchBar(
                        controller: controller,
                        hintText: 'Select a sequence...',
                        onTap: () => controller.openView(),
                        onChanged: (_) => controller.openView(),
                        leading: const Icon(Icons.search),
                      );
                    },
                    suggestionsBuilder: (context, controller) async {
                      // Calls your existing getSequences() function
                      final sequences = await _apiService.getSequences();

                      return sequences.map(
                        (data) => ListTile(
                          title: Text(data.id),
                          subtitle: Text('Original Label: ${data.label}'),
                          onTap: () {
                            setState(() {
                              _selectedSequence = data;
                              _searchController.closeView(data.id);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // The detection logic only runs when this button is pressed
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: FilledButton.icon(
                // Button is disabled (null) if no sequence is selected
                onPressed: (_selectedSequence == null || _isLoading)
                    ? null
                    : _handleDetection,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt),

                label: Text(
                  _isLoading ? 'Processing...' : 'Run Fraud Detection',
                ),

                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(double.infinity, 60),
                ),
              ),
            ),

            Divider(),

            if (_predictionResult != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildResultCard(),
              ),
          ],
        ),
      ),
    );
  }
}
