import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/auth_service.dart';
import 'data/couple_service.dart';
import 'data/day_widget.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/session_gate.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR');
  await DayWidget.init();
  runApp(
    CoupleCalendarApp(
      authService: AuthService(),
      coupleService: CoupleService(),
    ),
  );
}

class CoupleCalendarApp extends StatelessWidget {
  const CoupleCalendarApp({
    super.key,
    required this.authService,
    required this.coupleService,
  });

  final AuthService authService;
  final CoupleService coupleService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '준수♥️서진 캘린더',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: SplashGate(
        child: _AuthGate(
          authService: authService,
          coupleService: coupleService,
        ),
      ),
    );
  }
}

/// 로그인 상태에 따라 로그인 화면과 메인 화면을 바꾼다.
class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.authService, required this.coupleService});

  final AuthService authService;
  final CoupleService coupleService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      initialData: authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return LoginScreen(authService: authService);
        // 계정이 바뀌면 이전 사용자의 화면 상태를 버린다.
        return SessionGate(
          key: ValueKey(user.uid),
          user: user,
          authService: authService,
          coupleService: coupleService,
        );
      },
    );
  }
}
