import 'dart:async';

class AppLogger {
  static final StreamController<String> _flaskcontroller =
      StreamController<String>.broadcast();
  static final StreamController<String> _flowercontroller =
      StreamController<String>.broadcast();
  static final StreamController<String> _systemcontroller =
      StreamController<String>.broadcast();

  static Stream<String> get flaskStream => _flaskcontroller.stream;
  static Stream<String> get flowerStream => _flowercontroller.stream;
  static Stream<String> get systemStream => _systemcontroller.stream;

  static String cleanLog(String rawLog) {
    // This regex matches the 'ESC[' followed by numbers and 'm'
    final ansiRegex = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');
    return rawLog.replaceAll(ansiRegex, '');
  }

  static void logFlask(String message) {
    // Ensure newline trimmed and emit
    String cleanMessage = cleanLog(message);
    _flaskcontroller.add(cleanMessage.trimRight());
  }

  static void logFlower(String message) {
    // Ensure newline trimmed and emit
    String cleanMessage = cleanLog(message);
    _flowercontroller.add(cleanMessage.trimRight());
  }

  static void logSystem(String message) {
    // Ensure newline trimmed and emit
    _systemcontroller.add(message.trimRight());
  }

  static void dispose() {
    _flaskcontroller.close();
    _flowercontroller.close();
    _systemcontroller.close();
  }
}
