// lib/main.dart

// Import the Flutter material package.
// This package contains widgets necessary for building Material Design UI.
import 'package:flutter/material.dart';
// Import our custom application widget from app.dart.
// This is the root widget of our SANAD PLAYER application.
import 'package:sanad_player/app.dart'; // Make sure this path is correct based on your project name.

// Import the provider package.
import 'package:provider/provider.dart'; // Add this line
// Import our ThemeProvider.
import 'package:sanad_player/providers/theme_provider.dart'; // Add this line

// The main function is the entry point of any Flutter application.
// It is the entry point for the execution of your Flutter application.

void main() {
  // WidgetsFlutterBinding.ensureInitialized(); is important if you need to run Flutter plugins before runApp.
  // For shared_preferences, it's often a good practice to ensure this.
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized.

  runApp(
    // ChangeNotifierProvider makes a ChangeNotifier available to its descendants.
    // It's used here to provide our ThemeProvider throughout the app.
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(), // Create an instance of ThemeProvider.
      child: const SanadPlayerApp(), // Our main app widget.
    ),
  );
}