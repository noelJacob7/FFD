import 'dart:io';
import '../logging.dart';

class SystemService {
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
}
