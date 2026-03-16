import 'dart:math';
import 'package:flutter/material.dart';

/// หน้าจอโหลดแบบมีแบรนด์ที่โลโก้จะค่อยๆ เติมสีตามเส้น
class BrandedLoading extends StatefulWidget {
  final double size;
  final bool fullScreen;
  final Color? color;
  final Color? baseColor;

  const BrandedLoading({
    super.key,
    this.size = 100,
    this.fullScreen = false,
    this.color,
    this.baseColor,
  });

  @override
  State<BrandedLoading> createState() => _BrandedLoadingState();
}

class _BrandedLoadingState extends State<BrandedLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Widget content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AnimatedLogoPainter(
            progress: _controller.value,
            baseColor: widget.baseColor ?? Colors.grey.withOpacity(0.2),
            activeColor: widget.color ?? colorScheme.primary,
            secondaryColor: colorScheme.secondary,
          ),
        );
      },
    );

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}

class _AnimatedLogoPainter extends CustomPainter {
  final double progress; 
  final Color baseColor;
  final Color activeColor;
  final Color secondaryColor;

  _AnimatedLogoPainter({
    required this.progress,
    required this.baseColor,
    required this.activeColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ---- ขนาด (Copy logic มาจาก AppLogo เพื่อความแม่นยำ) ----
    final sw = w * 0.13; // stroke width
    final circleR = w * 0.29; 
    final ha = pi * 0.28; 
    final handleLen = w * 0.36; 
    final dotR = w * 0.055; 

    // ---- จัดกึ่งกลาง ----
    final outerR = circleR + sw / 2;
    final ext = circleR + handleLen + dotR;
    final rightOf = ext * cos(ha) + sw / 2;
    final botOf = ext * sin(ha) + sw / 2;
    final cx = w * 0.5 - (rightOf - outerR) / 2;
    final cy = h * 0.5 - (botOf - outerR) / 2;

    final bgPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    // 1. วาดโครงร่างพื้นหลัง
    _drawLogoStructure(canvas, cx, cy, circleR, ha, handleLen, dotR, bgPaint, drawDot: true);

    // 2. Flow Logic
    // Phase 1: หัวแว่นขยาย (0.0 - 0.7)
    final ringProgress = (progress / 0.7).clamp(0.0, 1.0);
    final openGap = pi * 0.26;
    final arcStart = ha + openGap;
    final totalArcSweep = 2 * pi - openGap;
    
    if (ringProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: circleR),
        arcStart,
        totalArcSweep * ringProgress,
        false,
        activePaint,
      );
    }

    // Phase 2: ด้ามจับ (0.7 - 0.9)
    if (progress > 0.7) {
      final handleProgress = ((progress - 0.7) / 0.2).clamp(0.0, 1.0);
      final hx0 = cx + circleR * cos(ha);
      final hy0 = cy + circleR * sin(ha);
      final fullHandleLen = handleLen - dotR;
      final hx1 = hx0 + (fullHandleLen * handleProgress) * cos(ha);
      final hy1 = hy0 + (fullHandleLen * handleProgress) * sin(ha);

      canvas.drawLine(Offset(hx0, hy0), Offset(hx1, hy1), activePaint);
    }

    // Phase 3: จุดปลายด้าม (0.9 - 1.0)
    if (progress > 0.9) {
      final dotProgress = ((progress - 0.9) / 0.1).clamp(0.0, 1.0);
      final tipX = cx + (circleR + handleLen) * cos(ha);
      final tipY = cy + (circleR + handleLen) * sin(ha);
      
      final dotPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(tipX, tipY), dotR * dotProgress, dotPaint);
    }
  }

  void _drawLogoStructure(Canvas canvas, double cx, double cy, double circleR, double ha, double handleLen, double dotR, Paint paint, {bool drawDot = false}) {
    final openGap = pi * 0.26;
    final arcStart = ha + openGap;
    final arcSweep = 2 * pi - openGap;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: circleR),
      arcStart,
      arcSweep,
      false,
      paint,
    );

    final hx0 = cx + circleR * cos(ha);
    final hy0 = cy + circleR * sin(ha);
    final hx1 = hx0 + (handleLen - dotR) * cos(ha);
    final hy1 = hy0 + (handleLen - dotR) * sin(ha);
    canvas.drawLine(Offset(hx0, hy0), Offset(hx1, hy1), paint);

    if (drawDot) {
      final tipX = cx + (circleR + handleLen) * cos(ha);
      final tipY = cy + (circleR + handleLen) * sin(ha);
      final fillPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), dotR, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedLogoPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.activeColor != activeColor;
}
