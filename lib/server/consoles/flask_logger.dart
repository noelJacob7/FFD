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
  StreamSubscription<int>? _portStatusSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _portStatusSubscription = SystemService.onPortKilled.stream.listen((
      killedPort,
    ) {
      if (killedPort == 5000 && mounted) {
        setState(() {
          _status = 'Offline';
        });
      }
    });

    _runStartupSequence();
  }

  Future<void> _runStartupSequence() async {
    final SystemService systemService = SystemService();

    await systemService.killPort(5000);

    if (mounted) {
      _startServer();
    }
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

  void _startServer() async {
    setState(() {
      _status = 'Starting server...';
    });
    await _apiService.startServer();
    if (mounted) {
      setState(() {
        _status = 'READY';
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
                    onPressed: (_status == 'Offline') ? _startServer : null,
                    child: const Text('Start Server'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _status == 'Offline' ? null : _checkStatus,
                    child: const Text('Check Health'),
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
