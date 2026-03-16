import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:project01/widgets/branded_loading.dart';

/// A wrapper for CachedNetworkImage that handles "Self-Healing" by fetching
/// a fresh download URL from Firebase Storage if the initial load fails (e.g. 412 error).
class SmartNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorPlaceholder;

  const SmartNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorPlaceholder,
  });

  @override
  State<SmartNetworkImage> createState() => _SmartNetworkImageState();
}

class _SmartNetworkImageState extends State<SmartNetworkImage> {
  String? _freshUrl;
  bool _useFallback = false;
  bool _isRefetching = false;
  bool _finalFailure = false;

  Future<void> _refetchUrl() async {
    if (_isRefetching || widget.imageUrl.isEmpty) return;
    
    setState(() {
      _isRefetching = true;
      _finalFailure = false;
    });

    try {
      // Check if it's a Firebase Storage URL
      if (widget.imageUrl.contains('firebasestorage.googleapis.com')) {
        // "โหลดจากฐานข้อมูล" - ดึง URL ใหม่จาก Storage โดยตรง
        Reference? ref;
        try {
          ref = FirebaseStorage.instance.refFromURL(widget.imageUrl);
        } catch (e) {
          debugPrint('SmartNetworkImage: refFromURL failed, trying manual parse: $e');
          // Fallback: Parse path manually from URL
          // Format: .../o/images%2F...%2Ffilename?alt=media...
          final uri = Uri.parse(widget.imageUrl);
          final pathSegment = uri.pathSegments.last; // This is the escaped path
          final decodedPath = Uri.decodeFull(pathSegment);
          ref = FirebaseStorage.instance.ref().child(decodedPath);
        }

        if (ref != null) {
          final freshUrl = await ref.getDownloadURL();
          if (mounted) {
            setState(() {
              _freshUrl = freshUrl;
              _useFallback = true;
              _isRefetching = false;
            });
          }
        }
      } else {
         // Not a Firebase URL, just fallback to standard Image.network
         if (mounted) {
           setState(() {
              _useFallback = true;
              _isRefetching = false;
            });
         }
      }
    } catch (e) {
      debugPrint('SmartNetworkImage: Failed to refetch fresh URL: $e');
      if (mounted) {
        setState(() {
          _isRefetching = false;
          _finalFailure = true; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) return _errorWidget();

    // หากรีเฟรชแล้วยังเสีย หรือไม่ใช่ Firebase URL ตั้งแต่แรก
    if (_finalFailure) return _errorWidget();

    if (_useFallback) {
      return Image.network(
        _freshUrl ?? widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingWidget();
        },
        errorBuilder: (context, error, stackTrace) => _errorWidget(),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => _loadingWidget(),
      errorWidget: (context, url, error) {
        // เมื่อเกิด Error (เช่น 412 หลังจากล้างแคช) 
        // ให้ลองดึง "Download URL" ใหม่จาก Firebase (Load from DB)
        // ✅ ป้องกัน setState() during build โดยใช้ addPostFrameCallback
        if (!_isRefetching && !_finalFailure) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _refetchUrl();
          });
        }
        return _loadingWidget(); // แสดง Loading ระหว่างลองดึงใหม่
      },
    );
  }

  Widget _loadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[900]?.withOpacity(0.1),
      child: const Center(child: BrandedLoading(size: 24)),
    );
  }

  Widget _errorWidget() {
    if (widget.errorPlaceholder != null) return widget.errorPlaceholder!;
    
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[900]?.withOpacity(0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, 
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'โหลดรูปไม่สำเร็จ',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _refetchUrl,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('ลองใหม่', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          )
        ],
      ),
    );
  }
}
