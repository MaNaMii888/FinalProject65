import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project01/Screen/home.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // กำหนดให้แอพแสดงเฉพาะแนวตั้ง
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // เริ่มต้น Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      debugShowCheckedModeBanner: false, // ลบแบนเนอร์ Debug
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Prompt', // ใส่ฟอนต์ภาษาไทย
        useMaterial3: true, // ใช้ Material Design 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      // กำหนด Dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      // เพิ่ม routes
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(),
        '/found': (context) => const FoundPage(),
        '/found-item': (context) => const FoundItemPage(),
      },
    );
  }
}
