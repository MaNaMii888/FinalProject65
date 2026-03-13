import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ 1. เพิ่ม import นี้
import 'package:project01/models/post.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/chat_service.dart';
import 'package:project01/Screen/page/chat/chat_room_page.dart';
import 'package:project01/utils/category_utils.dart';

class PostDetailSheet extends StatefulWidget {
  final Post post;

  const PostDetailSheet({super.key, required this.post});

  @override
  State<PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<PostDetailSheet> {
  bool _isLoadingChat = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final post = widget.post;

    // สร้างตัวแปรสีตามสถานะ (ของหาย=แดง / เจอของ=เขียว)
    final Color statusColor =
        post.isLostItem ? colorScheme.secondary : const Color(0xFF4CAF50);
    final backgroundColor = colorScheme.surface;
    final contentColor = colorScheme.onPrimary;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder:
          (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: contentColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
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
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      height: 250,
                                      color: Colors.grey[800],
                                      child: Icon(
                                        Icons.error,
                                        color: contentColor,
                                      ),
                                    ),
                              ),
                            ),
                            // ป้ายสถานะ
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  post.isLostItem ? 'ของหาย' : 'เจอของ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // หัวข้อและสถานะ
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.title,
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                color: contentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  post.status == 'found_owner'
                                      ? Colors.green[100]
                                      : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              post.status == 'found_owner'
                                  ? 'เจอเจ้าของแล้ว'
                                  : 'กำลังดำเนินการ',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    post.status == 'found_owner'
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // คำบรรยาย
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: contentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.description.isEmpty
                              ? 'ไม่มีรายละเอียด'
                              : post.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: contentColor.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(color: contentColor.withOpacity(0.2)),

                      // ข้อมูลเพิ่มเติม
                      _buildInfoTile(
                        icon: Icons.location_on,
                        text: '${post.building} • ${post.location}',
                        color: contentColor,
                      ),
                      _buildInfoTile(
                        icon: Icons.category,
                        text: _getCategoryName(post.category),
                        color: contentColor,
                      ),
                      _buildInfoTile(
                        icon: Icons.access_time,
                        text: 'แจ้งเมื่อ ${_formatDate(post.createdAt)}',
                        color: contentColor,
                      ),

                      const SizedBox(height: 16),

                      // ส่วนติดต่อ (แก้ปุ่มที่นี่)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: statusColor.withOpacity(0.1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.contact_phone,
                                color: contentColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ช่องทางติดต่อ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: contentColor.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    post.contact,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: contentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ✅✅✅ ปุ่ม Copy
                            IconButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: post.contact),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'คัดลอก "${post.contact}" แล้ว',
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.copy,
                                color: contentColor.withOpacity(0.7),
                              ),
                              tooltip: 'คัดลอก',
                            ),

                            // ปุ่มแชท (แสดงเฉพาะเมื่อไม่ใช่ของตัวเอง)
                            if (FirebaseAuth.instance.currentUser != null &&
                                FirebaseAuth.instance.currentUser!.uid !=
                                    post.userId)
                              ElevatedButton.icon(
                                onPressed:
                                    _isLoadingChat
                                        ? null
                                        : () async {
                                          setState(() {
                                            _isLoadingChat = true;
                                          });
                                          final currentUserId =
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser!
                                                  .uid;
                                          try {
                                            final chatId = await ChatService()
                                                .createOrGetChatRoom(
                                                  currentUserId,
                                                  post.userId, // เจ้าของโพสต์
                                                  post.id,
                                                );

                                            if (context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => ChatRoomPage(
                                                        chatId: chatId,
                                                        otherUserId:
                                                            post.userId,
                                                        postId: post.id,
                                                        initialUserName:
                                                            post.userName,
                                                      ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'ไม่สามารถเริ่มแชทได้: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() {
                                                _isLoadingChat = false;
                                              });
                                            }
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor:
                                      colorScheme
                                          .onPrimaryFixed, // สีขาวหรือสีตัดกัน
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon:
                                    _isLoadingChat
                                        ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.chat_bubble,
                                          size: 18,
                                        ),
                                label: Text(
                                  _isLoadingChat ? 'กำลังโหลด...' : 'แชทเลย',
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color.withOpacity(0.9), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _getCategoryName(String categoryId) {
    return CategoryUtils.getCategoryName(categoryId);
  }
}
