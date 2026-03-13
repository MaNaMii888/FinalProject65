import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// แสดงโลโก้แอปที่เป็น "แว่นขยาย วงไม่ครบ" — สื่อถึงสิ่งที่ขาดหายไป
class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({super.key, this.size = 120, this.color});

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(color: logoColor)),
    );
  }
}

/// Widget โลโก้ที่มีสีไล่ระดับ (Gradient) — สำหรับหน้า Splash / Landing
class AppLogoGradient extends StatelessWidget {
  final double size;

  const AppLogoGradient({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(
          color: colorScheme.primary,
          useGradient: true,
          gradientColors: [colorScheme.primary, colorScheme.secondary],
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  final bool useGradient;
  final List<Color>? gradientColors;

  _LogoPainter({
    required this.color,
    this.useGradient = false,
    this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ---- ขนาด ----
    final sw = w * 0.13; // stroke width
    final circleR = w * 0.29; // รัศมีกลางเส้นวง
    final ha = pi * 0.28; // ทิศด้าม (ลงขวา ~50°)
    final handleLen = w * 0.36; // ความยาวด้าม
    final dotR = w * 0.055; // รัศมีจุดปลาย

    // ---- จัดให้อยู่กึ่งกลาง ----
    final outerR = circleR + sw / 2;
    final ext = circleR + handleLen + dotR;
    final rightOf = ext * cos(ha) + sw / 2;
    final botOf = ext * sin(ha) + sw / 2;
    final cx = w * 0.5 - (rightOf - outerR) / 2;
    final cy = h * 0.5 - (botOf - outerR) / 2;

    // ---- Shader หลัก ----
    final p1 = Offset(cx - circleR, cy - circleR);
    final p2 = Offset(
      cx + (circleR + handleLen) * cos(ha),
      cy + (circleR + handleLen) * sin(ha),
    );
    ui.Shader makeShader() {
      if (useGradient && gradientColors != null) {
        return ui.Gradient.linear(p1, p2, gradientColors!);
      }
      return ui.Gradient.linear(p1, p2, [color, color]);
    }

    final mainPaint =
        Paint()
          ..shader = makeShader()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    // ============================================================
    // 1. วงแว่น — arc ไม่ครบวง (open ring / Q-shape)
    //    - arcEnd = ha  → ซ่อนอยู่ใต้ด้าม (ไม่มี blob ฝั่งซ้าย)
    //    - arcStart = ha + openGap → ปลายเปิด (visible gap) ฝั่งขวาด้าม
    // ============================================================
    final openGap  = pi * 0.26;        // ช่องว่างที่มองเห็น ~47°
    final arcStart = ha + openGap;     // เริ่มหลัง gap
    final arcSweep = 2 * pi - openGap; // วนส่วนใหญ่ จบที่ ha (ใต้ด้าม)

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: circleR),
      arcStart,
      arcSweep,
      false,
      mainPaint,
    );

    // ============================================================
    // 2. ไฮไลต์ในเลนส์ — arc จางๆ ให้ความรู้สึกกระจก
    //    วางใกล้ arcStart (ส่วน 12 o'clock ที่วงปิดแล้ว)
    // ============================================================
    final innerR = circleR - sw * 0.52;
    // ไฮไลต์ fixed ที่ upper-right (12→2 o'clock area = ~279°–369°)
    const hlStart = pi * 1.55;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
      hlStart,
      pi * 0.55,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 0.30
        ..strokeCap = StrokeCap.round,
    );

    // ============================================================
    // 3. ด้ามแว่น — เส้นทแยงลงขวา
    // ============================================================
    final hx0 = cx + circleR * cos(ha);
    final hy0 = cy + circleR * sin(ha);
    final hx1 = hx0 + (handleLen - dotR) * cos(ha);
    final hy1 = hy0 + (handleLen - dotR) * sin(ha);

    canvas.drawLine(Offset(hx0, hy0), Offset(hx1, hy1), mainPaint);

    // ============================================================
    // 4. จุดกลมปลายด้าม (Dot)
    // ============================================================
    final tipX = hx0 + handleLen * cos(ha);
    final tipY = hy0 + handleLen * sin(ha);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    if (useGradient && gradientColors != null) {
      dotPaint.shader = ui.Gradient.radial(
        Offset(tipX, tipY),
        dotR,
        gradientColors!,
      );
    } else {
      dotPaint.color = color;
    }
    canvas.drawCircle(Offset(tipX, tipY), dotR, dotPaint);

    // ไฮไลต์จุดจางๆ
    canvas.drawCircle(
      Offset(tipX - dotR * 0.28, tipY - dotR * 0.28),
      dotR * 0.30,
      Paint()..color = Colors.white.withOpacity(0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.color != color || old.useGradient != useGradient;
}
