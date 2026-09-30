// 앱 아이콘·스플래시 PNG를 lib/widgets/app_logo.dart 그림으로 만든다.
//
//   flutter test tool/generate_brand_assets_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
import 'dart:io';
import 'dart:ui' as ui;

import 'package:couple_calendar/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _render(
  String path,
  int size,
  void Function(Canvas canvas, Size size) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvasSize = Size.square(size.toDouble());
  paint(Canvas(recorder), canvasSize);
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('브랜드 이미지 생성', () async {
    const dir = 'assets/brand';

    // iOS·구형 안드로이드 아이콘: 모서리는 OS가 깎는다.
    await _render('$dir/icon.png', 1024, (c, s) {
      const AppLogoPainter(rounded: false).paint(c, s);
    });

    // 안드로이드 적응형 아이콘: 배경(그라데이션)과 전경(마크)을 나눈다.
    // 전경은 가운데 66% 안전 영역 안에 들어가야 잘리지 않는다.
    await _render('$dir/icon_background.png', 1024, (c, s) {
      c.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [BrandColors.gradientStart, BrandColors.gradientEnd],
          ).createShader(Offset.zero & s),
      );
    });
    await _render('$dir/icon_foreground.png', 1024, (c, s) {
      const AppLogoMarkPainter(scale: 0.4).paint(c, s);
    });

    // 스플래시 (안드로이드 11 이하, iOS): 둥근 로고. 4배율 기준 → 128dp.
    await _render('$dir/splash_logo.png', 512, (c, s) {
      const AppLogoPainter().paint(c, s);
    });

    // 스플래시 (안드로이드 12+): 288dp 원 안에서 가운데 2/3만 보인다.
    await _render('$dir/splash_android12.png', 1152, (c, s) {
      final logo = s.width * 0.5;
      c.translate((s.width - logo) / 2, (s.height - logo) / 2);
      const AppLogoPainter().paint(c, Size.square(logo));
    });
  });
}
