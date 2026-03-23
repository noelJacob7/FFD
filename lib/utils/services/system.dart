import 'dart:io';
import 'package:path/path.dart' as p;

import '../logging.dart';

class SystemService {
  // 1. Create a global broadcast stream

  Future<void> killPort(int port) async {
    try {
      await Process.run('fuser', ['-k', '$port/tcp']);
      AppLogger.logSystem('Port $port has been cleared.');
      print('Port $port has been cleared.');
    } catch (e) {
      AppLogger.logSystem('Port was already clear or error occurred: $e');
      print('Port was already clear or error occurred: $e');
    }
  }

  String getHandlerDir() {
    // 1. Get the directory of the currently running Dart script
    final scriptDir = File(Platform.script.toFilePath()).parent.path;

    final targetDir = p.join(scriptDir, 'handler/');
    final cleanPath = p.normalize(targetDir);

    return cleanPath;
  }
}
