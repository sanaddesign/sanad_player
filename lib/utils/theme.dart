import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF2856A1); // الأزرق الداكن
  static const Color accentCyan = Color(0xFF0794BA);  // السماوي الزاهي
  static const Color primaryBackground = Color(0xFF0D1117); // الخلفية العامة
  static const Color secondaryBackground = Color(0xFF324867); // خلفية البطاقات والقوائم
  static const Color primaryText = Color(0xFFFFFFFF); // النص الأساسي
  static const Color secondaryText = Color(0xFFB0B0B0); // النص الثانوي
  static const Color iconColor = Color(0xFF0A7BD5); // لون الأيقونات
  static const Color errorColor = Colors.red; // لون الخطأ
}

ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true, // لتمكين واجهات Material 3 الحديثة
    brightness: Brightness.dark,
    fontFamily: 'Poppins', // أو 'Cairo' إن أردت دعمًا عربيًا أفضل

    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: AppColors.primaryBackground,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryBlue,
      secondary: AppColors.accentCyan,
      background: AppColors.primaryBackground,
      surface: AppColors.secondaryBackground,
      onPrimary: AppColors.primaryText,
      onSecondary: AppColors.primaryText,
      onBackground: AppColors.primaryText,
      onSurface: AppColors.primaryText,
      error: AppColors.errorColor,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.secondaryBackground,
      foregroundColor: AppColors.primaryText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryText),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.primaryText),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.secondaryText),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.secondaryText),
    ),

    iconTheme: const IconThemeData(
      color: AppColors.iconColor,
      size: 24,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentCyan,
      foregroundColor: AppColors.primaryText,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primaryText,
      unselectedLabelColor: AppColors.secondaryText,
      indicatorColor: AppColors.accentCyan,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
    ),


    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.secondaryBackground,
      selectedItemColor: AppColors.accentCyan,
      unselectedItemColor: AppColors.secondaryText,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
  );
}

ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',

    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: Colors.white70,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      secondary: AppColors.accentCyan,
      background: Colors.blueGrey,
      surface: Color(0xFF7EA5C3),
      onPrimary: Colors.blueGrey,
      onSecondary: Colors.black,
      onBackground: Colors.black,
      onSurface: Colors.black,
      error: AppColors.errorColor,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF79ACD5),
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.grey),
      bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
    ),

    iconTheme: const IconThemeData(
      color: AppColors.primaryBlue,
      size: 24,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentCyan,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primaryBlue,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppColors.primaryBlue,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
  );
}
