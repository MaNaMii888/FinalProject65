import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
// removed firebase_auth.dart
import 'package:flutter/foundation.dart';
import 'package:project01/services/notifications_service.dart';

class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();

  factory ChatNotificationService() {
    return _instance;
  }

  ChatNotificationService._internal();

  static ChatNotificationService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _chatRoomsSubscription;
  final Map<String, StreamSubscription<QuerySnapshot>> _messagesSubscriptions = {};
  
  // Tracker to avoid notifying on initial stream load
  final Map<String, bool> _isInitialLoad = {};

  // Track which room the user is currently looking at so we don't notify
  String? _activeChatRoomId;

  void setActiveChatRoom(String? chatId) {
    _activeChatRoomId = chatId;
  }

  // Called when user logs in (or app starts while logged in)
  void startListening(String userId) {
    stopListening(); // clean up old listeners first

    _chatRoomsSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final chatId = change.doc.id;

        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          if (!_messagesSubscriptions.containsKey(chatId)) {
            _isInitialLoad[chatId] = true;
            _listenToMessages(chatId, userId);
          }
        } else if (change.type == DocumentChangeType.removed) {
          _messagesSubscriptions[chatId]?.cancel();
          _messagesSubscriptions.remove(chatId);
          _isInitialLoad.remove(chatId);
        }
      }
    }, onError: (e) {
      debugPrint('Error listening to chat rooms for notifications: $e');
    });
  }

  void _listenToMessages(String chatId, String currentUserId) {
    _messagesSubscriptions[chatId] = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1) // Only care about the latest message
        .snapshots()
        .listen((snapshot) async {
      
      if (snapshot.docs.isEmpty) return;

      if (_isInitialLoad[chatId] == true) {
        // Skip firing notification for the very first snapshot load
        _isInitialLoad[chatId] = false;
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final dynamic data = change.doc.data();
          
          final senderId = data?['senderId'] ?? '';
          
          // Don't notify if user is currently in this specific room
          if (chatId == _activeChatRoomId) continue;
          
          // Don't notify if we sent the message ourselves
          if (senderId == currentUserId) continue;

          // Fetch sender info for notification title
          String senderName = 'มีการแจ้งเตือนใหม่';
          try {
            final userDoc = await _firestore.collection('users').doc(senderId).get();
            if (userDoc.exists) {
              senderName = userDoc.data()?['firstName'] ?? userDoc.data()?['name'] ?? 'ผู้ใช้';
            }
          } catch (e) {
            debugPrint('Error fetching sender info: $e');
          }

          final text = data?['text'] ?? '';
          final type = data?['type'] ?? 'text';
          final messageBody = type == 'image' ? '[ส่งรูปภาพ]' : text;

          // Show local heads-up notification
          final notifId = DateTime.now().millisecondsSinceEpoch.hashCode.abs() % 2147483647;
          await NotificationService.showChatNotification(
            id: notifId,
            title: senderName,
            body: messageBody,
            payload: 'chat:$chatId',
          );
        }
      }
    }, onError: (e) {
      debugPrint('Error in _listenToMessages: $e');
    });
  }

  // Stop everything (e.g., when logging out)
  void stopListening() {
    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = null;
    for (var sub in _messagesSubscriptions.values) {
      sub.cancel();
    }
    _messagesSubscriptions.clear();
    _isInitialLoad.clear();
    _activeChatRoomId = null;
  }
}
