import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Required for Timer/Duration

import '../logging.dart';
import 'system.dart';

class FlowerService {
  Process? _process;

  Future<void> startServer() async {
    try {
      String dir = SystemService().findHandlerDir();
      _process = await Process.start(
        'python3',
        ['-u', 'server.py'],
        runInShell: true,
        workingDirectory: dir,
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

  Future<bool> isServerRunning() async {
    try {
      // Attempt a raw TCP connection to localhost on the target port
      final socket = await Socket.connect(
        '127.0.0.1',
        8080,
        timeout: const Duration(milliseconds: 500),
      );

      // If we get here, the connection succeeded! The port is actively in use.
      socket.destroy(); // Instantly close it so we don't hold up the server
      return true;
    } catch (e) {
      // Connection refused or timed out. The server is not up yet.
      return false;
    }
  }

  Future<void> startClient(String clientData) async {
    try {
      String dir = SystemService().findHandlerDir();
      String datasetDir = 'data/$clientData';
      _process = await Process.start(
        'python3',
        ['-u', 'client.py', datasetDir],
        runInShell: true,
        workingDirectory: dir,
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
