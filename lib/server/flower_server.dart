import 'package:fl_fraud_detection/common/consoles/system_console.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../utils/console.dart';
import '../utils/logging.dart';
import '../utils/services/flower.dart';
import '../utils/services/api.dart';
import '../utils/services/system.dart';

class FlowerServer extends StatefulWidget {
  const FlowerServer({super.key});

  @override
  State<FlowerServer> createState() => _FlowerServerState();
}

class _FlowerServerState extends State<FlowerServer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  StreamSubscription<String>? _portStatusSubscription;

  final _flowerService = FlowerService();
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    final systemService = SystemService();
    systemService.killPort(8080);

    _portStatusSubscription = SystemLogger.onPortKilled.stream.listen((
      killedPort,
    ) {
      if (killedPort == 'flower' && mounted) {
        setState(() {
          _status = 'Idle';
        });
      }
    });
  }

  @override
  void dispose() {
    _portStatusSubscription?.cancel();
    _flowerService.stopProcess();
    super.dispose();
  }

  void _startServer() async {
    await _flowerService.startServer(8080, ApiService.currentPort);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          'To connect clients open a public tcp port using \'ngrok tcp 8080\'',
        ),
        duration: Duration(seconds: 7),
      ),
    );
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
                    onPressed: (_status != "Running") ? _startServer : null,
                    child: const Text("Start Flower Server"),
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
