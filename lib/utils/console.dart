import 'dart:async';
import 'package:flutter/material.dart';
// import 'logging.dart';

class ConsoleWidget extends StatefulWidget {
  final Stream<String> logStream;
  final String title; // NEW: To label the Console

  const ConsoleWidget({
    super.key,
    required this.logStream,
    this.title = 'Console', // Default title
  });

  @override
  State<ConsoleWidget> createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
  final List<String> _logs = []; // The logs are stored here
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _sub;

  // NEW: Function to clear the screen
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    // Scroll to bottom logic...
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _sub = widget.logStream.listen(_addLog);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // NEW: Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[900], // Slightly lighter than background
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                // The Clear Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 18),
                  tooltip: 'Clear Console',
                  onPressed: _clearLogs, // Calls the clear function
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // Removes extra padding
                ),
              ],
            ),
          ),
          
          // The Logs List
          Expanded( // Important: Use Expanded so the list fills the remaining space
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Text(
                  _logs[index],
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'Courier',
                    fontSize: 18,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}