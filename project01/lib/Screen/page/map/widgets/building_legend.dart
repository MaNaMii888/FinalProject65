import 'package:flutter/material.dart';

class BuildingLegend extends StatelessWidget {
  const BuildingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'คำอธิบายสี',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLegendItem(
            color: const Color(0xffe3f2fd),
            borderColor: const Color(0xff1976d2),
            label: 'ห้องปกติ',
            description: 'ไม่มีรายการของหาย/เจอของ',
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            color: Colors.red[100]!,
            borderColor: Colors.red[600]!,
            label: 'มีของหาย',
            description: 'มีรายการแจ้งของหาย',
            showCount: true,
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            color: Colors.green[100]!,
            borderColor: Colors.green[600]!,
            label: 'มีของเจอ',
            description: 'มีรายการแจ้งเจอของ',
            showCount: true,
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            color: Colors.orange[100]!,
            borderColor: Colors.orange[600]!,
            label: 'มีทั้งของหายและเจอ',
            description: 'มีทั้งรายการแจ้งของหายและเจอของ',
            showCount: true,
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            color: Colors.yellow[100]!,
            borderColor: Colors.yellow[400]!,
            label: 'ห้องที่ค้นหา',
            description: 'ห้องที่ตรงกับการค้นหา',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'คลิกที่ห้องเพื่อดูรายการของหาย/เจอของ',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required Color borderColor,
    required String label,
    required String description,
    bool showCount = false,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child:
              showCount
                  ? Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  )
                  : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
