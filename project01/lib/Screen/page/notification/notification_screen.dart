import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/notifications_service.dart';
// อย่าลืม import model ของ NotificationModel ให้ถูกต้องด้วยนะครับ
// เช่น import 'package:project01/models/notification_model.dart';

class SmartNotificationScreen extends StatefulWidget {
  const SmartNotificationScreen({super.key});

  @override
  State<SmartNotificationScreen> createState() =>
      _SmartNotificationScreenState();
}

class _SmartNotificationScreenState extends State<SmartNotificationScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = (statusBarHeight * 0.3).clamp(8.0, 20.0);

    // ดึงสีจาก Theme
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: primaryColor, // ✅ พื้นหลังสี Primary (เข้ม)
      body: Column(
        children: [
          SizedBox(height: topPadding),
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(color: primaryColor),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: onPrimaryColor),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.notifications_active,
                  color: onPrimaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'รายการที่ตรงกัน',
                  style: TextStyle(
                    color: onPrimaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Prompt',
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: onPrimaryColor.withOpacity(0.2)),

          // Content
          Expanded(child: _buildNotificationList(onPrimaryColor)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีรายการที่ตรงกันในขณะนี้',
            style: TextStyle(
              fontSize: 18,
              color: textColor.withOpacity(0.7),
              fontFamily: 'Prompt',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(Color onPrimaryColor) {
    if (currentUserId == null) {
      return _buildEmptyState(onPrimaryColor);
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService.getUserNotifications(currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: onPrimaryColor),
          );
        }

        final items =
            snapshot.data?.where((n) => n.type == 'smart_match').toList() ?? [];

        if (items.isEmpty) {
          return _buildEmptyState(onPrimaryColor);
        }

        return ListView.builder(
          padding: EdgeInsets.zero, // ชิดขอบจอ
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(items[index]);
          },
        );
      },
    );
  }

  // ✅ ปรับ UI เป็นสไตล์ X (Feed เต็มจอ)
  Widget _buildNotificationCard(NotificationModel notification) {
    final matchScore = notification.matchScore ?? 0;
    final matchPercentage = (matchScore * 100).round();

    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return InkWell(
      onTap: () {
        // กดเพื่อดูรายละเอียด
        _viewPostDetails(notification);
        // mark as read logic here if needed
      },
      child: Container(
        // ✅ พื้นหลังสี Primary + เส้นคั่นล่าง
        decoration: BoxDecoration(
          color: primaryColor,
          border: Border(
            bottom: BorderSide(
              color: onPrimaryColor.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: คะแนน + เวลา
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMatchColor(matchScore),
                    borderRadius: BorderRadius.circular(20),
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
                Text(
                  _getTimeAgo(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: onPrimaryColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content: Avatar + Text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: onPrimaryColor.withOpacity(0.1),
                    child:
                        (notification.postImageUrl ?? '').isNotEmpty
                            ? Image.network(
                              notification.postImageUrl!,
                              fit: BoxFit.cover,
                            )
                            : Icon(
                              notification.postType == 'lost'
                                  ? Icons.help_outline
                                  : Icons.check_circle_outline,
                              color:
                                  notification.postType == 'lost'
                                      ? Colors.red[300]
                                      : Colors.green[300],
                              size: 28,
                            ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.postTitle ?? notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onPrimaryColor, // สี onPrimary
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: onPrimaryColor.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Match Reasons (กล่องเหตุผล)
            if (notification.matchReasons.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(
                  top: 12,
                  left: 66,
                ), // เว้นซ้ายให้ตรงข้อความ
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: onPrimaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: onPrimaryColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เหตุผลที่แจ้งเตือน:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: onPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...notification.matchReasons.map(
                      (r) => Text(
                        '• $r',
                        style: TextStyle(
                          fontSize: 12,
                          color: onPrimaryColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Action Buttons (ใช่/ไม่ใช่)
            Padding(
              padding: const EdgeInsets.only(left: 66),
              child: Row(
                children: [
                  // ปุ่ม ไม่ใช่
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(notification),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onPrimaryColor,
                        side: BorderSide(
                          color: onPrimaryColor.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'ไม่ใช่',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ปุ่ม ใช่ (ติดต่อ)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showContactDialog(notification),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text(
                        'ติดต่อ',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
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

  // ---------- Helper Functions (แก้จุดแดง) ----------

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

  void _removeNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  void _showRejectDialog(NotificationModel notification) {
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
                  _removeNotification(notification.id);
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

  void _showContactDialog(NotificationModel notification) {
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
                  title: Text(notification.postTitle ?? 'ไม่ระบุ'),
                  subtitle: const Text('สิ่งของที่เกี่ยวข้อง'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: Text(notification.data['contact'] ?? '-'),
                  subtitle: const Text('ช่องทางการติดต่อ'),
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

  void _viewPostDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(notification.postTitle ?? notification.title),
            content: Text(notification.message),
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
