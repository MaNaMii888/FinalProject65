import 'package:flutter/material.dart';

// CustomPainter for drawing Floor Plan B
class FloorPlanBPainter extends CustomPainter {
  final String? findRequest;

  FloorPlanBPainter({this.findRequest});

  /// Draw a room on the canvas with specified parameters
  void _drawRoom(
    Canvas canvas,
    Rect originalRect,
    String roomId,
    String roomName,
    Paint fill,
    Paint border,
    double scaleFactor,
    Paint highlightPaint,
    Paint highlightBorderPaint,
  ) {
    bool isHighlighted =
        findRequest != null &&
        (roomName.toLowerCase().contains(findRequest!.toLowerCase()) ||
            roomId.toLowerCase() == findRequest!.toLowerCase());

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
          fontSize: 12 * scaleFactor, // Scale font size as well
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
    // Paints
    final Paint roomPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xffe3f2fd);
    final Paint roomBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xff1976d2);
    final Paint lobbyPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xffe8f5e8);
    final Paint lobbyBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xff388e3c);

    final Paint highlightPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.yellow[100]!;
    final Paint highlightBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.yellow[400]!;

    // กำหนด scaleFactor: ใช้ความสูงของ Canvas (size.height) เทียบกับความสูงต้นฉบับของ SVG (350)
    final double scaleFactor =
        size.height / 350.0; // Original SVG viewBox height for Building B

    // Building B Rooms - ใช้ _drawRoom พร้อม scaleFactor
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 20, 50, 30),
      '28',
      '28',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 60, 40, 50),
      '19',
      '19',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(70, 60, 60, 30),
      '20',
      '20',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(140, 40, 40, 70),
      '22',
      '22',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(190, 20, 60, 50),
      '24',
      '24',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(270, 40, 40, 40),
      '26',
      '26',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(190, 80, 80, 40),
      '27',
      '27',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 130, 60, 40),
      '17',
      '17',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(90, 130, 80, 60),
      '18',
      '18',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(290, 120, 40, 50),
      '31',
      '31',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(220, 140, 60, 40),
      '29',
      '29',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(20, 190, 40, 40),
      '15',
      '15',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(70, 200, 40, 30),
      '16',
      '16',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(220, 190, 60, 50),
      '30',
      '30',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(120, 250, 100, 60),
      'lobby',
      'สนาม',
      lobbyPaint,
      lobbyBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
    _drawRoom(
      canvas,
      const Rect.fromLTWH(120, 320, 60, 20),
      '33',
      '33',
      roomPaint,
      roomBorderPaint,
      scaleFactor,
      highlightPaint,
      highlightBorderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FloorPlanBPainter &&
        oldDelegate.findRequest != findRequest;
  }
}
