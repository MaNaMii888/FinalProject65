import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/utils/debug_helper.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // --- Logic ส่วนเดิม (ทำงานถูกต้องแล้ว) ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    // ปิดคีย์บอร์ดก่อนเริ่ม process
    FocusScope.of(context).unfocus();

    if (!mounted) return;
    // Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'กำลังตรวจสอบ...',
                      style: TextStyle(fontFamily: 'Prompt'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      DebugHelper.log('ForgotPassword: sending reset to $email');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted && Navigator.canPop(context))
        Navigator.of(context).pop(); // ปิด Loading

      if (!mounted) return;
      _showResultDialog(
        title: 'เช็คอีเมลของคุณ',
        content:
            'เราได้ส่งลิงก์สำหรับรีเซ็ตรหัสผ่านไปยัง\n$email\n\n(หากไม่พบ กรุณาตรวจสอบในโฟลเดอร์สแปม)',
        isError: false,
      );
    } on FirebaseAuthException catch (e, st) {
      DebugHelper.logError('ForgotPassword error', e, st);
      if (mounted && Navigator.canPop(context))
        Navigator.of(context).pop(); // ปิด Loading

      String msg = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
      if (e.code == 'user-not-found') {
        msg = 'ไม่พบอีเมลนี้ในระบบ';
      } else if (e.code == 'invalid-email') {
        msg = 'รูปแบบอีเมลไม่ถูกต้อง';
      }

      if (!mounted) return;
      _showResultDialog(
        title: 'ส่งไม่สำเร็จ',
        content: '$msg\n(รหัส: ${e.code})',
        isError: true,
      );
    } catch (e, st) {
      DebugHelper.logError('ForgotPassword general error', e, st);
      if (mounted && Navigator.canPop(context))
        Navigator.of(context).pop(); // ปิด Loading
      if (!mounted) return;
      _showResultDialog(
        title: 'ข้อผิดพลาด',
        content: 'ระบบขัดข้อง: ${e.toString()}',
        isError: true,
      );
    }
  }

  // แยก Widget Dialog ออกมาเพื่อให้โค้ดอ่านง่ายขึ้น (Code Simplicity)
  Future<void> _showResultDialog({
    required String title,
    required String content,
    required bool isError,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color:
                      isError
                          ? Theme.of(context).colorScheme.error
                          : Colors.green,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (!isError) {
                    // ออปชั่นเสริม: ส่งสำเร็จแล้วอาจจะอยากให้กลับหน้า Login เลยหรือไม่?
                    // Navigator.of(context).pop();
                  }
                },
                child: const Text('ตกลง'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // --- UI ส่วนใหม่ (Aesthetics & Functionality) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // ใช้สี Background จาก Theme
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, // จัดกึ่งกลาง
                children: [
                  // 1. Icon Graphic
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Headings
                  Text(
                    'ลืมรหัสผ่าน?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ไม่ต้องกังวล กรอกอีเมลที่ใช้ลงทะเบียนด้านล่าง\nเราจะส่งลิงก์ตั้งรหัสผ่านใหม่ให้คุณ',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(), // กด Enter แล้วส่งเลย
                    decoration: InputDecoration(
                      labelText: 'อีเมล',
                      hintText: 'example@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'กรุณากรอกอีเมล';
                      // Regex เดิมใช้งานได้ดีแล้ว
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'รูปแบบอีเมลไม่ถูกต้อง';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.primary, // สีเทาเข้ม #444444
                        foregroundColor:
                            theme.colorScheme.onPrimary, // สีขาว/เทาอ่อน
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'ส่งลิงก์รีเซ็ตรหัสผ่าน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
