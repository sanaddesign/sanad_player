// lib/app.dart

// Import necessary Flutter material package.
// This package contains widgets for implementing Material Design.
import 'package:flutter/material.dart';

// Import our custom constants file for application-wide constants.
// This path should be relative to your project structure.
import 'package:sanad_player/utils/constants.dart'; // Make sure this path is correct based on your project name.
// Import our custom theme file for defining the app's visual theme.
// This path should be relative to your project structure.
import 'package:sanad_player/utils/theme.dart';     // Make sure this path is correct based on your project name.
import 'package:sanad_player/screens/media_list_screen.dart';
import 'package:provider/provider.dart'; // Add this line
import 'package:sanad_player/providers/theme_provider.dart'; // Add this line
import 'package:sanad_player/screens/home_screen.dart';
// SanadPlayerApp is the root widget of our application.
// It defines the overall structure, theme, and initial navigation.
class SanadPlayerApp extends StatelessWidget {
  // Constructor for SanadPlayerApp.
  // The 'super.key' is passed to the StatelessWidget constructor.
  const SanadPlayerApp({super.key});

  @override
  // The build method describes the user interface for this widget.
  // It returns a widget tree that Flutter uses to render on screen.
  Widget build(BuildContext buildContext) {
    // MaterialApp is a foundational widget for Material Design apps.
    // It provides necessary infrastructure like navigation, theming, etc.
    return MaterialApp(
      // The 'title' property sets the title of the application.
      // This is used by the device's multitasking UI (e.g., when viewing recent apps).
      title: appName, // Using the constant appName defined in constants.dart

      // The 'theme' property defines the visual styling for the entire app.
      // We are using our custom darkTheme defined in theme.dart.
      // The 'theme' property now dynamically picks the theme from the ThemeProvider.
      theme: Provider.of<ThemeProvider>(buildContext).currentTheme,

      // The 'home' property defines the initial screen that is displayed when the app starts.
      // For now, it's a simple placeholder to verify our setup and theme.
      // This will later be replaced by our SplashScreen widget.
      home: const HomeScreen(), // تطبيقنا سيبدأ الآن بشاشة MediaListScreen
    );
  }
}