import 'package:flutter/material.dart';

class CustomTopBar extends StatelessWidget {
  final Function()? onMenuPressed;
  final Function()? onNotificationPressed;

  const CustomTopBar({
    super.key,
    this.onMenuPressed,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip: 'เมนู',
                ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: เพิ่มฟังก์ชันเปิดหน้าแจ้งเตือนที่นี่
              print("Notification pressed");
            },
            tooltip: 'การแจ้งเตือน',
          ),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CustomTopBar(
                onMenuPressed: () {
                  // จัดการการกดปุ่มเมนู
                },
                onNotificationPressed: () {
                  // จัดการการกดปุ่มแจ้งเตือน
                },
              ),
              Expanded(
                child: Container(
                  // เนื้อหาของหน้า
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}
