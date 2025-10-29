import 'package:flutter/material.dart';
import 'package:project01/Screen/register.dart';
import 'package:project01/Screen/app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/services/auth_service.dart';
import 'package:project01/utils/debug_helper.dart';

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
                                print('=== Email/Password Login Starting ===');
                                print('Email: ${_emailController.text}');
                                print(
                                  'Password length: ${_passwordController.text.length}',
                                );

                                final userCredential = await FirebaseAuth
                                    .instance
                                    .signInWithEmailAndPassword(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                    );

                                print(
                                  'Login successful: ${userCredential.user?.email}',
                                );
                                Navigator.of(context).pop();

                                // ไปหน้าหลักทันทีโดยไม่แสดง success dialog
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const NavigationBarApp(),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                print('=== FirebaseAuth Error ===');
                                print('Error code: ${e.code}');
                                print('Error message: ${e.message}');

                                Navigator.of(context).pop();

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
                              } catch (e) {
                                print('=== General Login Error ===');
                                print('Error: $e');

                                Navigator.of(context).pop();

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
                              print('=== Google Sign-In Starting ===');
                              final UserCredential? userCredential =
                                  await signInWithGoogle();

                              print('=== Google Sign-In Result ===');
                              print('UserCredential: $userCredential');
                              print('User: ${userCredential?.user}');
                              print(
                                'User Email: ${userCredential?.user?.email}',
                              );
                              print(
                                'User DisplayName: ${userCredential?.user?.displayName}',
                              );

                              // ตรวจสอบว่า dialog ยังเปิดอยู่หรือไม่ก่อนปิด
                              if (Navigator.canPop(context)) {
                                Navigator.of(
                                  context,
                                ).pop(); // ปิด Loading Dialog
                              }

                              // ตรวจสอบทั้ง userCredential และ Firebase Auth currentUser
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              print('Current Firebase User: $currentUser');

                              if (userCredential != null &&
                                  userCredential.user != null) {
                                print('=== Login Success ===');
                                // เข้าสู่ระบบสำเร็จ
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('สำเร็จ'),
                                      content: Text(
                                        'เข้าสู่ระบบด้วย Google สำเร็จ\nยินดีต้อนรับ ${userCredential.user?.displayName ?? currentUser?.displayName ?? 'ผู้ใช้'}',
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
                              } else if (currentUser != null) {
                                print(
                                  '=== Login Success (via currentUser) ===',
                                );
                                // เข้าสู่ระบบสำเร็จผ่าน Firebase currentUser
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('สำเร็จ'),
                                      content: Text(
                                        'เข้าสู่ระบบด้วย Google สำเร็จ\nยินดีต้อนรับ ${currentUser.displayName ?? 'ผู้ใช้'}',
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
                                print('=== Login Failed - No User ===');
                                // รอสักครู่แล้วตรวจสอบอีกครั้ง (กรณี async delay)
                                await Future.delayed(
                                  Duration(milliseconds: 1000),
                                );
                                final retryCurrentUser =
                                    FirebaseAuth.instance.currentUser;
                                print('Retry Current User: $retryCurrentUser');

                                if (retryCurrentUser != null) {
                                  print('=== Login Success (after retry) ===');
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
                                  print('=== Login Failed - User is null ===');
                                  // เข้าสู่ระบบไม่สำเร็จจริงๆ
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('เกิดข้อผิดพลาด'),
                                        content: const Text(
                                          'ไม่สามารถเข้าสู่ระบบด้วย Google ได้\nกรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและลองใหม่อีกครั้ง',
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
                            } catch (e, stackTrace) {
                              print('=== Google Sign-In Error ===');
                              print('Error: $e');
                              print('StackTrace: $stackTrace');

                              // ตรวจสอบว่า dialog ยังเปิดอยู่หรือไม่ก่อนปิด
                              if (Navigator.canPop(context)) {
                                Navigator.of(
                                  context,
                                ).pop(); // ปิด Loading Dialog
                              }

                              String errorMessage =
                                  'ไม่สามารถเข้าสู่ระบบด้วย Google ได้';

                              // จัดการ error messages ต่างๆ
                              if (e.toString().contains('network_error') ||
                                  e.toString().contains('NetworkError')) {
                                errorMessage =
                                    'ตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและลองใหม่อีกครั้ง';
                              } else if (e.toString().contains(
                                    'sign_in_canceled',
                                  ) ||
                                  e.toString().contains('cancelled')) {
                                errorMessage = 'การเข้าสู่ระบบถูกยกเลิก';
                              } else if (e.toString().contains(
                                'account-exists-with-different-credential',
                              )) {
                                errorMessage =
                                    'บัญชีนี้มีอยู่แล้วกับข้อมูลประจำตัวอื่น';
                              } else if (e.toString().contains(
                                'user-disabled',
                              )) {
                                errorMessage = 'บัญชีผู้ใช้ถูกปิดใช้งาน';
                              } else if (e.toString().contains('PigeonUser') ||
                                  e.toString().contains('PigeonUserDetails') ||
                                  e.toString().contains('type cast') ||
                                  e.toString().contains(
                                    'การเข้าสู่ระบบด้วย Google ล้มเหลว',
                                  )) {
                                errorMessage =
                                    'เกิดข้อผิดพลาดในการเข้าสู่ระบบ Google\n\nวิธีแก้ไข:\n1. ปิดแอปแล้วเปิดใหม่\n2. หากยังไม่ได้ ลบข้อมูล Google app แล้วลองใหม่\n3. รีสตาร์ทโทรศัพท์';
                              } else if (e.toString().contains(
                                    'ApiException: 10',
                                  ) ||
                                  e.toString().contains('DEVELOPER_ERROR')) {
                                errorMessage =
                                    'การกำหนดค่า Google Sign-In ไม่ถูกต้อง\nกรุณาตรวจสอบ SHA-1 fingerprint ใน Firebase Console\nหรือติดต่อผู้พัฒนาแอป';
                              }
                              showDialog(
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
                                          'รายละเอียด: ${e.toString()}',
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
