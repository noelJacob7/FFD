import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'global_logger.dart';
import '../common/training.dart';
import '../common/detection.dart';
import 'evaluation.dart';

class ServerApp extends StatefulWidget {
  const ServerApp({super.key});

  @override
  State<ServerApp> createState() => _ServerAppState();
}

class _ServerAppState extends State<ServerApp> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = [
    'Server FFD App',
    'Consoles',
    'Training',
    'Fraud Detection',
    'Model Evaluation',
  ];

  final List<Widget> _widgetOptions = <Widget>[
    const Scaffold(
      body: Center(child: Text('Welcome to the Fraud Detection App!')),
    ),
    const GlobalLogger(),
    const TrainingPage(),
    const DetectionPage(),
    const EvaluationPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        forceMaterialTransparency: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 102, 48, 157),
              ),
              child: Text(
                'Fraud Detection App',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _selectedIndex == 0, // Highlight the active tab
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.terminal),
              title: const Text('Consoles'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.model_training),
              title: const Text('Training'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Fraud Detection'),
              selected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Evaluation'),
              selected: _selectedIndex == 4,
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                context.go('/');
              },
            ),
          ],
        ),
      ),

      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
    );
  }
}
