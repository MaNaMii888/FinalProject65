import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/notifications_service.dart';
import 'package:project01/utils/time_formatter.dart';
import 'package:project01/services/chat_service.dart';
import 'package:project01/Screen/page/chat/chat_room_page.dart';
import 'package:project01/widgets/branded_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final primaryColor = Theme.of(context).colorScheme.primary;
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
            child: BrandedLoading(size: 40, color: onPrimaryColor),
          );
        }

        final threeMonthsAgo = DateTime.now().subtract(
          const Duration(days: 90),
        );

        final notifications =
            snapshot.data
                ?.where((item) => item.type == 'smart_match')
                .where((item) => !item.createdAt.isBefore(threeMonthsAgo))
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

  // ✅✅✅ ดีไซน์ X-Style (Feed เต็มจอ)
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
        _contactOwner(notification);
      },
      child: Container(
        // พื้นหลังสี Primary + เส้นคั่นด้านล่าง
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
                  TimeFormatter.getTimeAgo(notification.createdAt),
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
                              size: 28,
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
                      // แสดงโพสต์ที่เกี่ยวข้อง (ถ้ามี)
                      // (อาจต้องปรับตามโครงสร้างข้อมูลใน NotificationModel)
                    ],
                  ),
                ),
              ],
            ),

            // Reasons (กล่องเหตุผล)
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

            // Actions (ปุ่ม)
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 66),
              child: Row(
                children: [
                  // ปุ่ม ไม่ใช่
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
                  // ปุ่ม ใช่ (ติดต่อ)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!notification.isRead) {
                          NotificationService.markAsRead(notification.id);
                        }
                        _contactOwner(notification);
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text(
                        'ของฉัน / แชทเลย',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

  // ---------- Helper Functions ----------

  Color _getMatchColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.7) return Colors.orange;
    return Colors.blue;
  }

  // ฟังก์ชันจัดการเมื่อกด "ไม่ใช่" (ลบการแจ้งเตือนออก)
  void _handleNotMatch(NotificationModel notification) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_rounded,
                    size: 32,
                    color: colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ลบการแจ้งเตือน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontFamily: 'Prompt',
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'คุณต้องการลบการแจ้งเตือนนี้\nใช่หรือไม่?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 14,
                      fontFamily: 'Prompt',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
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
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.surface,
                            foregroundColor: Colors.white,
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

    if (confirm == true) {
      await NotificationService.deleteNotification(notification.id);
    }
  }

  void _contactOwner(NotificationModel notification) {
    bool isLoadingChat = false;
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text('ข้อมูลติดต่อ'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.postTitle ?? 'ไม่ระบุสิ่งของ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            notification.postType == 'lost'
                                ? Icons.search
                                : Icons.check_box,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.postType == 'lost'
                                ? 'ของหาย'
                                : 'ของเจอ',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.phone, color: Colors.green),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.data['contact'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: notification.data['contact'] ?? '',
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('คัดลอกเบอร์ติดต่อแล้ว'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        subtitle: const Text('เบอร์โทร / Line ID'),
                      ),
                      if ((notification.data['location'] ?? '').isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.orange,
                          ),
                          title: Text(notification.data['location']),
                          subtitle: const Text('สถานที่'),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          isLoadingChat
                              ? null
                              : () async {
                                setStateDialog(() {
                                  isLoadingChat = true;
                                });
                                try {
                                  String? targetPostId =
                                      notification.postId ??
                                      notification.data['matchedPostId'] ??
                                      notification.data['newItemId'] ??
                                      notification.data['existingItemId'];
                                  if (targetPostId == null) {
                                    throw Exception('ไม่พบรหัสโพสต์');
                                  }

                                  final postDoc =
                                      await FirebaseFirestore.instance
                                          .collection('lost_found_items')
                                          .doc(targetPostId)
                                          .get();
                                  if (!postDoc.exists) {
                                    throw Exception('ไม่พบข้อมูลโพสต์ในระบบ');
                                  }

                                  final postUserId = postDoc.data()?['userId'];
                                  final postTitle =
                                      postDoc.data()?['title'] ?? 'Item';
                                  final postUserName =
                                      postDoc.data()?['userName'] ?? 'User';
                                  final currentUid =
                                      FirebaseAuth.instance.currentUser!.uid;

                                  if (postUserId == currentUid) {
                                    throw Exception(
                                      'คุณไม่สามารถแชทกับตัวเองได้',
                                    );
                                  }

                                  String? relatedPostId =
                                      notification.relatedPostId ??
                                      notification.data['relatedPostId'] ??
                                      notification.data['existingItemId'];
                                  if (relatedPostId == targetPostId) {
                                    relatedPostId =
                                        notification.data['newItemId'];
                                  }

                                  final chatId = await ChatService()
                                      .createOrGetChatRoom(
                                        currentUid,
                                        postUserId,
                                        targetPostId,
                                        relatedPostId: relatedPostId,
                                      );

                                  // ส่งข้อความระบบอัตโนมัติ
                                  final chatDoc =
                                      await FirebaseFirestore.instance
                                          .collection('chats')
                                          .doc(chatId)
                                          .get();
                                  final lastMessage =
                                      chatDoc.data()?['lastMessage'] as String?;
                                  if (lastMessage == null ||
                                      !lastMessage.contains(
                                        '[AI Smart Match]',
                                      )) {
                                    double notifyMatchScore =
                                        notification.matchScore ?? 0;
                                    final matchMessage =
                                        '🤖 [AI Smart Match]\nดูเหมือนว่าเราอาจจะพบของของคุณ!\n- ของในโพสต์: $postTitle\n(ความแม่นยำ: ${(notifyMatchScore * 100).toStringAsFixed(0)}%)\nลองตรวจสอบรายละเอียดและพูดคุยกันดูนะครับ!';
                                    await ChatService().sendMessage(
                                      chatId,
                                      'system',
                                      matchMessage,
                                      type: 'system',
                                    );
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context); // ปิด popup
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ChatRoomPage(
                                              chatId: chatId,
                                              otherUserId: postUserId,
                                              postId: targetPostId,
                                              initialUserName: postUserName,
                                            ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('เกิดข้อผิดพลาด: $e'),
                                      ),
                                    );
                                  }
                                  setStateDialog(() {
                                    isLoadingChat = false;
                                  });
                                }
                              },
                      icon:
                          isLoadingChat
                              ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: BrandedLoading(size: 20),
                              )
                              : const Icon(Icons.chat, size: 18),
                      label: Text(isLoadingChat ? 'กำลังโหลด...' : 'แชทเลย'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryFixed,
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}
