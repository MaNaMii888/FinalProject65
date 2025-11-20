import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:project01/models/profile.dart' show Profile;
import 'package:project01/Screen/login.dart';
import 'package:project01/services/auth_service.dart';
// แนะนำให้ import เพื่อใช้ log

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ไม่จำเป็นต้องประกาศ Firebase.initializeApp() ตรงนี้เพราะมักจะทำที่ main.dart แล้ว
  Profile profile = Profile(email: '', password: '');
  final AuthService _authService = AuthService();

  // Function ช่วยปิด Dialog แบบปลอดภัย
  void _dismissLoadingDialog() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  // Function แสดง Dialog แจ้งเตือน
  Future<void> _showAlertDialog({
    required String title,
    required String content,
    bool isError = false,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          icon: Icon(
            isError ? Icons.error : Icons.check_circle,
            color: isError ? Theme.of(context).colorScheme.error : Colors.green,
            size: 48,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  'ยินดีต้อนรับ', // แก้คำผิด
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 22,
                  ),
                ),
                Text(
                  'สมัครสมาชิก',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.9,
                    ), // ใช้ withOpacity แทน withValues เพื่อรองรับ Flutter เก่า/ใหม่
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // --- Email Input ---
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.surface,
                          ),
                          border: const UnderlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        validator:
                            MultiValidator([
                              RequiredValidator(errorText: "กรุณากรอกอีเมล"),
                              EmailValidator(
                                errorText: "รูปแบบอีเมลไม่ถูกต้อง",
                              ),
                            ]).call,
                        onSaved: (String? email) {
                          profile.email = email ?? '';
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- Password Input ---
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.surface,
                          ),
                          border: const UnderlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        validator:
                            MultiValidator([
                              RequiredValidator(errorText: "กรุณากรอกรหัสผ่าน"),
                              MinLengthValidator(
                                6,
                                errorText:
                                    "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร",
                              ),
                              // หากต้องการบังคับตัวอักษรพิเศษหรือตัวใหญ่ สามารถเพิ่ม PatternValidator ได้ที่นี่
                            ]).call,
                        onSaved: (String? password) {
                          profile.password = password ?? '';
                        },
                      ),
                      const SizedBox(height: 24),

                      // --- Register Button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF4CAF50,
                            ), // ใช้สี Primary ตาม Theme
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              // 1. Show Loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (c) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              );

                              try {
                                // 2. Process (ตัด delay 2 วิออกเพื่อให้เร็วขึ้น)
                                await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                                      email: profile.email,
                                      password: profile.password,
                                    );

                                // 3. Close Loading
                                _dismissLoadingDialog();

                                // 4. Success & Navigate
                                if (!mounted) return;
                                // ทางเลือก: ไปหน้า Dashboard เลย หรือ Login เลย (ตาม Flow ของ Login.dart)
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dashboard',
                                );
                              } on FirebaseAuthException catch (e) {
                                // 3. Close Loading (กรณี Error)
                                _dismissLoadingDialog();

                                // 4. Show Error
                                String message =
                                    e.message ?? "ไม่สามารถลงทะเบียนได้";
                                if (e.code == 'email-already-in-use') {
                                  message = "อีเมลนี้มีผู้ใช้งานแล้ว";
                                } else if (e.code == 'weak-password') {
                                  message =
                                      "รหัสผ่านต้องมีความยาว 6 ตัวอักษรขึ้นไป";
                                }
                                await _showAlertDialog(
                                  title: 'เกิดข้อผิดพลาด',
                                  content: message,
                                  isError: true,
                                );
                              }
                            }
                          },
                          child: const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Google Sign-Up Button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          // ตรวจสอบ path รูปภาพให้ถูกต้อง
                          icon: Image.asset(
                            'assets/img/google.jpg',
                            height: 24.0,
                          ),
                          label: const Text('สมัครด้วย Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            // 1. Show Loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (c) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            );

                            try {
                              // 2. Call Service
                              // เรียกใช้ authService โดยตรง ไม่ต้องผ่าน wrapper เพื่อให้ catch error ได้แม่นยำ
                              final UserCredential? userCredential =
                                  await _authService.signInWithGoogle();

                              // 3. Close Loading (สำคัญ: ต้องทำก่อนเช็คผลลัพธ์)
                              _dismissLoadingDialog();

                              // 4. Check Result
                              if (userCredential != null) {
                                if (!mounted) return;
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dashboard',
                                );
                              } else {
                                // กรณี user กด cancel ไม่ต้องขึ้น Error ก็ได้ หรือจะแจ้งเตือนเบาๆ
                                // แต่ต้องมั่นใจว่า Loading หายไปแล้ว (ซึ่งหายแล้วจากข้อ 3)
                              }
                            } catch (e) {
                              // 3. Close Loading (กรณี Exception)
                              _dismissLoadingDialog();

                              // 4. Show Error
                              await _showAlertDialog(
                                title: 'เกิดข้อผิดพลาด',
                                content: 'ไม่สามารถสมัครด้วย Google ได้: $e',
                                isError: true,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Switch to Login ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'มีบัญชีแล้ว?',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          TextButton(
                            onPressed: () {
                              // ใช้ pushReplacement เพื่อไม่ให้กด back กลับมาหน้า register ได้
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary, // ใช้สี Theme
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
