import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/Screen/page/profile/edit_profile_page.dart';
import 'package:project01/Screen/page/profile/menu/profile_menu_page.dart';
import 'package:project01/Screen/page/profile/widgets/edit_post_bottom_sheet.dart';
import 'package:project01/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:project01/models/post.dart';
import 'package:project01/models/post_detail_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  DateTime? lastBackPressed;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          leading: Builder(
            builder: (context) {
              return PopupMenuButton<ThemeMode>(
                icon: Icon(Icons.brightness_6, color: Colors.deepPurple),
                tooltip: 'เปลี่ยนธีม',
                onSelected: (mode) {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).setThemeMode(mode);
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: ThemeMode.system,
                        child: Row(
                          children: [
                            Icon(Icons.phone_android, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            const Text('ตามระบบ'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ThemeMode.light,
                        child: Row(
                          children: [
                            Icon(Icons.light_mode, color: Colors.amber[700]),
                            const SizedBox(width: 8),
                            const Text('โหมดสว่าง'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ThemeMode.dark,
                        child: Row(
                          children: [
                            Icon(Icons.dark_mode, color: Colors.blueGrey[700]),
                            const SizedBox(width: 8),
                            const Text('โหมดมืด'),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
          title: const Text('โปรไฟล์'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileMenuPage(),
                    ),
                  ),
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: _buildUserContent(user),
          ),
        ),
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
          return Column(
            children: [
              // ส่วนข้อมูลผู้ใช้
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Column(
                  children: [
                    _buildProfileImage(user, userData),
                    const SizedBox(height: 16),
                    _buildUserInfo(user, userData),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // ส่วน TabBar และประวัติ
              Expanded(child: _buildStats(userData)),
            ],
          );
        } else {
          // Tablet/Desktop layout
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth < 900 ? 600 : 800,
              maxHeight: screenWidth < 900 ? 700 : 800,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth < 900 ? 24 : 32,
                screenWidth < 900 ? 8 : 16,
                screenWidth < 900 ? 24 : 32,
                screenWidth < 900 ? 16 : 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProfileImage(user, userData),
                  const SizedBox(height: 20),
                  _buildUserInfo(user, userData),
                  const SizedBox(height: 20),
                  Expanded(child: _buildStats(userData)),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildProfileImage(User user, Map<String, dynamic> userData) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                (userData['profileUrl'] != null || user.photoURL != null)
                    ? CachedNetworkImageProvider(
                      userData['profileUrl'] ?? user.photoURL!,
                    )
                    : null,
            child:
                (userData['profileUrl'] == null && user.photoURL == null)
                    ? const Icon(Icons.person, size: 45, color: Colors.grey)
                    : null,
          ),
          if (userData['isOnline'] == true)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(User user, Map<String, dynamic> userData) {
    final name = userData['name'] ?? user.displayName ?? 'ไม่ระบุชื่อ';
    final email = user.email ?? 'ไม่ระบุอีเมล';
    final phone = userData['phone'] as String?;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // ชื่ออยู่ตรงกลาง
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          constraints.maxWidth * 0.8, // ใช้ 80% ของความกว้าง
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                // ปุ่มแก้ไขอยู่ด้านขวา
                Positioned(
                  right:
                      constraints.maxWidth * 0.1, // ใช้ 10% ของความกว้างจากขวา
                  child: GestureDetector(
                    onTap: () async {
                      // ใช้ push ธรรมดาและรอรับข้อมูลที่ส่งกลับมา
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );

                      // ถ้ามีการอัพเดทข้อมูล (result ไม่เป็น null) ให้รีเฟรชหน้า Profile
                      if (result != null) {
                        setState(() {
                          // ข้อมูลจะถูกอัพเดทผ่าน StreamBuilder อัตโนมัติ
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              email,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'โทร: $phone',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStats(Map<String, dynamic> userData) {
    return Column(
      children: [
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.0),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.search), text: 'ของหาย'),
              Tab(icon: Icon(Icons.check_circle), text: 'เจอของ'),
            ],
            indicatorColor: Colors.deepPurple,
            dividerColor: Colors.transparent,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryList(true), // ของหาย
              _buildHistoryList(false), // เจอของ
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildHistoryList(bool isLostItems) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบ'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('lost_found_items')
              .where('userId', isEqualTo: user.uid)
              .where('isLostItem', isEqualTo: isLostItems)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'เกิดข้อผิดพลาด: ${snapshot.error}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLostItems ? Icons.search_off : Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isLostItems
                      ? 'ยังไม่มีประวัติของหาย'
                      : 'ยังไม่มีประวัติเจอของ',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  isLostItems
                      ? 'เมื่อคุณแจ้งของหาย จะแสดงที่นี่'
                      : 'เมื่อคุณแจ้งเจอของ จะแสดงที่นี่',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final posts =
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Post.fromJson({...data, 'id': doc.id});
            }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            // Stream จะอัพเดทอัตโนมัติ
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PostDetailSheet(post: post),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    post.status == 'resolved' ||
                                            post.status == 'closed'
                                        ? Colors.green[100]
                                        : Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                post.status == 'resolved' ||
                                        post.status == 'closed'
                                    ? 'เสร็จสิ้น'
                                    : 'กำลังดำเนินการ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      post.status == 'resolved' ||
                                              post.status == 'closed'
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  // เปิดหน้าแก้ไขโพสต์
                                  await _editPost(post);
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('ยืนยันการลบ'),
                                          content: const Text(
                                            'คุณต้องการลบโพสต์นี้หรือไม่?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('ยกเลิก'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('ลบ'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('lost_found_items')
                                          .doc(post.id)
                                          .delete();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('ลบโพสต์เรียบร้อย'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'ไม่สามารถลบโพสต์ได้: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.black),
                                          SizedBox(width: 8),
                                          Text('แก้ไข'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('ลบโพสต์'),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (post.description.isNotEmpty) ...[
                          Text(
                            post.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (post.imageUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: post.imageUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getCategoryText(post.category),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(post.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getCategoryText(String category) {
    switch (category) {
      case '1':
        return 'ของใช้ส่วนตัว';
      case '2':
        return 'เอกสาร/บัตร';
      case '3':
        return 'อุปกรณ์การเรียน';
      case '4':
        return 'ของมีค่าอื่นๆ';
      default:
        return 'ไม่ระบุ';
    }
  }

  // ฟังก์ชันแก้ไขโพสต์
  Future<void> _editPost(Post post) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPostBottomSheet(post: post),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชม.ที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }
}
