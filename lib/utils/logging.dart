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

  static void _processAndEmit(String message, StreamController<String> controller) {
    // 1. Clean ANSI codes and remove carriage returns (\r) which cause weird line breaks
    String cleanMessage = cleanLog(message).replaceAll('\r', '');
    

    List<String> lines = cleanMessage.split('\n');
    
    for (String line in lines) {
      String trimmedLine = line.trim();
      // Add the line to the console if it actually contains text
      if (trimmedLine.isNotEmpty) {
        controller.add(trimmedLine);
      }
    }
  }

  static void logFlask(String message) {
    _processAndEmit(message, _flaskcontroller);
  }

  static void logFlower(String message) {
    _processAndEmit(message, _flowercontroller);
  }

  static void logSystem(String message) {
    _processAndEmit(message, _systemcontroller);
  }

  static void dispose() {
    _flaskcontroller.close();
    _flowercontroller.close();
    _systemcontroller.close();
  }
}