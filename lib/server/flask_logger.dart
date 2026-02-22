import 'package:flutter/material.dart';

import '../utils/logging.dart';
import '../utils/services/api.dart';
import '../utils/services/system.dart';
import '../utils/console.dart';

class FlaskLogger extends StatefulWidget {
  const FlaskLogger({super.key});

  @override
  State<FlaskLogger> createState() => _FlaskLoggerState();
}

class _FlaskLoggerState extends State<FlaskLogger> with AutomaticKeepAliveClientMixin {
  // Convention: Initialize the service class
  final ApiService _apiService = ApiService();
  String _status = 'Idle';
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final systemService = SystemService();
    systemService.killPort(5000);
    // Server will be started manually via button
  }

  @override
  void dispose() {
    _apiService.stopServer(); // Cleanup the sidecar
    super.dispose();
  }

  void _checkStatus() async {
    final result = await _apiService.getHealth();
    setState(() => _status = result);
  }

  void _startServer() async {
    setState(() {
      _status = 'Starting server...';
    });

    await _apiService.startServer();
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
                    onPressed: _startServer,
                    child: const Text('Start Server'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _checkStatus,
                    child: const Text('Check Health'),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Terminal area
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(height: 450, child: ConsoleWidget(logStream: AppLogger.flaskStream)),
            ),
          ],
        ),
      ),
    );
  }
}
