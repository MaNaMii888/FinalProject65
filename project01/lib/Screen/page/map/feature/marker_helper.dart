import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerHelper {
  /// สร้างรูปภาพวงกลม 2 ชั้น (Composite Badge)
  /// วงกลมใหญ่สีม่วงบอกรหัสตึก, วงกลมเล็กสีแดงซ้อนทับบอกยอดโพสต์
  static Future<BitmapDescriptor> createCompositeMarkerBitmap(
    String buildingId,
    String postCountText,
  ) async {
    const int size = 180; // เพิ่มขนาด Canvas ให้วาด 2 วงได้พอดี
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // สีหลักของวงกลม (สีม่วง)
    final Paint mainPaintFill = Paint()..color = const Color(0xFF8B2CF5);
    final Paint paintStroke =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0;

    // รัศมีและจุดศูนย์กลางวงกลมใหญ่
    final Offset mainCenter = const Offset(size * 0.45, size * 0.55);
    final double mainRadius = size * 0.40;

    // 1. วาดวงกลมสีม่วงพื้นหลัง
    canvas.drawCircle(mainCenter, mainRadius, mainPaintFill);

    // 2. วาดขอบวงกลมสีขาวให้วงใหญ่
    canvas.drawCircle(mainCenter, mainRadius - 3, paintStroke);

    // 3. วาดตัวอักษรให้อยู่ตรงกลางวงกลมใหญ่ (ชื่อ/ตึก)
    TextPainter mainTextPainter = TextPainter(textDirection: TextDirection.ltr);
    mainTextPainter.text = TextSpan(
      text: buildingId,
      style: TextStyle(
        fontSize: mainRadius, // ขนาดตัวหนังสือสัมพันธ์กับวงกลม
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    mainTextPainter.layout();
    mainTextPainter.paint(
      canvas,
      Offset(
        mainCenter.dx - (mainTextPainter.width / 2),
        mainCenter.dy - (mainTextPainter.height / 2),
      ),
    );

    // 4. วาด Badge สีแดงซ้อนที่มุมขวาบน (ถ้ามียอดโพสต์)
    if (postCountText.isNotEmpty && postCountText != '0') {
      final Paint badgePaintFill = Paint()..color = Colors.red;
      final Paint badgeStroke =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0; // ขอบของ badge เล็กลงหน่อย

      // จุดศูนย์กลางของ badge ให้อยู่มุมขวาบนของวงกลมใหญ่
      final Offset badgeCenter = const Offset(size * 0.75, size * 0.25);
      final double badgeRadius = size * 0.20;

      canvas.drawCircle(badgeCenter, badgeRadius, badgePaintFill);
      canvas.drawCircle(badgeCenter, badgeRadius - 2, badgeStroke);

      TextPainter badgeTextPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );
      badgeTextPainter.text = TextSpan(
        text: postCountText,
        style: TextStyle(
          fontSize: badgeRadius * 1.2,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      badgeTextPainter.layout();
      badgeTextPainter.paint(
        canvas,
        Offset(
          badgeCenter.dx - (badgeTextPainter.width / 2),
          badgeCenter.dy - (badgeTextPainter.height / 2),
        ),
      );
    }

    // 5. เรนเดอร์รูปภาพแคนวาสให้ออกมาเป็นข้อมูลบิตแทน (PNG Bytes)
    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
