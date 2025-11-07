import 'dart:ui';
import 'package:flutter/material.dart';

class PostActionButton extends StatefulWidget {
  final VoidCallback? onLostPress;
  final VoidCallback? onFoundPress;

  const PostActionButton({super.key, this.onLostPress, this.onFoundPress});

  @override
  State<PostActionButton> createState() => _PostActionButtonState();
}

class _PostActionButtonState extends State<PostActionButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.125, // 45 degrees
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ Overlay เบลอ + มืด เต็มจอ
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpanded, // แตะ overlay เพื่อปิด
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: Colors.black.withOpacity(0)),
              ),
            ),
          ),

        // ✅ ปุ่มทั้งหมด (ชิดขวาล่าง)
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // แจ้งของหาย button
                AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _expandAnimation.value,
                      child: Opacity(
                        opacity: _expandAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: FloatingActionButton.extended(
                            onPressed:
                                _isExpanded
                                    ? () {
                                      widget.onLostPress?.call();
                                      _toggleExpanded();
                                    }
                                    : null,
                            heroTag: "lost_btn",
                            backgroundColor:
                                Theme.of(context).colorScheme.onSecondary,
                            label: const Text(
                              'แจ้งของหาย',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            icon: const Icon(Icons.help_outline),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // แจ้งพบของหาย button
                AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _expandAnimation.value,
                      child: Opacity(
                        opacity: _expandAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: FloatingActionButton.extended(
                            onPressed:
                                _isExpanded
                                    ? () {
                                      widget.onFoundPress?.call();
                                      _toggleExpanded();
                                    }
                                    : null,
                            heroTag: "found_btn",
                            backgroundColor:
                                Theme.of(context).colorScheme.onSecondary,
                            label: const Text(
                              'แจ้งพบของหาย',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            icon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Main toggle button
                AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnimation.value * 2 * 3.14159,
                      child: FloatingActionButton(
                        onPressed: _toggleExpanded,
                        heroTag: "main_btn",
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const CircleBorder(),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child:
                              _isExpanded
                                  ? const Icon(
                                    Icons.close,
                                    key: ValueKey('close'),
                                  )
                                  : const Icon(Icons.add, key: ValueKey('add')),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
