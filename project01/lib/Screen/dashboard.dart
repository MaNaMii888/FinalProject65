import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/map_page.dart';
import 'package:project01/Screen/page/post/post_page.dart';
import 'package:project01/Screen/page/profile/profile_page.dart';
import 'package:project01/Screen/page/notification/realtime_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:project01/Screen/page/chat/chat_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  DateTime? lastPressed;

  @override
  void initState() {
    super.initState();
    // 🚀 Start listening for smart match notifications in the background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RealtimeNotificationService.startListening(context);
    });
  }

  final List<Widget> _pages = [
    const MapPage(), // index 0 - หน้าหลัก (แผนที่)
    const PostPage(), // index 1 - หน้าแจ้งของ/ฟีด
    const ChatListPage(), // index 2 - หน้ารายการแชท
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        if (_selectedIndex != 0) {
          // ถ้าไม่ได้อยู่ที่หน้าแผนที่ ให้กลับไปที่หน้าแผนที่
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        // ถ้าอยู่ที่หน้าแผนที่แล้ว ให้กดย้อนกลับ 2 ครั้งเพื่อออกจากแอป
        if (lastPressed == null ||
            DateTime.now().difference(lastPressed!) >
                const Duration(seconds: 2)) {
          lastPressed = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กดย้อนกลับอีกครั้งเพื่อออกจากแอป'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        // Exit the app
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: _pages),
            // ไอคอน Profile ที่มุมขวาบน (ลอยทับทุกหน้า)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              const ProfilePage(),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutQuint,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.transparent,
                    backgroundImage:
                        (photoUrl != null && photoUrl.isNotEmpty)
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                    child:
                        (photoUrl == null || photoUrl.isEmpty)
                            ? const Icon(
                              Icons.person_rounded,
                              color: Colors.blueAccent,
                              size: 28,
                            )
                            : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildResponsiveNavigation(),
      ),
    );
  }

  Widget _buildResponsiveNavigation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        if (screenWidth < 600) {
          // Mobile - ใช้ BottomNavigationBar ปกติ
          return BottomNavigationBar(
            backgroundColor: const Color(0xFF171717),
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFFEDEDED),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'แผนที่',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded),
                activeIcon: Icon(Icons.list_alt),
                label: 'รายการ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                activeIcon: Icon(Icons.chat_bubble_rounded),
                label: 'แชท',
              ),
            ],
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          );
        } else {
          // Tablet/Desktop - ใช้ NavigationRail หรือ Sidebar
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavigationButton(
                      icon: Icons.map_outlined,
                      activeIcon: Icons.map,
                      label: 'แผนที่',
                      isSelected: _selectedIndex == 0,
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                    _buildNavigationButton(
                      icon: Icons.list_alt_rounded,
                      activeIcon: Icons.list_alt,
                      label: 'รายการ',
                      isSelected: _selectedIndex == 1,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    _buildNavigationButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'แชท',
                      isSelected: _selectedIndex == 2,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
