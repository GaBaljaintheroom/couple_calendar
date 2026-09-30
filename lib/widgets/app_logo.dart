import 'package:flutter/material.dart';

/// 앱 로고: 코랄 그라데이션 위에 하트가 담긴 캘린더.
///
/// 앱 아이콘·스플래시 PNG(tool/generate_brand_assets_test.dart)와 앱 안의 스플래시가
/// 모두 이 그림을 쓴다.
abstract final class BrandColors {
  static const gradientStart = Color(0xFFF2937A);
  static const gradientEnd = Color(0xFFD9654A);
  static const ring = Color(0xFF9A442D);
  static const pageHeader = Color(0xFFFFE1D8);
  static const heartStart = Color(0xFFF08A70);
  static const heartEnd = Color(0xFFD9573F);
  static const splashBackground = Color(0xFFFFF8F6);
}

/// 둥근 사각형 배경까지 포함한 로고.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.rounded = true});

  final double size;

  /// false면 모서리를 깎지 않는다 (iOS 아이콘은 OS가 알아서 깎는다).
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: AppLogoPainter(rounded: rounded)),
    );
  }
}

/// 배경 + 캘린더 마크.
class AppLogoPainter extends CustomPainter {
  const AppLogoPainter({this.rounded = true, this.background = true});

  final bool rounded;

  /// false면 배경 없이 마크만 그린다 (안드로이드 적응형 아이콘 전경, 스플래시).
  final bool background;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & Size.square(s);

    if (background) {
      final radius = rounded ? Radius.circular(s * 0.23) : Radius.zero;
      final bg = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(
        bg,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BrandColors.gradientStart, BrandColors.gradientEnd],
          ).createShader(rect),
      );
      // 왼쪽 위의 은은한 빛
      canvas.save();
      canvas.clipRRect(bg);
      canvas.drawCircle(
        Offset(s * 0.18, s * 0.12),
        s * 0.55,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(s * 0.18, s * 0.12),
                  radius: s * 0.55,
                ),
              ),
      );
      canvas.restore();
    }

    paintMark(canvas, rect.center, s * 0.62);
  }

  /// 캘린더 마크를 [center]를 중심으로 [width] 크기에 그린다.
  static void paintMark(Canvas canvas, Offset center, double width) {
    final w = width;
    final h = w * 0.9;
    final page = Rect.fromCenter(
      center: center + Offset(0, w * 0.04),
      width: w,
      height: h,
    );
    final pageRRect = RRect.fromRectAndRadius(page, Radius.circular(w * 0.2));

    // 종이 그림자
    canvas.drawRRect(
      pageRRect.shift(Offset(0, w * 0.035)),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
    );
    canvas.drawRRect(pageRRect, Paint()..color = Colors.white);

    // 상단 머리띠
    canvas.save();
    canvas.clipRRect(pageRRect);
    canvas.drawRect(
      Rect.fromLTWH(page.left, page.top, page.width, h * 0.26),
      Paint()..color = BrandColors.pageHeader,
    );
    canvas.restore();

    // 고리 두 개
    final ringPaint = Paint()..color = BrandColors.ring;
    for (final dx in [-0.24, 0.24]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + w * dx, page.top),
            width: w * 0.1,
            height: w * 0.24,
          ),
          Radius.circular(w * 0.05),
        ),
        ringPaint,
      );
    }

    // 하트
    final heartCenter = Offset(center.dx, page.top + h * 0.61);
    final heart = heartPath(heartCenter, w * 0.46);
    canvas.drawPath(
      heart,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [BrandColors.heartStart, BrandColors.heartEnd],
        ).createShader(heart.getBounds()),
    );
  }

  /// 가로 폭이 [width]인 하트. [center]는 하트 외곽 사각형의 중심.
  static Path heartPath(Offset center, double width) {
    final w = width;
    final h = w * 0.9;
    final l = center.dx - w / 2;
    final t = center.dy - h / 2;
    Offset p(double x, double y) => Offset(l + w * x, t + h * y);
    return Path()
      ..moveTo(p(0.5, 1).dx, p(0.5, 1).dy)
      ..cubicTo(
        p(0.12, 0.72).dx,
        p(0.12, 0.72).dy,
        p(0, 0.5).dx,
        p(0, 0.5).dy,
        p(0, 0.3).dx,
        p(0, 0.3).dy,
      )
      ..cubicTo(
        p(0, 0.1).dx,
        p(0, 0.1).dy,
        p(0.15, 0).dx,
        p(0.15, 0).dy,
        p(0.28, 0).dx,
        p(0.28, 0).dy,
      )
      ..cubicTo(
        p(0.4, 0).dx,
        p(0.4, 0).dy,
        p(0.47, 0.07).dx,
        p(0.47, 0.07).dy,
        p(0.5, 0.16).dx,
        p(0.5, 0.16).dy,
      )
      ..cubicTo(
        p(0.53, 0.07).dx,
        p(0.53, 0.07).dy,
        p(0.6, 0).dx,
        p(0.6, 0).dy,
        p(0.72, 0).dx,
        p(0.72, 0).dy,
      )
      ..cubicTo(
        p(0.85, 0).dx,
        p(0.85, 0).dy,
        p(1, 0.1).dx,
        p(1, 0.1).dy,
        p(1, 0.3).dx,
        p(1, 0.3).dy,
      )
      ..cubicTo(
        p(1, 0.5).dx,
        p(1, 0.5).dy,
        p(0.88, 0.72).dx,
        p(0.88, 0.72).dy,
        p(0.5, 1).dx,
        p(0.5, 1).dy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(AppLogoPainter oldDelegate) =>
      rounded != oldDelegate.rounded || background != oldDelegate.background;
}

/// 배경 없이 마크만 (투명 배경).
class AppLogoMarkPainter extends CustomPainter {
  const AppLogoMarkPainter({this.scale = 0.62});

  /// 캔버스 대비 마크 폭.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    AppLogoPainter.paintMark(canvas, Offset(s / 2, s / 2), s * scale);
  }

  @override
  bool shouldRepaint(AppLogoMarkPainter oldDelegate) =>
      scale != oldDelegate.scale;
}
