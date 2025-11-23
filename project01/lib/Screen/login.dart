import 'package:flutter/material.dart';
import 'package:project01/Screen/register.dart';
import 'package:project01/Screen/forgot_password.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/auth_service.dart';
import 'package:project01/utils/debug_helper.dart';
import 'package:project01/services/log_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final LogService _logService = LogService();

  // --- Logic ส่วนเดิม ---
  Future<UserCredential?> signInWithGoogle() async {
    DebugHelper.log('=== Login.dart: Google Sign-In Starting ===');
    try {
      final result = await _authService.signInWithGoogle();
      return result;
    } catch (e, stackTrace) {
      DebugHelper.logError('Login.dart: Google Sign-In Error', e, stackTrace);
      rethrow;
    }
  }

  // Function ช่วยปิด Dialog แบบปลอดภัย
  void _dismissLoadingDialog() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  // Function แสดง Dialog แจ้งเตือน
  Future<void> _showAlertDialog({
    required String title,
    required Widget content,
    bool isError = false,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: content,
          icon: Icon(
            isError ? Icons.error : Icons.check_circle,
            color: isError ? Theme.of(context).colorScheme.error : Colors.green,
            size: 48,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // เรียกใช้ Theme สั้นๆ

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ยินดีต้อนรับ',
                  style: TextStyle(
                    color:
                        theme.colorScheme.onSurface, // ปรับให้เห็นชัดบนพื้นหลัง
                    fontSize: 22,
                  ),
                ),
                Text(
                  'เข้าสู่ระบบ', // แก้คำผิด
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // --- Card Container แบบเดียวกับ Register ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.9,
                    ), // ใช้ withOpacity เพื่อความชัวร์
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // --- Email Input ---
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: Colors.black87,
                        ), // สีตัวอักษรเวลาพิมพ์
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.primary,
                          ),
                          // ใส่ Icon และกำหนดสีตาม Theme
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          border: const UnderlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "กรุณากรอกอีเมล";
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                            return "รูปแบบอีเมลไม่ถูกต้อง";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- Password Input ---
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.primary,
                          ),
                          // ใส่ Icon และกำหนดสีตาม Theme
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: theme.colorScheme.primary,
                          ),
                          border: const UnderlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "กรุณากรอกรหัสผ่าน";
                          if (value.length < 6)
                            return "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร";
                          return null;
                        },
                      ),

                      // --- Forgot Password Button ---
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
                              color:
                                  theme
                                      .colorScheme
                                      .error, // ใช้สีแดงหรือ secondary ให้เด่น
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ), // ลดระยะห่างนิดหน่อยเพราะมีปุ่มลืมรหัสผ่าน
                      // --- Login Button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                theme
                                    .colorScheme
                                    .primary, // ใช้สีหลัก (เทาเข้ม)
                            foregroundColor:
                                theme
                                    .colorScheme
                                    .onPrimary, // สีตัวหนังสือ (ขาว/เทาอ่อน)
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                30,
                              ), // ความโค้งเท่ากับหน้า Register
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // Show Loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (c) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              );

                              try {
                                // Logic การ login เดิม
                                final userCredential = await FirebaseAuth
                                    .instance
                                    .signInWithEmailAndPassword(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                    )
                                    .timeout(const Duration(seconds: 15));

                                // บันทึก log การเข้าสู่ระบบ
                                if (userCredential.user != null) {
                                  await _logService.logUserLogin(
                                    userId: userCredential.user!.uid,
                                    userName:
                                        userCredential.user!.email?.split(
                                          '@',
                                        )[0] ??
                                        'Unknown',
                                    provider: 'email',
                                  );
                                }

                                _dismissLoadingDialog();
                                if (!mounted) return;
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dashboard',
                                );
                              } on FirebaseAuthException catch (e) {
                                _dismissLoadingDialog();
                                String msg = "เข้าสู่ระบบไม่สำเร็จ";
                                if (e.code == 'user-not-found')
                                  msg = "ไม่พบผู้ใช้งานนี้";
                                else if (e.code == 'wrong-password')
                                  msg = "รหัสผ่านไม่ถูกต้อง";
                                else if (e.code == 'invalid-credential')
                                  msg = "อีเมลหรือรหัสผ่านไม่ถูกต้อง";

                                await _showAlertDialog(
                                  title: 'เกิดข้อผิดพลาด',
                                  content: Text(msg),
                                  isError: true,
                                );
                              } catch (e) {
                                _dismissLoadingDialog();
                                await _showAlertDialog(
                                  title: 'เกิดข้อผิดพลาด',
                                  content: Text(e.toString()),
                                  isError: true,
                                );
                              }
                            }
                          },
                          child: const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Google Login Button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Image.asset(
                            'assets/img/google.jpg',
                            height: 24.0,
                          ),
                          label: const Text('เข้าสู่ระบบด้วย Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                30,
                              ), // ความโค้งเท่ากัน
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (c) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            );

                            try {
                              final userCredential = await signInWithGoogle();
                              _dismissLoadingDialog();

                              if (userCredential != null && mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dashboard',
                                );
                              }
                            } catch (e) {
                              _dismissLoadingDialog();
                              if (!mounted) return;
                              await _showAlertDialog(
                                title: 'เกิดข้อผิดพลาด',
                                content: Text('Google Sign-In Error: $e'),
                                isError: true,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Register Link ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ยังไม่มีการลงทะเบียน? ',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'ลงทะเบียน',
                              style: TextStyle(
                                color:
                                    theme
                                        .colorScheme
                                        .primary, // ใช้สี Theme ให้ดูเป็นลิงก์
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
