import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/Screen/dashboard.dart'; // หน้าหลักหลังล็อกอิน
import 'package:project01/Screen/login.dart'; // เพิ่ม import
import 'package:project01/Screen/page/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'dart:async';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load theme mode
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString("theme_mode");
      final themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedMode,
        orElse: () => ThemeMode.light,
      );

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set system UI
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      runApp(
        ChangeNotifierProvider(
          create: (_) => ThemeProvider.withMode(themeMode),
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Error: $error');
      debugPrint('Stack: $stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Your App Name',
          debugShowCheckedModeBanner: false,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasData) {
                return const DashboardPage(); // หน้าหลักสำหรับผู้ใช้ที่ล็อกอินแล้ว
              }
              return const LoginPage(); // หน้าล็อกอินสำหรับผู้ใช้ที่ยังไม่ได้ล็อกอิน
            },
          ),
          routes: {
            '/login': (context) => const LoginPage(),
            '/dashboard': (context) => const DashboardPage(),
            '/profile': (context) => const ProfilePage(),
          },
          theme: themeProvider.theme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                physics: const BouncingScrollPhysics(),
              ),
              child: child!,
            );
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder:
                  (context) => Scaffold(
                    appBar: AppBar(title: const Text('ไม่พบหน้าที่ต้องการ')),
                    body: const Center(child: Text('ไม่พบหน้าที่ต้องการ')),
                  ),
            );
          },
        );
      },
    );
  }
}

// เพิ่ม helper method สำหรับสร้าง MaterialColor
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  ThemeProvider.withMode(this._themeMode);

  ThemeMode get themeMode => _themeMode;

  ThemeData get theme => _themeMode == ThemeMode.light ? lightTheme : darkTheme;
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF433D8B),
      brightness: Brightness.dark,
      primary: const Color(0xFF433D8B),
      secondary: const Color(0xFFC8ACD6),
      surface: const Color(0xFF2E236C),
      background: const Color(0xFF17153B),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF17153B),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      color: Color(0xFF2E236C),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Prompt',
        color: Colors.white,
      ),
    ),
  );

  static final lightTheme = ThemeData(
    primarySwatch: createMaterialColor(const Color(0xFFA594F9)),
    fontFamily: 'Prompt',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFA594F9), // สีม่วงหลัก
      brightness: Brightness.light,
      primary: const Color(0xFFA594F9), // ม่วงเข้ม
      secondary: const Color(0xFFCDC1FF), // ม่วงอ่อน
      surface: const Color(0xFFF5EFFF), // พื้นหลังอ่อน
      background: const Color(0xFFE5D9F2), // พื้นหลังเข้ม
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
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
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  void setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("theme_mode", mode.toString());
  }
}

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder:
          (context, themeProvider, _) => Switch(
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          // ...other items...
          ListTile(title: const Text('เปลี่ยนธีม'), trailing: ThemeSwitcher()),
        ],
      ),
    );
  }
}
