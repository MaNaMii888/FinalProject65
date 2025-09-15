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
  // Use the package singleton for GoogleSignIn (v7+ API)
  // Note: the package encourages calling initialize(...) once at app startup if needed.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Web uses a different flow: use FirebaseAuth signInWithPopup
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();

        // Optionally add scopes or custom params here:
        // googleProvider.addScope('email');

        final userCredential = await _auth.signInWithPopup(googleProvider);

        if (userCredential.user != null) {
          await saveUserData(userCredential.user!);
        }

        return userCredential;
      }

      // Mobile / desktop flow using google_sign_in package (v7+)
      // Try a lightweight restore first (may return null). If that fails, fall back
      // to an interactive authenticate() call.
      GoogleSignInAccount? account;
      try {
        final Future<GoogleSignInAccount?>? lightweightFuture =
            _googleSignIn.attemptLightweightAuthentication();
        if (lightweightFuture != null) {
          account = await lightweightFuture;
        }
      } catch (_) {
        account = null;
      }

      if (account == null) {
        // Interactive sign-in (may throw on configuration issues or if unsupported)
        try {
          account = await _googleSignIn.authenticate();
        } catch (e) {
          // If user cancels or UI unavailable, return null
          print('Google authenticate threw: $e');
          return null;
        }
      }

      // account is non-null here

      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        print('Google sign-in succeeded but idToken is null');
        return null;
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await _auth.signInWithCredential(credential);

      // Save user in Firestore (create or update)
      if (userCredential.user != null) {
        await saveUserData(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      // Give better diagnostics for common failures
      if (e is FirebaseAuthException) {
        print(
          'FirebaseAuthException during Google sign-in: ${e.code} ${e.message}',
        );
      } else {
        print('Error signing in with Google: $e');
      }
      return null;
    }
  }

  /// Signs out from both FirebaseAuth and the GoogleSignIn plugin (where applicable).
  Future<void> signOut() async {
    try {
      // Disconnect the google_sign_in plugin on non-web platforms to clear cached accounts
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
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
