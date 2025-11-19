import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/models/post.dart';

class SmartNotificationScreen extends StatefulWidget {
  const SmartNotificationScreen({super.key});

  @override
  State<SmartNotificationScreen> createState() =>
      _SmartNotificationScreenState();
}

class _SmartNotificationScreenState extends State<SmartNotificationScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<SmartNotificationItem> smartNotifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSmartNotifications();
  }

  // ✅ 1. เปลี่ยนมาดึงข้อมูลจาก Database โดยตรง (แทนการคำนวณเอง)
  Future<void> _loadSmartNotifications() async {
    if (currentUserId == null) return;

    setState(() => isLoading = true);

    try {
      // ดึงข้อมูลจาก Collection 'smart_notifications' ที่ระบบบันทึกไว้
      final snapshot =
          await FirebaseFirestore.instance
              .collection('smart_notifications')
              .where('userId', isEqualTo: currentUserId)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();

      List<SmartNotificationItem> notifications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // ดึงข้อมูลโพสต์หลัก (ของคนอื่น)
        final postDoc =
            await FirebaseFirestore.instance
                .collection('lost_found_items')
                .doc(data['postId'])
                .get();

        if (postDoc.exists) {
          final post = Post.fromJson({...postDoc.data()!, 'id': postDoc.id});

          // ดึงข้อมูลโพสต์ของเราที่เกี่ยวข้อง (ถ้ามี)
          Post? relatedUserPost;
          if (data['relatedPostId'] != null) {
            final relatedDoc =
                await FirebaseFirestore.instance
                    .collection('lost_found_items')
                    .doc(data['relatedPostId'])
                    .get();

            if (relatedDoc.exists) {
              relatedUserPost = Post.fromJson({
                ...relatedDoc.data()!,
                'id': relatedDoc.id,
              });
            }
          }

          notifications.add(
            SmartNotificationItem(
              post: post,
              matchScore: (data['matchScore'] as num).toDouble(),
              matchReasons: List<String>.from(data['matchReasons'] ?? []),
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              relatedUserPost: relatedUserPost,
              notificationId: doc.id, // ✅ เก็บ ID ไว้ลบ
              isRead: data['isRead'] ?? false,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          smartNotifications = notifications;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading smart notifications: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ฟังก์ชันลบการแจ้งเตือน (เมื่อตอบ "ไม่ใช่")
  Future<void> _removeNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('smart_notifications')
          .doc(notificationId)
          .delete();

      setState(() {
        smartNotifications.removeWhere(
          (item) => item.notificationId == notificationId,
        );
      });
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = (statusBarHeight * 0.3).clamp(8.0, 20.0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          SizedBox(height: topPadding),
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'รายการที่ตรงกัน',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Prompt',
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : smartNotifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ไม่มีรายการที่ตรงกันในขณะนี้',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontFamily: 'Prompt',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: smartNotifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(smartNotifications[index]);
      },
    );
  }

  // ✅ 2. ปรับปรุงการ์ดให้มีปุ่ม "ใช่/ไม่ใช่"
  Widget _buildNotificationCard(SmartNotificationItem notification) {
    final post = notification.post;
    final matchPercentage = (notification.matchScore * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: คะแนนความตรง + อาคาร
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMatchColor(notification.matchScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$matchPercentage% ตรงกัน',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'อาคาร ${post.building}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _getTimeAgo(notification.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content: รูป + ข้อความ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปภาพ หรือ Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: post.isLostItem ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    image:
                        post.imageUrl.isNotEmpty
                            ? DecorationImage(
                              image: NetworkImage(post.imageUrl),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      post.imageUrl.isEmpty
                          ? Icon(
                            post.isLostItem
                                ? Icons.help_outline
                                : Icons.check_circle_outline,
                            color: post.isLostItem ? Colors.red : Colors.green,
                            size: 30,
                          )
                          : null,
                ),
                const SizedBox(width: 12),

                // รายละเอียด
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        post.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // แสดงเหตุผลการจับคู่ (ถ้ามี)
                      if (notification.matchReasons.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• ${notification.matchReasons.first}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ 3. ส่วนคำถามยืนยัน "ใช่/ไม่ใช่"
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'ใช่สิ่งที่คุณตามหาหรือไม่?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // ปุ่ม ไม่ใช่
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRejectDialog(notification),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('ไม่ใช่'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ปุ่ม ใช่
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showContactDialog(post),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('ใช่ (ติดต่อ)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.7) return Colors.orange;
    return Colors.blue;
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} วันที่แล้ว';
    if (diff.inHours > 0) return '${diff.inHours} ชม. ที่แล้ว';
    return '${diff.inMinutes} นาทีที่แล้ว';
  }

  // Dialog ยืนยันการปฏิเสธ
  void _showRejectDialog(SmartNotificationItem notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ยืนยัน'),
            content: const Text('รายการนี้จะถูกลบออกจากการแจ้งเตือน'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (notification.notificationId != null) {
                    _removeNotification(notification.notificationId!);
                  }
                },
                child: const Text(
                  'ยืนยัน',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // Dialog ติดต่อ
  void _showContactDialog(Post post) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ข้อมูลติดต่อ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(
                    post.userName.isEmpty ? 'ไม่ระบุชื่อ' : post.userName,
                  ),
                  subtitle: const Text('ผู้โพสต์'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: Text(post.contact),
                  subtitle: const Text('ช่องทางการติดต่อ'),
                  onTap: () {
                    // สามารถเพิ่มโค้ด url_launcher ตรงนี้เพื่อโทรออกได้
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ],
          ),
    );
  }
}

// ✅ Model ที่รองรับ ID จาก Firestore (เหมือนเดิมแต่เพิ่ม field)
class SmartNotificationItem {
  final Post post;
  final double matchScore;
  final List<String> matchReasons;
  final DateTime createdAt;
  final Post? relatedUserPost;
  final String? notificationId; // ใช้สำหรับลบ
  final bool isRead;

  SmartNotificationItem({
    required this.post,
    required this.matchScore,
    required this.matchReasons,
    required this.createdAt,
    this.relatedUserPost,
    this.notificationId,
    this.isRead = false,
  });
}
