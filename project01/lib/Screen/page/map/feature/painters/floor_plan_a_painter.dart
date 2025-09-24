import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart';
import 'package:project01/models/post.dart';

// CustomPainter for drawing Floor Plan A
class FloorPlanAPainter extends CustomPainter {
  // Add constants for configuration
  static const double originalSvgHeight = 500.0;
  static const double fontSize = 12.0;
  static const double strokeWidth = 2.0;
  static const double highlightStrokeWidth = 3.0;

  final String? findRequest; // สำหรับไฮไลท์ห้องที่ค้นหา
  final Map<String, RoomData>? roomDataMap; // เพิ่มข้อมูลห้อง
  final Function(String roomId, String roomName, List<Post> posts)?
  onRoomTap; // เพิ่ม callback สำหรับการคลิก

  FloorPlanAPainter({this.findRequest, this.roomDataMap, this.onRoomTap});

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
    RoomData? roomData, // เพิ่มข้อมูลห้อง
  ) {
    bool isHighlighted =
        highlightRequest != null &&
        (roomName.toLowerCase().contains(highlightRequest.toLowerCase()) ||
            roomId.toLowerCase() == highlightRequest.toLowerCase());

    // ตรวจสอบว่ามีโพสต์ในห้องนี้หรือไม่
    bool hasPosts = roomData != null && roomData.posts.isNotEmpty;
    bool hasLostItems = roomData != null && roomData.lostItemCount > 0;
    bool hasFoundItems = roomData != null && roomData.foundItemCount > 0;

    // Apply scaling to the rectangle coordinates
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
              ..strokeWidth = strokeWidth + 1
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
              ..strokeWidth = strokeWidth + 1
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
              ..strokeWidth = strokeWidth + 1
              ..color = Colors.green[600]!;
      }
    }

    canvas.drawRect(scaledRect, finalFillPaint);
    canvas.drawRect(scaledRect, finalBorderPaint);

    // วาดไอคอนแสดงจำนวนโพสต์
    if (hasPosts) {
      _drawPostIndicator(canvas, scaledRect, roomData, scaleFactor);
    }

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: roomName,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: fontSize * scaleFactor, // Scale font size as well
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
    final Paint roomPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xffe3f2fd); // Fill color
    final Paint roomBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = const Color(0xff1976d2); // Border color

    final Paint foodPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xfffff3e0);
    final Paint foodBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = const Color(0xfff57c00);
    final Paint highlightPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.yellow[100]!;
    final Paint highlightBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlightStrokeWidth
          ..color = Colors.yellow[400]!;

    // กำหนด scaleFactor: ใช้ความสูงของ Canvas (size.height) เทียบกับความสูงต้นฉบับของ SVG (600)
    final double scaleFactor = size.height / originalSvgHeight;

    // Building A Rooms - ใช้ _drawRoom พร้อม scaleFactor และข้อมูลห้อง
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
      roomDataMap?['7'],
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
      roomDataMap?['6'],
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
      roomDataMap?['8'],
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
      roomDataMap?['5'],
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
      roomDataMap?['9'],
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
      roomDataMap?['2'],
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
      roomDataMap?['4'],
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
      roomDataMap?['1'],
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
      roomDataMap?['3'],
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
      roomDataMap?['10'],
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
      roomDataMap?['food'],
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
      roomDataMap?['12'],
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
      roomDataMap?['11'],
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FloorPlanAPainter &&
        (oldDelegate.findRequest != findRequest ||
            oldDelegate.roomDataMap != roomDataMap);
  }
}
