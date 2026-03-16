import 'package:flutter/material.dart';
import 'dart:async';

import '../../utils/console.dart';
import '../../utils/logging.dart';
import '../../utils/services/system.dart';
import '../../utils/services/flower.dart';
import '../../utils/services/api.dart';

class ClientFlower extends StatefulWidget {
  const ClientFlower({super.key});

  @override
  State<ClientFlower> createState() => _ClientFlowerState();
}

class _ClientFlowerState extends State<ClientFlower>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  StreamSubscription<int>? _portStatusSubscription;

  final flowerService = FlowerService();
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    // final systemService = SystemService();
    // systemService.killPort(8080);

    _portStatusSubscription = SystemService.onPortKilled.stream.listen((
      killedPort,
    ) {
      if (killedPort == 8080 && mounted) {
        setState(() {
          _status = 'Idle';
        });
      }
    });
  }

  @override
  void dispose() {
    _portStatusSubscription?.cancel();
    super.dispose();
  }

  Future<(String, String)?> _showDialog() async {
    return await showDialog<(String, String)>(
      context: context,
      // Prevents dismissing by clicking outside, forcing them to use Cancel/Connect
      barrierDismissible: false,
      builder: (context) => const DatasetSelectionDialog(),
    );
  }

  void _startClient() async {
    final result = await _showDialog();

    if (result == null) {
      return; // User hit cancel
    }

    // Destructure the record
    final clientDataset = result.$1;
    final serverUrl = result.$2;

    await flowerService.startClient(clientDataset, serverUrl);

    setState(() {
      _status = "Running";
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SelectionArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: Text("Flower Server status: $_status")),
                  ElevatedButton(
                    onPressed: (_status != "Running") ? _startClient : null,
                    child: const Text("Start Flower Client"),
                  ),
                ],
              ),
            ),
            Divider(),

            // Terminal area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 450,
                  child: ConsoleWidget(logStream: AppLogger.flowerStream),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//CUSTOM WIDGET
class DatasetSelectionDialog extends StatefulWidget {
  const DatasetSelectionDialog({super.key});

  @override
  State<DatasetSelectionDialog> createState() => _DatasetSelectionDialogState();
}

class _DatasetSelectionDialogState extends State<DatasetSelectionDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _urlController = TextEditingController();

  List<String> _dataFiles = [];
  String? _selectedFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  @override
  void dispose() {
    _urlController.dispose(); // Always dispose controllers!
    super.dispose();
  }

  Future<void> _fetchFiles() async {
    try {
      final files = await _apiService.getDataFiles();

      setState(() {
        _dataFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching files: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure Client Node'), // Updated title
      // Wrap content in a Column to hold both the Dropdown and TextField
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min, // Keeps dialog compact
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_dataFiles.isEmpty)
                  const Text("No .npz files found.")
                else ...[
                  const SizedBox(height: 20),
                  const Text(
                    "1. Select Dataset:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    focusColor: Colors.transparent,
                    dropdownColor: const Color.fromARGB(255, 234, 229, 234),
                    value: _selectedFile,
                    hint: const Text("Select a dataset"),
                    items: _dataFiles.map((String fileName) {
                      return DropdownMenuItem<String>(
                        value: fileName,
                        child: Text(fileName),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFile = newValue;
                        });
                      }
                    },
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  "2. Server Connection:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'ngrok URL (or leave blank for local)',
                    hintText: 'e.g., tcp://0.tcp.ngrok.io:14321',
                    border: OutlineInputBorder(),
                    isDense: true, // Makes the text field slightly less bulky
                  ),
                ),
              ],
            ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          // Disable if loading, no file selected, OR no URL typed (if URL is strictly required)
          onPressed:
              (_isLoading ||
                  _selectedFile == null ||
                  _urlController.text.trim().isEmpty)
              ? null
              : () {
                  // Return both the dataset and the URL as a Record
                  Navigator.pop(context, (
                    _selectedFile!,
                    _urlController.text.trim(),
                  ));
                },
          child: const Text("Connect"),
        ),
      ],
    );
  }
}
