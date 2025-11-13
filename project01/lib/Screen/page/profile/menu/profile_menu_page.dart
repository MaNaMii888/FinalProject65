import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project01/Screen/login.dart';
import 'package:project01/services/auth_service.dart';

class ProfileMenuPage extends StatefulWidget {
  const ProfileMenuPage({super.key});

  @override
  State<ProfileMenuPage> createState() => _ProfileMenuPageState();
}

class _ProfileMenuPageState extends State<ProfileMenuPage> {
  bool isLegendExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFFFF),
      appBar: AppBar(
        title: const Text('เมนู'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorLegendSection(),
            const Spacer(),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildColorLegendSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }


  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[600], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ออกจากระบบ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[600],
                    ),
                  ),
                  Text(
                    'ออกจากระบบและกลับไปหน้าเข้าสู่ระบบ',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ยืนยันการออกจากระบบ'),
            content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
    ).then((confirm) async {
      if (confirm == true && context.mounted) {
        // แสดง loading dialog
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => true,
              child: const Center(
                child: AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('กำลังออกจากระบบ...'),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        try {
          // ใช้ AuthService สำหรับ sign out แทน FirebaseAuth โดยตรง
          final authService = AuthService();
          await authService.signOut();

          if (context.mounted) {
            // ปิด loading dialog
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }

            // กลับไปหน้า login และ clear navigation stack
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            // ปิด loading dialog ในกรณี error
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }

            // แสดง error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }
}
