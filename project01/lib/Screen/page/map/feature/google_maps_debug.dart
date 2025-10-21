import 'package:flutter/material.dart';

// Widget แสดงข้อมูล debug สำหรับ Google Maps
class GoogleMapsDebugWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onUseFallback;

  const GoogleMapsDebugWidget({super.key, this.onRetry, this.onUseFallback});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              const Text(
                'Google Maps Debug',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'API Key: AIzaSyB3fq8yyrO0n346CIDdgXeg60WVTZ1Yhn0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'หากแผนที่ไม่แสดง:\n1. ตรวจสอบว่าเปิด Maps SDK for Android\n2. รัน flutter clean && flutter pub get\n3. Rebuild แอป',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองโหลด Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onUseFallback,
                child: const Text(
                  'ใช้แผนผังอาคารแทน (ระบบเดิม)',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
