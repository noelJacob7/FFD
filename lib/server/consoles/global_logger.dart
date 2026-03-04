import 'package:flutter/material.dart';
import 'flask_logger.dart';
import 'flower_logger.dart';
import 'system_logger.dart';

class GlobalLogger extends StatelessWidget {
  const GlobalLogger({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight:0, 
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Flask', icon: Icon(Icons.api)),
              Tab(text: 'Flower', icon: Icon(Icons.account_tree)),
              Tab(text: 'System', icon: Icon(Icons.error_outline)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FlaskLogger(),
            FlowerLogger(),
            SystemLogger(),
          ],
        ),
      ),
    );
  }
}
