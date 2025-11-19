import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/notifications_service.dart';

class SmartNotificationPopup extends StatefulWidget {
  const SmartNotificationPopup({super.key});

  @override
  State<SmartNotificationPopup> createState() => _SmartNotificationPopupState();
}

class _SmartNotificationPopupState extends State<SmartNotificationPopup> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    // ดึงสีจาก Theme
    final primaryColor = Theme.of(context).colorScheme.surface;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: primaryColor, // ✅ พื้นหลัง Popup เป็นสี Primary (เข้ม)
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: onPrimaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: onPrimaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'การแจ้งเตือน',
                    style: TextStyle(
                      color: onPrimaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Prompt',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: onPrimaryColor),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีการแจ้งเตือนที่ตรงกับความสนใจของคุณ',
              style: TextStyle(
                fontSize: 18,
                color: textColor.withOpacity(0.7),
                fontFamily: 'Prompt',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

        final notifications =
            snapshot.data
                ?.where((item) => item.type == 'smart_match')
                .toList() ??
            [];

        if (notifications.isEmpty) {
          return _buildEmptyState(onPrimaryColor);
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(notifications[index]);
          },
        );
      },
    );
  }

  // ✅✅✅ ดีไซน์ใหม่: แบบ X (Feed) เต็มจอ ไม่มี Card
  Widget _buildNotificationCard(NotificationModel notification) {
    final matchScore = notification.matchScore ?? 0;
    final matchPercentage = (matchScore * 100).round();

    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return InkWell(
      onTap: () async {
        if (!notification.isRead) {
          await NotificationService.markAsRead(notification.id);
        }
        _viewPostDetails(notification);
      },
      child: Container(
        // ✅ พื้นหลังสี Primary + เส้นคั่นด้านล่าง
        decoration: BoxDecoration(
          color: primaryColor,
          border: Border(
            bottom: BorderSide(
              color: onPrimaryColor.withOpacity(0.2), // เส้นสีจางๆ
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
                                  ? Icons.search
                                  : Icons.find_in_page,
                              color:
                                  notification.postType == 'lost'
                                      ? Colors.red[300]
                                      : Colors.green[300],
                            ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.postTitle ?? notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onPrimaryColor,
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
                      if (notification.matchReasons.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• ${notification.matchReasons.first}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[300],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Reasons
            if (notification.matchReasons.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12, left: 66),
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

            // Actions
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 66),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleNotMatch(notification),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onPrimaryColor,
                        side: BorderSide(
                          color: onPrimaryColor.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'ไม่ใช่',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleMatchConfirmed(notification),
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

  // --- Helper Functions ---

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

  // ฟังก์ชันจัดการเมื่อกด "ไม่ใช่" (ลบการแจ้งเตือนออก)
  void _handleNotMatch(NotificationModel notification) async {
    // ดึงสีจาก Theme
    final colorScheme = Theme.of(context).colorScheme;

    // แสดง Dialog ที่ตกแต่งแล้ว
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                Colors.white, // หรือใช้ colorScheme.onPrimary ถ้าชอบสีเทาอ่อนๆ
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // มุมมนสวยงาม
            ),
            contentPadding: EdgeInsets.zero, // จัด Layout เอง
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                // 1. ไอคอนถังขยะด้านบน (ใช้สีแดงจาก surface)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(
                      0.1,
                    ), // พื้นหลังสีแดงจางๆ
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_rounded,
                    size: 32,
                    color: colorScheme.surface, // ไอคอนสีแดง
                  ),
                ),
                const SizedBox(height: 16),

                // 2. หัวข้อ
                Text(
                  'ลบการแจ้งเตือน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary, // สีดำเข้ม
                    fontFamily: 'Prompt',
                  ),
                ),

                const SizedBox(height: 8),

                // 3. ข้อความรายละเอียด
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'คุณต้องการลบการแจ้งเตือนนี้\nใช่หรือไม่?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.secondary, // สีเทาเข้ม
                      fontSize: 14,
                      fontFamily: 'Prompt',
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. ปุ่มกด (วางแนวนอน)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // ปุ่ม "ยกเลิก"
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: colorScheme.secondary,
                          ),
                          child: const Text(
                            'ยกเลิก',
                            style: TextStyle(fontFamily: 'Prompt'),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ปุ่ม "ยืนยัน" (สีแดง)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.surface, // สีแดงตามธีม
                            foregroundColor: Colors.white, // ตัวหนังสือสีขาว
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ยืนยัน',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontWeight: FontWeight.bold,
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

    // Logic การลบข้อมูล (เหมือนเดิม)
    if (confirm == true) {
      await NotificationService.deleteNotification(notification.id);
    }
  }

  void _handleMatchConfirmed(NotificationModel notification) {
    _contactOwner(notification);
  }

  void _contactOwner(NotificationModel notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ติดต่อเจ้าของ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(
                    (notification.data['userName'] ?? '').isEmpty
                        ? 'ไม่ระบุชื่อ'
                        : notification.data['userName'],
                  ),
                  subtitle: const Text('ผู้โพสต์'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(notification.data['contact'] ?? '-'),
                  subtitle: const Text('เบอร์โทร / Line'),
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
