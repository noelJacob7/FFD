import 'package:flutter/material.dart';

import 'consoles.dart';

class ClientApp extends StatefulWidget {
  const ClientApp({super.key});

  @override
  State<ClientApp> createState() => _ClientAppState();
}

class _ClientAppState extends State<ClientApp> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = [
    'Client Server App',
    'Consoles',
    'Training',
    'Fraud Detection',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _widgetOptions = [
    const Scaffold(body: Center(child: Text('Welcome to the client side!'))),
    ClientConsoles(),
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
            // ListTile(
            //   leading: const Icon(Icons.model_training),
            //   title: const Text('Training'),
            //   selected: _selectedIndex == 2,
            //   onTap: () {
            //     _onItemTapped(2);
            //     Navigator.pop(context);
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.report),
            //   title: const Text('Fraud Detection'),
            //   selected: _selectedIndex == 3,
            //   onTap: () {
            //     _onItemTapped(3);
            //     Navigator.pop(context);
            //   },
            // ),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
    );
  }
}
