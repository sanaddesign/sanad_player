// lib/screens/smart_tools_screen.dart

import 'package:flutter/material.dart';

// A placeholder screen for Smart Tools functionalities.
class SmartToolsScreen extends StatelessWidget {
  const SmartToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Tools'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman, size: 80, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 20),
            Text(
              'Advanced Utilities & Converters',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '(Coming Soon)',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}