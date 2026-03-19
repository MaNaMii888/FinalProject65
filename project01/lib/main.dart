import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/Screen/dashboard.dart'; // หน้าหลักหลังล็อกอิน
import 'package:project01/Screen/login.dart'; // เพิ่ม import
import 'package:project01/Screen/splash_screen.dart';
import 'package:project01/Screen/page/profile/profile_page.dart';
import 'package:project01/providers/theme_provider.dart';
import 'package:project01/providers/post_provider.dart';
import 'package:provider/provider.dart';
import 'package:project01/firebase_options.dart';
import 'package:project01/services/notifications_service.dart';
import 'package:project01/services/chat_notification_service.dart';
import 'dart:async';
import 'dart:io';
// ignore: unused_import
import 'package:project01/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runZonedGuarded(
    () async {
      // ThemeProvider will load saved theme from SharedPreferences internally.

      // Initialize Firebase with diagnostics.
      bool firebaseInitialized = false;
      Object? initError;
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        // Initialize notifications service
        await NotificationService.initialize();
        // Request Android 13+ Notification Permissions (if applicable)
        await NotificationService.requestAndroidPermission();
        firebaseInitialized = true;
      } catch (e, st) {
        firebaseInitialized = false;
        initError = e;
        debugPrint('Firebase.initializeApp error: $e');
        debugPrintStack(stackTrace: st);
      }

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
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => PostProvider()),
          ],
          child: MyApp(
            firebaseInitialized: firebaseInitialized,
            initError: initError,
          ),
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
  final bool firebaseInitialized;
  final Object? initError;

  const MyApp({super.key, this.firebaseInitialized = false, this.initError});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Your App Name',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.theme,
          builder: (context, child) {
            return NetworkAwareWrapper(child: child!);
          },
          home: Builder(
            builder: (context) {
              if (!firebaseInitialized) {
                return ErrorInitScreen(error: initError);
              }

              return SplashScreen(
                nextPage: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      ChatNotificationService.instance.startListening(
                        snapshot.data!.uid,
                      );
                      return const DashboardPage();
                    }

                    ChatNotificationService.instance.stopListening();
                    return const LoginPage();
                  },
                ),
              );
            },
          ),
          routes: {
            '/login': (context) => const LoginPage(),
            '/dashboard': (context) => const DashboardPage(),
            '/profile': (context) => const ProfilePage(),
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
  final int r = (color.r * 255.0).round() & 0xff;
  final int g = (color.g * 255.0).round() & 0xff;
  final int b = (color.b * 255.0).round() & 0xff;

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
  return MaterialColor(color.toARGB32(), swatch);
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          // Theme switching removed — app uses a single global theme
        ],
      ),
    );
  }
}

class NetworkAwareWrapper extends StatefulWidget {
  final Widget child;
  const NetworkAwareWrapper({super.key, required this.child});

  @override
  State<NetworkAwareWrapper> createState() => _NetworkAwareWrapperState();
}

class _NetworkAwareWrapperState extends State<NetworkAwareWrapper> {
  bool _hasConnection = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkConnection(),
    );
  }

  Future<void> _checkConnection() async {
    bool previousConnection = _hasConnection;
    try {
      final result = await InternetAddress.lookup('google.com');
      _hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _hasConnection = false;
    }
    if (previousConnection != _hasConnection && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasConnection) {
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 80,
                color: colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'ไม่มีการเชื่อมต่ออินเตอร์เน็ต',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'กรุณาตรวจสอบการเชื่อมต่อของคุณ\nระบบจะกลับมาทำงานอัตโนมัติเมื่อเชื่อมต่อสำเร็จ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}

class ErrorInitScreen extends StatelessWidget {
  final Object? error;

  const ErrorInitScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final String message = error?.toString() ?? 'Unknown initialization error';
    return Scaffold(
      appBar: AppBar(title: const Text('Initialization error')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase failed to initialize.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const Text(
              'Suggested steps:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Stop the app and run a full rebuild: flutter clean && flutter pub get',
            ),
            const Text(
              '2. If iOS: run pod install inside ios/ and rebuild in Xcode.',
            ),
            const Text(
              '3. If Android: ensure google-services.json is in android/app/',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Try a hot retry by restarting the app process — here we just suggest the command
                await showDialog(
                  context: context,
                  builder:
                      (c) => AlertDialog(
                        title: const Text('Run rebuild'),
                        content: const Text(
                          'Please stop the app and run:\nflutter clean && flutter pub get\nthen rebuild the app.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                );
              },
              child: const Text('How to fix'),
            ),
          ],
        ),
      ),
    );
  }
}
