import 'dart:io';
import 'dart:convert';
import 'dart:async'; 

import '../logging.dart';
import 'system.dart';

class FlowerService {
  static Process? _process;
  
  static int _activeServerPort = 8080;
  static int get activeServerPort => _activeServerPort;

  Future<void> startServer(int port, int flaskPort) async {
    _activeServerPort = port;
    try {
      String dir = SystemService().getHandlerDir();
      
      _process = await Process.start(
        'python3',
        [
          '-u', 'server.py',
          '--port', port.toString(),             
          '--flask-port', flaskPort.toString()   
        ],
        runInShell: true,
        workingDirectory: dir,
      );

      _process!.stdout.transform(utf8.decoder).listen((data) {
        AppLogger.logFlower('Flower Server: $data');
      });
      _process!.stderr.transform(utf8.decoder).listen((log) {
        AppLogger.logFlower('Flower Server Log: $log');
      });
      
      AppLogger.logFlower('Flower server started with PID: ${_process!.pid}');
    } catch (e) {
      AppLogger.logFlower('Failed to start Flower server: $e');
    }
  }

  Future<bool> isRunning(int port) async {
    try {
      final socket = await Socket.connect(
        '127.0.0.1',
        port,
        timeout: const Duration(milliseconds: 500),
      );
      socket.destroy(); 
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> startClient(String clientData, String serverUrl, int flaskPort) async {
    try {
      String dir = SystemService().getHandlerDir();
      String datasetDir = 'data/$clientData';
      
      String cleanAddress = serverUrl
          .replaceAll('tcp://', '')
          .replaceAll('https://', '')
          .replaceAll('http://', '');
      
      // Check if the user only entered a port number
      if (int.tryParse(cleanAddress) != null) {
        cleanAddress = '127.0.0.1:$cleanAddress';
      }

      _process = await Process.start(
        'python3',
        [
          '-u', 'client.py',
          '--data', datasetDir,
          '--server', cleanAddress,
          '--flask-port', flaskPort.toString()
        ],
        runInShell: true,
        workingDirectory: dir,
      );

      _process!.stdout.transform(utf8.decoder).listen((data) {
        AppLogger.logFlower('Flower Client: $data');
      });
      _process!.stderr.transform(utf8.decoder).listen((log) {
        AppLogger.logFlower('Flower Client Log: $log');
      });
      
      AppLogger.logFlower('Flower client started with PID: ${_process!.pid}');
    } catch (e) {
      AppLogger.logFlower('Failed to start Flower client: $e');
    }
  }

  Future<void> stopProcess() async {
    if (_process != null) {
      bool killed = _process!.kill();
      
      if (killed) {
        AppLogger.logFlower('Sent kill signal to process (PID: ${_process!.pid})');
        AppLogger.logSystem('Sent kill signal to process (PID: ${_process!.pid})');
        
        _process = null; // Clear it from memory
      } else {
        AppLogger.logFlower('Attempted to kill process, but it may already be dead.');
        AppLogger.logSystem('Attempted to kill process, but it may already be dead.');
      }
    } else {
      AppLogger.logFlower('No active process found to stop.');
      AppLogger.logSystem('No active process found to stop.');
    }
  }
}