import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'consoles.dart';
import 'package:fl_fraud_detection/common/training.dart';
import 'package:fl_fraud_detection/common/detection.dart';

class ClientApp extends StatefulWidget {
  const ClientApp({super.key});

  @override
  State<ClientApp> createState() => _ClientAppState();
}

class _ClientAppState extends State<ClientApp> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = ['Consoles', 'Training', 'Fraud Detection'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _widgetOptions = [
    ClientConsoles(),
    TrainingPage(),
    DetectionPage(),
  ];

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
                'Fraud Detection Client App',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.terminal),
              title: const Text('Consoles'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.model_training),
              title: const Text('Training'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Fraud Detection'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
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
