import 'package:flutter/material.dart';

// CustomPainter for drawing Floor Plan A
class FloorPlanAPainter extends CustomPainter {
  // Add constants for configuration
  static const double ORIGINAL_SVG_HEIGHT = 500.0;
  static const double FONT_SIZE = 12.0;
  static const double STROKE_WIDTH = 2.0;
  static const double HIGHLIGHT_STROKE_WIDTH = 3.0;

  final String? findRequest; // สำหรับไฮไลท์ห้องที่ค้นหา

  FloorPlanAPainter({this.findRequest});

  /// Draw a room on the canvas with specified parameters
  void _drawRoom(
    Canvas canvas,
    Rect originalRect, // รับ Rect ที่เป็นค่าพิกัดเดิมจาก SVG
    String roomId,
    String roomName,
    Paint fill,
    Paint border,
    double scaleFactor, // เพิ่ม scaleFactor
    Paint highlightPaint, // เพิ่ม Paint สำหรับ Highlight
    Paint highlightBorderPaint, // เพิ่ม Paint สำหรับ Highlight Border
    String? highlightRequest, // ไม่ shadow ชื่อ findRequest
  ) {
    bool isHighlighted =
        highlightRequest != null &&
        (roomName.toLowerCase().contains(highlightRequest.toLowerCase()) ||
            roomId.toLowerCase() == highlightRequest.toLowerCase());

    // Apply scaling to the rectangle coordinates
    final Rect scaledRect = Rect.fromLTWH(
      originalRect.left * scaleFactor,
      originalRect.top * scaleFactor,
      originalRect.width * scaleFactor,
      originalRect.height * scaleFactor,
    );

    canvas.drawRect(scaledRect, isHighlighted ? highlightPaint : fill);
    canvas.drawRect(scaledRect, isHighlighted ? highlightBorderPaint : border);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: roomName,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: FONT_SIZE * scaleFactor, // Scale font size as well
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: scaledRect.width, maxWidth: scaledRect.width);
    textPainter.paint(
      canvas,
      Offset(scaledRect.left, scaledRect.center.dy - textPainter.height / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint roomPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xffe3f2fd); // Fill color
    final Paint roomBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = STROKE_WIDTH
          ..color = const Color(0xff1976d2); // Border color

    final Paint foodPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xfffff3e0);
    final Paint foodBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = STROKE_WIDTH
          ..color = const Color(0xfff57c00);
    final Paint highlightPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.yellow[100]!;
    final Paint highlightBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = HIGHLIGHT_STROKE_WIDTH
          ..color = Colors.yellow[400]!;

    // กำหนด scaleFactor: ใช้ความสูงของ Canvas (size.height) เทียบกับความสูงต้นฉบับของ SVG (600)
    final double scaleFactor = size.height / ORIGINAL_SVG_HEIGHT;

    // Building A Rooms - ใช้ _drawRoom พร้อม scaleFactor
    _drawRoom(
      canvas,
      const Rect.fromLTWH(150, 20, 100, 40),
      '7',
      '7',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(160, 80, 80, 60),
      '6',
      '6',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(30, 80, 40, 60),
      '8',
      '8',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(340, 80, 40, 60),
      '5',
      '5',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 160, 60, 80),
      '9',
      '9',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(160, 160, 80, 60),
      '2',
      '2',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(340, 150, 40, 80),
      '4',
      '4',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(160, 240, 80, 60),
      '1',
      '1',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(340, 240, 40, 80),
      '3',
      '3',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 260, 50, 80),
      '10',
      '10',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(160, 305, 80, 60),
      'food',
      'โรงอาหาร',
      foodPaint,
      foodBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(340, 360, 40, 120),
      '12',
      '12',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(10, 360, 60, 120),
      '11',
      '11',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
      findRequest,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FloorPlanAPainter &&
        oldDelegate.findRequest != findRequest;
  }
}
