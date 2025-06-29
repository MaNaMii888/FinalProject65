import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _key = "theme_mode";
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() : _themeMode = ThemeMode.light {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_key);
    if (savedMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedMode,
        orElse: () => ThemeMode.light,
      );
      notifyListeners();
    }
  }

  static final lightTheme = ThemeData(
    primarySwatch: Colors.deepPurple,
    fontFamily: 'Prompt',
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFFA594F9),
      secondary: const Color(0xFFCDC1FF),
      surface: const Color(0xFFF5EFFF),
      background: const Color(0xFFE5D9F2),
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5EFFF),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      color: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Prompt',
      ),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Prompt',
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF424874),
      onPrimary: Color(0xFFF4EEFF),
      secondary: Color(0xFFA6B1E1),
      onSecondary: Color(0xFF424874),
      background: Color(0xFF424874),
      onBackground: Color(0xFFF4EEFF),
      surface: Color(0xFFDCD6F7),
      onSurface: Color(0xFF424874),
      error: Color(0xFFEF5350),
      onError: Color(0xFFF4EEFF),
    ),
    scaffoldBackgroundColor: const Color(0xFF424874),
    cardColor: const Color(0xFFDCD6F7),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      color: Color(0xFF424874),
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Prompt',
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Color(0xFFF4EEFF)),
      bodyMedium: TextStyle(color: Color(0xFFDCD6F7)),
      bodySmall: TextStyle(color: Color(0xFFA6B1E1)),
      labelLarge: TextStyle(color: Color(0xFFF4EEFF)),
      labelMedium: TextStyle(color: Color(0xFFDCD6F7)),
      labelSmall: TextStyle(color: Color(0xFFA6B1E1)),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFF4EEFF)),
    dividerColor: const Color(0xFFA6B1E1),
    shadowColor: const Color(0xFF424874),
  );
}
