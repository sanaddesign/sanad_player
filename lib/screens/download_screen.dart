// lib/screens/download_screen.dart

import 'package:flutter/material.dart';

// A placeholder screen for the Download/Stream functionality.
class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download & Stream'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_download, size: 80, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 20),
            Text(
              'Download or Stream from Social Media',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '(Coming Soon - Advanced Feature)',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}