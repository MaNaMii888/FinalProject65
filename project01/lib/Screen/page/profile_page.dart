import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:project01/Screen/page/edit_profile_page.dart';

import 'package:project01/Screen/login.dart'; // เพิ่ม import นี้ที่ด้านบนของไฟล์

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  DateTime? lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // เช็คว่ามีการล็อกอินหรือไม่
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFFFFF),
        appBar: AppBar(
          title: const Text('โปรไฟล์'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 100, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'ยังไม่ได้เข้าสู่ระบบ',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('เข้าสู่ระบบ'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (lastBackPressed == null ||
            now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
          lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กดย้อนกลับอีกครั้งเพื่อออกจากแอป'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFFFFF),
        appBar: AppBar(
          title: const Text('โปรไฟล์'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirm = await showDialog<bool>(
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
                );

                if (confirm == true && mounted) {
                  try {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      // เปลี่ยนวิธีการ navigate
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const LoginPage(), // หรือหน้า HomePage แล้วแต่โครงสร้างแอพ
                        ),
                        (route) => false, // ลบ stack ทั้งหมด
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
        body: Center(child: _buildUserContent(user)),
      ),
    );
  }

  Widget _buildUserContent(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // ถ้าไม่มีข้อมูลใน Firestore ให้สร้างข้อมูลเริ่มต้น
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'ไม่ระบุชื่อ',
            'email': user.email,
            'profileUrl': user.photoURL,
            'phone': '',
            'lostCount': 0,
            'foundCount': 0,
            'isOnline': true,
          }, SetOptions(merge: true));

          // แสดงข้อมูลเริ่มต้น
          return _buildResponsiveProfileCard(
            user: user,
            userData: {},
            isDefaultData: true,
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return _buildResponsiveProfileCard(
          user: user,
          userData: userData,
          isDefaultData: false,
        );
      },
    );
  }

  Widget _buildResponsiveProfileCard({
    required User user,
    required Map<String, dynamic> userData,
    required bool isDefaultData,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        if (screenWidth < 600) {
          // Mobile layout
          return SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileImage(user, userData),
                    const SizedBox(height: 16),
                    _buildUserInfo(user, userData),
                    const SizedBox(height: 20),
                    _buildStats(userData),
                    const SizedBox(height: 20),
                    _buildEditButton(context),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Tablet/Desktop layout
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth < 900 ? 600 : 800,
                maxHeight: screenWidth < 900 ? 700 : 800,
              ),
              child: Card(
                elevation: 6,
                margin: EdgeInsets.all(screenWidth < 900 ? 24 : 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth < 900 ? 32 : 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProfileImage(user, userData),
                      const SizedBox(height: 24),
                      _buildUserInfo(user, userData),
                      const SizedBox(height: 32),
                      _buildStats(userData),
                      const SizedBox(height: 32),
                      _buildEditButton(context),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildProfileImage(User user, Map<String, dynamic> userData) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage:
              (userData['profileUrl'] != null || user.photoURL != null)
                  ? CachedNetworkImageProvider(
                    userData['profileUrl'] ?? user.photoURL!,
                  )
                  : null,
          child:
              (userData['profileUrl'] == null && user.photoURL == null)
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
        ),
        if (userData['isOnline'] == true)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo(User user, Map<String, dynamic> userData) {
    final name = userData['name'] ?? user.displayName ?? 'ไม่ระบุชื่อ';
    final email = user.email ?? 'ไม่ระบุอีเมล';
    final phone = userData['phone'] as String?;

    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
          textAlign: TextAlign.center,
        ),
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'โทร: $phone',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildStats(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'ของหาย',
            '${userData['lostCount'] ?? 0}',
            Icons.search,
          ),
          _buildStatItem(
            'เจอของ',
            '${userData['foundCount'] ?? 0}',
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.edit),
      label: const Text('แก้ไขโปรไฟล์'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () async {
        // ใช้ push ธรรมดาและรอรับข้อมูลที่ส่งกลับมา
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(builder: (context) => const EditProfilePage()),
        );

        // ถ้ามีการอัพเดทข้อมูล (result ไม่เป็น null) ให้รีเฟรชหน้า Profile
        if (result != null) {
          setState(() {
            // ข้อมูลจะถูกอัพเดทผ่าน StreamBuilder อัตโนมัติ
          });
        }
      },
    );
  }
}
