import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/auth_service.dart';
import '../data/couple_service.dart';
import '../models/couple_profile.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/couple_app_bar.dart';
import '../widgets/owner_style.dart';
import 'onboarding/onboarding_widgets.dart';
import 'onboarding/profile_step.dart';
import 'session_gate.dart';

/// 우리공간 탭 (Stitch "우리공간 (설정·프로필)").
class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    required this.session,
    required this.authService,
    required this.coupleService,
  });

  final Session session;
  final AuthService authService;
  final CoupleService coupleService;

  Future<void> _editStartDate(BuildContext context) async {
    final current = session.couple.startDate!;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: '사귄 날짜',
    );
    if (picked == null || picked == current) return;
    await coupleService.setStartDate(session.couple.id, picked);
  }

  Future<void> _editCalendarName(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          _CalendarNameDialog(initial: session.coupleProfile.calendarName),
    );
    if (name == null) return;
    await coupleService.setCalendarName(session.couple.id, name);
  }

  /// 우리 함께·내 색을 고른다. 상대 색은 상대가 자기 프로필에서 정한다.
  Future<void> _editColor(BuildContext context, EventOwner owner) async {
    final profile = session.coupleProfile;
    final choice = await showOwnerColorSheet(
      context,
      title: owner == EventOwner.together ? '우리 함께 색' : '내 색',
      previewLabel: profile.nameOf(owner),
      current: profile.customColorOf(owner),
      defaultStyle: OwnerStyle.defaultOf(owner),
    );
    if (choice == null) return;
    final argb = choice.color?.toARGB32();
    if (owner == EventOwner.together) {
      await coupleService.setTogetherColor(session.couple.id, argb);
    } else {
      await coupleService.setMyColor(session.me.uid, argb);
    }
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('커플 연결을 해제할까요?', style: AppTextStyles.headlineMd),
        content: Text(
          '${session.partner.name}님과의 연결이 끊어지고, 다시 연결하려면 초대 코드가 필요해요.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('연결 해제'),
          ),
        ],
      ),
    );
    if (ok == true) await coupleService.disconnect(session.me);
  }

  @override
  Widget build(BuildContext context) {
    final me = session.me;
    final partner = session.partner;
    final startDate = session.couple.startDate!;
    final profile = session.coupleProfile;
    String birthdayText(DateTime? b) =>
        b == null ? '생일 미입력' : '${b.month}월 ${b.day}일 생일';

    return Scaffold(
      appBar: CoupleAppBar(
        profile: profile,
        onProfileTap: () =>
            openProfileEditor(context, me: me, coupleService: coupleService),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          AppSpacing.sm,
          AppSpacing.margin,
          AppSpacing.xl,
        ),
        children: [
          _CoupleCard(session: session),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('우리 정보'),
          _Group(
            children: [
              _Row(
                icon: Icons.edit_calendar_outlined,
                label: '캘린더 이름',
                value: profile.calendarName,
                onTap: () => _editCalendarName(context),
              ),
              _Row(
                icon: Icons.calendar_today_outlined,
                label: '사귄 날짜',
                value: DateFormat('yyyy년 M월 d일', 'ko_KR').format(startDate),
                onTap: () => _editStartDate(context),
              ),
              _Row(
                icon: Icons.person_outline,
                label: '내 프로필',
                value: '${me.name} · ${birthdayText(me.birthday)}',
                onTap: () => openProfileEditor(
                  context,
                  me: me,
                  coupleService: coupleService,
                ),
              ),
              _Row(
                icon: Icons.favorite_border,
                label: '상대 프로필',
                value: '${partner.name} · ${birthdayText(partner.birthday)}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('캘린더 색'),
          _Group(
            children: [
              for (final owner in EventOwner.values)
                _Row(
                  icon: switch (owner) {
                    EventOwner.together => Icons.favorite_border,
                    EventOwner.me => Icons.person_outline,
                    EventOwner.partner => Icons.person_outline,
                  },
                  label: switch (owner) {
                    EventOwner.together => '우리 함께',
                    EventOwner.me => '내 색',
                    EventOwner.partner => '${partner.name}님 색',
                  },
                  value: '',
                  trailing: _ColorDot(profile.styleOf(owner).dot),
                  // 상대 색은 상대가 정한다.
                  onTap: owner == EventOwner.partner
                      ? null
                      : () => _editColor(context, owner),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('계정'),
          _Group(
            children: [
              _Row(
                icon: Icons.mail_outline,
                label: '로그인 계정',
                value: authService.currentUser?.email ?? me.email ?? '',
                neutralIcon: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: authService.signOut,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                ),
                child: const Text('로그아웃'),
              ),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: AppColors.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              TextButton(
                onPressed: () => _confirmDisconnect(context),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('커플 연결 해제'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoupleCard extends StatelessWidget {
  const _CoupleCard({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final me = session.me;
    final partner = session.partner;
    final startDate = session.couple.startDate!;
    final dayCount = session.coupleProfile.dayCountOn(DateTime.now());

    Widget person(String? photoUrl, String name) => Column(
      children: [
        ProfileAvatar(
          photoUrl: photoUrl,
          size: 72,
          borderWidth: 3,
          borderColor: AppColors.secondaryContainer,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              person(me.photoUrl, me.name),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.card,
                    border: Border.all(color: AppColors.secondaryFixed),
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 16,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
              person(partner.photoUrl, partner.name),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              text: me.name,
              children: [
                const TextSpan(
                  text: ' ♡ ',
                  style: TextStyle(color: AppColors.primaryContainer),
                ),
                TextSpan(text: partner.name),
              ],
            ),
            style: AppTextStyles.headlineLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: '${DateFormat('yyyy.MM.dd').format(startDate)}부터 · ',
              children: [
                TextSpan(
                  text: 'D+$dayCount',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 64,
                color: AppColors.surfaceContainerHigh,
              ),
            child,
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
    this.neutralIcon = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// 값 글자 대신 오른쪽에 보여줄 위젯 (예: 색 점).
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool neutralIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: neutralIcon
                      ? AppColors.surfaceContainer
                      : AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: neutralIcon
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: trailing != null
                    ? Align(alignment: Alignment.centerRight, child: trailing)
                    : Text(
                        value,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.outlineVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 캘린더 이름 수정. 저장하면 새 이름을, 취소하면 null을 반환한다.
class _CalendarNameDialog extends StatefulWidget {
  const _CalendarNameDialog({required this.initial});

  final String initial;

  @override
  State<_CalendarNameDialog> createState() => _CalendarNameDialogState();
}

class _CalendarNameDialogState extends State<_CalendarNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('캘린더 이름', style: AppTextStyles.headlineMd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: CoupleService.calendarNameMaxLength,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: defaultCalendarName),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          Text(
            '상단에 보이는 이름이에요. 비워 두면 "$defaultCalendarName"로 돌아가요.',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceContainerLowest, width: 2),
        boxShadow: AppShadows.card,
      ),
    );
  }
}
