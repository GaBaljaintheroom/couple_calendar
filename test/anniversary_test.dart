import 'package:couple_calendar/models/anniversary.dart';
import 'package:couple_calendar/models/couple_profile.dart';
import 'package:couple_calendar/models/event.dart';
import 'package:couple_calendar/screens/anniversary_screen.dart';
import 'package:couple_calendar/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// 세로 피드 스크롤 (필터 칩의 가로 스크롤과 구분).
final _feed = find.byType(Scrollable).first;

void main() {
  group('upcomingAnniversaries', () {
    final profile = CoupleProfile(
      myName: '나',
      partnerName: '너',
      startDate: DateTime(2024, 1, 1),
      myBirthday: DateTime(1990, 3, 10),
      partnerBirthday: DateTime(1991, 1, 5),
    );

    final result = upcomingAnniversaries(
      profile: profile,
      today: DateTime(2024, 12, 1),
      customs: [
        CustomAnniversary(
          id: 'xmas',
          title: '첫 크리스마스',
          date: DateTime(2023, 12, 25),
        ),
        CustomAnniversary(
          id: 'past',
          title: '지난 일회성',
          date: DateTime(2024, 6, 1),
          repeatsYearly: false,
        ),
      ],
    );

    test('1년 안의 100일 단위·주년·생일·직접 등록 기념일을 날짜순으로 모은다', () {
      expect(result.map((a) => a.title), [
        '첫 크리스마스', // 2024-12-25
        '1주년 기념일', // 2025-01-01
        '너 생일', // 2025-01-05
        '400일 기념일', // 2025-02-03
        '나 생일', // 2025-03-10
        '500일 기념일', // 2025-05-14
        '600일 기념일', // 2025-08-22
        '700일 기념일', // 2025-11-30
      ]);
    });

    test('날짜와 종류가 올바르다', () {
      final d400 = result.firstWhere((a) => a.id == 'days-400');
      expect(d400.date, DateTime(2025, 2, 3));
      expect(d400.dDayFrom(DateTime(2024, 12, 1)), 64);

      final birthday = result.firstWhere(
        (a) => a.kind == AnniversaryKind.birthday,
      );
      expect(birthday.birthdayOf, EventOwner.partner);
      expect(birthday.id, 'birthday-partner-2025');

      final xmas = result.first;
      expect(xmas.customId, 'xmas');
      expect(xmas.id, 'custom-xmas-2024');
    });

    test('기념일 당일은 D-0으로 포함된다', () {
      final onDay = upcomingAnniversaries(
        profile: profile,
        today: DateTime(2025, 2, 3),
      );
      expect(onDay.first.id, 'days-400');
      expect(onDay.first.dDayFrom(DateTime(2025, 2, 3)), 0);
    });
  });

  group('AnniversaryScreen', () {
    late CoupleProfile profile;

    Future<void> pump(WidgetTester tester) async {
      await initializeDateFormatting('ko_KR');
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      profile = CoupleProfile(
        myName: '민준',
        partnerName: '서연',
        // 오늘이 90일째 → 100일까지 D-10
        startDate: today.subtract(const Duration(days: 89)),
        partnerBirthday: today.add(const Duration(days: 20)),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AnniversaryScreen(profile: profile),
        ),
      );
    }

    testWidgets('D+일수와 다음 100일 기념일을 보여준다', (tester) async {
      await pump(tester);

      expect(find.text('D+90'), findsWidgets);
      expect(find.text('100일 기념일'), findsWidgets);
      expect(find.text('D-10'), findsWidgets);
      expect(find.text('달성도 (90일 / 100일)'), findsOneWidget);
    });

    testWidgets('생일 필터는 생일만 보여준다', (tester) async {
      await pump(tester);

      await tester.ensureVisible(find.text('생일 🎂'));
      await tester.tap(find.text('생일 🎂'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('서연 생일'),
        200,
        scrollable: _feed,
      );

      expect(find.text('서연 생일'), findsOneWidget);
      expect(find.text('연인 생일'), findsOneWidget);
      expect(find.text('총 1개 예정'), findsOneWidget);
    });

    testWidgets('기념일을 등록하고 메모를 남길 수 있다', (tester) async {
      await pump(tester);

      await tester.scrollUntilVisible(
        find.text('새로운 기념일 등록'),
        300,
        scrollable: _feed,
      );
      await tester.tap(find.text('새로운 기념일 등록'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '첫 여행');
      await tester.enterText(find.byType(TextField).last, '사진 앨범 만들기');
      await tester.pump();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // 오늘 날짜로 등록되어 D-DAY로 맨 위에 온다.
      await tester.scrollUntilVisible(
        find.text('첫 여행'),
        -200,
        scrollable: _feed,
      );
      expect(find.text('첫 여행'), findsOneWidget);
      expect(find.text('D-DAY'), findsOneWidget);
      expect(find.text('사진 앨범 만들기'), findsOneWidget);
    });
  });
}
