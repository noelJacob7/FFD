import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelect extends StatelessWidget {
  const RoleSelect({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Spacer(flex: 1),
            Card(
              elevation: 2,
              shadowColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[800]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  height: 300,
                  width: 300,
                  child: Column(
                    spacing: 20,
                    children: [
                      SizedBox(height: 10),
                      Text('Select the ROLE'),
                      SizedBox(height: 60),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(8),
                          ),
                        ),
                        onPressed: () => context.go('/server'),
                        icon: const Icon(Icons.dns),
                        label: const Text('Server'),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(8),
                          ),
                        ),
                        onPressed: () => context.go('/client'),
                        icon: const Icon(Icons.computer),
                        label: const Text('Client'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
