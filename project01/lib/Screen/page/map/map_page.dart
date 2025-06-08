import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/campus_navigation.dart'
    show CampusNavigation;
import 'package:project01/Screen/widgets/custom_top_bar.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // แสดงแผนที่
        const CampusNavigation(),
        // ทับด้วย TopBar
        CustomTopBar(
          onMenuPressed: () {
            // TODO: เพิ่มการทำงานเมื่อกดปุ่ม menu
          },
          
          onNotificationPressed: () {
            // TODO: เพิ่มการทำงานเมื่อกดปุ่มแจ้งเตือน
          },
        ),
      ],
    );
  }
}
