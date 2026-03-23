import 'package:fl_fraud_detection/common/consoles/system_console.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../../utils/logging.dart';
import '../../utils/services/api.dart';
import '../../utils/services/system.dart';
import '../../utils/console.dart';

class FlaskLogger extends StatefulWidget {
  const FlaskLogger({super.key});

  @override
  State<FlaskLogger> createState() => _FlaskLoggerState();
}

class _FlaskLoggerState extends State<FlaskLogger>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  String _status = 'Offline';
  StreamSubscription<String>? _portStatusSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // The stream now checks against the dynamically selected port
    _portStatusSubscription = SystemLogger.onPortKilled.stream.listen((
      killedPort,
    ) {
      if (killedPort == 'flask' && mounted) {
        setState(() {
          _status = 'Offline';
        });
      }
    });

    // // Schedule the dialog to show AFTER the initial build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showPortDialog();
      }
    });
  }

  @override
  void dispose() {
    _apiService.stopServer();
    _portStatusSubscription?.cancel();
    super.dispose();
  }

  void _checkStatus() async {
    final result = await _apiService.getHealth();
    setState(() => _status = result);
  }

  // --- CUSTOM PORT DIALOG ---
  void _showPortDialog() {
    final TextEditingController portController = TextEditingController(
      text: ApiService.currentPort.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Flask Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the port you want to run the Flask API on:'),
            const SizedBox(height: 10),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Port Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              int? selectedPort = int.tryParse(portController.text);
              if (selectedPort != null) {
                Navigator.pop(context); // Close dialog
                _startServer(selectedPort);
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _startServer(int port) async {
    setState(() {
      _status = 'Starting server on $port...';
    });

    // Kill the port first just to be safe before starting
    await SystemService().killPort(port);
    await _apiService.startServer(port);

    if (mounted) {
      setState(() {
        _status = 'READY on port $port';
      });
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
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(child: Text('API Status: $_status')),

                  ElevatedButton(
                    onPressed: _status == 'Offline' ? null : _checkStatus,
                    child: const Text('Check Health'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_status == 'Offline') ? _showPortDialog : null,
                    child: const Text('Start API'),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Terminal area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 450,
                  child: ConsoleWidget(logStream: AppLogger.flaskStream),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
