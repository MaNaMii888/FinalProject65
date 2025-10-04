import 'package:flutter/material.dart';
import 'package:project01/Screen/app.dart';
import 'package:project01/Screen/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Using singleton instance

  Future<UserCredential?> signInWithGoogle() async {
    try {
      return await _authService.signInWithGoogle();
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text('Welcome to', style: TextStyle(fontSize: 22)),
                const Text(
                  'Sign In!',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Gmail',
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
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
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
                                await Future.delayed(
                                  const Duration(seconds: 2),
                                );

                                await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    );

                                Navigator.of(context).pop();

                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('สำเร็จ'),
                                      content: const Text('เข้าสู่ระบบสำเร็จ'),
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 48,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _formKey.currentState!.reset();
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const NavigationBarApp(),
                                              ),
                                            );
                                          },
                                          child: const Text('ตกลง'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } on FirebaseAuthException catch (e) {
                                Navigator.of(context).pop();

                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('เกิดข้อผิดพลาด'),
                                      content: Text(
                                        e.message ?? "ไม่สามารถเข้าสู่ระบบได้",
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
                            'SIGN IN',
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
                          label: const Text('Sign in with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (BuildContext context) {
                                return WillPopScope(
                                  onWillPop: () async {
                                    // อนุญาตให้กด back เพื่อปิด loading dialog
                                    return true;
                                  },
                                  child: const Center(
                                    child: AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text(
                                            "กำลังเข้าสู่ระบบด้วย Google...",
                                          ),
                                          SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );

                            try {
                              final UserCredential? userCredential =
                                  await signInWithGoogle();

                              // ตรวจสอบว่า dialog ยังเปิดอยู่หรือไม่ก่อนปิด
                              if (Navigator.canPop(context)) {
                                Navigator.of(
                                  context,
                                ).pop(); // ปิด Loading Dialog
                              }

                              // ตรวจสอบทั้ง userCredential และ Firebase Auth currentUser
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;

                              if (userCredential != null ||
                                  currentUser != null) {
                                // เข้าสู่ระบบสำเร็จ (ตรวจสอบ 2 แหล่ง)
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('สำเร็จ'),
                                      content: Text(
                                        'เข้าสู่ระบบด้วย Google สำเร็จ\nยินดีต้อนรับ ${currentUser?.displayName ?? 'ผู้ใช้'}',
                                      ),
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 48,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const NavigationBarApp(),
                                              ),
                                            );
                                          },
                                          child: const Text('ตกลง'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                // รอสักครู่แล้วตรวจสอบอีกครั้ง (กรณี async delay)
                                await Future.delayed(
                                  Duration(milliseconds: 500),
                                );
                                final retryCurrentUser =
                                    FirebaseAuth.instance.currentUser;

                                if (retryCurrentUser != null) {
                                  // Login สำเร็จแล้วจริงๆ แต่ async delay
                                  await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('สำเร็จ'),
                                        content: Text(
                                          'เข้าสู่ระบบด้วย Google สำเร็จ\nยินดีต้อนรับ ${retryCurrentUser.displayName ?? 'ผู้ใช้'}',
                                        ),
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 48,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const NavigationBarApp(),
                                                ),
                                              );
                                            },
                                            child: const Text('ตกลง'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  // เข้าสู่ระบบไม่สำเร็จจริงๆ
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('เกิดข้อผิดพลาด'),
                                        content: const Text(
                                          'ไม่สามารถเข้าสู่ระบบด้วย Google ได้\nกรุณาลองใหม่อีกครั้ง',
                                        ),
                                        icon: const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('ปิด'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            } catch (e) {
                              // ตรวจสอบว่า dialog ยังเปิดอยู่หรือไม่ก่อนปิด
                              if (Navigator.canPop(context)) {
                                Navigator.of(
                                  context,
                                ).pop(); // ปิด Loading Dialog
                              }
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('เกิดข้อผิดพลาด'),
                                    content: const Text(
                                      'ไม่สามารถเข้าสู้ระบบด้วย googleได้',
                                    ),
                                    icon: const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "SIGN UP",
                              style: TextStyle(fontWeight: FontWeight.bold),
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
