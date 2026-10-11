import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/couple_service.dart';
import '../models/couple_profile.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';
import 'onboarding/connect_step.dart';
import 'onboarding/profile_step.dart';
import 'onboarding/start_date_step.dart';
import 'splash_screen.dart';

/// 연결이 끝난 커플의 현재 상태.
class Session {
  const Session({
    required this.me,
    required this.partner,
    required this.couple,
  });

  final UserProfile me;
  final UserProfile partner;
  final Couple couple;

  CoupleProfile get coupleProfile => CoupleProfile(
    myName: me.name,
    partnerName: partner.name,
    startDate: couple.startDate!,
    myBirthday: me.birthday,
    partnerBirthday: partner.birthday,
    calendarName: couple.calendarName ?? defaultCalendarName,
    togetherColor: _color(couple.togetherColor),
    myColor: _color(me.color),
    partnerColor: _color(partner.color),
  );

  static Color? _color(int? argb) => argb == null ? null : Color(argb);
}

/// 로그인 이후: Firestore 상태를 보고 온보딩 단계나 메인 화면을 보여준다.
///
/// 프로필 없음 → 1단계, 커플 미연결 → 2단계, 사귄 날짜 없음 → 3단계, 모두 있음 → 메인.
/// 각 단계는 Firestore에 저장만 하고, 화면 전환은 이 위젯이 데이터 변화를 보고 한다.
class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.user,
    required this.authService,
    required this.coupleService,
  });

  final User user;
  final AuthService authService;
  final CoupleService coupleService;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Stream<UserProfile?> _meStream = widget.coupleService.watchUser(
    widget.user.uid,
  );

  // 스트림은 id가 바뀔 때만 새로 만든다 (빌드마다 다시 구독하지 않도록).
  String? _coupleId;
  Stream<Couple?>? _coupleStream;
  String? _partnerId;
  Stream<UserProfile?>? _partnerStream;

  /// 2단계에서 뒤로가기를 누르면 1단계(프로필)를 다시 보여준다.
  bool _editingProfile = false;

  Stream<Couple?> _watchCouple(String id) {
    if (id != _coupleId) {
      _coupleId = id;
      _coupleStream = widget.coupleService.watchCouple(id);
    }
    return _coupleStream!;
  }

  Stream<UserProfile?> _watchPartner(String uid) {
    if (uid != _partnerId) {
      _partnerId = uid;
      _partnerStream = widget.coupleService.watchUser(uid);
    }
    return _partnerStream!;
  }

  Future<void> _saveProfile({
    required String name,
    required DateTime? birthday,
  }) async {
    await widget.coupleService.saveProfile(
      uid: widget.user.uid,
      name: name,
      birthday: birthday,
      photoUrl: widget.user.photoURL,
      email: widget.user.email,
    );
    if (mounted) setState(() => _editingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _meStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final me = snapshot.data;

        if (me == null || !me.isComplete || _editingProfile) {
          return ProfileStep(
            initialName: me?.name ?? widget.user.displayName ?? '',
            initialBirthday: me?.birthday,
            photoUrl: widget.user.photoURL,
            email: widget.user.email,
            onSubmit: _saveProfile,
          );
        }

        final coupleId = me.coupleId;
        if (coupleId == null) return _connectStep(me, null);

        return StreamBuilder<Couple?>(
          stream: _watchCouple(coupleId),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
            if (!snapshot.hasData &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            final couple = snapshot.data;
            if (couple == null || !couple.members.contains(me.uid)) {
              return _connectStep(me, null);
            }
            if (!couple.isConnected) return _connectStep(me, couple);

            return StreamBuilder<UserProfile?>(
              stream: _watchPartner(couple.partnerOf(me.uid)!),
              builder: (context, snapshot) {
                if (!snapshot.hasData &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const _Splash();
                }
                final partner =
                    snapshot.data ??
                    UserProfile(uid: couple.partnerOf(me.uid)!, name: '상대방');

                if (couple.startDate == null) {
                  return StartDateStep(
                    me: me,
                    partner: partner,
                    onSubmit: (date) =>
                        widget.coupleService.setStartDate(couple.id, date),
                  );
                }

                return HomeShell(
                  session: Session(me: me, partner: partner, couple: couple),
                  authService: widget.authService,
                  coupleService: widget.coupleService,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _connectStep(UserProfile me, Couple? pending) => ConnectStep(
    me: me,
    pendingCouple: pending,
    coupleService: widget.coupleService,
    onBack: () => setState(() => _editingProfile = true),
  );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const BrandSplash(showProgress: true);
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.outline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '정보를 불러오지 못했어요.\n네트워크를 확인해 주세요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
