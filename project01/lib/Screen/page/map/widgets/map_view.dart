import 'package:flutter/material.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            height: 384,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.map, size: 64, color: Colors.green[600])],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildMapView() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // ใช้ MediaQuery เพื่อดึงขนาดหน้าจอ
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      // กำหนด breakpoints สำหรับ responsive design
      if (screenWidth < 600) {
        // Mobile (หน้าจอเล็ก)
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const MapView(),
          ),
        );
      } else if (screenWidth < 900) {
        // Tablet (หน้าจอกลาง)
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const MapView(),
          ),
        );
      } else {
        // Desktop (หน้าจอใหญ่)
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.8, // 80% ของความกว้างหน้าจอ
              maxHeight: screenHeight * 0.7, // 70% ของความสูงหน้าจอ
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: const MapView(),
            ),
          ),
        );
      }
    },
  );
}
