import 'package:flutter/material.dart';
import '../utils/console.dart';
import '../utils/logging.dart';
import '../utils/services/flower.dart';
import '../utils/services/system.dart';

class FlowerLogger extends StatefulWidget {
  const FlowerLogger({super.key});

  @override
  State<FlowerLogger> createState() => _FlowerLoggerState();
}

class _FlowerLoggerState extends State<FlowerLogger>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final flowerService = FlowerService();

   @override
  void initState() {
    super.initState();
    final systemService = SystemService();
    systemService.killPort(8080);
    // Server will be started manually via button
  }

  void _startServer() async {
    // Convention: Initialize the service class
    await flowerService.startServer();
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
                  const Expanded(child: Text("Flower Logs")),
                  ElevatedButton(
                    onPressed: _startServer,
                    child: const Text("Start Flower Server"),
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
                child: ConsoleWidget(logStream: AppLogger.flowerStream),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
