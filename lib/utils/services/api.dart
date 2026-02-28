import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Required for Timer/Duration
import 'package:http/http.dart' as http;
import '../logging.dart';
import 'data_manager.dart';

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

  Future<List<SequenceData>> getSequences() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/get_sequences'))
          .timeout(
            const Duration(seconds: 5),
          ); // Always use timeouts for network calls

      if (response.statusCode == 200) {
        // 1. Decode the JSON string into a Dart Map
        final Map<String, dynamic> decodedJson = jsonDecode(response.body);

        // 2. Convert the Map into a strongly-typed List
        List<SequenceData> sequences = [];
        decodedJson.forEach((key, value) {
          sequences.add(
            SequenceData.fromJson(key, value as Map<String, dynamic>),
          );
        });

        return sequences;
      } else {
        // Handle custom errors (like the 500 "Data not initialized" from your Flask code)
        final errorPayload = jsonDecode(response.body);
        AppLogger.logFlask('Failed to fetch sequences: ${response.statusCode}');
        throw Exception(
          errorPayload['error'] ??
              'Server returned status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Failed to fetch sequences: $e');
      AppLogger.logFlask('getSequences error: $e');
      rethrow; // Rethrow so your UI can catch it and show an error message
    }
  }

  // The Detection Function
  Future<Map<String, dynamic>> runPrediction(String sequenceId) async {
    try {
      // Pass the ID to Flask so it knows which sequence to load from X_DATA
      final response = await http
          .get(Uri.parse('$_baseUrl/predict?id=$sequenceId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        AppLogger.logFlask('Failed to run prediction: ${response.statusCode}');
        throw Exception('Failed to run prediction: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.logFlask('runPrediction Error: $e');
      print('runPrediction Error: $e');
      rethrow;
    }
  }

  Future<List<String>> getModels() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/get_models'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return List<String>.from(data['models']);
      } else {
        final errorData = jsonDecode(response.body);
        AppLogger.logFlask('Failed to fetch models: ${response.statusCode}');
        throw Exception(errorData['error'] ?? 'Unknown error fetching models');
      }
    } catch (e) {
      AppLogger.logFlask('getModels Error: $e');
      print('Failed to fetch models: $e');
      rethrow; // Pass the error to the UI so you can show a Snackbar or error text
    }
  }

  Future<EvaluationMetrics> getEvaluationMetrics(String modelName) async {
    try {
      // Safely encode the model name in case it has spaces or special characters
      final encodedModelName = Uri.encodeComponent(modelName);

      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/get_evaluation_metrics?model=$encodedModelName',
            ),
          )
          // INCREASED TIMEOUT: Loading Keras and running inference takes time!
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return EvaluationMetrics.fromJson(data);
      } else {
        // This will catch your 400 (No model provided) and 404 (Model not found) errors
        final errorData = jsonDecode(response.body);
        AppLogger.logFlask(
          'Failed to fetch evaluation metrics: ${response.statusCode}',
        );
        throw Exception(
          errorData['error'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.logFlask('getEvaluationMetrics Error: $e');
      print('Failed to evaluate model: $e');
      rethrow;
    }
  }

  Future<void> stopServer() async {
    _process?.kill();
    _process = null;
  }
}
