import 'package:flutter/material.dart';
import 'package:project01/widgets/branded_loading.dart';

class LoadingOverlay {
  static OverlayEntry? _overlay;

  static void show(BuildContext context) {
    if (_overlay != null) return;

    _overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Background Dim
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.5),
          ),
          // Logo in Center
          const Center(
            child: BrandedLoading(size: 150),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  static void hide() {
    if (_overlay != null) {
      _overlay!.remove();
      _overlay = null;
    }
  }
}
