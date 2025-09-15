import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart';
import 'package:project01/Screen/page/map/widgets/room_posts_dialog.dart';
import 'package:project01/Screen/page/map/painters/floor_plan_a_painter.dart';
import 'package:project01/Screen/page/map/painters/floor_plan_b_painter.dart';

class InteractiveFloorPlan extends StatefulWidget {
  final String buildingId;
  final String? findRequest;
  final Map<String, RoomData>? roomDataMap;

  const InteractiveFloorPlan({
    super.key,
    required this.buildingId,
    this.findRequest,
    this.roomDataMap,
  });

  @override
  State<InteractiveFloorPlan> createState() => _InteractiveFloorPlanState();
}

class _InteractiveFloorPlanState extends State<InteractiveFloorPlan> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTap,
      child: CustomPaint(painter: _getPainter(), size: Size.infinite),
    );
  }

  CustomPainter _getPainter() {
    if (widget.buildingId == 'A') {
      return FloorPlanAPainter(
        findRequest: widget.findRequest,
        roomDataMap: widget.roomDataMap,
      );
    } else {
      return FloorPlanBPainter(
        findRequest: widget.findRequest,
        roomDataMap: widget.roomDataMap,
      );
    }
  }

  void _handleTap(TapUpDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    final roomInfo = _getRoomAtPosition(localPosition);
    if (roomInfo != null) {
      final roomId = roomInfo['roomId'];
      final roomName = roomInfo['roomName'];
      if (roomId != null && roomName != null) {
        _showRoomPosts(roomId, roomName);
      }
    }
  }

  Map<String, String>? _getRoomAtPosition(Offset position) {
    // กำหนดตำแหน่งห้องสำหรับอาคาร A
    if (widget.buildingId == 'A') {
      return _getRoomAtPositionBuildingA(position);
    } else {
      return _getRoomAtPositionBuildingB(position);
    }
  }

  Map<String, String>? _getRoomAtPositionBuildingA(Offset position) {
    // กำหนดตำแหน่งห้องสำหรับอาคาร A - ปรับให้ขยายเต็มพื้นที่
    final roomPositions = {
      '7': Rect.fromLTWH(120, 15, 100, 50), // ขยายและปรับตำแหน่ง
      '6': Rect.fromLTWH(140, 75, 100, 70), // ขยายและปรับตำแหน่ง
      '8': Rect.fromLTWH(20, 75, 50, 70), // ขยายและปรับตำแหน่ง
      '5': Rect.fromLTWH(320, 75, 50, 70), // ขยายและปรับตำแหน่ง
      '9': Rect.fromLTWH(15, 155, 70, 90), // ขยายและปรับตำแหน่ง
      '2': Rect.fromLTWH(140, 155, 100, 70), // ขยายและปรับตำแหน่ง
      '4': Rect.fromLTWH(320, 145, 50, 90), // ขยายและปรับตำแหน่ง
      '1': Rect.fromLTWH(140, 235, 100, 70), // ขยายและปรับตำแหน่ง
      '3': Rect.fromLTWH(320, 235, 50, 70), // ขยายและปรับตำแหน่ง
      '10': Rect.fromLTWH(10, 255, 60, 90), // ขยายและปรับตำแหน่ง
      'food': Rect.fromLTWH(140, 300, 100, 70), // ขยายและปรับตำแหน่ง
      '12': Rect.fromLTWH(320, 350, 50, 130), // ขยายและปรับตำแหน่ง
      '11': Rect.fromLTWH(5, 350, 70, 130), // ขยายและปรับตำแหน่ง
    };

    final roomNames = {
      '7': 'อาคาร 7',
      '6': 'อาคาร 6',
      '8': 'อาคาร 8',
      '5': 'อาคาร 5',
      '9': 'อาคาร 9',
      '2': 'อาคาร 2',
      '4': 'อาคาร 4',
      '1': 'อาคาร 1',
      '3': 'อาคาร 3',
      '10': 'อาคาร 10',
      'food': 'โรงอาหาร',
      '12': 'อาคาร 12',
      '11': 'อาคาร 11',
    };

    return _checkRoomPosition(position, roomPositions, roomNames);
  }

  Map<String, String>? _getRoomAtPositionBuildingB(Offset position) {
    // กำหนดตำแหน่งห้องสำหรับอาคาร B - ปรับให้ขยายเต็มพื้นที่
    final roomPositions = {
      '28': Rect.fromLTWH(15, 15, 60, 35), // ขยายและปรับตำแหน่ง
      '19': Rect.fromLTWH(15, 55, 50, 55), // ขยายและปรับตำแหน่ง
      '20': Rect.fromLTWH(70, 55, 70, 35), // ขยายและปรับตำแหน่ง
      '22': Rect.fromLTWH(150, 35, 50, 75), // ขยายและปรับตำแหน่ง
      '24': Rect.fromLTWH(210, 15, 70, 55), // ขยายและปรับตำแหน่ง
      '26': Rect.fromLTWH(290, 35, 50, 45), // ขยายและปรับตำแหน่ง
      '27': Rect.fromLTWH(200, 75, 90, 45), // ขยายและปรับตำแหน่ง
      '17': Rect.fromLTWH(15, 125, 70, 45), // ขยายและปรับตำแหน่ง
      '18': Rect.fromLTWH(95, 125, 90, 65), // ขยายและปรับตำแหน่ง
      '31': Rect.fromLTWH(300, 115, 50, 55), // ขยายและปรับตำแหน่ง
      '29': Rect.fromLTWH(230, 135, 70, 45), // ขยายและปรับตำแหน่ง
      '15': Rect.fromLTWH(15, 185, 50, 45), // ขยายและปรับตำแหน่ง
      '16': Rect.fromLTWH(70, 195, 50, 35), // ขยายและปรับตำแหน่ง
      '30': Rect.fromLTWH(230, 185, 70, 55), // ขยายและปรับตำแหน่ง
      'lobby': Rect.fromLTWH(125, 245, 110, 65), // ขยายและปรับตำแหน่ง
      '33': Rect.fromLTWH(125, 315, 70, 25), // ขยายและปรับตำแหน่ง
    };

    final roomNames = {
      '28': 'อาคาร 28',
      '19': 'อาคาร 19',
      '20': 'อาคาร 20',
      '22': 'อาคาร 22',
      '24': 'อาคาร 24',
      '26': 'อาคาร 26',
      '27': 'อาคาร 27',
      '17': 'อาคาร 17',
      '18': 'อาคาร 18',
      '31': 'อาคาร 31',
      '29': 'อาคาร 29',
      '15': 'อาคาร 15',
      '16': 'อาคาร 16',
      '30': 'อาคาร 30',
      'lobby': 'สนาม',
      '33': 'อาคาร 33',
    };

    return _checkRoomPosition(position, roomPositions, roomNames);
  }

  Map<String, String>? _checkRoomPosition(
    Offset position,
    Map<String, Rect> roomPositions,
    Map<String, String> roomNames,
  ) {
    // คำนวณ scale factor - ปรับให้อาคารขยายเต็มพื้นที่
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // ปรับ scale factor ให้อาคารขยายเต็มพื้นที่และลดขอบขาว
    final scaleFactorX =
        size.width / 400.0; // ปรับจาก 500 เป็น 400 เพื่อขยายอาคาร
    final scaleFactorY =
        size.height / 500.0; // ปรับจาก 500 เป็น 500 เพื่อรักษาอัตราส่วน

    for (final entry in roomPositions.entries) {
      final roomId = entry.key;
      final originalRect = entry.value;

      // คำนวณตำแหน่งที่ scale แล้ว - ปรับให้ขยายเต็มพื้นที่
      final scaledRect = Rect.fromLTWH(
        originalRect.left * scaleFactorX,
        originalRect.top * scaleFactorY,
        originalRect.width * scaleFactorX,
        originalRect.height * scaleFactorY,
      );

      if (scaledRect.contains(position)) {
        return {'roomId': roomId, 'roomName': roomNames[roomId] ?? roomId};
      }
    }
    return null;
  }

  void _showRoomPosts(String roomId, String roomName) {
    final roomData = widget.roomDataMap?[roomId];
    final posts = roomData?.posts ?? [];

    showDialog(
      context: context,
      builder:
          (context) => RoomPostsDialog(
            roomName: roomName,
            buildingName: widget.buildingId == 'A' ? 'อาคาร A' : 'อาคาร B',
            posts: posts,
          ),
    );
  }
}
