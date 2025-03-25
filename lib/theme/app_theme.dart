import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme({bool isDark = true, Color accentColor = Colors.tealAccent}) {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        titleMedium: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 14,
        ),
      ),
      colorScheme: isDark
          ? ColorScheme.dark(
        primary: accentColor,
        onPrimary: Colors.black,
        surface: const Color(0xFF1F1F1F),
      )
          : ColorScheme.light(
        primary: accentColor,
        onPrimary: Colors.white,
        surface: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? Colors.grey[900]!.withValues(alpha: 0.95) : Colors.white,
        indicatorColor: accentColor.withValues(alpha: isDark ? 0.3 : 0.1),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  // For backward compatibility
  static final ThemeData darkTheme = getTheme(isDark: true, accentColor: Colors.tealAccent);
  static final ThemeData lightTheme = getTheme(isDark: false, accentColor: Colors.tealAccent);
}