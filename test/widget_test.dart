import 'package:couple_calendar/data/event_repository.dart';
import 'package:couple_calendar/models/couple_profile.dart';
import 'package:couple_calendar/models/event.dart';
import 'package:couple_calendar/screens/calendar_screen.dart';
import 'package:couple_calendar/theme/app_theme.dart';
import 'package:couple_calendar/widgets/month_calendar_card.dart';
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

  testWidgets('왼쪽으로 밀어 삭제하면 확인 후 사라진다', (tester) async {
    await _pumpCalendar(tester);

    await tester.ensureVisible(find.text('저녁 데이트'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('저녁 데이트'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('일정을 삭제하시겠습니까?'), findsOneWidget);

    // 취소하면 그대로 남는다.
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('저녁 데이트'), findsOneWidget);

    await tester.ensureVisible(find.text('저녁 데이트'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('저녁 데이트'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();

    expect(find.text('저녁 데이트'), findsNothing);
    expect(find.text('1개의 일정'), findsOneWidget);
  });

  testWidgets('왼쪽으로 밀어 수정하면 기존 내용이 채워진 시트에서 고칠 수 있다', (tester) async {
    await _pumpCalendar(tester);

    await tester.ensureVisible(find.text('저녁 데이트'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('저녁 데이트'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();

    expect(find.text('일정 수정'), findsOneWidget);
    expect(find.widgetWithText(TextField, '저녁 데이트'), findsOneWidget);
    expect(find.widgetWithText(TextField, '성수동 파스타바'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '저녁 데이트 🍷');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('저녁 데이트 🍷'), findsOneWidget);
    expect(find.text('성수동 파스타바'), findsOneWidget);
    expect(find.text('2개의 일정'), findsOneWidget);
  });

  testWidgets('일정이 있는 날짜를 누르면 일정 목록까지 내려가고, 없는 날은 그대로다', (tester) async {
    await initializeDateFormatting('ko_KR');
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 같은 달 안에서 오늘이 아닌 날 두 개.
    final withEvent = today.day <= 14 ? today.day + 7 : today.day - 7;
    final empty = today.day <= 14 ? today.day + 8 : today.day - 8;
    final repository = EventRepository.memory([
      Event(
        id: 'x',
        title: '전시회',
        date: DateTime(now.year, now.month, withEvent),
        owner: EventOwner.together,
      ),
    ]);
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CalendarScreen(repository: repository),
      ),
    );

    double offset() => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    Finder dayCell(int day) => find.descendant(
      of: find.byType(MonthCalendarCard),
      matching: find.text('$day'),
    );

    await tester.tap(dayCell(empty).first);
    await tester.pumpAndSettle();
    expect(offset(), 0);

    await tester.tap(dayCell(withEvent).first);
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(0));
    expect(find.text('전시회'), findsOneWidget);
  });

  testWidgets('상대가 등록한 상대 일정은 밀어도 수정·삭제가 나오지 않는다', (tester) async {
    await initializeDateFormatting('ko_KR');
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final repository = EventRepository.memory([
      Event(
        id: 'p',
        title: '서연 필라테스',
        date: today,
        owner: EventOwner.partner,
        createdByMe: false,
      ),
      Event(
        id: 't',
        title: '서연이 만든 데이트',
        date: today,
        owner: EventOwner.together,
        createdByMe: false,
      ),
    ]);
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CalendarScreen(repository: repository),
      ),
    );

    Future<void> swipe(String title) async {
      await tester.ensureVisible(find.text(title));
      await tester.pumpAndSettle();
      await tester.drag(find.text(title), const Offset(-300, 0));
      await tester.pumpAndSettle();
    }

    await swipe('서연 필라테스');
    expect(find.text('삭제'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    // "우리 함께" 일정은 상대가 만들었어도 고칠 수 있다.
    await swipe('서연이 만든 데이트');
    expect(find.text('삭제'), findsOneWidget);
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
