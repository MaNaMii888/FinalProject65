import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart';

// CustomPainter for drawing Floor Plan B
class FloorPlanBPainter extends CustomPainter {
  final String? findRequest;
  final Map<String, RoomData>? roomDataMap; // เพิ่มข้อมูลห้อง

  FloorPlanBPainter({this.findRequest, this.roomDataMap});

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
    RoomData? roomData, // เพิ่มข้อมูลห้อง
  ) {
    bool isHighlighted =
        findRequest != null &&
        (roomName.toLowerCase().contains(findRequest!.toLowerCase()) ||
            roomId.toLowerCase() == findRequest!.toLowerCase());

    // ตรวจสอบว่ามีโพสต์ในห้องนี้หรือไม่
    bool hasPosts = roomData != null && roomData.posts.isNotEmpty;
    bool hasLostItems = roomData != null && roomData.lostItemCount > 0;
    bool hasFoundItems = roomData != null && roomData.foundItemCount > 0;

    final Rect scaledRect = Rect.fromLTWH(
      originalRect.left * scaleFactor,
      originalRect.top * scaleFactor,
      originalRect.width * scaleFactor,
      originalRect.height * scaleFactor,
    );

    // เลือกสีตามสถานะของห้อง
    Paint finalFillPaint = fill;
    Paint finalBorderPaint = border;

    if (isHighlighted) {
      finalFillPaint = highlightPaint;
      finalBorderPaint = highlightBorderPaint;
    } else if (hasPosts) {
      // ถ้ามีโพสต์ ให้ใช้สีที่แตกต่าง
      if (hasLostItems && hasFoundItems) {
        // มีทั้งของหายและเจอของ
        finalFillPaint =
            Paint()
              ..style = PaintingStyle.fill
              ..color = Colors.orange[100]!;
        finalBorderPaint =
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 + 1
              ..color = Colors.orange[600]!;
      } else if (hasLostItems) {
        // มีเฉพาะของหาย
        finalFillPaint =
            Paint()
              ..style = PaintingStyle.fill
              ..color = Colors.red[100]!;
        finalBorderPaint =
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 + 1
              ..color = Colors.red[600]!;
      } else if (hasFoundItems) {
        // มีเฉพาะเจอของ
        finalFillPaint =
            Paint()
              ..style = PaintingStyle.fill
              ..color = Colors.green[100]!;
        finalBorderPaint =
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 + 1
              ..color = Colors.green[600]!;
      }
    }

    canvas.drawRect(scaledRect, finalFillPaint);
    canvas.drawRect(scaledRect, finalBorderPaint);

    // วาดไอคอนแสดงจำนวนโพสต์
    if (hasPosts && roomData != null) {
      _drawPostIndicator(canvas, scaledRect, roomData, scaleFactor);
    }

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

  // วาดไอคอนแสดงจำนวนโพสต์
  void _drawPostIndicator(
    Canvas canvas,
    Rect roomRect,
    RoomData roomData,
    double scaleFactor,
  ) {
    final double indicatorSize = 16 * scaleFactor;
    final double indicatorX = roomRect.right - indicatorSize - 4 * scaleFactor;
    final double indicatorY = roomRect.top + 4 * scaleFactor;

    // วาดพื้นหลังของ indicator
    final Paint indicatorBgPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withOpacity(0.9);

    canvas.drawCircle(
      Offset(indicatorX + indicatorSize / 2, indicatorY + indicatorSize / 2),
      indicatorSize / 2,
      indicatorBgPaint,
    );

    // วาดขอบของ indicator
    final Paint indicatorBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * scaleFactor
          ..color = Colors.grey[600]!;

    canvas.drawCircle(
      Offset(indicatorX + indicatorSize / 2, indicatorY + indicatorSize / 2),
      indicatorSize / 2,
      indicatorBorderPaint,
    );

    // วาดตัวเลขจำนวนโพสต์
    final TextPainter countPainter = TextPainter(
      text: TextSpan(
        text: roomData.posts.length.toString(),
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 10 * scaleFactor,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    countPainter.layout();
    countPainter.paint(
      canvas,
      Offset(
        indicatorX + (indicatorSize - countPainter.width) / 2,
        indicatorY + (indicatorSize - countPainter.height) / 2,
      ),
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

    // Building B Rooms - ใช้ _drawRoom พร้อม scaleFactor และข้อมูลห้อง
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
      roomDataMap?['28'],
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
      roomDataMap?['19'],
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
      roomDataMap?['20'],
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
      roomDataMap?['22'],
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
      roomDataMap?['24'],
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
      roomDataMap?['26'],
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
      roomDataMap?['27'],
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
      roomDataMap?['17'],
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
      roomDataMap?['18'],
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
      roomDataMap?['31'],
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
      roomDataMap?['29'],
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
      roomDataMap?['15'],
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
      roomDataMap?['16'],
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
      roomDataMap?['30'],
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
      roomDataMap?['lobby'],
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
      roomDataMap?['33'],
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FloorPlanBPainter &&
        (oldDelegate.findRequest != findRequest ||
            oldDelegate.roomDataMap != roomDataMap);
  }
}
