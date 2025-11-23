import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/models/post.dart';

class SmartNotificationPopup extends StatefulWidget {
  const SmartNotificationPopup({super.key});

  @override
  State<SmartNotificationPopup> createState() => _SmartNotificationPopupState();
}

class _SmartNotificationPopupState extends State<SmartNotificationPopup> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<SmartNotificationItem> smartNotifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSmartNotifications();
  }

  Future<void> _loadSmartNotifications() async {
    if (currentUserId == null) {
      debugPrint('❌ No current user ID');
      return;
    }

    setState(() => isLoading = true);

    try {
      debugPrint('🔍 Loading notifications for user: $currentUserId');

      final snapshot =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: currentUserId)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();

      debugPrint('📊 Found ${snapshot.docs.length} notification documents');

      List<SmartNotificationItem> notifications = [];

      for (var doc in snapshot.docs) {
        debugPrint('📝 Processing notification: ${doc.id}');
        final data = doc.data();
        final dataMap = Map<String, dynamic>.from(data['data'] ?? {});

        // รองรับทั้ง field ใหม่และเก่า
        final postId =
            data['postId'] ?? dataMap['newPostId'] ?? dataMap['matchingPostId'];
        final relatedPostId =
            data['relatedPostId'] ??
            dataMap['relatedPostId'] ??
            dataMap['matchingPostId'];
        final matchScore =
            (data['matchScore'] as num?)?.toDouble() ??
            (dataMap['matchPercentage'] as num?)?.toDouble() ??
            0.0;

        debugPrint(
          '   postId: $postId, relatedPostId: $relatedPostId, matchScore: $matchScore',
        );

        if (postId == null) {
          debugPrint('⚠️ Skipping notification ${doc.id}: no postId found');
          continue;
        }

        final postDoc =
            await FirebaseFirestore.instance
                .collection('lost_found_items')
                .doc(postId)
                .get();

        if (postDoc.exists) {
          final post = Post.fromJson({...postDoc.data()!, 'id': postDoc.id});
          Post? relatedUserPost;
          if (relatedPostId != null) {
            final relatedDoc =
                await FirebaseFirestore.instance
                    .collection('lost_found_items')
                    .doc(relatedPostId)
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
              matchScore: matchScore,
              matchReasons: List<String>.from(data['matchReasons'] ?? []),
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              relatedUserPost: relatedUserPost,
              notificationId: doc.id,
              isRead: data['isRead'] ?? false,
            ),
          );
          debugPrint('✅ Added notification to list');
        } else {
          debugPrint('⚠️ Post document not found for ID: $postId');
        }
      }

      debugPrint('📋 Total notifications loaded: ${notifications.length}');

      if (mounted) {
        setState(() {
          smartNotifications = notifications;
          isLoading = false;
        });
        debugPrint(
          '✅ UI updated with ${smartNotifications.length} notifications',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading smart notifications: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) setState(() => isLoading = false);
    }
  }

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
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(color: onPrimaryColor),
                    )
                    : smartNotifications.isEmpty
                    ? _buildEmptyState(onPrimaryColor)
                    : _buildNotificationList(),
          ),
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

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: EdgeInsets.zero, // ✅ ลบ Padding เพื่อให้ชิดขอบ
      itemCount: smartNotifications.length,
      itemBuilder: (context, index) {
        final notification = smartNotifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  // ✅✅✅ ดีไซน์ใหม่: แบบ X (Feed) เต็มจอ ไม่มี Card
  Widget _buildNotificationCard(SmartNotificationItem notification) {
    final post = notification.post;
    final matchPercentage = (notification.matchScore * 100).round();

    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return InkWell(
      onTap: () async {
        if (notification.notificationId != null && !notification.isRead) {
          await _markNotificationAsRead(notification.notificationId!);
        }
        _viewPostDetails(post);
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
                    color: _getMatchColor(notification.matchScore),
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
                        post.imageUrl.isNotEmpty
                            ? Image.network(post.imageUrl, fit: BoxFit.cover)
                            : Icon(
                              post.isLostItem
                                  ? Icons.search
                                  : Icons.find_in_page,
                              color:
                                  post.isLostItem
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
                        post.title,
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
                        post.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: onPrimaryColor.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (notification.relatedUserPost != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'ตรงกับ: ${notification.relatedUserPost!.title}',
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
                      onPressed: () => _handleMatchConfirmed(post),
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

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  void _handleNotMatch(SmartNotificationItem notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ลบการแจ้งเตือน'),
            content: const Text('คุณต้องการลบการแจ้งเตือนนี้ใช่หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        smartNotifications.remove(notification);
      });
      if (notification.notificationId != null) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.notificationId)
            .delete();
      }
    }
  }

  void _handleMatchConfirmed(Post post) {
    _contactOwner(post);
  }

  void _contactOwner(Post post) {
    final displayName =
        post.userName.isEmpty || post.userName == 'ไม่ระบุชื่อ'
            ? 'ผู้ใช้งาน'
            : post.userName;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ติดต่อเจ้าของของที่โพสต์'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.isLostItem ? '📍 ของหาย' : '✅ ของเจอ',
                  style: TextStyle(
                    fontSize: 14,
                    color: post.isLostItem ? Colors.red : Colors.green,
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text('ชื่อผู้โพสต์'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: Text(
                    post.contact,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text('เบอร์โทร / Line ID'),
                ),
                if (post.building.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_on,
                      color: Colors.orange,
                    ),
                    title: Text(
                      '${post.building}${post.location.isNotEmpty ? ' - ${post.location}' : ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text('สถานที่'),
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

  void _viewPostDetails(Post post) {
    // คุณสามารถใส่โค้ดเปิดหน้า PostDetailSheet ที่นี่ได้
    // หรือใช้ Dialog ง่ายๆ แบบนี้ไปก่อน
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(post.title),
            content: Text(post.description),
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

// Model Class
class SmartNotificationItem {
  final Post post;
  final double matchScore;
  final List<String> matchReasons;
  final DateTime createdAt;
  final Post? relatedUserPost;
  final String? notificationId;
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
