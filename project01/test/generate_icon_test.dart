// test/generate_icon_test.dart
//
// รัน: flutter test test/generate_icon_test.dart
// จะสร้างไฟล์ assets/img/app_icon.png (1024×1024)
// จากนั้นรัน: dart run flutter_launcher_icons

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project01/widgets/app_logo.dart';

void main() {
  testWidgets('Export app icon to PNG', (WidgetTester tester) async {
    // ตั้งขนาด viewport ให้เป็น 1024×1024
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        // ใช้สีจริงของแอป
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFDA0037),   // สีแดงเข้ม (secondary ของแอป)
            secondary: Color(0xFF8B0000), // deep crimson
          ),
        ),
        home: RepaintBoundary(
          key: key,
          child: Container(
            width: 1024,
            height: 1024,
            color: const Color(0xFF1A1A1A), // พื้นหลังสีเข้มเหมือน splash
            child: const Center(
              child: AppLogoGradient(size: 700),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Capture widget เป็น image
    final RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    // สร้าง directory และ save
    final outputFile = File('assets/img/app_icon.png');
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsBytes(pngBytes);

    debugPrint('✅ Icon saved to: ${outputFile.absolute.path}');
    debugPrint('   Size: ${(pngBytes.length / 1024).toStringAsFixed(1)} KB');

    expect(pngBytes.isNotEmpty, true);
    expect(outputFile.existsSync(), true);
  });
}
