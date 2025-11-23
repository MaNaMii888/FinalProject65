import 'package:cloud_firestore/cloud_firestore.dart';

class LogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Log types
  static const String userRegister = 'user_register';
  static const String userLogin = 'user_login';
  static const String postCreate = 'post_create';
  static const String postUpdate = 'post_update';
  static const String postDelete = 'post_delete';
  static const String postStatusChange = 'post_status_change';

  /// สร้าง log บันทึกกิจกรรม
  Future<void> createLog({
    required String type,
    String? userId,
    String? userName,
    required String action,
    String? details,
  }) async {
    try {
      await _firestore.collection('activity_logs').add({
        'type': type,
        'userId': userId,
        'userName': userName ?? 'ไม่ระบุ',
        'action': action,
        'details': details ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating log: $e');
    }
  }

  /// Log การสมัครสมาชิก
  Future<void> logUserRegister({
    required String userId,
    required String userName,
    required String email,
  }) async {
    await createLog(
      type: userRegister,
      userId: userId,
      userName: userName,
      action: 'สมัครสมาชิกใหม่',
      details: 'Email: $email',
    );
  }

  /// Log การเข้าสู่ระบบ
  Future<void> logUserLogin({
    required String userId,
    required String userName,
    required String provider,
  }) async {
    await createLog(
      type: userLogin,
      userId: userId,
      userName: userName,
      action: 'เข้าสู่ระบบ',
      details: 'Provider: $provider',
    );
  }

  /// Log การสร้างโพสต์
  Future<void> logPostCreate({
    required String userId,
    required String userName,
    required String postId,
    required String postTitle,
    required bool isLostItem,
  }) async {
    await createLog(
      type: postCreate,
      userId: userId,
      userName: userName,
      action: 'สร้างโพสต์',
      details: 'โพสต์: $postTitle (${isLostItem ? 'หาย' : 'เจอ'}) ID: $postId',
    );
  }

  /// Log การแก้ไขโพสต์
  Future<void> logPostUpdate({
    required String userId,
    required String userName,
    required String postId,
    required String postTitle,
  }) async {
    await createLog(
      type: postUpdate,
      userId: userId,
      userName: userName,
      action: 'แก้ไขโพสต์',
      details: 'โพสต์: $postTitle ID: $postId',
    );
  }

  /// Log การลบโพสต์
  Future<void> logPostDelete({
    required String userId,
    required String userName,
    required String postId,
    required String postTitle,
  }) async {
    await createLog(
      type: postDelete,
      userId: userId,
      userName: userName,
      action: 'ลบโพสต์',
      details: 'โพสต์: $postTitle ID: $postId',
    );
  }

  /// Log การเปลี่ยนสถานะโพสต์
  Future<void> logPostStatusChange({
    required String userId,
    required String userName,
    required String postId,
    required String postTitle,
    required String oldStatus,
    required String newStatus,
  }) async {
    await createLog(
      type: postStatusChange,
      userId: userId,
      userName: userName,
      action: 'เปลี่ยนสถานะโพสต์',
      details: 'โพสต์: $postTitle จาก $oldStatus เป็น $newStatus (ID: $postId)',
    );
  }
}
