import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/notifications_service.dart';

// 1. Notification Popup (Modal Bottom Sheet)
class NotificationPopup {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationBottomSheet(),
    );
  }
}

class NotificationBottomSheet extends StatefulWidget {
  const NotificationBottomSheet({super.key});

  @override
  State<NotificationBottomSheet> createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'การแจ้งเตือน',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    StreamBuilder<int>(
                      stream:
                          currentUser != null
                              ? NotificationService.getUnreadCount(
                                currentUser.uid,
                              )
                              : Stream.value(0),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        if (unreadCount == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount ใหม่',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.mark_email_read),
                      onPressed: () => _markAllAsRead(),
                      tooltip: 'อ่านทั้งหมด',
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: const Text('ดูทั้งหมด'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildNotificationList(currentUser)),
        ],
      ),
    );
  }

  Widget _buildNotificationList(User? currentUser) {
    if (currentUser == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อดูการแจ้งเตือน'));
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService.getUserNotifications(
        currentUser.uid,
        limit: 10,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('ลองใหม่'),
                ),
              ],
            ),
          );
        }
        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'ไม่มีการแจ้งเตือน',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              isCompact: true,
            );
          },
        );
      },
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
    }
    Navigator.pop(context);
    switch (notification.type) {
      case 'match_found':
        _handleMatchNotification(notification);
        break;
      case 'item_claimed':
        _handleItemClaimedNotification(notification);
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _handleMatchNotification(NotificationModel notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'เปิดรายละเอียดการจับคู่: ${notification.data['newItemTitle']}',
        ),
        action: SnackBarAction(
          label: 'ดูรายละเอียด',
          onPressed: () {
            // TODO: Navigate to item details
          },
        ),
      ),
    );
  }

  void _handleItemClaimedNotification(NotificationModel notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${notification.data['claimerName']} ต้องการรับสิ่งของของคุณ',
        ),
        action: SnackBarAction(
          label: 'ดูรายละเอียด',
          onPressed: () {
            // TODO: Navigate to claim details
          },
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(notification.title),
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

  void _markAllAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final success = await NotificationService.markAllAsRead(currentUser.uid);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อ่านทั้งหมดแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// 2. Full Screen Notification Screen
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('การแจ้งเตือน')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'กรุณาเข้าสู่ระบบเพื่อดูการแจ้งเตือน',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          StreamBuilder<Map<String, int>>(
            stream: _getNotificationStats(currentUser.uid),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {};
              final unread = stats['unread'] ?? 0;
              if (unread == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('$unread ใหม่'),
                  backgroundColor: Colors.red,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, currentUser.uid),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read),
                        SizedBox(width: 8),
                        Text('อ่านทั้งหมด'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.red),
                        SizedBox(width: 8),
                        Text('ลบทั้งหมด', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'stats',
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart),
                        SizedBox(width: 8),
                        Text('สถิติ'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ทั้งหมด'),
            Tab(text: 'จับคู่'),
            Tab(text: 'รับสิ่งของ'),
            Tab(text: 'ทั่วไป'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationTab(currentUser.uid, null),
          _buildNotificationTab(currentUser.uid, 'match_found'),
          _buildNotificationTab(currentUser.uid, 'item_claimed'),
          _buildNotificationTab(currentUser.uid, 'general'),
        ],
      ),
    );
  }

  Widget _buildNotificationTab(String userId, String? filterType) {
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService.getUserNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('ลองใหม่'),
                ),
              ],
            ),
          );
        }
        final allNotifications = snapshot.data ?? [];
        final notifications =
            filterType == null
                ? allNotifications
                : allNotifications.where((n) => n.type == filterType).toList();
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getEmptyIcon(filterType), size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(filterType),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onDelete: () => _deleteNotification(notification.id),
            );
          },
        );
      },
    );
  }

  IconData _getEmptyIcon(String? filterType) {
    switch (filterType) {
      case 'match_found':
        return Icons.link_off;
      case 'item_claimed':
        return Icons.check_circle_outline;
      case 'general':
        return Icons.info_outline;
      default:
        return Icons.notifications_none;
    }
  }

  String _getEmptyMessage(String? filterType) {
    switch (filterType) {
      case 'match_found':
        return 'ไม่มีการแจ้งเตือนการจับคู่';
      case 'item_claimed':
        return 'ไม่มีการแจ้งเตือนการรับสิ่งของ';
      case 'general':
        return 'ไม่มีการแจ้งเตือนทั่วไป';
      default:
        return 'ไม่มีการแจ้งเตือน';
    }
  }

  Stream<Map<String, int>> _getNotificationStats(String userId) {
    return NotificationService.getUserNotifications(userId).asyncMap((
      notifications,
    ) async {
      int total = notifications.length;
      int unread = notifications.where((n) => !n.isRead).length;
      int matchFound =
          notifications.where((n) => n.type == 'match_found').length;
      int itemClaimed =
          notifications.where((n) => n.type == 'item_claimed').length;
      int general = notifications.where((n) => n.type == 'general').length;
      return {
        'total': total,
        'unread': unread,
        'match_found': matchFound,
        'item_claimed': itemClaimed,
        'general': general,
      };
    });
  }

  void _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
    }
    switch (notification.type) {
      case 'match_found':
        _handleMatchNotification(notification);
        break;
      case 'item_claimed':
        _handleItemClaimedNotification(notification);
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _handleMatchNotification(NotificationModel notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('การจับคู่สิ่งของ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message),
                const SizedBox(height: 16),
                if (notification.data['matchScore'] != null)
                  Row(
                    children: [
                      const Text('ความแม่นยำ: '),
                      Text(
                        '${notification.data['matchScore']}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to item details
                },
                child: const Text('ดูรายละเอียด'),
              ),
            ],
          ),
    );
  }

  void _handleItemClaimedNotification(NotificationModel notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('การขอรับสิ่งของ'),
            content: Text(notification.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to claim management
                },
                child: const Text('จัดการ'),
              ),
            ],
          ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(notification.title),
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

  void _handleMenuAction(String action, String userId) async {
    switch (action) {
      case 'mark_all_read':
        final success = await NotificationService.markAllAsRead(userId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อ่านทั้งหมดแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
      case 'delete_all':
        _confirmDeleteAll(userId);
        break;
      case 'stats':
        _showStats(userId);
        break;
    }
  }

  void _confirmDeleteAll(String userId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ลบการแจ้งเตือนทั้งหมด'),
            content: const Text(
              'คุณแน่ใจหรือไม่ที่จะลบการแจ้งเตือนทั้งหมด? ข้อมูลจะไม่สามารถกู้คืนได้',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success =
                      await NotificationService.deleteAllNotifications(userId);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ลบการแจ้งเตือนทั้งหมดแล้ว'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('ลบทั้งหมด'),
              ),
            ],
          ),
    );
  }

  void _showStats(String userId) async {
    final stats = await NotificationService.getNotificationStats(userId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('สถิติการแจ้งเตือน'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow('ทั้งหมด', stats['total'] ?? 0),
                _buildStatRow('ยังไม่อ่าน', stats['unread'] ?? 0, Colors.red),
                _buildStatRow(
                  'การจับคู่',
                  stats['match_found'] ?? 0,
                  Colors.green,
                ),
                _buildStatRow(
                  'การรับสิ่งของ',
                  stats['item_claimed'] ?? 0,
                  Colors.orange,
                ),
                _buildStatRow('ทั่วไป', stats['general'] ?? 0, Colors.blue),
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

  Widget _buildStatRow(String label, int count, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(String notificationId) async {
    final success = await NotificationService.deleteNotification(
      notificationId,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบการแจ้งเตือนแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// 3. Enhanced NotificationCard
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isCompact;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 4 : 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
            size: isCompact ? 16 : 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: isCompact ? 14 : 16,
          ),
          maxLines: isCompact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              maxLines: isCompact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: isCompact ? 12 : 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatDateTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (notification.type == 'match_found' &&
                    notification.data['matchScore'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${notification.data['matchScore']}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            if (onDelete != null && !isCompact) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, size: 16),
                onPressed: onDelete,
                color: Colors.red,
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'match_found':
        return Colors.green;
      case 'item_claimed':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'match_found':
        return Icons.link;
      case 'item_claimed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }
}
