import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/anniversary_repository.dart';
import '../data/daily_messages.dart';
import '../data/demo_profile.dart';
import '../models/anniversary.dart';
import '../models/couple_profile.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/add_anniversary_sheet.dart';
import '../widgets/couple_app_bar.dart';
import '../widgets/soft_components.dart';

enum _Filter {
  all('전체 보기'),
  hundredDays('100일 단위'),
  yearly('매년 기념일'),
  birthday('생일 🎂');

  const _Filter(this.label);

  final String label;

  bool matches(Anniversary a) => switch (this) {
    _Filter.all => true,
    _Filter.hundredDays => a.kind == AnniversaryKind.hundredDays,
    _Filter.yearly =>
      a.kind == AnniversaryKind.yearly ||
          (a.kind == AnniversaryKind.custom && a.repeatsYearly),
    _Filter.birthday => a.kind == AnniversaryKind.birthday,
  };
}

/// 기념일 & D-Day 피드.
class AnniversaryScreen extends StatefulWidget {
  AnniversaryScreen({
    super.key,
    CoupleProfile? profile,
    this.repository,
    this.onProfileTap,
  }) : profile = profile ?? demoCoupleProfile;

  final CoupleProfile profile;

  /// 없으면 메모리 저장소를 쓴다 (테스트·미리보기용).
  final AnniversaryRepository? repository;
  final VoidCallback? onProfileTap;

  @override
  State<AnniversaryScreen> createState() => _AnniversaryScreenState();
}

class _AnniversaryScreenState extends State<AnniversaryScreen> {
  AnniversaryRepository? _fallbackRepository;
  AnniversaryRepository get _repository =>
      widget.repository ??
      (_fallbackRepository ??= AnniversaryRepository.memory());
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _fallbackRepository?.dispose();
    super.dispose();
  }

  /// 저장은 기다리지 않는다 (화면에는 바로 반영되고, 오프라인이면 나중에 올라간다).
  void _save(Future<void> write) {
    write.catchError((Object e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장하지 못했어요. 잠시 후 다시 시도해 주세요.')),
      );
    });
  }

  List<Anniversary> _upcoming(DateTime today) => upcomingAnniversaries(
    profile: widget.profile,
    today: today,
    customs: _repository.customs,
  );

  Future<void> _addAnniversary() async {
    final result = await showAddAnniversarySheet(context);
    if (result == null) return;
    _save(_repository.add(result.anniversary));
    if (result.memo.isEmpty) return;
    // 메모는 이번에 돌아오는 회차에 붙인다. 저장소 반영을 기다리지 않도록 새 기념일만으로 계산한다.
    final occurrence = upcomingAnniversaries(
      profile: widget.profile,
      today: DateTime.now(),
      customs: [result.anniversary],
    ).where((a) => a.customId == result.anniversary.id).firstOrNull;
    if (occurrence != null) {
      _save(_repository.setMemo(occurrence.id, result.memo));
    }
  }

  Future<void> _editMemo(Anniversary anniversary) async {
    final result = await showDialog<_MemoResult>(
      context: context,
      builder: (context) => _MemoDialog(
        anniversary: anniversary,
        initialMemo: _repository.memoFor(anniversary.id) ?? '',
      ),
    );
    switch (result) {
      case _MemoSaved(:final memo):
        _save(_repository.setMemo(anniversary.id, memo));
      case _AnniversaryDeleted():
        _save(_repository.remove(anniversary.customId!));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final today = DateTime.now();
    return Scaffold(
      appBar: CoupleAppBar(profile: profile, onProfileTap: widget.onProfileTap),
      body: ListenableBuilder(
        listenable: _repository,
        builder: (context, _) {
          final upcoming = _upcoming(today);
          final nextHundred = upcoming
              .where((a) => a.kind == AnniversaryKind.hundredDays)
              .firstOrNull;
          final visible = upcoming.where(_filter.matches).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.sm,
              AppSpacing.margin,
              AppSpacing.xl,
            ),
            children: [
              _CoupleIdentityCard(profile: profile),
              const SizedBox(height: AppSpacing.md),
              _HeroBanner(dayCount: profile.dayCountOn(today)),
              if (nextHundred != null) ...[
                const SizedBox(height: AppSpacing.md),
                _NextMilestoneCard(
                  anniversary: nextHundred,
                  dayCount: profile.dayCountOn(today),
                  today: today,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _FilterChips(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(count: visible.length),
              const SizedBox(height: AppSpacing.gutter),
              if (visible.isEmpty)
                const _EmptyFeed()
              else
                for (final (index, anniversary) in visible.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.gutter),
                  _AnniversaryCard(
                    anniversary: anniversary,
                    today: today,
                    highlighted: identical(anniversary, upcoming.first),
                    memo: _repository.memoFor(anniversary.id),
                    onMemoTap: () => _editMemo(anniversary),
                  ),
                ],
              const SizedBox(height: AppSpacing.xl),
              _AddButton(onPressed: _addAnniversary),
            ],
          );
        },
      ),
    );
  }
}

String _dDayLabel(int d) => d == 0 ? 'D-DAY' : 'D-$d';

class _CoupleIdentityCard extends StatelessWidget {
  const _CoupleIdentityCard({required this.profile});

  final CoupleProfile profile;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          Flexible(
            child: Text(
              '${profile.myName} ♥️ ${profile.partnerName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headlineMd,
            ),
          ),
          const SizedBox(width: 6),
          const PillLabel(
            text: '연애중',
            background: AppColors.secondaryFixed,
            foreground: AppColors.onSecondaryFixedVariant,
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.dayCount});

  final int dayCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryFixed, AppColors.secondaryContainer],
        ),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          // 오른쪽 위의 은은한 빛 번짐
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '우리 함께 걸어온',
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onPrimaryFixedVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'D+$dayCount',
                                style: AppTextStyles.displayLg.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '일째',
                                style: AppTextStyles.headlineMd.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest.withValues(
                          alpha: 0.8,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.celebration,
                        size: 26,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dailyMessageFor(dayCount),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '오늘',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSecondaryFixedVariant,
                        ),
                      ),
                    ],
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

class _NextMilestoneCard extends StatelessWidget {
  const _NextMilestoneCard({
    required this.anniversary,
    required this.dayCount,
    required this.today,
  });

  final Anniversary anniversary;
  final int dayCount;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final target = dayCount + anniversary.dDayFrom(today);
    final ratio = (dayCount / target).clamp(0.0, 1.0);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PillLabel(
                text: _dDayLabel(anniversary.dDayFrom(today)),
                background: AppColors.primaryContainer,
                foreground: AppColors.onPrimary,
                bold: true,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  anniversary.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd,
                ),
              ),
              Text(
                DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(anniversary.date),
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(
                child: Text(
                  '달성도 ($dayCount일 / $target일)',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${(ratio * 100).toStringAsFixed(1)}%',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final _Filter selected;
  final ValueChanged<_Filter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _Filter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Material(
                color: filter == selected
                    ? AppColors.primary
                    : AppColors.surfaceContainer,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onSelected(filter),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      filter.label,
                      style: AppTextStyles.labelMd.copyWith(
                        color: filter == selected
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.event_repeat, size: 22, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '다가오는 기념일',
            style: AppTextStyles.headlineLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '총 $count개 예정',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AnniversaryCard extends StatelessWidget {
  const _AnniversaryCard({
    required this.anniversary,
    required this.today,
    required this.highlighted,
    required this.memo,
    required this.onMemoTap,
  });

  final Anniversary anniversary;
  final DateTime today;

  /// 가장 가까운 기념일이면 D-day 배지를 강조한다.
  final bool highlighted;
  final String? memo;
  final VoidCallback onMemoTap;

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, iconFg) = switch (anniversary) {
      Anniversary(kind: AnniversaryKind.hundredDays) => (
        Icons.hotel_class,
        AppColors.primaryFixed,
        AppColors.primary,
      ),
      Anniversary(kind: AnniversaryKind.yearly) => (
        Icons.diamond,
        AppColors.secondaryFixed,
        AppColors.onSecondaryFixedVariant,
      ),
      Anniversary(birthdayOf: EventOwner.partner) => (
        Icons.cake,
        AppColors.secondaryContainer,
        AppColors.onSecondaryContainer,
      ),
      Anniversary(kind: AnniversaryKind.birthday) => (
        Icons.celebration,
        AppColors.tertiaryFixed,
        AppColors.onTertiaryContainer,
      ),
      _ => (Icons.favorite, AppColors.primaryFixed, AppColors.primary),
    };

    final (badgeBg, badgeFg) = highlighted
        ? (AppColors.primaryContainer, AppColors.onPrimary)
        : anniversary.birthdayOf == EventOwner.partner
        ? (AppColors.secondaryFixed, AppColors.onSecondaryFixedVariant)
        : (AppColors.surfaceContainer, AppColors.onSurfaceVariant);

    final tag = switch (anniversary) {
      Anniversary(birthdayOf: EventOwner.partner) => '연인 생일',
      Anniversary(birthdayOf: EventOwner.me) => '내 생일',
      Anniversary(kind: AnniversaryKind.custom, repeatsYearly: true) ||
      Anniversary(kind: AnniversaryKind.yearly) => '매년',
      _ => null,
    };

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconFg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          anniversary.title,
                          style: AppTextStyles.headlineMd.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        if (tag != null)
                          _Tag(text: tag, anniversary: anniversary),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat(
                        'yyyy년 M월 d일 (EEEE)',
                        'ko_KR',
                      ).format(anniversary.date),
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _dDayLabel(anniversary.dDayFrom(today)),
                  style: AppTextStyles.labelMd.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          Material(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: onMemoTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        memo ?? '메모를 남겨보세요',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: memo == null
                              ? AppColors.outline
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.anniversary});

  final String text;
  final Anniversary anniversary;

  @override
  Widget build(BuildContext context) {
    final birthdayOf = anniversary.birthdayOf;
    if (birthdayOf == null) {
      return PillLabel(
        text: text,
        background: AppColors.secondaryFixed,
        foreground: AppColors.onSecondaryFixedVariant,
      );
    }
    final color = birthdayOf == EventOwner.partner
        ? AppColors.secondary
        : AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.labelSm.copyWith(color: color)),
      ],
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: AppColors.outlineVariant,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '1년 안에 다가오는 기념일이 없어요',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        shadows: [
          BoxShadow(
            color: Color(0x47E07A5F),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(56),
          textStyle: AppTextStyles.headlineMd.copyWith(fontSize: 18),
        ),
        icon: const Icon(Icons.add_circle_outline, size: 22),
        label: const Text('새로운 기념일 등록'),
      ),
    );
  }
}

sealed class _MemoResult {}

class _MemoSaved extends _MemoResult {
  _MemoSaved(this.memo);

  final String memo;
}

class _AnniversaryDeleted extends _MemoResult {}

/// 기념일 메모 편집. 직접 등록한 기념일은 여기서 삭제할 수 있다.
class _MemoDialog extends StatefulWidget {
  const _MemoDialog({required this.anniversary, required this.initialMemo});

  final Anniversary anniversary;
  final String initialMemo;

  @override
  State<_MemoDialog> createState() => _MemoDialogState();
}

class _MemoDialogState extends State<_MemoDialog> {
  late final _controller = TextEditingController(text: widget.initialMemo);
  bool _confirmingDelete = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = widget.anniversary.customId != null;
    return AlertDialog(
      title: Text(widget.anniversary.title, style: AppTextStyles.headlineMd),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(hintText: '준비할 선물이나 계획을 적어두세요.'),
      ),
      actions: [
        if (canDelete)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: _confirmingDelete
                ? () => Navigator.pop(context, _AnniversaryDeleted())
                : () => setState(() => _confirmingDelete = true),
            child: Text(_confirmingDelete ? '정말 삭제' : '기념일 삭제'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _MemoSaved(_controller.text)),
          child: const Text('저장'),
        ),
      ],
    );
  }
}
