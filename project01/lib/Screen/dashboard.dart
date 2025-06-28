import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/map_page.dart';
import 'package:project01/Screen/page/post_page.dart';
import 'package:project01/Screen/page/profile_page.dart';
// Ensure this file contains the ActionPage class

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  DateTime? lastPressed;

  // กำหนดให้ MapPage เป็นหน้าแรก
  final List<Widget> _pages = [
    const MapPage(), // index 0 - หน้าหลัก (แผนที่)
    const PostPage(), // index 1 - หน้าแจ้งของ
    const ProfilePage(), // index 2 - หน้าโปรไฟล์
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          // ถ้าไม่ได้อยู่ที่หน้าแผนที่ ให้กลับไปที่หน้าแผนที่
          setState(() {
            _selectedIndex = 0;
          });
          return false;
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
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
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
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'แผนที่',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'แจ้งของ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'โปรไฟล์',
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
                      icon: Icons.add_circle_outline,
                      activeIcon: Icons.add_circle,
                      label: 'แจ้งของ',
                      isSelected: _selectedIndex == 1,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    _buildNavigationButton(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'โปรไฟล์',
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
