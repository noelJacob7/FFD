import "package:flutter/material.dart";
import 'dart:math';

import '../utils/services/api.dart';
import '../utils/services/data_manager.dart';
import '../utils/metrics_charts.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  final SearchController _searchController = SearchController();
  final ApiService _apiService = ApiService();

  SequenceData? selectedSequence;
  String predictionModel = 'production_model.keras';
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;

  Future<List<SequenceData>>? _sequencesFuture;

  void _fetchSequences() {
    setState(() {
      // Catch the error at the Future level so we can handle it in the UI
      _sequencesFuture = _apiService.getSequences().catchError((error) {
        throw error;
      });
    });
  }

  void _handleDetection() async {
    if (selectedSequence == null) return;

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Detecting fraud for sequence ${selectedSequence!.id}'),
          duration: const Duration(seconds: 2),
        ),
      );

      final result = await _apiService.runPrediction(
        predictionModel,
        selectedSequence!.id,
      );

      setState(() {
        _predictionResult = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Detection Complete')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSettingsDialog() async {
    // 1. You might want a loading spinner here, but assuming it fetches fast:
    final _models = await _apiService.getModels();

    // 2. Safety Check: If our current predictionModel is NOT in the fetched list,
    // default to the first item in the list (if the list isn't empty) to prevent a crash.
    if (_models.isNotEmpty && !_models.contains(predictionModel)) {
      predictionModel = _models.first;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          // 3. StatefulBuilder allows the dialog to redraw itself when you change the dropdown
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Detection Settings'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fixed the inverted logic here
                    if (_models.isEmpty)
                      const Text('No models available on server.')
                    else ...[
                      SizedBox(height: 10),
                      const Text(
                        'The system defaults to the latest deployed federated model.\nYou can manually select an older version below.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        focusColor: Colors.transparent,
                        dropdownColor: const Color.fromARGB(255, 234, 229, 234),
                        value: predictionModel,
                        hint: const Text("Select a model"),
                        items: _models.map((String fileName) {
                          return DropdownMenuItem<String>(
                            value: fileName,
                            child: Text(fileName),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            // Update the dialog's UI
                            setDialogState(() {
                              predictionModel = newValue;
                            });
                            // Also update the parent page's memory
                            setState(() {
                              predictionModel = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Widget _buildResultCard() {
    if (selectedSequence == null || _predictionResult == null) {
      return const SizedBox.shrink();
    }

    double prob = _predictionResult!['predicted_probability'] ?? 0.0;
    prob *= 100;
    final Color color = prob > 50 ? Colors.redAccent : Colors.greenAccent;

    return Card(
      margin: const EdgeInsets.all(20),
      color: const Color.fromARGB(255, 28, 27, 27),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: prob,
                minHeight: 12,
                backgroundColor: Colors.grey,
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
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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

  Widget _buildFingerprintCard() {
    if (selectedSequence == null || _predictionResult == null) {
      return const SizedBox.shrink();
    }

    // 1. This is now a List<List<double>> (20 time steps, 30 features)
    final List<List<double>> sequence = selectedSequence!.features;

    // 2. Flatten temporarily JUST to calculate the overall metrics
    final List<double> allValues = sequence.expand((step) => step).toList();

    final double peak = allValues
        .map((e) => e.abs())
        .reduce((a, b) => max(a, b));
    final double magnitude = allValues
        .map((e) => e.abs())
        .reduce((a, b) => a + b);

    final double mean = allValues.reduce((a, b) => a + b) / allValues.length;
    final double volatility =
        allValues.map((e) => pow(e - mean, 2)).reduce((a, b) => a + b) /
        allValues.length;

    // 3. Compress the 20x30 matrix into a 30-bar signature for the chart
    // We find the highest spike (positive or negative) for each of the 30 features
    int numFeatures = sequence.isNotEmpty ? sequence.first.length : 0;
    List<double> signatureSpikes = List.generate(numFeatures, (featureIndex) {
      double maxSpike = 0.0;
      for (int t = 0; t < sequence.length; t++) {
        if (sequence[t][featureIndex].abs() > maxSpike.abs()) {
          maxSpike =
              sequence[t][featureIndex]; // Keep the sign for visual up/down
        }
      }
      return maxSpike;
    });

    double prob = _predictionResult!['predicted_probability'] ?? 0.0;
    final Color themeColor = prob > 0.5 ? Colors.redAccent : Colors.cyanAccent;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(
        0xFF161616,
      ), // Extra dark to contrast with the prediction card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- LEFT SIDE: Metrics ---
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TRANSACTION FINGERPRINT",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFingerprintStat(
                    "Peak Anomaly",
                    peak.toStringAsFixed(3),
                  ),
                  _buildFingerprintStat(
                    "Volatility",
                    volatility.toStringAsFixed(3),
                  ),
                  _buildFingerprintStat(
                    "Magnitude",
                    magnitude.toStringAsFixed(2),
                  ),
                  _buildFingerprintStat(
                    "Components",
                    "${signatureSpikes.length} Data Points",
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // --- RIGHT SIDE: The Spike Graph (Using MetricsCharts) ---
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 140, // Enough height to see the top and bottom spikes
                child: MetricsCharts.buildFingerprintChart(
                  signatureSpikes,
                  themeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for the metrics text layout
  Widget _buildFingerprintStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily:
                  'monospace', // Monospace fonts look great for raw data
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 40, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            selectedSequence == null
                ? "Select a sequence from the dropdown above to begin."
                : "Sequence ${selectedSequence!.id} selected.\nHit 'Run Fraud Detection' to view results.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: _searchAnchor(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (selectedSequence == null || _isLoading)
                            ? null
                            : _handleDetection,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.bolt),
                        label: Text(
                          _isLoading ? 'Processing...' : 'Run Fraud Detection',
                        ),
                        style: FilledButton.styleFrom(
                          shadowColor: Colors.grey,
                          // Rounded on the left, completely flat on the right
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(8),
                              right: Radius.zero,
                            ),
                          ),
                          minimumSize: const Size(0, 60),
                        ),
                      ),
                    ),

                    const SizedBox(width: 1),

                    // --- RIGHT SIDE: Settings Action ---
                    FilledButton(
                      // Ensure the button enables/disables at the exact same time as the main button
                      onPressed: (selectedSequence == null || _isLoading)
                          ? null
                          : _showSettingsDialog,
                      style: FilledButton.styleFrom(
                        shadowColor: Colors.grey,
                        padding:
                            EdgeInsets.zero, // Removes default text padding
                        // Flat on the left, rounded on the right
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.zero,
                            right: Radius.circular(8),
                          ),
                        ),
                        minimumSize: const Size(
                          60,
                          60,
                        ), // Forces a perfect square
                      ),
                      child: const Icon(Icons.settings),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),

              // ADDED: The Section Header
              const Text(
                "-- PREDICTION RESULTS --",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),

              // Display the placeholder if no results exist yet
              if (_predictionResult == null) ...[
                SizedBox(height: 100),
                _buildPlaceholderState(),
              ],

              // Display the actual results if they exist
              if (_predictionResult != null) ...[
                const SizedBox(height: 20),
                _buildResultCard(),
                const SizedBox(height: 20),
                _buildFingerprintCard(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  SearchAnchor _searchAnchor() {
    return SearchAnchor(
      searchController: _searchController,
      viewShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      viewConstraints: const BoxConstraints(maxHeight: 300),

      viewLeading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _searchController.closeView(_searchController.text);
        },
      ),

      viewTrailing: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Fetch New Sequences',
          onPressed: () {
            _fetchSequences();
            _searchController.closeView(_searchController.text);
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) _searchController.openView();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _searchController.clear();
            setState(() {
              selectedSequence = null;
              _predictionResult = null;
            });
            _searchController.closeView('');
          },
        ),
      ],
      builder: (context, controller) {
        return SearchBar(
          controller: controller,
          elevation: const WidgetStatePropertyAll(0),
          readOnly: true, // Prevents typing on the main screen widget
          leading: const Icon(Icons.search),
          hintText: 'Select a sequence...',
          onTap: () => controller.openView(),
          onChanged: (_) => controller.openView(),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
      suggestionsBuilder: (context, controller) async {
        if (_sequencesFuture == null) {
          return [
            SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Hit the refresh icon above to load sequences from the server.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ];
        }
        try {
          final sequences = await (_sequencesFuture ?? Future.value([]));

          // final query = controller.text.toLowerCase();
          // final filteredSequences = query.isEmpty
          //     ? sequences
          //     : sequences
          //           .where(
          //             (s) => s.id.toLowerCase().contains(query),
          //           )
          //           .toList();

          // if (filteredSequences.isEmpty) {
          //   return [
          //     const ListTile(
          //       title: Text('No sequences found.'),
          //     ),
          //   ];
          // }

          return sequences.map(
            (data) => ListTile(
              title: Text(data.id),
              subtitle: Text('Original Label: ${data.label}'),
              onTap: () {
                setState(() {
                  selectedSequence = data;
                  _predictionResult = null;
                  _searchController.closeView(data.id);
                });
              },
            ),
          );
        } catch (e) {
          // Clean error state with a manual retry button
          return [
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load sequences.\nPlease check your API connection.\n\nClick the refresh button above to try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ];
        }
      },
    );
  }
}
