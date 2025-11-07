import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/Screen/page/map/feature/room_posts_dialog.dart';
import 'package:project01/models/post.dart';

class FloorPlanB extends StatelessWidget {
  const FloorPlanB({super.key});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = (statusBarHeight * 0.1).clamp(4.0, 12.0);

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SizedBox(height: topPadding),
          Expanded(
            child: Row(
              children: [
                // คอลัมน์ซ้าย
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(flex: 2, child: Container()),
                      const SizedBox(height: 8),
                      Expanded(child: _buildingBox(context, "17")),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox(context, "15")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildingBox(context, "16")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // คอลัมน์กลาง
                // คอลัมน์กลาง
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        // ✅ เพิ่ม Expanded ให้ Row
                        flex: 1, // ✅ กำหนด flex ให้ 19, 20
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox(context, "19")),
                            const SizedBox(width: 5),
                            Expanded(child: _buildingBox(context, "20")),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        // ✅ เปลี่ยนจาก fixed height เป็น Expanded
                        flex: 1, // ✅ กำหนด flex ให้ 18
                        child: _buildingBox(context, "18"),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 3,
                        child: _buildingBox(context, "สนาม", isSpecial: true),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        // ✅ เปลี่ยนจาก fixed height เป็น Expanded
                        flex: 1, // ✅ กำหนด flex ให้ 33
                        child: _buildingBox(context, "33"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // คอลัมน์ขวา
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(child: _buildingBox(context, "28")),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox(context, "22")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildingBox(context, "24")),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox(context, "26")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildingBox(context, "27")),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox(context, "29")),
                            const SizedBox(width: 4),
                            Expanded(child: _buildingBox(context, "31")),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(child: _buildingBox(context, "30")),
                          ],
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

  Widget _buildingBox(
    BuildContext context,
    String number, {
    double? height,
    bool isSpecial = false,
  }) {
    final displayName = isSpecial ? 'สนาม' : 'อาคาร $number';
    final displayText = isSpecial ? 'สนาม' : number;

    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('lost_found_items')
              .where('building', isEqualTo: displayName)
              .get(),
      builder: (context, snapshot) {
        int postCount = 0;
        if (snapshot.hasData) {
          postCount = snapshot.data!.docs.length;
        }

        return GestureDetector(
          onTap: () => _showRoomPosts(context, number, displayName),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child:
                      isSpecial
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
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
                          : CircleAvatar(
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
                ),
              ),
              if (postCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$postCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showRoomPosts(BuildContext context, String roomId, String roomName) {
    showDialog(
      context: context,
      builder:
          (context) => FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('lost_found_items')
                    .where('building', isEqualTo: roomName)
                    .orderBy('createdAt', descending: true)
                    .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return AlertDialog(
                  title: const Text('เกิดข้อผิดพลาด'),
                  content: Text(snapshot.error.toString()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ],
                );
              }

              final posts =
                  snapshot.data!.docs
                      .map(
                        (doc) => Post.fromJson({
                          ...doc.data() as Map<String, dynamic>,
                          'id': doc.id,
                        }),
                      )
                      .toList();

              return RoomPostsDialog(
                roomName: roomName,
                buildingName: 'Zone B',
                posts: posts,
              );
            },
          ),
    );
  }
}
