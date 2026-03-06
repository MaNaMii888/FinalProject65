import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:project01/services/qr_handover_service.dart';

class QRScannerPage extends StatefulWidget {
  final String currentUserId;

  const QRScannerPage({super.key, required this.currentUserId});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.contains(':')) {
        setState(() {
          _isProcessing = true;
        });

        _controller.stop();

        final success = await QRHandoverService().verifyAndCompleteHandover(
          code,
          widget.currentUserId,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ ยืนยันการรับของสำเร็จ!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // คืนค่า true ให้หน้าก่อนรู้ว่าสำเร็จ
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ QR Code ไม่ถูกต้อง หรือคุณไม่ใช่ผู้รับ'),
                backgroundColor: Colors.red,
              ),
            );

            // ให้โอกาสสแกนใหม่
            setState(() {
              _isProcessing = false;
            });
            _controller.start();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR รับของ'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.videocam_off, color: Colors.white, size: 60),
                      SizedBox(height: 16),
                      Text(
                        'ไม่สามารถใช้งานกล้องได้\nกรุณาอนุญาตสิทธิ์การเข้าถึงกล้องในการตั้งค่าของอุปกรณ์',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // สร้างกรอบสแกน
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'กำลังตรวจสอบข้อมูล...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'วาง QR Code ให้อยู่ในกรอบ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
