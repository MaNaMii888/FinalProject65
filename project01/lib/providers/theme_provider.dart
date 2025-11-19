import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData get theme {
    return ThemeData(
      fontFamily: 'Prompt',
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF444444),
        secondary: const Color(0xFFDA0037),
        surface: const Color(0xFF171717),
        onPrimary: const Color(0xFFEDEDED),
        onSecondary: Colors.black87,
        onSurface: const Color(0xFFEDEDED),
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
}
