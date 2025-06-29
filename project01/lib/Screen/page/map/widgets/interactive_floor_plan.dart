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
    // กำหนดตำแหน่งห้องสำหรับอาคาร A
    final roomPositions = {
      '7': Rect.fromLTWH(150, 20, 100, 40),
      '6': Rect.fromLTWH(160, 80, 80, 60),
      '8': Rect.fromLTWH(30, 80, 40, 60),
      '5': Rect.fromLTWH(340, 80, 40, 60),
      '9': Rect.fromLTWH(20, 160, 60, 80),
      '2': Rect.fromLTWH(160, 160, 80, 60),
      '4': Rect.fromLTWH(340, 150, 40, 80),
      '1': Rect.fromLTWH(160, 240, 80, 60),
      '3': Rect.fromLTWH(340, 240, 40, 80),
      '10': Rect.fromLTWH(20, 260, 50, 80),
      'food': Rect.fromLTWH(160, 305, 80, 60),
      '12': Rect.fromLTWH(340, 360, 40, 120),
      '11': Rect.fromLTWH(10, 360, 60, 120),
    };

    final roomNames = {
      '7': 'ห้อง 7',
      '6': 'ห้อง 6',
      '8': 'ห้อง 8',
      '5': 'ห้อง 5',
      '9': 'ห้อง 9',
      '2': 'ห้อง 2',
      '4': 'ห้อง 4',
      '1': 'ห้อง 1',
      '3': 'ห้อง 3',
      '10': 'ห้อง 10',
      'food': 'โรงอาหาร',
      '12': 'ห้อง 12',
      '11': 'ห้อง 11',
    };

    return _checkRoomPosition(position, roomPositions, roomNames);
  }

  Map<String, String>? _getRoomAtPositionBuildingB(Offset position) {
    // กำหนดตำแหน่งห้องสำหรับอาคาร B
    final roomPositions = {
      '28': Rect.fromLTWH(20, 20, 50, 30),
      '19': Rect.fromLTWH(20, 60, 40, 50),
      '20': Rect.fromLTWH(70, 60, 60, 30),
      '22': Rect.fromLTWH(140, 40, 40, 70),
      '24': Rect.fromLTWH(190, 20, 60, 50),
      '26': Rect.fromLTWH(270, 40, 40, 40),
      '27': Rect.fromLTWH(190, 80, 80, 40),
      '17': Rect.fromLTWH(20, 130, 60, 40),
      '18': Rect.fromLTWH(90, 130, 80, 60),
      '31': Rect.fromLTWH(290, 120, 40, 50),
      '29': Rect.fromLTWH(220, 140, 60, 40),
      '15': Rect.fromLTWH(20, 190, 40, 40),
      '16': Rect.fromLTWH(70, 200, 40, 30),
      '30': Rect.fromLTWH(220, 190, 60, 50),
      'lobby': Rect.fromLTWH(120, 250, 100, 60),
      '33': Rect.fromLTWH(120, 320, 60, 20),
    };

    final roomNames = {
      '28': 'ห้อง 28',
      '19': 'ห้อง 19',
      '20': 'ห้อง 20',
      '22': 'ห้อง 22',
      '24': 'ห้อง 24',
      '26': 'ห้อง 26',
      '27': 'ห้อง 27',
      '17': 'ห้อง 17',
      '18': 'ห้อง 18',
      '31': 'ห้อง 31',
      '29': 'ห้อง 29',
      '15': 'ห้อง 15',
      '16': 'ห้อง 16',
      '30': 'ห้อง 30',
      'lobby': 'ล็อบบี้',
      '33': 'ห้อง 33',
    };

    return _checkRoomPosition(position, roomPositions, roomNames);
  }

  Map<String, String>? _checkRoomPosition(
    Offset position,
    Map<String, Rect> roomPositions,
    Map<String, String> roomNames,
  ) {
    // คำนวณ scale factor
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final scaleFactor = size.height / 500.0; // ใช้ความสูงต้นฉบับของ SVG

    for (final entry in roomPositions.entries) {
      final roomId = entry.key;
      final originalRect = entry.value;

      // คำนวณตำแหน่งที่ scale แล้ว
      final scaledRect = Rect.fromLTWH(
        originalRect.left * scaleFactor,
        originalRect.top * scaleFactor,
        originalRect.width * scaleFactor,
        originalRect.height * scaleFactor,
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
 