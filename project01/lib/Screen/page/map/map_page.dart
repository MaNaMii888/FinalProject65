import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/campus_navigation.dart'
    show CampusNavigation;

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // แสดงแผนที่
        const CampusNavigation(),
        // ทับด้วย TopBar
      ],
    );
  }
}
