import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/couple_service.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import 'onboarding_widgets.dart';

/// 내 프로필 수정 화면을 연다 (헤더의 프로필 버튼, 우리공간 > 내 프로필).
Future<void> openProfileEditor(
  BuildContext context, {
  required UserProfile me,
  required CoupleService coupleService,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (routeContext) => ProfileStep(
        editMode: true,
        initialName: me.name,
        initialBirthday: me.birthday,
        photoUrl: me.photoUrl,
        email: me.email,
        onSubmit: ({required name, required birthday}) async {
          await coupleService.saveProfile(
            uid: me.uid,
            name: name,
            birthday: birthday,
          );
          if (routeContext.mounted) Navigator.of(routeContext).pop();
        },
      ),
    ),
  );
}

typedef ProfileSubmit = Future<void> Function({
  required String name,
  required DateTime? birthday,
});

/// 온보딩 1단계 (Stitch "온보딩 1단계: 내 프로필 입력").
/// [editMode]면 우리공간에서 여는 프로필 수정 화면으로 쓴다.
class ProfileStep extends StatefulWidget {
  const ProfileStep({
    super.key,
    required this.onSubmit,
    this.initialName = '',
    this.initialBirthday,
    this.photoUrl,
    this.email,
    this.editMode = false,
  });

  final ProfileSubmit onSubmit;
  final String initialName;
  final DateTime? initialBirthday;
  final String? photoUrl;
  final String? email;
  final bool editMode;

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late DateTime? _birthday = widget.initialBirthday;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1996, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        name: _nameController.text.trim(),
        birthday: _birthday,
      );
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
    return Scaffold(
      appBar: widget.editMode
          ? AppBar(
              title: Text('내 프로필', style: AppTextStyles.headlineMd),
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.editMode) const OnboardingHeader(step: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                children: [
                  if (!widget.editMode) ...[
                    const OnboardingTitle(
                      line1: '반가워요! 👋',
                      line2: '어떻게 불러드릴까요?',
                      subtitle: '상대방에게 보여질 내 프로필이에요',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ] else
                    const SizedBox(height: AppSpacing.md),
                  Center(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.floating,
                      ),
                      child: ProfileAvatar(
                        photoUrl: widget.photoUrl,
                        size: 120,
                        borderWidth: 4,
                      ),
                    ),
                  ),
                  if (widget.email case final email?) ...[
                    const SizedBox(height: AppSpacing.md),
                    Center(child: _GoogleAccountChip(email: email)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  LabeledCard(
                    label: '이름 (애칭)',
                    labelColor: AppColors.primary,
                    child: TextField(
                      controller: _nameController,
                      autofocus: !widget.editMode && widget.initialName.isEmpty,
                      textInputAction: TextInputAction.done,
                      style: AppTextStyles.headlineMd,
                      decoration: InputDecoration(
                        hintText: '예: 민준',
                        hintStyle: AppTextStyles.headlineMd.copyWith(
                          color: AppColors.outlineVariant,
                        ),
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 28,
                        ),
                        suffixIcon: ListenableBuilder(
                          listenable: _nameController,
                          builder: (context, _) => _nameController.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  tooltip: '지우기',
                                  onPressed: _nameController.clear,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                  LabeledCard(
                    label: '생일',
                    onTap: _pickBirthday,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cake_outlined,
                          size: 20,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _birthday == null
                                ? '생일을 선택해 주세요'
                                : DateFormat(
                                    'yyyy년 M월 d일',
                                    'ko_KR',
                                  ).format(_birthday!),
                            style: AppTextStyles.headlineMd.copyWith(
                              color: _birthday == null
                                  ? AppColors.outlineVariant
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Text(
                      '생일은 기념일 피드에 자동으로 추가돼요 🎂',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: _nameController,
              builder: (context, _) => OnboardingButton(
                label: widget.editMode ? '저장' : '다음',
                icon: widget.editMode ? null : Icons.arrow_forward,
                loading: _saving,
                onPressed: _nameController.text.trim().isEmpty ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleAccountChip extends StatelessWidget {
  const _GoogleAccountChip({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'G',
            style: AppTextStyles.labelMd.copyWith(
              color: const Color(0xFF4285F4),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$email 으로 로그인됨',
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
