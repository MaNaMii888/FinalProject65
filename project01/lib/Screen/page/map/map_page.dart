import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/campus_map_polygon.dart'
    show CampusMapPolygon;

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // แสดงแผนที่
        const CampusMapPolygon(),
        // ทับด้วย TopBar
      ],
    );
  }
}
