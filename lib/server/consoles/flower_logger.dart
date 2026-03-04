import 'package:flutter/material.dart';
import 'dart:async';

import '../../utils/console.dart';
import '../../utils/logging.dart';
import '../../utils/services/flower.dart';
import '../../utils/services/system.dart';

class FlowerLogger extends StatefulWidget {
  const FlowerLogger({super.key});

  @override
  State<FlowerLogger> createState() => _FlowerLoggerState();
}

class _FlowerLoggerState extends State<FlowerLogger>
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

  void _startServer() async {
    await flowerService.startServer();
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
