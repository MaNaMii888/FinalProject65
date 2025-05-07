import 'package:flutter/material.dart';

class PostActionButtons extends StatelessWidget {
  final VoidCallback? onLostPress;
  final VoidCallback? onFoundPress;

  const PostActionButtons({super.key, this.onLostPress, this.onFoundPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            onPressed: onLostPress,
            icon: Icons.help_outline,
            label: 'แจ้งของหาย',
            backgroundColor: Colors.amber[100],
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            onPressed: onFoundPress,
            icon: Icons.search,
            label: 'แจ้งเจอของ',
            backgroundColor: Colors.white,
            borderColor: Colors.amber[100],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    VoidCallback? onPressed,
    required IconData icon,
    required String label,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side:
              borderColor != null
                  ? BorderSide(color: borderColor)
                  : BorderSide.none,
        ),
        elevation: 2,
      ),
    );
  }
}
