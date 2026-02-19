import 'package:flutter/material.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  String _status = 'Idle';
  int _clientCount = 0;

  void _startServer() async {
    setState(() {
      _status = 'Starting server...';
    });
  }

  void _startTraining() {
    setState(() {
      _status = 'Training started...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SelectionArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: Text("Training status: $_status")),
                  ElevatedButton(
                    onPressed: _startServer,
                    child: const Text("Start Server"),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _startTraining,
                    child: const Text("Start Training"),
                  ),
                ],
              ),
            ),
            Text('Clients: $_clientCount')
          ],
        ),
      ),
    );
  }
}
