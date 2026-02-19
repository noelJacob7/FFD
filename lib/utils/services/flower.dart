import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Required for Timer/Duration
import '../logging.dart';

class FlowerService {
  Process? _process;

  Future<void> startServer() async {
    try {
      _process = await Process.start(
        'python3',
        ['-u', 'server.py'],
        runInShell: true,
        workingDirectory: '/home/noel/project/fl_fraud_detection/handler',
      );

      // Pipe output to logger so UI terminal can display Flask logs
      _process!.stdout.transform(utf8.decoder).listen((data) {
        AppLogger.logFlower('Flower: $data');
        print('Flower: $data');
      });
      _process!.stderr.transform(utf8.decoder).listen((log) {
        AppLogger.logFlower('Flower Log: $log');
        print('Flower Log: $log');
      });
      AppLogger.logFlower('Python server started with PID: ${_process!.pid}');
      print('Python server started with PID: ${_process!.pid}');
    } catch (e) {
      AppLogger.logFlower('Failed to start Python process: $e');
      print('Failed to start Python process: $e');
    }
  }
}
