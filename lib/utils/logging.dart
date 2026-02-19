import 'dart:async';

class AppLogger {
  static final StreamController<String> _flaskcontroller = StreamController<String>.broadcast();
  static final StreamController<String> _flowercontroller = StreamController<String>.broadcast();
  static final StreamController<String> _systemcontroller = StreamController<String>.broadcast();

  static Stream<String> get flaskStream => _flaskcontroller.stream;
  static Stream<String> get flowerStream => _flowercontroller.stream;
  static Stream<String> get systemStream => _systemcontroller.stream;

  static void logFlask(String message) {
    // Ensure newline trimmed and emit
    _flaskcontroller.add(message.trimRight());
  }

  static void logFlower(String message) {
    // Ensure newline trimmed and emit
    _flowercontroller.add(message.trimRight());
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
