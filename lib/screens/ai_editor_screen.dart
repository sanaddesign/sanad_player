// lib/screens/ai_editor_screen.dart

import 'package:flutter/material.dart';

// A placeholder screen for AI Editor functionalities.
class AiEditorScreen extends StatelessWidget {
  const AiEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Editor'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 80, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 20),
            Text(
              'AI-Powered Video Editing Tools',
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