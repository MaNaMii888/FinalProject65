import 'package:flutter/material.dart';
import '../widgets/custom_top_bar.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.grey[200],
          width: double.infinity,
          height: double.infinity,
        ),
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
