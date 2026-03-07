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

  SequenceData? _selectedSequence;
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;

  Future<List<SequenceData>>? _sequencesFuture;

  // @override
  // void initState() {
  //   super.initState();
  //   _fetchSequences();
  // }

  void _fetchSequences() {
    setState(() {
      // Catch the error at the Future level so we can handle it in the UI
      _sequencesFuture = _apiService.getSequences().catchError((error) {
        throw error;
      });
    });
  }

  void _handleDetection() async {
    if (_selectedSequence == null) return;

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Detecting fraud for sequence ${_selectedSequence!.id}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final result = await _apiService.runPrediction(_selectedSequence!.id);

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

  Widget _buildResultCard() {
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
                child: FilledButton.icon(
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
                    shadowColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              if (_predictionResult != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildResultCard(),
                ),
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
              _selectedSequence = null;
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
                  _selectedSequence = data;
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
                    'Failed to load sequences.\nPlease check your connection.\n\nClick the refresh button above to try again.',
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
