import 'package:couple_calendar/models/couple_profile.dart';
import 'package:couple_calendar/screens/calendar_screen.dart';
import 'package:couple_calendar/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> _pumpCalendar(WidgetTester tester) async {
  await initializeDateFormatting('ko_KR');
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: CalendarScreen()),
  );
}

void main() {
  testWidgets('캘린더 화면에 오늘의 더미 일정이 보인다', (tester) async {
    await _pumpCalendar(tester);

    expect(find.text('캘린더'), findsOneWidget);
    expect(find.text('세차 및 차량점검'), findsOneWidget);
    expect(find.text('저녁 데이트'), findsOneWidget);
    expect(find.text('2개의 일정'), findsOneWidget);
  });

  testWidgets('필터 칩으로 한 사람의 일정만 볼 수 있다', (tester) async {
    await _pumpCalendar(tester);

    await tester.tap(find.text('민준').first);
    await tester.pumpAndSettle();

    expect(find.text('세차 및 차량점검'), findsOneWidget);
    expect(find.text('저녁 데이트'), findsNothing);
  });

  testWidgets('일정 추가 시트로 일정을 추가할 수 있다', (tester) async {
    await _pumpCalendar(tester);

    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '카페 가기');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('카페 가기'), findsOneWidget);
    expect(find.text('3개의 일정'), findsOneWidget);
  });

  testWidgets('카테고리·챙길 것·메모를 넣어 일정을 등록할 수 있다', (tester) async {
    await _pumpCalendar(tester);

    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    // 제목이 비어 있으면 등록 버튼이 비활성화된다.
    final submit = find.widgetWithText(FilledButton, '우리 일정 등록하기');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '한강 피크닉');
    await tester.tap(find.text('여행'));
    await tester.ensureVisible(find.text('+ 직접 입력'));
    await tester.tap(find.text('+ 직접 입력'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, '챙길 것 입력'), '돗자리');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, '둘만의 소소한 약속이나 메모를 남겨보세요.'),
      '2시 전 도착',
    );
    await tester.pump();

    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('한강 피크닉'), findsOneWidget);
    expect(find.text('🚗'), findsOneWidget);
    expect(find.text('2시 전 도착'), findsOneWidget);
    expect(find.text('챙길 것 1개 · 돗자리'), findsOneWidget);
  });

  group('CoupleProfile', () {
    final profile = CoupleProfile(
      myName: '나',
      partnerName: '너',
      startDate: DateTime(2024, 1, 1),
    );

    test('시작일이 D+1이다', () {
      expect(profile.dayCountOn(DateTime(2024, 1, 1)), 1);
      expect(profile.dayCountOn(DateTime(2024, 4, 9)), 100);
    });

    test('다음 100일 단위 기념일을 계산한다', () {
      expect(profile.nextHundredDayMilestone(DateTime(2024, 1, 1)), 100);
      expect(profile.nextHundredDayMilestone(DateTime(2024, 4, 9)), 200);
      expect(profile.dateOfDay(100), DateTime(2024, 4, 9));
    });
  });
}
