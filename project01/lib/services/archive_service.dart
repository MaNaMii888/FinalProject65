import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ArchiveService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ย้ายโพสต์ของ user ที่หมดอายุ (เกิน 90 วัน) หรือสถานะไม่ใช่ active ไปยัง archived_items
  static Future<void> autoArchiveOldPosts(String userId) async {
    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 90));

      final QuerySnapshot snapshot =
          await _firestore
              .collection('lost_found_items')
              .where('userId', isEqualTo: userId)
              .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      bool hasArchived = false;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        bool shouldArchive = false;

        // 1. เช็คอายุเกิน 90 วัน
        if (data.containsKey('createdAt')) {
          final createdAtRaw = data['createdAt'];
          if (createdAtRaw is Timestamp) {
            if (createdAtRaw.toDate().isBefore(cutoffDate)) {
              shouldArchive = true;
              data['archiveReason'] = 'expired_90_days'; // ใส่เหตุผลไว้ดู
            }
          }
        }

        // 2. เช็คสถานะ (เช่น resolved, returned)
        if (data.containsKey('status') && data['status'] != 'active') {
          shouldArchive = true;
          data['archiveReason'] = 'resolved';
        }

        if (shouldArchive) {
          // ประทับเวลาที่ย้ายลงโกดัง
          data['archivedAt'] = FieldValue.serverTimestamp();

          final archiveRef = _firestore
              .collection('archived_items')
              .doc(doc.id);
          final originalRef = _firestore
              .collection('lost_found_items')
              .doc(doc.id);

          batch.set(archiveRef, data); // คัดลอกไปโกดัง
          batch.delete(originalRef); // ลบจากที่เดิม
          hasArchived = true;
        }
      }

      if (hasArchived) {
        await batch.commit();
        debugPrint(
          'ArchiveService: Successfully migrated old posts for user $userId to archived_items.',
        );
      }
    } catch (e) {
      debugPrint('ArchiveService Error: $e');
    }
  }
}
