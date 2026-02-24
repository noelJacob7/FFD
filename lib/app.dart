import 'package:flutter/material.dart';
import '../server/global_logger.dart';
import '../server/training.dart';
import 'server/detection.dart';
import 'server/evaluation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = [
    'Fraud App Home',
    'Global Console',
    'Training',
    'Fraud Detection',
    'Evaluation',
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
              title: const Text('Global Console'),
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
          ],
        ),
      ),

      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
    );
  }
}
