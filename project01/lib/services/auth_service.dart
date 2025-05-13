import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profileUrl;
  final String provider;
  final DateTime createdAt;
  final DateTime lastLogin;
  final int lostCount;
  final int foundCount;
  final int helpCount;
  final String status;
  final bool notificationsEnabled;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profileUrl,
    required this.provider,
    required this.createdAt,
    required this.lastLogin,
    required this.lostCount,
    required this.foundCount,
    required this.helpCount,
    required this.status,
    required this.notificationsEnabled,
  });

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? 'ไม่มีชื่อ',
      email: user.email ?? '',
      profileUrl: user.photoURL,
      provider: 'google',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      lostCount: 0,
      foundCount: 0,
      helpCount: 0,
      status: 'active',
      notificationsEnabled: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileUrl': profileUrl,
      'provider': provider,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'lostCount': lostCount,
      'foundCount': foundCount,
      'helpCount': helpCount,
      'status': status,
      'notificationsEnabled': notificationsEnabled,
    };
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // เก็บข้อมูลผู้ใช้ใน Firestore
      if (userCredential.user != null) {
        await saveUserData(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> saveUserData(User user) async {
    final userModel = UserModel.fromFirebaseUser(user);

    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // สร้างข้อมูลผู้ใช้ใหม่
        await userDoc.set(userModel.toMap());
      } else {
        // อัพเดทข้อมูลที่จำเป็น
        await userDoc.update({
          'lastLogin': FieldValue.serverTimestamp(),
          'profileUrl': user.photoURL,
          'name': user.displayName,
        });
      }
    } catch (e) {
      print('Error saving user data: $e');
      throw Exception('ไม่สามารถบันทึกข้อมูลผู้ใช้ได้');
    }
  }
}
