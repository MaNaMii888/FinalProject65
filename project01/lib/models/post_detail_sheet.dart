import 'package:flutter/material.dart';
import 'package:project01/models/post.dart';

class PostDetailSheet extends StatelessWidget {
  final Post post;

  const PostDetailSheet({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5, // เพิ่มค่าขั้นต่ำ
      maxChildSize: 0.95, // เพิ่มค่าสูงสุด
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // เพิ่ม handle bar สำหรับการลาก
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // รูปภาพ
                  if (post.imageUrl.isNotEmpty)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        // เพิ่มป้ายสถานะ
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: post.isLostItem
                                  ? Colors.red[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              post.isLostItem ? 'ของหาย' : 'เจอของ',
                              style: TextStyle(
                                color: post.isLostItem
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // รายละเอียด
                  Text(post.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(post.description),
                  const SizedBox(height: 16),
                  // ข้อมูลสถานที่และการติดต่อ
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text('${post.building} • ${post.location}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(post.category),
                  ),
                  ListTile(
                    leading: const Icon(Icons.contact_phone),
                    title: Text(post.contact),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement contact action
                      },
                      child: const Text('ติดต่อ'),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(
                      'แจ้งเมื่อ ${_formatDate(post.createdAt)}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // TODO: Implement proper date formatting
    return date.toString();
  }
}
