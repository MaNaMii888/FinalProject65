import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notifications_service.dart';
import 'notification_screen.dart'; // ปรับ path ให้ตรงกับโปรเจกต์ของคุณ

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
    final currentUser = FirebaseAuth.instance.currentUser;

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
                  onPressed:
                      onMenuPressed ??
                      () {
                        Scaffold.of(context).openDrawer();
                      },
                  tooltip: 'เมนู',
                ),
          ),
          _buildNotificationButton(context, currentUser),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, User? currentUser) {
    return StreamBuilder<int>(
      stream:
          currentUser != null
              ? NotificationService.getUnreadCount(currentUser.uid)
              : Stream.value(0),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed:
                  onNotificationPressed ??
                  () {
                    // Show notification popup (bottom sheet)
                    NotificationPopup.show(context);
                  },
              tooltip: 'การแจ้งเตือน',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Notification Popup Class
class NotificationPopup {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationBottomSheet(),
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
