import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Persistent keys
  static const _kPrimaryKey = 'theme_primary';
  static const _kSecondaryKey = 'theme_secondary';
  static const _kSurfaceKey = 'theme_surface';

  // Default colors
  Color _primary = const Color(0xFF171717);
  Color _secondary = const Color(0xFF444444);
  Color _surface = const Color(0xFFDA0037);

  ThemeProvider() {
    // Try loading saved colors; non-blocking
    _loadFromPrefs();
  }

  // getters
  Color get primary => _primary;
  Color get secondary => _secondary;
  Color get surface => _surface;

  // Update methods
  Future<void> updatePrimary(Color c) async {
    _primary = c;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrimaryKey, c.toARGB32());
  }

  Future<void> updateSecondary(Color c) async {
    _secondary = c;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSecondaryKey, c.toARGB32());
  }

  Future<void> updateSurface(Color c) async {
    _surface = c;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSurfaceKey, c.toARGB32());
  }

  ThemeData get theme {
    return ThemeData(
      fontFamily: 'Prompt',
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: _primary,
        secondary: _secondary,
        surface: _surface,
        onPrimary: const Color(0xFFEDEDED),
        onSecondary: Colors.black87,
        onSurface: const Color(0x0014ffec),
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
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_kPrimaryKey)) {
        _primary = Color(prefs.getInt(_kPrimaryKey)!);
      }
      if (prefs.containsKey(_kSecondaryKey)) {
        _secondary = Color(prefs.getInt(_kSecondaryKey)!);
      }
      if (prefs.containsKey(_kSurfaceKey)) {
        _surface = Color(prefs.getInt(_kSurfaceKey)!);
      }
      notifyListeners();
    } catch (e) {
      // ignore load errors, keep defaults
      debugPrint('ThemeProvider: failed to load prefs: $e');
    }
  }
}
