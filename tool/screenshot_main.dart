// README용 스크린샷을 찍기 위한 실행 파일. 실제 Firebase 대신 가짜 데이터로 앱을 띄운다.
//
//   flutter run -t tool/screenshot_main.dart --dart-define=SCENE=main
//   SCENE: main (기본) | login | connect
import 'package:couple_calendar/data/auth_service.dart';
import 'package:couple_calendar/data/couple_service.dart';
import 'package:couple_calendar/screens/login_screen.dart';
import 'package:couple_calendar/screens/session_gate.dart';
import 'package:couple_calendar/theme/app_theme.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

const _scene = String.fromEnvironment('SCENE', defaultValue: 'main');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');

  final db = FakeFirebaseFirestore();
  await _seed(db, connected: _scene != 'connect');

  final user = MockUser(
    uid: 'me',
    email: 'minjun@example.com',
    displayName: '민준',
  );
  final auth = MockFirebaseAuth(signedIn: true, mockUser: user);
  final authService = AuthService(auth: auth);
  final coupleService = CoupleService(db: db);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: _scene == 'login'
          ? LoginScreen(authService: authService)
          : SessionGate(
              user: user,
              authService: authService,
              coupleService: coupleService,
            ),
    ),
  );
}

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _seed(FakeFirebaseFirestore db, {required bool connected}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  await db.doc('users/me').set({
    'name': '민준',
    'birthday': '1996-11-05',
    'email': 'minjun@example.com',
    'coupleId': 'c1',
  });
  if (!connected) {
    await db.doc('couples/c1').set({
      'members': ['me'],
    });
    return;
  }

  await db.doc('users/partner').set({
    'name': '서연',
    'birthday': '1997-08-30',
    'coupleId': 'c1',
  });
  await db.doc('couples/c1').set({
    'members': ['me', 'partner'],
    'startDate': _d(today.subtract(const Duration(days: 427))),
    'calendarName': '민준 ♡ 서연',
  });

  final events = db.collection('couples/c1/events');
  Future<void> event(
    String id,
    String title,
    int dayOffset,
    String owner, {
    required String category,
    String? start,
    String? end,
    String? location,
    String? memo,
    List<String> checklist = const [],
  }) => events.doc(id).set({
    'title': title,
    'date': _d(today.add(Duration(days: dayOffset))),
    'owner': owner,
    'category': category,
    'startTime': start,
    'endTime': end,
    'location': location,
    'memo': memo,
    'checklist': checklist,
  });

  await event(
    'e1',
    '세차 및 차량점검',
    0,
    'me',
    category: 'daily',
    start: '10:30',
    end: '12:00',
    location: '오토케어 성수센터',
  );
  await event(
    'e2',
    '뚝섬 한강공원 피크닉',
    0,
    'together',
    category: 'date',
    start: '14:00',
    end: '17:30',
    location: '뚝섬한강공원 3주차장 앞 잔디밭',
    memo: '매트 챙기기 & 레몬 마들렌 먹기 🧺',
    checklist: ['피크닉 매트', '삼각대'],
  );
  await event(
    'e3',
    '성수동 파스타바',
    0,
    'together',
    category: 'food',
    start: '19:00',
    end: '21:00',
    location: '바위파스타바 성수점',
  );
  await event(
    'e4',
    '필라테스',
    1,
    'partner',
    category: 'daily',
    start: '08:00',
    end: '09:00',
  );
  await event(
    'e5',
    '영화 보기',
    3,
    'together',
    category: 'culture',
    start: '14:00',
  );
  await event('e6', '팀 회식', 5, 'me', category: 'daily', start: '19:00');
  await event('e7', '전시회 데이트', 9, 'together', category: 'culture');
  await event('e8', '친구 결혼식', 12, 'partner', category: 'daily', start: '12:00');
  await event('e9', '제주도 여행', 16, 'together', category: 'travel');

  await db.doc('couples/c1/anniversaries/first-met').set({
    'title': '처음 만난 날',
    'date': _d(today.subtract(const Duration(days: 470))),
    'repeatsYearly': true,
  });
  await db.doc('couples/c1/anniversaryMemos/days-500').set({
    'text': '선물 준비 & 제주도 감성 숙소 예약하기',
  });
}
