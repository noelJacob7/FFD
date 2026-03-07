import 'dart:io';
import 'dart:async'; // Added for StreamController
import 'package:path/path.dart' as p;

import '../logging.dart';

class SystemService {
  // 1. Create a global broadcast stream
  static final StreamController<int> onPortKilled =
      StreamController<int>.broadcast();

  Future<void> killPort(int port) async {
    try {
      await Process.run('fuser', ['-k', '$port/tcp']);
      AppLogger.logSystem('Port $port has been cleared.');
      print('Port $port has been cleared.');

      // 2. Broadcast that the port was successfully killed
      onPortKilled.add(port);
    } catch (e) {
      AppLogger.logSystem('Port was already clear or error occurred: $e');
      print('Port was already clear or error occurred: $e');

      // We also broadcast here so if the server crashed and the port
      // is already clear, the UI button still properly resets.
      onPortKilled.add(port);
    }
  }

  String findHandlerDir() {
    // 1. Get the directory of the currently running Dart script
    final scriptDir = File(Platform.script.toFilePath()).parent.path;

    final targetDir = p.join(scriptDir, 'handler/');
    final cleanPath = p.normalize(targetDir);

    return cleanPath;
  }
}

