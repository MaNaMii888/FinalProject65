import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class DebugHelper {
  static void log(String message) {
    // Simple console log helper - can be replaced with a more
    // sophisticated logging framework if needed.
    final time = DateTime.now().toIso8601String();
    print('[DEBUG] $time - $message');
  }

  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    final time = DateTime.now().toIso8601String();
    print('[ERROR] $time - $context: $error');
    if (stackTrace != null) {
      print('[STACKTRACE] $stackTrace');
    }
  }

  static void logUserState() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[USER_STATE] No user is currently signed in.');
      } else {
        print(
          '[USER_STATE] Signed-in user: uid=${user.uid}, email=${user.email}, name=${user.displayName}',
        );
      }
    } catch (e) {
      print('[USER_STATE] Error reading current user: $e');
    }
  }

  static Future<void> logGoogleSignInState() async {
    // Placeholder for async checks relating to Google Sign-In.
    // Keep it lightweight to avoid side-effects.
    try {
      print('[GOOGLE_SIGN_IN] Performing quick health check...');
      // In the real app we might check cached tokens or plugin state.
      await Future.delayed(const Duration(milliseconds: 20));
      print('[GOOGLE_SIGN_IN] Health check completed.');
    } catch (e) {
      print('[GOOGLE_SIGN_IN] Health check failed: $e');
    }
  }

  static void logAuthError(dynamic error) {
    print('[AUTH_ERROR] Authentication error: $error');
  }
}
