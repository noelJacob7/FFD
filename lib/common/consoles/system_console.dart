import 'package:flutter/material.dart';
import 'dart:async';

import 'package:fl_fraud_detection/utils/services/api.dart';
import 'package:fl_fraud_detection/utils/services/flower.dart';
import '../../utils/console.dart';
import '../../utils/logging.dart';
import '../../utils/services/system.dart';

class SystemLogger extends StatefulWidget {
  const SystemLogger({super.key});

  static final StreamController<String> onPortKilled =
      StreamController<String>.broadcast();
  @override
  State<SystemLogger> createState() => _SystemLoggerState();
}

class _SystemLoggerState extends State<SystemLogger>
    with AutomaticKeepAliveClientMixin {

  final SystemService _systemService = SystemService();
  final FlowerService _flowerService = FlowerService();

  @override
  bool get wantKeepAlive => true;

  void _showKillDialog() {
    String? selectedPort; // Variable to store the selection
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Allows the dialog to track state
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Ports'),
            content: DropdownMenu<String>(
              width: 230,
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'flask', label: 'Flask'),
                DropdownMenuEntry(value: 'flower', label: 'Flower'),
                DropdownMenuEntry(value: 'all', label: 'All Ports'),
              ],
              onSelected: (value) {
                // Update the local variable when a user clicks an item
                setState(() {
                  selectedPort = value;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedPort != null
                    ? () {
                        // Only execute if selectedPort is NOT null (not empty)
                        if (selectedPort == 'all') {
                          _systemService.killPort(ApiService.currentPort);
                          SystemLogger.onPortKilled.add('flask');
                          _flowerService.stopProcess();
                          _systemService.killPort(FlowerService.activeServerPort);
                          SystemLogger.onPortKilled.add('flower');
                        } else if (selectedPort == 'flower') {
                          _flowerService.stopProcess();
                          _systemService.killPort(FlowerService.activeServerPort);
                          SystemLogger.onPortKilled.add('flower');
                        } else {
                          _systemService.killPort(ApiService.currentPort);
                          SystemLogger.onPortKilled.add('flask');
                        }
                        Navigator.pop(context);
                      }
                    : null, // If it is null, this button does nothing
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
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
                  const Expanded(child: Text("System Logs")),
                  ElevatedButton(
                    onPressed: _showKillDialog,
                    child: const Text("Kill Ports"),
                  ),
                ],
              ),
            ),
            Divider(),

            // Terminal area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: SizedBox(
                  height: 240,
                  child: ConsoleWidget(logStream: AppLogger.systemStream),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
