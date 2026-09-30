import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/anniversary.dart';
import '../theme/app_theme.dart';
import 'sheet_components.dart';

typedef NewAnniversary = ({CustomAnniversary anniversary, String memo});

/// 기념일 등록 바텀시트. 저장하면 새 기념일과 메모를, 닫으면 null을 반환한다.
Future<NewAnniversary?> showAddAnniversarySheet(BuildContext context) {
  return showModalBottomSheet<NewAnniversary>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    useSafeArea: true,
    barrierColor: AppColors.inverseSurface.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => const _AddAnniversarySheet(),
  );
}

class _AddAnniversarySheet extends StatefulWidget {
  const _AddAnniversarySheet();

  @override
  State<_AddAnniversarySheet> createState() => _AddAnniversarySheetState();
}

class _AddAnniversarySheetState extends State<_AddAnniversarySheet> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _repeatsYearly = true;

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_canSave) return;
    Navigator.pop<NewAnniversary>(context, (
      anniversary: CustomAnniversary(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        date: DateTime(_date.year, _date.month, _date.day),
        repeatsYearly: _repeatsYearly,
      ),
      memo: _memoController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        // 입력칸은 다시 그리지 않고 저장 버튼만 제목 변화에 반응한다 (한글 조합 보호).
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenableBuilder(
              listenable: _titleController,
              builder: (context, _) => SheetHeader(
                title: '새로운 기념일 등록',
                canSave: _canSave,
                onClose: () => Navigator.pop(context),
                onSave: _save,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.xs,
                  AppSpacing.margin,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel('기념일 이름'),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _titleController,
                      autofocus: true,
                      style: AppTextStyles.headlineMd,
                      decoration: filledInputDecoration(
                        hint: '어떤 날인가요? (예: 처음 만난 날)',
                        hintStyle: AppTextStyles.bodyLg,
                        radius: AppRadius.xl,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        fill: AppColors.surfaceContainerLow,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FormSection(child: _buildDate()),
                    const SizedBox(height: AppSpacing.lg),
                    const FieldLabel('메모'),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _memoController,
                      minLines: 2,
                      maxLines: 4,
                      style: AppTextStyles.bodyMd,
                      decoration: filledInputDecoration(
                        hint: '준비할 선물이나 계획을 적어두세요.',
                        radius: AppRadius.xl,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        fill: AppColors.surfaceContainerLow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _titleController,
              builder: (context, _) => SheetSubmitBar(
                label: '기념일 등록하기',
                icon: Icons.add_circle_outline,
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '날짜',
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '매년 반복',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _repeatsYearly,
                activeTrackColor: AppColors.primaryContainer,
                inactiveTrackColor: AppColors.surfaceContainerHighest,
                inactiveThumbColor: AppColors.surfaceContainerLowest,
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                onChanged: (v) => setState(() => _repeatsYearly = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: _pickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_date),
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
