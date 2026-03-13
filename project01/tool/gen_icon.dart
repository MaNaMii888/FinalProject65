// tool/gen_icon.dart
// รัน: dart run tool/gen_icon.dart
// สร้างไฟล์ assets/img/app_icon.png (1024×1024)
// ใช้พารามิเตอร์และสี gradient เดียวกับ AppLogoGradient ใน app_logo.dart

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // พื้นหลังสีเข้ม (เหมือน splash screen)
  img.fill(image, color: img.ColorRgb8(0x1A, 0x1A, 0x1A));

  // ---- ขนาดของโลโก้ (ย่อลงให้มีขอบว่าง ไม่ชิดขอบไอคอนเกินไป) ----
  // ถ้าวาดเต็ม 1024 จะโดนตัดบน Android/iOS
  final w = size * 0.65; // ย่อโลโก้เหลือ 65% ของพื้นที่

  // ---- ขนาด (เหมือน _LogoPainter) ----
  final sw        = w * 0.13;
  final circleR   = w * 0.29;
  final ha        = pi * 0.28;
  final handleLen = w * 0.36;
  final dotR      = w * 0.055;

  // ---- จัดให้อยู่กึ่งกลาง canvas 1024x1024 ----
  final outerR  = circleR + sw / 2;
  final ext     = circleR + handleLen + dotR;
  final rightOf = ext * cos(ha) + sw / 2;
  final botOf   = ext * sin(ha) + sw / 2;
  
  // ซ้าย - ขวา ของตัว icon ให้ศูนย์กลางอยู่ที่กลาง canvas (size/2)
  final cx      = (size / 2) - (rightOf - outerR) / 2;
  final cy      = (size / 2) - (botOf   - outerR) / 2;

  // ---- สี: ตรงกับ AppLogoGradient (primary→secondary ของแอป) ----
  // primary  = #444444 (เทาเข้ม)
  // secondary = #DA0037 (แดงสด)
  final colorA = img.ColorRgb8(0x44, 0x44, 0x44); // top-left (เทา)
  final colorB = img.ColorRgb8(0xDA, 0x00, 0x37); // bottom-right (แดง)

  final halfSw = (sw / 2).round();

  // helper: gradient linear จาก p1(top-left ของ logo) → p2(bottom-right)
  // ตรงกับ p1 = Offset(cx-circleR, cy-circleR), p2 = Offset(cx+handleLen*cos, cy+handleLen*sin)
  final gx0 = cx - circleR;
  final gy0 = cy - circleR;
  final gx1 = cx + (circleR + handleLen) * cos(ha);
  final gy1 = cy + (circleR + handleLen) * sin(ha);
  final gLen = sqrt(pow(gx1 - gx0, 2) + pow(gy1 - gy0, 2));

  img.Color gradientAt(double x, double y) {
    // project (x,y) onto gradient vector → t in [0,1]
    final t = (((x - gx0) * (gx1 - gx0) + (y - gy0) * (gy1 - gy0)) / (gLen * gLen))
        .clamp(0.0, 1.0);
    return img.ColorRgb8(
      (colorA.r + (colorB.r - colorA.r) * t).round().clamp(0, 255),
      (colorA.g + (colorB.g - colorA.g) * t).round().clamp(0, 255),
      (colorA.b + (colorB.b - colorA.b) * t).round().clamp(0, 255),
    );
  }

  // วาดจุดหนาๆ ตาม path
  void plotArc(double r, double startAngle, double sweep, int steps) {
    for (int i = 0; i <= steps; i++) {
      final angle = startAngle + sweep * i / steps;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      img.fillCircle(image,
          x: x.round(), y: y.round(), radius: halfSw, color: gradientAt(x, y));
    }
  }

  void plotLine(double x0, double y0, double x1, double y1, int steps) {
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = x0 + (x1 - x0) * t;
      final y = y0 + (y1 - y0) * t;
      img.fillCircle(image,
          x: x.round(), y: y.round(), radius: halfSw, color: gradientAt(x, y));
    }
  }

  // ============================================================
  // 1. วงแว่น (open ring arc) — gap ใกล้ด้าม
  // ============================================================
  final arcStart = ha + pi * 0.26;
  final arcSweep = 2 * pi - pi * 0.26;
  plotArc(circleR, arcStart, arcSweep, 700);

  // ============================================================
  // 2. ไฮไลต์วงในเลนส์ (white arc จางๆ — upper-right)
  // ============================================================
  final hlR = circleR - sw * 0.52;
  final hlHalfSw = (sw * 0.15).round();
  for (int i = 0; i <= 120; i++) {
    final angle = pi * 1.55 + pi * 0.55 * i / 120;
    final x = cx + hlR * cos(angle);
    final y = cy + hlR * sin(angle);
    img.fillCircle(image,
        x: x.round(), y: y.round(), radius: hlHalfSw,
        color: img.ColorRgba8(255, 255, 255, 76));
  }

  // ============================================================
  // 3. ด้ามแว่น
  // ============================================================
  final hx0 = cx + circleR * cos(ha);
  final hy0 = cy + circleR * sin(ha);
  final hx1 = hx0 + (handleLen - dotR) * cos(ha);
  final hy1 = hy0 + (handleLen - dotR) * sin(ha);
  plotLine(hx0, hy0, hx1, hy1, 350);

  // ============================================================
  // 4. จุดปลายด้าม
  // ============================================================
  final tipX = hx0 + handleLen * cos(ha);
  final tipY = hy0 + handleLen * sin(ha);
  img.fillCircle(image,
      x: tipX.round(), y: tipY.round(), radius: dotR.round(),
      color: gradientAt(tipX, tipY));
  // highlight บนจุด
  img.fillCircle(image,
      x: (tipX - dotR * 0.28).round(), y: (tipY - dotR * 0.28).round(),
      radius: (dotR * 0.30).round(),
      color: img.ColorRgba8(255, 255, 255, 120));

  // ---- บันทึกไฟล์ ----
  final outputFile = File('assets/img/app_icon.png');
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsBytesSync(img.encodePng(image));
  print('✅ Icon saved: ${outputFile.absolute.path}');
  print('   Size: ${(outputFile.lengthSync() / 1024).toStringAsFixed(1)} KB  (${size}x${size}px)');
}
