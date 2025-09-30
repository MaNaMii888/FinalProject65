import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/feature/room_posts_dialog.dart';
import 'package:project01/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FloorPlanA extends StatelessWidget {
  const FloorPlanA({super.key});

  @override
  Widget build(BuildContext context) {
    // ตรวจหา safe area และ status bar แบบ dynamic
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = (statusBarHeight * 0.1).clamp(4.0, 12.0);

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SizedBox(height: topPadding),
          Expanded(
            child: Column(
              children: [
                // แถว 1: 8, 7, 5
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildingBox(context, "8")),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildingBox(context, "7")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildingBox(context, "5")),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // แถว 2: 9, 6, 4
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildingBox(context, "9")),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildingBox(context, "6")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildingBox(context, "4")),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // แถว 3: 10, 2, 3
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildingBox(context, "10")),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildingBox(context, "2")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildingBox(context, "3")),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // แถว 4: 11, 1, 12
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(child: _buildingBox(context, "11")),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Expanded(flex: 1, child: _buildingBox(context, "1")),
                            const SizedBox(height: 4),
                            Expanded(flex: 1, child: Container()), // พื้นที่ว่าง
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _buildingBox(context, "12")),
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

  /// Widget กล่องอาคาร พร้อม badge แสดงจำนวนโพสต์
  Widget _buildingBox(BuildContext context, String number) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('lost_found_items')
          .where('building', isEqualTo: 'อาคาร $number')
          .get(),
      builder: (context, snapshot) {
        int postCount = 0;
        if (snapshot.hasData) {
          postCount = snapshot.data!.docs.length;
        }

        return GestureDetector(
          onTap: () => _showRoomPosts(context, number, 'อาคาร $number'),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CircleAvatar(
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
                ),
              ),
              // แสดง badge จำนวนโพสต์
              if (postCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
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

  /// โหลดโพสต์จาก Firestore ของตึกที่กด
  void _showRoomPosts(BuildContext context, String roomId, String roomName) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('lost_found_items')
            .where('building', isEqualTo: 'อาคาร $roomId')
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

          final posts = snapshot.data!.docs
              .map((doc) => Post.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
              .toList();

          return RoomPostsDialog(
            roomName: roomName,
            buildingName: 'Zone A',
            posts: posts,
          );
        },
      ),
    );
  }
}
