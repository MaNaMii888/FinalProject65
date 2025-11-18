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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('กำลังส่งอีเมลสำหรับรีเซ็ตรหัสผ่าน...'),
                ],
              ),
            ),
          ),
    );

    try {
      DebugHelper.log('ForgotPassword: sending reset to $email');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();

      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('ส่งแล้ว'),
              content: Text(
                'เราได้ส่งอีเมลสำหรับรีเซ็ตรหัสผ่านไปยัง $email\nกรุณาตรวจสอบกล่องจดหมาย (รวมถึงโฟลเดอร์สแปม)',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ตกลง'),
                ),
              ],
            ),
      );
    } on FirebaseAuthException catch (e, st) {
      DebugHelper.logError('ForgotPassword error', e, st);
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      String msg = 'ไม่สามารถส่งอีเมลรีเซ็ตรหัสผ่านได้ กรุณาลองอีกครั้ง';
      if (e.code == 'user-not-found') {
        msg = 'ไม่พบผู้ใช้งานที่ใช้อีเมลนี้ กรุณาตรวจสอบอีเมลอีกครั้ง';
      }
      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('เกิดข้อผิดพลาด'),
              content: Text('$msg\n\nรายละเอียด: ${e.message ?? e.code}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ปิด'),
                ),
              ],
            ),
      );
    } catch (e, st) {
      DebugHelper.logError('ForgotPassword general error', e, st);
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('เกิดข้อผิดพลาด'),
              content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ปิด'),
                ),
              ],
            ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลืมรหัสผ่าน')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'กรอกอีเมลที่ใช้ลงทะเบียน\nเพื่อรับลิงก์รีเซ็ตรหัสผ่าน',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกอีเมล';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'รูปแบบอีเมลไม่ถูกต้อง';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('ส่งลิงก์รีเซ็ตรหัสผ่าน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
