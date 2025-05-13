import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String profileUrl;
  final String provider;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final int lostCount;
  final int foundCount;
  final int helpCount;
  final String status;
  final bool notificationsEnabled;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profileUrl = '',
    required this.provider,
    this.createdAt,
    this.lastLogin,
    this.lostCount = 0,
    this.foundCount = 0,
    this.helpCount = 0,
    this.status = 'active',
    this.notificationsEnabled = true,
  });

  // แปลงข้อมูลจาก Firestore เป็น UserModel
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? 'ไม่ระบุชื่อ',
      email: data['email'] ?? '',
      profileUrl: data['profileUrl'] ?? '',
      provider: data['provider'] ?? 'email',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      lostCount: data['lostCount'] ?? 0,
      foundCount: data['foundCount'] ?? 0,
      helpCount: data['helpCount'] ?? 0,
      status: data['status'] ?? 'active',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
    );
  }

  // แปลงข้อมูลเป็น Map สำหรับเก็บใน Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileUrl': profileUrl,
      'provider': provider,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'lostCount': lostCount,
      'foundCount': foundCount,
      'helpCount': helpCount,
      'status': status,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  // สร้าง UserModel จาก Firebase User
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? 'ไม่ระบุชื่อ',
      email: user.email ?? '',
      profileUrl: user.photoURL ?? '',
      provider: user.providerData.first.providerId,
    );
  }

  // สร้าง copy ของ UserModel พร้อมอัพเดทข้อมูล
  UserModel copyWith({
    String? name,
    String? profileUrl,
    String? status,
    bool? notificationsEnabled,
    int? lostCount,
    int? foundCount,
    int? helpCount,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      profileUrl: profileUrl ?? this.profileUrl,
      provider: provider,
      createdAt: createdAt,
      lastLogin: lastLogin,
      lostCount: lostCount ?? this.lostCount,
      foundCount: foundCount ?? this.foundCount,
      helpCount: helpCount ?? this.helpCount,
      status: status ?? this.status,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
