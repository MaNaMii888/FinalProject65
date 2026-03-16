import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:project01/services/qr_handover_service.dart';
import 'package:project01/widgets/branded_loading.dart';

class QRHandoverDialog extends StatefulWidget {
  final String postId;
  final String senderId;
  final String receiverId;
  final String chatId;

  const QRHandoverDialog({
    super.key,
    required this.postId,
    required this.senderId,
    required this.receiverId,
    required this.chatId,
  });

  @override
  State<QRHandoverDialog> createState() => _QRHandoverDialogState();
}

class _QRHandoverDialogState extends State<QRHandoverDialog> {
  String? _qrData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  Future<void> _generateQR() async {
    try {
      final qrData = await QRHandoverService().createHandoverTransaction(
        widget.postId,
        widget.senderId,
        widget.receiverId,
        widget.chatId,
      );
      if (mounted) {
        setState(() {
          _qrData = qrData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'ไม่สามารถสร้าง QR Code ได้: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'QR Code สำหรับรับของ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const BrandedLoading(size: 40)
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_qrData != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'ให้ผู้รับสแกน QR Code นี้เพื่อยืนยันการรับของ\nเมื่อสแกนเสร็จสถานะโพสต์จะเปลี่ยนเป็นส่งมอบสำเร็จ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
              ),
              child: const Text('ปิด'),
            ),
          ],
        ),
      ),
    );
  }
}
