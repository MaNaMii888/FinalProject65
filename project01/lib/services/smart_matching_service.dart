import 'package:cloud_firestore/cloud_firestore.dart';

class SmartMatchingService {
  /// Updates the user's last active timestamp in Firestore.
  /// This can be used for tracking user activity for smart matching algorithms.
  static Future<void> updateUserActivity(String userId) async {
    if (userId.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
      // debugPrint('✅ User activity updated for $userId');
    } catch (e) {
      // debugPrint('❌ Error updating user activity: $e');
      // Quietly fail if the user document doesn't exist or permission denied
    }
  }
}
