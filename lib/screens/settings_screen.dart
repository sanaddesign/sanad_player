// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sanad_player/providers/theme_provider.dart';

// SettingsScreen is a StatelessWidget as it primarily displays options.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to get and toggle the current theme.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'), // Title for the settings screen
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Toggle Option
          ListTile(
            title: const Text('Dark Theme'),
            leading: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark, // Switch state based on current theme
              onChanged: (value) {
                themeProvider.toggleTheme(); // Toggle theme when switch is changed
              },
              activeColor: Theme.of(context).colorScheme.primary, // Primary color for active state
            ),
            onTap: () {
              // Tapping the ListTile also toggles the theme.
              themeProvider.toggleTheme();
            },
          ),
          const Divider(), // A visual separator

          // Placeholder for other settings
          ListTile(
            title: const Text('About SANAD PLAYER'),
            leading: const Icon(Icons.info),
            onTap: () {
              // TODO: Navigate to an About screen or show dialog
              print('About tapped');
            },
          ),
          const Divider(),

          ListTile(
            title: const Text('Version'),
            leading: const Icon(Icons.verified),
            trailing: Text('1.0.0', style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              print('Version tapped');
            },
          ),
        ],
      ),
    );
  }
}