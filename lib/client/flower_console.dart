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
    final systemService = SystemService();
    systemService.killPort(8080);

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

  Future<String?> _showDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => const DatasetSelectionDialog(),
    );
  }

  void _startClient() async {
    //get data from api
    final clientDataset = await _showDialog();

    if (clientDataset == null) {
      return;
    }
    await flowerService.startClient(clientDataset);
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

  List<String> _dataFiles = [];
  String? _selectedFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
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
      title: const Text('Select a Dataset'),

      // CONTENT AREA
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _dataFiles.isEmpty
          ? const Text("No .npz files found.")
          : DropdownButton<String>(
              isExpanded: true,
              focusColor: Colors.transparent,
              menuWidth: 250,
              itemHeight: 49,
              menuMaxHeight: 200,
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

      // BUTTONS AREA
      actions: [
        // CANCEL BUTTON
        TextButton(
          onPressed: () {
            Navigator.pop(context, null); // Return null
          },
          child: const Text("Cancel"),
        ),

        // CONFIRM BUTTON
        ElevatedButton(
          // Disable button if loading or no file selected
          onPressed: (_isLoading || _selectedFile == null)
              ? null
              : () {
                  Navigator.pop(
                    context,
                    _selectedFile,
                  ); // Return the selected string
                },
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}
