import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'match_found', 'item_claimed', 'general'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
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
    };
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // เรียกใช้ใน main.dart (เช่นใน main หรือ initState)
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(initSettings);
  }

  // แสดง local notification
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'lost_found_channel',
      'Lost & Found Notifications',
      channelDescription: 'Notifications for Lost & Found items',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notifications.show(id, title, body, details, payload: payload);
  }

  // บันทึก notification ลง Firestore
  static Future<void> saveNotificationToFirestore(
    NotificationModel notification,
  ) async {
    try {
      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  // ตรวจสอบ match อัตโนมัติเมื่อมีการโพสต์ใหม่
  static Future<void> checkForMatches(Map<String, dynamic> newItem) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final oppositeType = newItem['isLostItem'] ? false : true;
      final querySnapshot =
          await _firestore
              .collection('lost_found_items')
              .where('isLostItem', isEqualTo: oppositeType)
              .where('status', isEqualTo: 'active')
              .get();

      for (final doc in querySnapshot.docs) {
        final existingItem = doc.data();
        if (existingItem['userId'] == currentUserId) continue;
        if (await _isLikelyMatch(newItem, existingItem)) {
          await _sendMatchNotification(existingItem, newItem, doc.id);
        }
      }
    } catch (e) {
      debugPrint('Error checking for matches: $e');
    }
  }

  // Logic การ match (category/building/keywords/date)
  static Future<bool> _isLikelyMatch(
    Map<String, dynamic> item1,
    Map<String, dynamic> item2,
  ) async {
    int matchScore = 0;
    if (item1['category'] == item2['category']) matchScore += 30;
    if (item1['building'] == item2['building']) matchScore += 20;

    final keywords1 = List<String>.from(item1['searchKeywords'] ?? []);
    final keywords2 = List<String>.from(item2['searchKeywords'] ?? []);
    int keywordMatches = 0;
    for (final keyword in keywords1) {
      if (keywords2.contains(keyword)) keywordMatches++;
    }
    if (keywordMatches > 0) matchScore += (keywordMatches * 10).clamp(0, 25);

    try {
      final date1 = DateTime.tryParse(item1['date'] ?? '');
      final date2 = DateTime.tryParse(item2['date'] ?? '');
      if (date1 != null && date2 != null) {
        final daysDifference = date1.difference(date2).inDays.abs();
        if (daysDifference <= 7) {
          matchScore += 15;
        } else if (daysDifference <= 14) {
          matchScore += 10;
        }
      }
    } catch (_) {}

    return matchScore >= 50;
  }

  // ส่ง match notification
  static Future<void> _sendMatchNotification(
    Map<String, dynamic> existingItem,
    Map<String, dynamic> newItem,
    String existingItemId,
  ) async {
    try {
      final existingUserId = existingItem['userId'];
      final newItemType = newItem['isLostItem'] ? 'หาย' : 'เจอ';

      final notification = NotificationModel(
        id: '',
        userId: existingUserId,
        title: 'พบสิ่งของที่อาจตรงกัน!',
        message:
            'มีคนแจ้ง${newItemType}ของ "${newItem['title']}" '
            'ที่อาจตรงกับ "${existingItem['title']}" ของคุณ',
        type: 'match_found',
        data: {
          'existingItemId': existingItemId,
          'newItemTitle': newItem['title'],
          'newItemCategory': newItem['categoryName'],
          'newItemBuilding': newItem['building'],
          'newItemRoom': newItem['room'],
          'matchType': 'potential_match',
        },
        createdAt: DateTime.now(),
      );

      await saveNotificationToFirestore(notification);

      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: notification.title,
        body: notification.message,
        payload: 'match_found:$existingItemId',
      );
    } catch (e) {
      debugPrint('Error sending match notification: $e');
    }
  }

  // ดึง notification ของ user
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // mark as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
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
  static Future<void> sendGeneralNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      message: message,
      type: 'general',
      data: data ?? {},
      createdAt: DateTime.now(),
    );
    await saveNotificationToFirestore(notification);
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: message,
    );
  }
}
