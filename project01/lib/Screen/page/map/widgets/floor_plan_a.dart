import 'package:flutter/material.dart';
import 'package:project01/Screen/page/map/painters/floor_plan_a_painter.dart';

class FloorPlanA extends StatelessWidget {
  final String? findRequest;
  const FloorPlanA({super.key, this.findRequest});

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
          Text(
            'อาคาร A - ผังอาคาร',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 384,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: FloorPlanAPainter(findRequest: findRequest),
            ),
          ),
          if (findRequest != null && findRequest!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔍 กำลังค้นหา: $findRequest',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.yellow[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
