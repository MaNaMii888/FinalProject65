import 'package:flutter/material.dart';
import 'package:project01/Screen/register.dart'; // unused — kept commented in case needed later
// import 'package:project01/Screen/app.dart'; // not used anymore; keep commented in case needed
import 'package:project01/Screen/forgot_password.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/auth_service.dart';
import 'package:project01/utils/debug_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Using singleton instance

  Future<UserCredential?> signInWithGoogle() async {
    DebugHelper.log('=== Login.dart: Google Sign-In Starting ===');

    try {
      DebugHelper.logUserState();
      await DebugHelper.logGoogleSignInState();

      final result = await _authService.signInWithGoogle();

      DebugHelper.log('=== Login.dart: Sign-In Result ===');
      DebugHelper.log('Result: $result');
      DebugHelper.logUserState();

      return result;
    } catch (e, stackTrace) {
      DebugHelper.logError('Login.dart: Google Sign-In Error', e, stackTrace);
      DebugHelper.logAuthError(e);
      rethrow;
    }
  }

  // Password reset moved to a separate screen: ForgotPasswordPage

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'ยินดีตอนรับ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 22,
                  ),
                ),
                Text(
                  'เข้าสู่ะบบ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Gmail',
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "กรุณากรอกอีเมลให้ถูกต้อง";
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return "กรุณากรอกอีเมลให้ถูกต้อง";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "กรุณากรอกรหัสผ่านให้ถูกต้อง";
                          }
                          if (value.length < 6) {
                            return "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            'ลืมรหัสผ่าน?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const Center(
                                    child: AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text("กำลังเข้าสู่ระบบ..."),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                              try {
                                DebugHelper.log(
                                  '=== Email/Password Login Starting ===',
                                );
                                DebugHelper.log(
                                  'Email: ${_emailController.text.trim()}',
                                );
                                DebugHelper.log(
                                  'Password length: ${_passwordController.text.length}',
                                );

                                // Attempt sign-in with a timeout to avoid hanging spinner
                                final userCredential = await FirebaseAuth
                                    .instance
                                    .signInWithEmailAndPassword(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                    )
                                    .timeout(
                                      const Duration(seconds: 15),
                                      onTimeout: () {
                                        DebugHelper.log(
                                          'Email/Password sign-in timed out',
                                        );
                                        throw TimeoutException(
                                          'Sign-in timed out',
                                        );
                                      },
                                    );

                                DebugHelper.log(
                                  'Login successful: ${userCredential.user?.email}',
                                );

                                // If the widget was disposed while awaiting, abort further UI work
                                if (!mounted) return;

                                // Ensure loading dialog is dismissed
                                if (mounted && Navigator.canPop(context)) {
                                  Navigator.of(context).pop();
                                }

                                // Navigate to dashboard route (consistent with main authStateChanges)
                                _formKey.currentState?.reset();
                                if (!mounted) return;
                                if (Navigator.canPop(context)) {
                                  Navigator.of(context).pop();
                                }
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dashboard',
                                );
                              } on TimeoutException catch (e) {
                                DebugHelper.logError(
                                  'Email/Password Timeout',
                                  e,
                                  null,
                                );
                                if (mounted && Navigator.canPop(context)) {
                                  Navigator.of(context).pop();
                                }
                                if (!mounted) return;
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('เกิดข้อผิดพลาด'),
                                      content: const Text(
                                        'การเชื่อมต่อล้มเหลว (หมดเวลาการเชื่อมต่อ). กรุณาลองอีกครั้ง',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: const Text('ปิด'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } on FirebaseAuthException catch (e) {
                                DebugHelper.logError(
                                  'FirebaseAuth Error',
                                  e,
                                  null,
                                );

                                if (mounted && Navigator.canPop(context)) {
                                  Navigator.of(context).pop();
                                }

                                if (!mounted) return;

                                String errorMessage = 'ไม่สามารถเข้าสู่ระบบได้';

                                switch (e.code) {
                                  case 'user-not-found':
                                    errorMessage =
                                        'ไม่พบผู้ใช้งานนี้ กรุณาตรวจสอบอีเมลหรือลงทะเบียนใหม่';
                                    break;
                                  case 'wrong-password':
                                    errorMessage =
                                        'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';
                                    break;
                                  case 'invalid-email':
                                    errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
                                    break;
                                  case 'user-disabled':
                                    errorMessage = 'บัญชีผู้ใช้ถูกปิดใช้งาน';
                                    break;
                                  case 'too-many-requests':
                                    errorMessage =
                                        'มีการพยายามเข้าสู่ระบบมากเกินไป กรุณารอสักครู่แล้วลองใหม่';
                                    break;
                                  case 'invalid-credential':
                                    errorMessage =
                                        'ข้อมูลการเข้าสู่ระบบไม่ถูกต้อง กรุณาตรวจสอบอีเมลและรหัสผ่าน';
                                    break;
                                  default:
                                    errorMessage =
                                        e.message ??
                                        'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
                                }

                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('เกิดข้อผิดพลาด'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(errorMessage),
                                          SizedBox(height: 8),
                                          Text(
                                            'รหัสข้อผิดพลาด: ${e.code}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      icon: const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: const Text('ปิด'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } catch (e, stack) {
                                DebugHelper.logError(
                                  'General Login Error',
                                  e,
                                  stack,
                                );

                                if (mounted && Navigator.canPop(context)) {
                                  Navigator.of(context).pop();
                                }

                                if (!mounted) return;

                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('เกิดข้อผิดพลาด'),
                                      content: Text(
                                        'เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}',
                                      ),
                                      icon: const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: const Text('ปิด'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                          child: const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Image.asset(
                            'assets/img/google.jpg',
                            height: 24.0,
                          ),
                          label: const Text('เข้าสูระบบด้วย Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            // แสดง dialog loading ขณะเริ่มกระบวนการ Google Sign-In
                            showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext dialogContext) {
                                return WillPopScope(
                                  onWillPop: () async => false,
                                  child: Center(
                                    child: AlertDialog(
                                      backgroundColor:
                                          Theme.of(
                                            dialogContext,
                                          ).scaffoldBackgroundColor,
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text(
                                            "กำลังเข้าสู่ระบบด้วย Google...",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );

                            try {
                              final userCredential = await signInWithGoogle();

                              DebugHelper.log(
                                'Google sign-in finished: $userCredential',
                              );

                              // ถ้า widget ถูกยกเลิก ให้หยุด
                              if (!mounted) return;

                              // ปิด loading dialog ถ้ามันยังเปิดอยู่
                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }

                              if (userCredential != null && mounted) {
                                // นำทางไปยังหน้า dashboard (consistent with main auth state)
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dashboard',
                                );
                              } else {
                                // ผู้ใช้ยกเลิกการเลือกบัญชีหรือไม่ได้ล็อกอิน
                                if (mounted) {
                                  await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text(
                                          'ยกเลิกการเข้าสู่ระบบ',
                                        ),
                                        content: const Text(
                                          'คุณยกเลิกการเข้าสู่ระบบด้วย Google',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: const Text('ปิด'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            } catch (e, stack) {
                              DebugHelper.logError(
                                'Google Sign-In Error',
                                e,
                                stack,
                              );

                              // ปิด loading dialog ถ้ามันยังเปิดอยู่
                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }

                              if (!mounted) return;

                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('เกิดข้อผิดพลาด'),
                                    content: Text(
                                      'ไม่สามารถเข้าสู่ระบบด้วย Google ได้: ${e.toString()}',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: const Text('ปิด'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ยังไม่มีการลงทะเบียน?',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('ลงทะเบียน'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
