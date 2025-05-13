import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map_page.dart';
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
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
        ),
      ),
    );
  }
}
