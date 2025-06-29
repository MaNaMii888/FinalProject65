import 'package:cloud_firestore/cloud_firestore.dart';

class PostCountService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // อัพเดทจำนวนโพสต์เมื่อมีการสร้างโพสต์ใหม่
  static Future<void> updatePostCount(String userId, bool isLostItem) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // ใช้ transaction เพื่อให้แน่ใจว่าการอัพเดทเป็น atomic
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final currentData = userDoc.data() as Map<String, dynamic>;
          final currentLostCount = currentData['lostCount'] ?? 0;
          final currentFoundCount = currentData['foundCount'] ?? 0;

          if (isLostItem) {
            transaction.update(userRef, {'lostCount': currentLostCount + 1});
          } else {
            transaction.update(userRef, {'foundCount': currentFoundCount + 1});
          }
        }
      });
    } catch (e) {
      print('Error updating post count: $e');
    }
  }

  // ลดจำนวนโพสต์เมื่อมีการลบโพสต์
  static Future<void> decreasePostCount(String userId, bool isLostItem) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final currentData = userDoc.data() as Map<String, dynamic>;
          final currentLostCount = currentData['lostCount'] ?? 0;
          final currentFoundCount = currentData['foundCount'] ?? 0;

          if (isLostItem && currentLostCount > 0) {
            transaction.update(userRef, {'lostCount': currentLostCount - 1});
          } else if (!isLostItem && currentFoundCount > 0) {
            transaction.update(userRef, {'foundCount': currentFoundCount - 1});
          }
        }
      });
    } catch (e) {
      print('Error decreasing post count: $e');
    }
  }

  // อัพเดทจำนวนโพสต์เมื่อมีการเปลี่ยนสถานะ
  static Future<void> updatePostStatus(
    String userId,
    bool oldIsLostItem,
    bool newIsLostItem,
  ) async {
    try {
      if (oldIsLostItem != newIsLostItem) {
        // ลดจำนวนจากประเภทเดิม
        await decreasePostCount(userId, oldIsLostItem);
        // เพิ่มจำนวนในประเภทใหม่
        await updatePostCount(userId, newIsLostItem);
      }
    } catch (e) {
      print('Error updating post status: $e');
    }
  }

  // คำนวณจำนวนโพสต์จากฐานข้อมูลจริง
  static Future<Map<String, int>> calculatePostCounts(String userId) async {
    try {
      final lostQuery =
          await _firestore
              .collection('lost_found_items')
              .where('userId', isEqualTo: userId)
              .where('isLostItem', isEqualTo: true)
              .get();

      final foundQuery =
          await _firestore
              .collection('lost_found_items')
              .where('userId', isEqualTo: userId)
              .where('isLostItem', isEqualTo: false)
              .get();

      return {
        'lostCount': lostQuery.docs.length,
        'foundCount': foundQuery.docs.length,
      };
    } catch (e) {
      print('Error calculating post counts: $e');
      return {'lostCount': 0, 'foundCount': 0};
    }
  }

  // ซิงค์จำนวนโพสต์กับฐานข้อมูลจริง
  static Future<void> syncPostCounts(String userId) async {
    try {
      final counts = await calculatePostCounts(userId);

      await _firestore.collection('users').doc(userId).update({
        'lostCount': counts['lostCount'],
        'foundCount': counts['foundCount'],
      });
    } catch (e) {
      print('Error syncing post counts: $e');
    }
  }
}
