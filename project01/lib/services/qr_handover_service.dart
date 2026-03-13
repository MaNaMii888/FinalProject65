import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class QRHandoverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  /// สร้างรายการ Handover (รอให้ผู้รับมาสแกน)
  Future<String> createHandoverTransaction(
    String postId,
    String senderId,
    String receiverId,
    String chatId,
  ) async {
    try {
      final transactionRef =
          _firestore.collection('handover_transactions').doc();
      final secretToken = _generateSecret();

      await transactionRef.set({
        'transactionId': transactionRef.id,
        'postId': postId,
        'chatId': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'secretToken': secretToken,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return '${transactionRef.id}:$secretToken';
    } catch (e) {
      debugPrint('Error creating handover: $e');
      rethrow;
    }
  }

  /// ผู้รับสแกน QR Code เพื่อยืนยันรับของเสร็จสิ้น
  Future<bool> verifyAndCompleteHandover(
    String qrData,
    String scannerId,
  ) async {
    try {
      final parts = qrData.split(':');
      if (parts.length != 2) return false;

      final transactionId = parts[0];
      final secretToken = parts[1];

      final doc =
          await _firestore
              .collection('handover_transactions')
              .doc(transactionId)
              .get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      if (data['status'] != 'pending') return false;
      if (data['secretToken'] != secretToken) return false;
      // ผู้ที่สแกนต้องเป็นคนรับเท่านั้น (receiverId)
      if (data['receiverId'] != scannerId) return false;

      final postId = data['postId'];
      final chatId = data['chatId'];

      WriteBatch batch = _firestore.batch();

      // เปลี่ยนสถานะโพสต์เป็น resolved (คืนเจ้าของแล้ว)
      final postRef = _firestore.collection('lost_found_items').doc(postId);
      batch.update(postRef, {'status': 'resolved'});

      // อัปเดตสถานะโพสต์ที่เกี่ยวข้อง (ถ้าเป็น Smart Match chat)
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final relatedPostId = chatData['relatedPostId'];
        if (relatedPostId != null && relatedPostId.toString().isNotEmpty) {
          final relatedPostRef = _firestore
              .collection('lost_found_items')
              .doc(relatedPostId);
          batch.update(relatedPostRef, {'status': 'resolved'});
        }
      }

      // ทำรายการสำเร็จ
      batch.update(doc.reference, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // แจ้งเตือนลงไปในห้องแชทด้วยว่าส่งมอบเสร็จสิ้น
      final messageRef =
          _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc();
      batch.set(messageRef, {
        'senderId': 'system', // ระบุว่าเป็นแชทจากระบบ
        'text':
            '🎉 การส่งมอบสิ่งของเสร็จสิ้นแล้วผ่านการสแกน QR Code! สถานะของโพสต์ถูกอัปเดตเรียบร้อย',
        'type': 'system',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // อัปเดตข้อความล่าสุดในแอพ
      batch.update(chatRef, {
        'lastMessage': '🎉 การส่งมอบสิ่งของเสร็จสิ้นแล้ว!',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': 'system',
        'postStatus': 'resolved',
      });

      await batch.commit();

      return true;
    } catch (e) {
      debugPrint('QR Verify Error: $e');
      return false;
    }
  }
}
