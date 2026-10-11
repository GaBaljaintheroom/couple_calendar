import 'package:flutter/material.dart';

import '../data/anniversary_repository.dart';
import '../data/auth_service.dart';
import '../data/couple_service.dart';
import '../data/day_widget.dart';
import '../data/event_repository.dart';
// import '../theme/app_theme.dart'; // _ComingSoon에서만 사용
import 'account_screen.dart';
import 'anniversary_screen.dart';
import 'calendar_screen.dart';
import 'onboarding/profile_step.dart';
import 'session_gate.dart';

/// 하단 탭 구조. 위시/메모 탭은 화면이 준비될 때까지 주석 처리해 두었다.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.session,
    required this.authService,
    required this.coupleService,
  });

  final Session session;
  final AuthService authService;
  final CoupleService coupleService;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // 커플이 함께 쓰는 데이터. 탭을 옮겨도 구독을 유지하도록 여기서 만든다.
  late EventRepository _events;
  late AnniversaryRepository _anniversaries;

  @override
  void initState() {
    super.initState();
    _createRepositories();
    DayWidget.update(widget.session.coupleProfile);
    widget.coupleService.push.register(widget.session.me.uid);
  }

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.session;
    final now = widget.session;
    if (old.couple.id != now.couple.id || old.partner.uid != now.partner.uid) {
      _disposeRepositories();
      _createRepositories();
    }
    // 사귄 날짜나 이름이 바뀌면 위젯도 바꾼다.
    final before = old.coupleProfile;
    final after = now.coupleProfile;
    if (before.startDate != after.startDate ||
        before.myName != after.myName ||
        before.partnerName != after.partnerName) {
      DayWidget.update(after);
    }
  }

  @override
  void dispose() {
    _disposeRepositories();
    super.dispose();
  }

  void _createRepositories() {
    final db = widget.coupleService.firestore;
    final session = widget.session;
    _events = EventRepository.firestore(
      db: db,
      coupleId: session.couple.id,
      myUid: session.me.uid,
      partnerUid: session.partner.uid,
    );
    _anniversaries = AnniversaryRepository.firestore(
      db: db,
      coupleId: session.couple.id,
    );
  }

  void _disposeRepositories() {
    _events.dispose();
    _anniversaries.dispose();
  }

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: '캘린더',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite),
      label: '기념일',
    ),
    // TODO: 위시/메모 화면을 만들면 다시 연다.
    // NavigationDestination(
    //   icon: Icon(Icons.edit_note_outlined),
    //   selectedIcon: Icon(Icons.edit_note),
    //   label: '위시/메모',
    // ),
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '우리공간',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = widget.session.coupleProfile;
    final me = widget.session.me;
    void openMyProfile() =>
        openProfileEditor(context, me: me, coupleService: widget.coupleService);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          CalendarScreen(
            profile: profile,
            repository: _events,
            onProfileTap: openMyProfile,
          ),
          AnniversaryScreen(
            profile: profile,
            repository: _anniversaries,
            onProfileTap: openMyProfile,
          ),
          // const _ComingSoon(title: '위시/메모'),
          AccountScreen(
            session: widget.session,
            authService: widget.authService,
            coupleService: widget.coupleService,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}

// 위시/메모 탭을 다시 열 때 함께 주석을 푼다.
// class _ComingSoon extends StatelessWidget {
//   const _ComingSoon({required this.title});
//
//   final String title;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title, style: AppTextStyles.headlineMd),
//         backgroundColor: AppColors.surface,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: Center(
//         child: Text(
//           '준비 중이에요',
//           style: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
//         ),
//       ),
//     );
//   }
// }
