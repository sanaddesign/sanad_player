// lib/providers/theme_provider.dart

// Import Flutter material package for ThemeData and ChangeNotifier.
import 'package:flutter/material.dart';
// Import shared_preferences for persisting the theme preference.
import 'package:shared_preferences/shared_preferences.dart';
// Import our custom theme definitions (darkTheme, lightTheme).
import 'package:sanad_player/utils/theme.dart'; // Make sure path is correct.

// ThemeProvider manages the current theme of the application (light or dark).
// It extends ChangeNotifier to notify listeners about theme changes.
class ThemeProvider with ChangeNotifier {
  // Key to store the theme preference in shared preferences.
  static const String _themeModeKey = 'themeMode';

  // Private variable to hold the current theme mode (initially set to dark).
  ThemeMode _themeMode = ThemeMode.dark;

  // Getter to access the current theme mode.
  ThemeMode get themeMode => _themeMode;

  // Getter to provide the actual ThemeData based on the current theme mode.
  ThemeData get currentTheme {
    return _themeMode == ThemeMode.dark ? darkTheme : lightTheme;
  }

  // Constructor: Initializes the theme mode by loading the saved preference.
  ThemeProvider() {
    _loadThemeMode();
  }

  // Asynchronously loads the saved theme preference from shared preferences.
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Get the saved theme preference string (e.g., 'dark', 'light').
    final savedTheme = prefs.getString(_themeModeKey);
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark; // Default to dark if no preference or 'dark' saved.
    }
    notifyListeners(); // Notify listeners (widgets) that the theme has been loaded.
  }

  // Toggles the theme mode between dark and light.
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveThemeMode(_themeMode); // Save the new theme preference.
    notifyListeners(); // Notify listeners (widgets) about the change.
  }

  // Asynchronously saves the new theme preference to shared preferences.
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}