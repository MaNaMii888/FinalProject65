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
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.menu), onPressed: onMenuPressed),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: onNotificationPressed,
            ),
          ],
        ),
      ),
    );
  }
}
