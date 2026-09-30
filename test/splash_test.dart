import 'package:couple_calendar/screens/splash_screen.dart';
import 'package:couple_calendar/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('시작 애니메이션이 끝나면 앱 화면으로 넘어간다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashGate(child: Text('앱 화면'))),
    );

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('앱 화면'), findsNothing);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('둘만의 일정과 기념일을 함께'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('앱 화면'), findsOneWidget);
    expect(find.byType(AppLogo), findsNothing);
  });
}
