import 'package:flutter/material.dart';
import '../widgets/custom_top_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
        ),
        CustomTopBar(
          onMenuPressed: () {
            // TODO: เพิ่มการทำงานสำหรับหน้า Profile
          },
          onNotificationPressed: () {
            // TODO: เพิ่มการทำงานสำหรับหน้า Profile
          },
        ),
      ],
    );
  }
}
