import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 28.0,
    this.elevation = 8.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Wrap FAB in a SizedBox to control diameter. Use size as the icon size but derive
    // a circular button diameter from it (icon size + padding).
    final double diameter = size + 24; // 12px padding around icon
    return SizedBox(
      width: diameter,
      height: diameter,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
        elevation: elevation,
        child: Icon(icon, size: size),
      ),
    );
  }
}

// ปุ่มสำหรับเปลี่ยนไปหน้าอาคาร
class BuildingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final double elevation;

  const BuildingActionButton({
    super.key,
    required this.onPressed,
    this.size = 28.0,
    this.elevation = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      icon: Icons.apartment,
      onPressed: onPressed,
      size: size,
      elevation: elevation,
    );
  }
}

// ปุ่มสำหรับเปลี่ยนไปหน้าแผนที่
class MapActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final double elevation;

  const MapActionButton({
    super.key,
    required this.onPressed,
    this.size = 28.0,
    this.elevation = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      icon: Icons.map,
      onPressed: onPressed,
      size: size,
      elevation: elevation,
    );
  }
}
