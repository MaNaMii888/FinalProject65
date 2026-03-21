import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:project01/models/post.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'smart_match', 'match_found', 'item_claimed', 'general'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final String? postId;
  final String? relatedPostId;
  final double? matchScore;
  final List<String> matchReasons;
  final String? postTitle;
  final String? postType;
  final String? postImageUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.createdAt,
    this.isRead = false,
    this.postId,
    this.relatedPostId,
    this.matchScore,
    List<String>? matchReasons,
    this.postTitle,
    this.postType,
    this.postImageUrl,
  }) : matchReasons = matchReasons ?? const [];

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dataMap = Map<String, dynamic>.from(data['data'] ?? {});

    // รองรับทั้ง field ใหม่และเก่า (backward compatibility)
    String? postId =
        data['postId'] ?? dataMap['newPostId'] ?? dataMap['matchingPostId'];
    String? relatedPostId =
        data['relatedPostId'] ??
        dataMap['relatedPostId'] ??
        dataMap['matchingPostId'];
    String? postTitle =
        data['postTitle'] ??
        dataMap['newPostTitle'] ??
        dataMap['matchingPostTitle'];
    String? postType =
        data['postType'] ??
        dataMap['newPostType'] ??
        dataMap['matchingPostType'];

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      data: dataMap,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      postId: postId,
      relatedPostId: relatedPostId,
      matchScore:
          (data['matchScore'] as num?)?.toDouble() ??
          (dataMap['matchPercentage'] as num?)?.toDouble(),
      matchReasons: List<String>.from(data['matchReasons'] ?? const []),
      postTitle: postTitle,
      postType: postType,
      postImageUrl: data['postImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'postId': postId,
      'relatedPostId': relatedPostId,
      'matchScore': matchScore,
      'matchReasons': matchReasons,
      'postTitle': postTitle,
      'postType': postType,
      'postImageUrl': postImageUrl,
    }..removeWhere((key, value) => value == null);
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  // เรียกใน main/initState
  static Future<void> initialize() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Request iOS permissions
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
          
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // สามารถเชื่อมกับ NavigationService หรือ EventBus ได้
    debugPrint('Notification tapped: ${response.payload}');
  }

  // แสดง local notification (ทั่วไป)
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'lost_found_channel',
        'Lost & Found Notifications',
        channelDescription: 'Notifications for Lost & Found items',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _notifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // ขอ Permission สำหรับ Android 13+
  static Future<void> requestAndroidPermission() async {
    try {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.requestNotificationsPermission();
        debugPrint('Notification permission granted: $granted');
      }
    } catch (e) {
      debugPrint('Error requesting Android notification permission: $e');
    }
  }

  // แสดง local notification สำหรับแชท
  static Future<void> showChatNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'chat_channel',
        'Chat Notifications',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.max, // Max เพื่อให้เด้งเป็น pop-up ด้านบน
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _notifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error showing chat notification: $e');
    }
  }

  static Future<String?> createSmartMatchNotification({
    required String targetUserId,
    required Post matchedPost,
    required Post relatedPost,
    required double matchScore,
    required List<String> matchReasons,
    bool showLocal = true,
  }) async {
    try {
      final matchPercentage = (matchScore * 100).round();
      final bool matchedIsLost = matchedPost.isLostItem;
      final bool relatedIsLost = relatedPost.isLostItem;

      String title;
      String message;

      if (matchedIsLost && !relatedIsLost) {
        title = '🔍 มีคนหาสิ่งของที่คุณพบ!';
        message =
            'ผู้ใช้ ${matchedPost.userName} กำลังหา "${matchedPost.title}" ที่คล้ายกับที่คุณพบ ($matchPercentage%)';
      } else if (!matchedIsLost && relatedIsLost) {
        title = '🎯 มีคนพบสิ่งของที่คุณหา!';
        message =
            'ผู้ใช้ ${matchedPost.userName} พบ "${matchedPost.title}" ที่คล้ายกับที่คุณหา ($matchPercentage%)';
      } else {
        title = '🎯 พบสิ่งของที่อาจเกี่ยวข้อง';
        message = '${matchedPost.title} - ความตรง $matchPercentage%';
      }

      final notification = NotificationModel(
        id: '',
        userId: targetUserId,
        title: title,
        message: message,
        type: 'smart_match',
        data: {
          'matchedPostId': matchedPost.id,
          'relatedPostId': relatedPost.id,
          'matchPercentage': matchPercentage,
          'contact': matchedPost.contact,
          'userName': matchedPost.userName,
        },
        createdAt: DateTime.now(),
        postId: matchedPost.id,
        relatedPostId: relatedPost.id,
        matchScore: matchScore,
        matchReasons: matchReasons,
        postTitle: matchedPost.title,
        postType: matchedPost.isLostItem ? 'lost' : 'found',
        postImageUrl:
            matchedPost.imageUrl.isEmpty ? null : matchedPost.imageUrl,
      );

      final notificationId = await saveNotificationToFirestore(notification);

      if (notificationId != null && showLocal) {
        final notifId =
            DateTime.now().millisecondsSinceEpoch.hashCode.abs() % 2147483647;
        debugPrint('🔔 Showing local notification with ID: $notifId');
        debugPrint('📝 Notification title: $title');
        debugPrint('📝 Notification message: $message');
        await showLocalNotification(
          id: notifId,
          title: title,
          body: message,
          payload: 'smart_match:${matchedPost.id}',
        );
        debugPrint('✅ Local notification displayed successfully');
      }

      return notificationId;
    } catch (e) {
      debugPrint('Error creating smart match notification: $e');
      return null;
    }
  }

  // บันทึก notification ลง Firestore
  static Future<String?> saveNotificationToFirestore(
    NotificationModel notification,
  ) async {
    try {
      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving notification: $e');
      return null;
    }
  }

  // ตรวจสอบ match อัตโนมัติเมื่อมีการโพสต์ใหม่
  static Future<void> checkForMatches(Map<String, dynamic> newItem) async {
    // ปิดการใช้งานแล้ว (ยกเลิกการใช้โค้ดซ้ำซ้อน)
    // การจับคู่ทั้งหมดจะย้ายไปทำที่ SmartMatchingService.processNewPost แทน
    return;
  }

  // ลบ _calculateMatchScore และ _sendMatchNotification อาศัย SmartMatchingService แทน

  // ดึง notification ของ user (stream)
  static Stream<List<NotificationModel>> getUserNotifications(
    String userId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // mark as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  // mark all as read
  static Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  // นับ unread
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ส่ง general notification
  static Future<bool> sendGeneralNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    bool showLocal = true,
  }) async {
    try {
      if (userId.isEmpty || title.isEmpty || message.isEmpty) return false;
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: 'general',
        data: data ?? {},
        createdAt: DateTime.now(),
      );
      final notificationId = await saveNotificationToFirestore(notification);
      if (notificationId != null && showLocal) {
        await showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch % 2147483647,
          title: title,
          body: message,
        );
      }
      return notificationId != null;
    } catch (e) {
      debugPrint('Error sending general notification: $e');
      return false;
    }
  }

  // ส่งแจ้งเตือนเมื่อมีคนขอรับของ
  static Future<bool> sendItemClaimedNotification({
    required String ownerUserId,
    required String claimerName,
    required String itemTitle,
    required String itemId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: ownerUserId,
      title: 'มีคนขอรับสิ่งของของคุณ!',
      message: '$claimerName ต้องการรับ "$itemTitle" กรุณาตรวจสอบและยืนยัน',
      type: 'item_claimed',
      data: {
        'itemId': itemId,
        'itemTitle': itemTitle,
        'claimerName': claimerName,
        'action': 'claim_request',
      },
      createdAt: DateTime.now(),
    );
    final success = await saveNotificationToFirestore(notification);
    if (success != null) {
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch % 2147483647,
        title: notification.title,
        body: notification.message,
        payload: 'item_claimed:$itemId',
      );
      return true;
    }
    return false;
  }

  // ส่งแจ้งเตือนสถานะ
  static Future<bool> sendStatusUpdateNotification({
    required String userId,
    required String itemTitle,
    required String newStatus,
    required String itemId,
  }) async {
    String title = '';
    String message = '';
    switch (newStatus.toLowerCase()) {
      case 'found':
        title = 'สิ่งของของคุณถูกพบแล้ว!';
        message = 'มีคนพบ "$itemTitle" แล้ว กรุณาติดต่อเพื่อรับคืน';
        break;
      case 'returned':
        title = 'สิ่งของถูกส่งคืนแล้ว';
        message = '"$itemTitle" ได้ถูกส่งคืนให้เจ้าของแล้ว';
        break;
      case 'closed':
        title = 'รายการถูกปิดแล้ว';
        message = 'รายการ "$itemTitle" ถูกปิดเรียบร้อยแล้ว';
        break;
      default:
        title = 'อัพเดทสถานะสิ่งของ';
        message = 'สถานะของ "$itemTitle" ถูกเปลี่ยนเป็น $newStatus';
    }
    return await sendGeneralNotification(
      userId: userId,
      title: title,
      message: message,
      data: {
        'itemId': itemId,
        'itemTitle': itemTitle,
        'newStatus': newStatus,
        'action': 'status_update',
      },
    );
  }

  // ลบ notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  // ลบทั้งหมดของ user
  static Future<bool> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .get();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      return false;
    }
  }

  // ลบ local notification ทั้งหมด
  static Future<void> clearAllLocalNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Error clearing local notifications: $e');
    }
  }

  // สถิติ notification
  static Future<Map<String, int>> getNotificationStats(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .get();
      int total = querySnapshot.docs.length;
      int unread = 0;
      int matchFound = 0;
      int itemClaimed = 0;
      int general = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (!(data['isRead'] ?? false)) unread++;
        switch (data['type']) {
          case 'match_found':
            matchFound++;
            break;
          case 'item_claimed':
            itemClaimed++;
            break;
          case 'general':
            general++;
            break;
        }
      }
      return {
        'total': total,
        'unread': unread,
        'match_found': matchFound,
        'item_claimed': itemClaimed,
        'general': general,
      };
    } catch (e) {
      debugPrint('Error getting notification stats: $e');
      return {
        'total': 0,
        'unread': 0,
        'match_found': 0,
        'item_claimed': 0,
        'general': 0,
      };
    }
  }

  // ลบ notification เก่าตามวัน
  static Future<void> cleanupOldNotifications({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final querySnapshot =
          await _firestore
              .collection('notifications')
              .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
              .get();
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error cleaning up old notifications: $e');
    }
  }
}
