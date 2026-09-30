import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/anniversary.dart';
import '../../models/couple_profile.dart';
import '../../models/event.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import 'onboarding_widgets.dart';

/// 온보딩 3단계 (Stitch "온보딩 3단계: 사귄 날짜 설정 (완성)").
class StartDateStep extends StatefulWidget {
  const StartDateStep({
    super.key,
    required this.me,
    required this.partner,
    required this.onSubmit,
  });

  final UserProfile me;
  final UserProfile partner;
  final Future<void> Function(DateTime startDate) onSubmit;

  @override
  State<StartDateStep> createState() => _StartDateStepState();
}

class _StartDateStepState extends State<StartDateStep> {
  DateTime? _startDate;
  bool _saving = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(1980),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_startDate!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장하지 못했어요. ($e)')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = _startDate;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(
              step: 3,
              stepLabels: ['프로필', '파트너 연결', '기념일 설정'],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  0,
                  AppSpacing.margin,
                  AppSpacing.lg,
                ),
                children: [
                  _ConnectedBanner(me: widget.me, partner: widget.partner),
                  const SizedBox(height: AppSpacing.lg),
                  const OnboardingTitle(
                    line1: '우리가 처음 사귄 날은',
                    line2: '언제인가요?',
                    subtitle: '이 날이 D+1이 돼요. 둘 중 한 명만 설정하면 함께 공유돼요.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _DateCard(date: startDate, onTap: _pickDate),
                  if (startDate != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _Preview(
                      profile: CoupleProfile(
                        myName: widget.me.name,
                        partnerName: widget.partner.name,
                        startDate: startDate,
                        myBirthday: widget.me.birthday,
                        partnerBirthday: widget.partner.birthday,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            OnboardingButton(
              label: '데이로그 시작하기',
              icon: Icons.favorite_border,
              loading: _saving,
              onPressed: startDate == null ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedBanner extends StatelessWidget {
  const _ConnectedBanner({required this.me, required this.partner});

  final UserProfile me;
  final UserProfile partner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          colors: [AppColors.secondaryFixed, AppColors.surfaceContainerLow],
        ),
        border: Border.all(color: AppColors.secondaryFixed),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 52,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ProfileAvatar(photoUrl: me.photoUrl, size: 52),
                Positioned(
                  left: 32,
                  child: ProfileAvatar(photoUrl: partner.photoUrl, size: 52),
                ),
                Positioned(
                  left: 22,
                  bottom: -6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 11,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${partner.name}님과 연결되었어요! 🎉',
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '이제 둘만의 일정을 실시간으로 함께해요',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final years = date == null
        ? 0
        : (DateTime.now().difference(date!).inDays ~/ 365) + 1;
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.margin),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '처음 만난 날 (연애 시작일)',
                      style: AppTextStyles.labelMd,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'D+1 기준일',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSecondaryFixedVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(
                height: AppSpacing.lg,
                color: AppColors.surfaceContainerHigh,
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date == null
                              ? '날짜를 선택해 주세요'
                              : DateFormat(
                                  'yyyy년 M월 d일 (E)',
                                  'ko_KR',
                                ).format(date!),
                          style: AppTextStyles.headlineLg.copyWith(
                            fontWeight: FontWeight.w700,
                            color: date == null
                                ? AppColors.outlineVariant
                                : AppColors.onSurface,
                          ),
                        ),
                        if (date != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                size: 14,
                                color: AppColors.primaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text.rich(
                                TextSpan(
                                  text: '우리가 손잡고 시작한 지 ',
                                  children: [
                                    TextSpan(
                                      text: '$years년째',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date == null ? '선택' : '변경',
                          style: AppTextStyles.labelMd,
                        ),
                        const Icon(Icons.expand_more, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 고른 날짜로 D+일수와 다가오는 기념일을 미리 보여준다.
class _Preview extends StatelessWidget {
  const _Preview({required this.profile});

  final CoupleProfile profile;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final upcoming = upcomingAnniversaries(profile: profile, today: today);
    Anniversary? first(bool Function(Anniversary) test) =>
        upcoming.where(test).firstOrNull;

    final hundred = first((a) => a.kind == AnniversaryKind.hundredDays);
    final yearly = first((a) => a.kind == AnniversaryKind.yearly);
    final partnerBirthday = first((a) => a.birthdayOf == EventOwner.partner);

    String dDay(Anniversary a) {
      final d = a.dDayFrom(today);
      return d == 0 ? 'D-DAY' : 'D-$d';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.margin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryFixed, AppColors.surfaceContainerLow],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 13,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '실시간 계산 미리보기',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${profile.myName} ♡ ${profile.partnerName}',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'TOGETHER TODAY',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
          Text.rich(
            TextSpan(
              text: '오늘은 ',
              children: [
                TextSpan(
                  text: 'D+${profile.dayCountOn(today)}',
                  style: const TextStyle(color: AppColors.primaryContainer),
                ),
              ],
            ),
            style: AppTextStyles.displayLg.copyWith(
              color: AppColors.onPrimaryFixedVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '소중한 매 순간이 데이로그에 기록됩니다',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children:
                [
                      if (hundred != null)
                        _MiniStat(
                          label: '다음 ${hundred.title.replaceAll(' 기념일', '')}',
                          value: dDay(hundred),
                        ),
                      if (yearly != null)
                        _MiniStat(
                          label: yearly.title.replaceAll(' 기념일', ''),
                          value: DateFormat('yyyy.MM.dd').format(yearly.date),
                          small: true,
                        ),
                      if (partnerBirthday != null)
                        _MiniStat(
                          label: '${profile.partnerName} 생일',
                          value: dDay(partnerBirthday),
                        ),
                    ]
                    .expand((w) => [w, const SizedBox(width: AppSpacing.sm)])
                    .toList()
                  ..removeLast(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '나중에 [우리공간]에서 언제든 수정할 수 있어요',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.small = false,
  });

  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                value,
                style: (small ? AppTextStyles.labelMd : AppTextStyles.bodyLg)
                    .copyWith(
                      color: small ? AppColors.onSurface : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
