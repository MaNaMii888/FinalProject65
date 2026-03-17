import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 1. สร้างหรือดึงห้องแชทที่มีอยู่แล้ว
  /// ถ้าทั้งคู่เคยคุยกันเรื่องของชิ้นนี้แล้ว จะดึงห้องเดิมมา
  Future<String> createOrGetChatRoom(
    String uid1,
    String uid2,
    String postId, {
    String? relatedPostId,
  }) async {
    try {
      // ค้นหาว่ามีห้องแชทของ 2 คนนี้และ post นี้หรือยัง
      final querySnapshot =
          await _firestore
              .collection('chats')
              .where('postId', isEqualTo: postId)
              .where('participants', arrayContains: uid1)
              .get();

      // เช็คว่ามี uid2 อยู่ใน participants ด้วยหรือไม่
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(uid2)) {
          // หากมาจาก AI Smart Match และมี relatedPostId ให้ทำการอัปเดตห้องแชทเดิมด้วย
          if (relatedPostId != null && relatedPostId.isNotEmpty) {
            await _firestore.collection('chats').doc(doc.id).update({
              'relatedPostId': relatedPostId,
            });
          }
          return doc.id; // เจอห้องเดิม คืนค่า ID ห้องกลับไป
        }
      }

      // ถ้าไม่มี ให้สร้างห้องใหม่
      final newChatRef = _firestore.collection('chats').doc();
      final Map<String, dynamic> chatData = {
        'postId': postId,
        'participants': [uid1, uid2],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCount': {uid1: 0, uid2: 0},
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (relatedPostId != null && relatedPostId.isNotEmpty) {
        chatData['relatedPostId'] = relatedPostId;
      }

      await newChatRef.set(chatData);

      return newChatRef.id;
    } catch (e) {
      debugPrint('Error in createOrGetChatRoom: $e');
      rethrow;
    }
  }

  /// 2. ส่งข้อความ พร้อมใช้ Batch Update เลื่อนแชทขึ้นหน้าแรก
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text, {
    String type = 'text',
  }) async {
    try {
      final batch = _firestore.batch();

      // --- ส่วนที่ 1: เพิ่มข้อความลงใน sub-collection ---
      final messageRef =
          _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc();

      batch.set(messageRef, {
        'senderId': senderId,
        'text': text,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // --- ส่วนที่ 2: อัปเดตหน้าปกห้องแชท (Chats Collection) ---
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();

      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        final participants = List<String>.from(data['participants'] ?? []);

        // หาว่าเป็นใครที่เป็นคนรับข้อความ (ไม่ใช่ตัวเอง)
        final receiverId = participants.firstWhere(
          (id) => id != senderId,
          orElse: () => '',
        );

        Map<String, dynamic> unreadCount = Map<String, dynamic>.from(
          data['unreadCount'] ?? {},
        );
        if (receiverId.isNotEmpty) {
          // เพิ่มเลขแจ้งเตือน (Unread) ให้อีกฝั่ง +1
          unreadCount[receiverId] = (unreadCount[receiverId] ?? 0) + 1;
        }

        // เซ็ตตัวแปร lastMessage ให้โชว์หน้าลิสต์ถูกประเภท
        String displayMsg = text;
        if (type == 'image') displayMsg = '[รูปภาพ]';
        if (type == 'location') displayMsg = '[ตำแหน่งพิกัด]';

        batch.update(chatRef, {
          'lastMessage': displayMsg,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': senderId,
          'unreadCount': unreadCount,
        });
      }

      await batch.commit(); // ทำ 2 งานให้เสร็จพร้อมกัน (Atomic)
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      rethrow;
    }
  }

  /// 2.5 อัปโหลดรูปภาพลง Firebase Storage
  Future<String?> uploadImageToStorage(String chatId, File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        debugPrint('❌ [CHAT_UPLOAD] ไฟล์ไม่มีอยู่จริง: ${imageFile.path}');
        return null;
      }

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(
        'chat_images/$chatId/$fileName',
      );

      debugPrint(
        '🔥 [CHAT_UPLOAD] ขนาดไฟล์: ${await imageFile.length()} bytes',
      );
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// 2.6 ส่งข้อความประเภทรูปภาพ
  Future<void> sendImageMessage(
    String chatId,
    String senderId,
    String imageUrl,
  ) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final messageRef = chatRef.collection('messages').doc();

      WriteBatch batch = _firestore.batch();

      batch.set(messageRef, {
        'senderId': senderId,
        'text': '[รูปภาพ]', // สำหรับซับไตเติ้ลในหน้ารวมแชท
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image', // ระบุประเภทชัดเจนว่าเป็นรูปภาพ
      });

      final chatDoc = await chatRef.get();
      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        List<String> participants = List<String>.from(
          data['participants'] ?? [],
        );
        String receiverId = participants.firstWhere(
          (id) => id != senderId,
          orElse: () => '',
        );

        Map<String, dynamic> unreadCount = Map<String, dynamic>.from(
          data['unreadCount'] ?? {},
        );
        if (receiverId.isNotEmpty) {
          unreadCount[receiverId] = (unreadCount[receiverId] ?? 0) + 1;
        }

        batch.update(chatRef, {
          'lastMessage': '[รูปภาพ]',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': senderId,
          'unreadCount': unreadCount,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in sendImageMessage: $e');
      rethrow;
    }
  }

  /// 3. ดึงรายการห้องแชททั้งหมดของ User (แบบ Real-time) เพื่อโชว์หน้า ChatList
  /// [แก้ไข: เอา orderBy ออกชั่วคราวเพื่อหลีกเลี่ยงปัญหา Index ของ Firebase ให้ไป sort ที่ฝั่ง Client แทน]
  Stream<QuerySnapshot> getUserChatRoomsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  /// 4. ดึงข้อความในห้องแชท (แบบ Real-time พร้อม Pagination 20 ข้อความ)
  /// สั่ง limit() เพื่อเซฟค่าใช้จ่าย Cost (Firebase billing)
  Stream<QuerySnapshot> getChatMessagesStream(String chatId, {int limit = 20}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// 5. เคลียร์ตัวเลข Unread เมื่อเปิดเข้าห้องแชท
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();

      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        Map<String, dynamic> unreadCount = Map<String, dynamic>.from(
          data['unreadCount'] ?? {},
        );

        // รีเซ็ตเลข Unread ของตัวเองเป็น 0
        if (unreadCount[userId] != 0) {
          unreadCount[userId] = 0;
          await chatRef.update({'unreadCount': unreadCount});
        }
      }
    } catch (e) {
      debugPrint('Error in markMessagesAsRead: $e');
    }
  }

  /// 6. Delete a chat room and all its messages
  Future<void> deleteChatRoom(String chatId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final messagesRef = chatRef.collection('messages');

      // Fetch all messages and delete them in batches
      final messagesSnapshot = await messagesRef.get();
      WriteBatch batch = _firestore.batch();

      int batchCount = 0;
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;
        // Commit in chunks if there are more than 500 messages (Firestore limit)
        if (batchCount == 500) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      // Finally delete the parent chat room
      await chatRef.delete();
    } catch (e) {
      debugPrint('Error deleting chat room: $e');
      rethrow;
    }
  }
}
