import 'package:flutter/material.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/post_action_buttons.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    top: 100, // พื้นที่สำหรับ TopBar
                    bottom: 140, // พื้นที่สำหรับปุ่มด้านล่าง
                  ),
                  children: [
                    const SizedBox(height: 20),
                    // Recent Posts Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'โพสต์ล่าสุด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Posts List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      itemBuilder: (context, index) => _buildPostItem(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // TopBar at top
          const Positioned(top: 0, left: 0, right: 0, child: CustomTopBar()),
          // Action Buttons at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PostActionButtons(
              onLostPress: () {
                // TODO: Navigate to lost item form
              },
              onFoundPress: () {
                // TODO: Navigate to found item form
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัวโพสต์
            const Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://placeholder.com/50x50',
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ชื่อผู้โพสต์',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('2 ชั่วโมงที่แล้ว'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // เนื้อหาโพสต์
            const Text(
              'เนื้อหาโพสต์จะแสดงตรงนี้...',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // ปุ่มดำเนินการ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.thumb_up_outlined),
                  label: const Text('ถูกใจ'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.comment_outlined),
                  label: const Text('แสดงความคิดเห็น'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('แชร์'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
