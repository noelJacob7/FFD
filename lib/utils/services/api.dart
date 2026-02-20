import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Required for Timer/Duration
import 'package:http/http.dart' as http;
import '../logging.dart';

class ApiService {
  Process? _process;
  final String _baseUrl = 'http://localhost:5000';

  Future<void> startServer() async {
    try {
      _process = await Process.start(
        'python3',
        ['-u', 'app.py'],
        runInShell: true,
        workingDirectory: '/home/noel/project/fl_fraud_detection/handler',
      );

      // Pipe output to logger so UI terminal can display Flask logs
      _process!.stdout.transform(utf8.decoder).listen((data) {
        AppLogger.logFlask('Flask: $data');
        print('Flask: $data');
      });
      _process!.stderr.transform(utf8.decoder).listen((log) {
        AppLogger.logFlask('Flask Log: $log');
        print('Flask Log: $log');
      });
      AppLogger.logFlask('Python server started with PID: ${_process!.pid}');
      print('Python server started with PID: ${_process!.pid}');
    } catch (e) {
      AppLogger.logFlask('Failed to start Python process: $e');
      print('Failed to start Python process: $e');
    }
  }

  // Improved: Retries the connection instead of giving up
  Future<String> getHealth({int retries = 5}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/get_health'))
            .timeout(const Duration(seconds: 2)); // Don't hang forever

        if (response.statusCode == 200) {
          return jsonDecode(response.body)['status'];
        }
      } on SocketException {
        AppLogger.logFlask('Server not ready, retrying ($i)...');
        print('Server not ready, retrying ($i)...');
        // Wait 1 second before trying again
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        AppLogger.logFlask('getHealth error: $e');
        return 'Error: $e';
      }
    }
    return 'Offline: Server failed to respond after $retries attempts';
  }
  
  Future<Map<String, dynamic>> getTrainingMetrics() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/training_metrics'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        AppLogger.logFlask('Failed to fetch metrics: ${response.statusCode}');
        return {'error': 'Failed to fetch metrics'};
      }
    } catch (e) {
      AppLogger.logFlask('getTrainingMetrics error: $e');
      return {'error': e.toString()};
    }
  }

  
  Future<void> stopServer() async {
    _process?.kill();
    _process = null;
  }
}
