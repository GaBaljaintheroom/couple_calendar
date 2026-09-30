import 'dart:math';

import 'package:couple_calendar/data/auth_service.dart';
import 'package:couple_calendar/data/couple_service.dart';
import 'package:couple_calendar/models/couple_profile.dart';
import 'package:couple_calendar/models/user_profile.dart';
import 'package:couple_calendar/screens/session_gate.dart';
import 'package:couple_calendar/theme/app_theme.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// 반복 애니메이션(대기 표시)·카운트다운 타이머가 있어 pumpAndSettle 대신 일정 시간만 진행한다.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late CoupleService service;
  late MockUser user;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = CoupleService(db: db, random: Random(7));
    user = MockUser(uid: 'me', email: 'me@example.com', displayName: '');
  });

  Future<void> pumpGate(WidgetTester tester) async {
    await initializeDateFormatting('ko_KR');
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final auth = MockFirebaseAuth(signedIn: true, mockUser: user);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SessionGate(
          user: user,
          authService: AuthService(auth: auth),
          coupleService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('프로필 → 초대 코드 → 상대 합류 → 사귄 날짜 → 메인 화면', (tester) async {
    await pumpGate(tester);

    // 1단계: 프로필
    expect(find.text('어떻게 불러드릴까요?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '민준');
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // 2단계: 코드 만들기
    expect(find.text('우리 둘을 연결해요 💞'), findsOneWidget);
    await tester.tap(find.text('초대 코드 만들기'));
    await settle(tester);
    expect(find.text('상대방이 코드를 입력하길 기다리는 중...'), findsOneWidget);

    // 상대가 다른 기기에서 코드를 입력한다.
    final code = (await db.collection('invites').get()).docs.single.id;
    await service.saveProfile(uid: 'partner', name: '서연', birthday: null);
    await service.joinWithCode(
      const UserProfile(uid: 'partner', name: '서연'),
      code,
    );
    await settle(tester);

    // 3단계: 사귄 날짜
    expect(find.text('서연님과 연결되었어요! 🎉'), findsOneWidget);
    final coupleId = (await db.doc('users/me').get()).data()!['coupleId'];
    // 날짜 선택 창 대신 상대가 먼저 설정한 경우를 흉내낸다.
    await service.setStartDate(coupleId as String, DateTime(2024, 8, 1));
    await settle(tester);

    // 메인 화면
    expect(find.byType(NavigationBar), findsOneWidget);
    // 헤더에는 기본 캘린더 이름이 보인다 (하단 탭의 "캘린더"와 구분).
    expect(
      find.descendant(
        of: find.byType(AppBar).first,
        matching: find.text(defaultCalendarName),
      ),
      findsOneWidget,
    );

    // 헤더의 프로필 버튼 → 내 프로필 수정 화면
    await tester.tap(find.byTooltip('내 프로필').first);
    await settle(tester);
    expect(find.widgetWithText(AppBar, '내 프로필'), findsOneWidget);
    expect(find.widgetWithText(TextField, '민준'), findsOneWidget);
  });

  testWidgets('잘못된 코드를 입력하면 안내 문구를 보여준다', (tester) async {
    await service.saveProfile(uid: 'me', name: '민준', birthday: null);
    await pumpGate(tester);

    await tester.enterText(
      find.widgetWithText(TextField, '예: W4X8P2'),
      'zzzzzz',
    );
    await tester.pump();
    await tester.tap(find.text('연결하기'));
    await tester.pumpAndSettle();

    expect(find.text('코드를 찾을 수 없어요. 다시 확인해 주세요.'), findsOneWidget);
  });
}
