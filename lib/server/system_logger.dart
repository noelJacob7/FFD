import 'package:flutter/material.dart';
import '../utils/console.dart';
import '../utils/logging.dart';
import '../utils/services/system.dart';

class SystemLogger extends StatefulWidget {
  const SystemLogger({super.key});

  @override
  State<SystemLogger> createState() => _SystemLoggerState();
}

class _SystemLoggerState extends State<SystemLogger>
    with AutomaticKeepAliveClientMixin {
  final SystemService _systemService = SystemService();
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
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: '5000', label: 'Flask (5000)'),
                DropdownMenuEntry(value: '8080', label: 'Flower (8080)'),
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
                onPressed: () {
                  // 1. Only execute if selectedPort is NOT null (not empty)
                  if (selectedPort != null) {
                    _killPorts(selectedPort!);
                    Navigator.pop(context);
                  }
                  // 2. If it is null, this button does nothing
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _killPorts(String port) {
    if (port == 'all') {
      _systemService.killPort(5000);
      _systemService.killPort(8080);
    } else {
      _systemService.killPort(int.parse(port));
    }
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 240,
                child: ConsoleWidget(logStream: AppLogger.systemStream),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
