import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/mapmodel/building_data.dart';
import 'package:project01/Screen/page/map/widgets/room_posts_dialog.dart';

class FloorPlanB extends StatelessWidget {
  final String? findRequest;
  final Map<String, RoomData>? roomDataMap;

  const FloorPlanB({super.key, this.findRequest, this.roomDataMap});

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

          // จัด layout Zone B เป็น 3 คอลัมน์ตามแผนใหม่
          Expanded(
            child: Row(
              children: [
                // คอลัมน์ซ้าย - บนว่าง, 17 บน, 15,16 ล่าง
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // ส่วนบน - พื้นที่ว่าง
                      Expanded(
                        flex: 2,
                        child: Container(), // พื้นที่ว่าง
                      ),
                      const SizedBox(height: 8),
                      // อาคาร 17 อยู่บน
                      Expanded(child: _buildingBox("17")),
                      const SizedBox(height: 8),
                      // 15, 16 อยู่ด้วยกันข้างล่าง
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox("15")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildingBox("16")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // คอลัมน์กลาง - ปรับตามแผนใหม่
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      // 19, 20 คู่กันบนสุด
                      Row(
                        children: [
                          Expanded(child: _buildingBox("19")),
                          const SizedBox(width: 4),
                          Expanded(child: _buildingBox("20")),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 18 อยู่ล่าง
                      _buildingBox("18", height: 50),
                      const SizedBox(height: 8),
                      // สนาม - เต็มพื้นที่
                      Expanded(
                        flex: 3,
                        child: _buildingBox("lobby", isSpecial: true),
                      ),
                      const SizedBox(height: 8),
                      // 33 ล่างสุด
                      _buildingBox("33", height: 60),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // คอลัมน์ขวา - ปรับตามแผนใหม่
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // 28 เต็มพื้นที่บนสุด
                      Expanded(child: _buildingBox("28")),
                      const SizedBox(height: 8),
                      // ่ม, 24 อยู่ด้วยกัน (ยาวกว่าอันอื่น)
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox("22")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildingBox("24")),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 26, 27 อยู่ด้วยกัน
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox("26")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildingBox("27")),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 29, 31 คู่กัน
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox("29")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildingBox("31")),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 30 ล่างสุด
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [Expanded(child: _buildingBox("30"))],
                        ),
                      ),
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
  Widget _buildingBox(
    String number, {
    double? height,
    bool isSpecial = false,
    bool isHighlighted = false,
  }) {
    return Builder(
      builder: (context) {
        // ตรวจสอบว่ามีข้อมูลห้องหรือไม่
        final hasRoomData = roomDataMap?.containsKey(number) == true;
        final roomData = roomDataMap?[number];
        final postCount = roomData?.posts.length ?? 0;

        // สำหรับแสดงชื่อ
        final displayName = isSpecial ? 'สนาม' : 'อาคาร $number';
        final displayText = isSpecial ? 'สนาม' : number;

        return GestureDetector(
          onTap: () {
            if (hasRoomData) {
              _showRoomPosts(context, number, displayName, roomData!);
            }
          },
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  hasRoomData
                      ? (isSpecial
                          ? Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.8)
                          : Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.8))
                      : Colors.grey[600],
              borderRadius: BorderRadius.circular(8),
              border:
                  hasRoomData
                      ? Border.all(
                        color:
                            isSpecial
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                      : (isHighlighted
                          ? Border.all(color: Colors.blue, width: 3)
                          : null),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // สำหรับสนาม - แสดงข้อความในกล่อง, อื่นๆ - แสดงในวงกลม
                  if (isSpecial)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                          color:
                              isSpecial
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary,
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
            buildingName: 'Zone B',
            posts: roomData.posts,
          ),
    );
  }
}
