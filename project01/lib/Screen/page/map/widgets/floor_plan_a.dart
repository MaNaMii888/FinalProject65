import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart';
import 'package:project01/Screen/page/map/widgets/room_posts_dialog.dart';

class FloorPlanA extends StatelessWidget {
  final String? findRequest;
  final Map<String, RoomData>? roomDataMap;

  const FloorPlanA({super.key, this.findRequest, this.roomDataMap});

  @override
  Widget build(BuildContext context) {
    // ตรวจหา safe area และ status bar แบบ dynamic [[memory:7064663]]
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = (statusBarHeight * 0.1).clamp(4.0, 12.0);

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SizedBox(height: topPadding),

          // จัด layout ตามภาพที่ส่งมา - Grid 3x4
          Expanded(
            child: Column(
              children: [
                // แถวที่ 1: 8, 7, 5
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildingBox("8")),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildingBox("7")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildingBox("5")),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // แถวที่ 2: 9, 6, 4
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildingBox("9")),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildingBox("6")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildingBox("4")),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // แถวที่ 3: 10, 2, 3
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildingBox("10")),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildingBox("2")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildingBox("3")),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // แถวที่ 4: 11, 1 (เล็กลง + พื้นที่ว่าง), 12
                Expanded(
                  flex: 2, // รักษาความสูงเดิม
                  child: Row(
                    children: [
                      Expanded(child: _buildingBox("11")),
                      const SizedBox(width: 8),
                      // อาคาร 1 - แบ่งเป็น 2 ส่วน
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            // ส่วนบน - อาคาร 1 ขนาดเล็ก (ครึ่งหนึ่ง)
                            Expanded(flex: 1, child: _buildingBox("1")),
                            const SizedBox(height: 4),
                            // ส่วนล่าง - พื้นที่ว่าง (ครึ่งหนึ่ง)
                            Expanded(
                              flex: 1,
                              child: Container(), // พื้นที่ว่าง
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _buildingBox("12")),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget กล่องอาคาร ที่สามารถ tap ได้
  Widget _buildingBox(String number, {double? height}) {
    return Builder(
      builder: (context) {
        // ตรวจสอบว่ามีข้อมูลห้องหรือไม่
        final hasRoomData = roomDataMap?.containsKey(number) == true;
        final roomData = roomDataMap?[number];
        final postCount = roomData?.posts.length ?? 0;

        return GestureDetector(
          onTap: () {
            if (hasRoomData) {
              _showRoomPosts(context, number, 'อาคาร $number', roomData!);
            }
          },
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  hasRoomData
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                      : Colors.grey[600],
              borderRadius: BorderRadius.circular(8),
              border:
                  hasRoomData
                      ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                      : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (hasRoomData && postCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$postCount โพสต์',
                        style: TextStyle(
                          fontSize: 8,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRoomPosts(
    BuildContext context,
    String roomId,
    String roomName,
    RoomData roomData,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => RoomPostsDialog(
            roomName: roomName,
            buildingName: 'Zone A',
            posts: roomData.posts,
          ),
    );
  }
}
