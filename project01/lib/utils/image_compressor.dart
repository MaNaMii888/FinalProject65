import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  /// Compresses an image file, reducing its file size while maintaining acceptable quality.
  /// Used before uploading to Firebase Storage to save bandwidth and costs.
  static Future<File?> compressImage(
    File file, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 80,
  }) async {
    try {
      if (!await file.exists()) {
        debugPrint('❌ ImageCompressor: Source file does not exist at ${file.path}');
        return null;
      }

      final String targetPath = await _getTargetPath(file);

      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            minWidth: minWidth,
            minHeight: minHeight,
            quality: quality,
            format: _getFormat(file.path),
          );

      if (compressedXFile == null) return null;

      final compressedFile = File(compressedXFile.path);
      if (!await compressedFile.exists()) return null;

      // Calculate sizes for debug purposes
      final originalSize = await file.length();
      final compressedSize = await compressedFile.length();
      debugPrint(
        '📸 Image Compression: ${(originalSize / 1024).toStringAsFixed(2)} KB -> ${(compressedSize / 1024).toStringAsFixed(2)} KB',
      );

      return compressedFile;
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      // Fallback to original if it exists
      if (await file.exists()) return file;
      return null;
    }
  }

  static Future<String> _getTargetPath(File file) async {
    final supportDir = await getApplicationSupportDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last.toLowerCase();

    // Output target must end with correct format
    String compressExt = extension;
    if (extension != 'jpg' &&
        extension != 'jpeg' &&
        extension != 'png' &&
        extension != 'webp') {
      compressExt = 'jpg'; // default to jpeg if unknown
    }

    return '${supportDir.path}/compressed_$timestamp.$compressExt';
  }

  static CompressFormat _getFormat(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return CompressFormat.png;
      case 'webp':
        return CompressFormat.webp;
      case 'heic':
        return CompressFormat.heic;
      case 'jpg':
      case 'jpeg':
      default:
        return CompressFormat.jpeg;
    }
  }
}
