import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final String? idToken; // เพิ่มเก็บ ID token
  final String? accessToken; // เพิ่มเก็บ access token

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
    this.idToken,
    this.accessToken,
  });

  factory UserModel.fromFirebaseUser(
    User user, {
    String? idToken,
    String? accessToken,
  }) {
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
      idToken: idToken,
      accessToken: accessToken,
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
      'idToken': idToken,
      'accessToken': accessToken,
    };
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Rate limiting
  static DateTime? _lastAttempt;
  static int _attemptCount = 0;
  static const int _maxAttempts = 5;
  static const Duration _cooldownPeriod = Duration(minutes: 15);

  // Cache mechanism - ปรับให้เหมาะสมกับการใช้งาน
  // ignore: unused_field
  static UserCredential? _cachedCredential;
  static DateTime? _lastSignInAttempt;
  static const Duration _cacheTimeout = Duration(minutes: 5); // ลดเวลา cache
  bool _checkRateLimit() {
    final now = DateTime.now();
    if (_lastAttempt == null ||
        now.difference(_lastAttempt!) > _cooldownPeriod) {
      _attemptCount = 1;
      _lastAttempt = now;
      return true;
    }

    if (_attemptCount >= _maxAttempts) {
      print('Rate limit exceeded. Please wait before trying again.');
      return false;
    }

    _attemptCount++;
    _lastAttempt = now;
    return true;
  }

  Future<void> saveUserData(
    User user, {
    String? idToken,
    String? accessToken,
  }) async {
    final userModel = UserModel.fromFirebaseUser(
      user,
      idToken: idToken,
      accessToken: accessToken,
    );

    try {
      // ตรวจสอบ token expiration
      if (user.metadata.lastSignInTime != null) {
        final lastSignIn = user.metadata.lastSignInTime!;
        final now = DateTime.now();
        final difference = now.difference(lastSignIn);

        // ถ้า token หมดอายุ (1 ชั่วโมง)
        if (difference.inHours >= 1) {
          // ขอ token ใหม่
          final newIdToken = await user.getIdToken(true);
          idToken = newIdToken;
        }
      }

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnapshot = await userDoc.get();

      final userData = {
        'lastLogin': FieldValue.serverTimestamp(),
        'profileUrl': user.photoURL,
        'name': user.displayName,
        'idToken': idToken,
        'accessToken': accessToken,
        'lastTokenRefresh': DateTime.now(),
      };

      if (!docSnapshot.exists) {
        // สร้างข้อมูลผู้ใช้ใหม่
        await userDoc.set(userModel.toMap());
      } else {
        // อัพเดทข้อมูลที่จำเป็น และ tokens
        await userDoc.update(userData);
      }
    } catch (e) {
      print('Error saving user data: $e');
      throw Exception('ไม่สามารถบันทึกข้อมูลผู้ใช้ได้');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // ตรวจสอบ rate limiting
      if (!_checkRateLimit()) {
        throw Exception('Too many sign-in attempts. Please try again later.');
      }

      // ปิดการใช้ cache เพื่อให้ Google Sign-In ทำงานได้ถูกต้องหลัง logout
      final now = DateTime.now();
      
      // Clear cache เสมอเพื่อให้ user เลือก account ใหม่ได้
      _cachedCredential = null;
      _lastSignInAttempt = null;

      GoogleSignInAccount? account;

      if (kIsWeb) {
        try {
          final googleProvider = GoogleAuthProvider();
          googleProvider.addScope('email');
          googleProvider.addScope(
            'https://www.googleapis.com/auth/userinfo.profile',
          );

          final userCredential = await _auth.signInWithPopup(googleProvider);
          if (userCredential.user != null) {
            final credential = GoogleAuthProvider.credential(
              accessToken:
                  (userCredential.credential as OAuthCredential?)?.accessToken,
              idToken: (userCredential.credential as OAuthCredential?)?.idToken,
            );
            await saveUserData(
              userCredential.user!,
              idToken: credential.idToken,
              accessToken: credential.accessToken,
            );

            // บันทึก cache
            _cachedCredential = userCredential;
            _lastSignInAttempt = now;
          }
          return userCredential;
        } catch (e) {
          print('Web sign-in error: $e');
          rethrow;
        }
      } else {
        try {
          // ไม่ใช้ silent sign-in หลัง logout เพื่อให้ user เลือก account ใหม่ได้
          // account = await _googleSignIn.signInSilently();
          account = null; // บังคับให้แสดง account picker เสมอ
        } catch (e) {
          print('Silent sign-in disabled for better UX');
          account = null;
        }

        if (account == null) {
          try {
            // เพิ่ม error handling สำหรับ PigeonUser type casting
            account = await _googleSignIn.signIn();
            if (account == null) {
              print('User cancelled sign-in');
              return null;
            }
          } catch (e) {
            print('Interactive sign-in error: $e');
            
            // หาก error เกี่ยวกับ PigeonUser ให้ลอง clear และ retry
            if (e.toString().contains('PigeonUser') || e.toString().contains('List<Object?>')) {
              print('PigeonUser type error detected, clearing Google Sign-In cache...');
              try {
                await _googleSignIn.signOut();
                await _googleSignIn.disconnect();
                // รอสักครู่แล้วลองใหม่
                await Future.delayed(Duration(milliseconds: 500));
                account = await _googleSignIn.signIn();
                if (account == null) {
                  print('User cancelled sign-in after retry');
                  return null;
                }
              } catch (retryError) {
                print('Retry after PigeonUser error failed: $retryError');
                rethrow;
              }
            } else {
              rethrow;
            }
          }
        }

        try {
          final googleAuth = await account.authentication;
          print('Got authentication tokens');

          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final userCredential = await _auth.signInWithCredential(credential);
          print('Firebase sign-in successful');

          if (userCredential.user != null) {
            await saveUserData(
              userCredential.user!,
              idToken: googleAuth.idToken,
              accessToken: googleAuth.accessToken,
            );

            // บันทึก cache
            _cachedCredential = userCredential;
            _lastSignInAttempt = now;
          }

          return userCredential;
        } catch (e) {
          print('Error during authentication/credential flow: $e');
          if (e is FirebaseAuthException) {
            print(
              'Firebase Auth Error - Code: ${e.code}, Message: ${e.message}',
            );
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Final error catch - Sign-in failed: $e');
      return null;
    }
  }

  /// Signs out from both FirebaseAuth and the GoogleSignIn plugin (where applicable).
  Future<void> signOut() async {
    try {
      print('Starting sign out process...');
      
      // Clear cache ก่อน sign out
      _cachedCredential = null;
      _lastSignInAttempt = null;
      
      // Reset rate limiting
      _attemptCount = 0;
      _lastAttempt = null;
      
      // Sign out และ disconnect Google Sign-In อย่างสมบูรณ์
      if (!kIsWeb) {
        try {
          // Sign out จาก Google Sign-In ก่อน
          await _googleSignIn.signOut();
          print('Google Sign-In signed out');
          
          // รอสักครู่เพื่อให้ Google Sign-In process เสร็จสมบูรณ์
          await Future.delayed(Duration(milliseconds: 300));
          
          // Disconnect เพื่อ clear cached accounts และ tokens
          await _googleSignIn.disconnect();
          print('Google Sign-In disconnected');
          
          // รอเพิ่มเติมเพื่อให้ Pigeon communication clear
          await Future.delayed(Duration(milliseconds: 200));
          
        } catch (e) {
          print('Error during Google Sign-In logout: $e');
          // ถ้า error ก็ยังคงทำต่อ แต่ลอง force clear
          try {
            await Future.delayed(Duration(milliseconds: 100));
            await _googleSignIn.disconnect();
          } catch (forceError) {
            print('Force disconnect also failed: $forceError');
          }
        }
      }
      
      // Sign out จาก Firebase Auth
      await _auth.signOut();
      print('Firebase Auth signed out');
      
      // รอสักครู่เพื่อให้ทุก process เสร็จสมบูรณ์
      await Future.delayed(Duration(milliseconds: 100));
      
      print('Sign out completed successfully');
    } catch (e) {
      print('Error signing out: $e');
      // แม้จะเกิด error ก็ยัง clear cache และ state
      _cachedCredential = null;
      _lastSignInAttempt = null;
      _attemptCount = 0;
      _lastAttempt = null;
      
      // พยายาม force clear Google Sign-In พร้อม delay
      try {
        if (!kIsWeb) {
          await Future.delayed(Duration(milliseconds: 200));
          await _googleSignIn.signOut();
          await Future.delayed(Duration(milliseconds: 200));
          await _googleSignIn.disconnect();
          await Future.delayed(Duration(milliseconds: 100));
        }
      } catch (clearError) {
        print('Error force clearing Google Sign-In: $clearError');
      }
    }
  }
}
