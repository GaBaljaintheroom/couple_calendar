import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/couple_profile.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import 'sheet_components.dart';

/// 일정 등록 바텀시트 (Stitch "일정 등록 모달"). 저장하면 [Event]를, 닫으면 null을 반환한다.
Future<Event?> showAddEventSheet(
  BuildContext context, {
  required DateTime date,
  required CoupleProfile profile,
}) {
  return showModalBottomSheet<Event>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    useSafeArea: true,
    barrierColor: AppColors.inverseSurface.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => _AddEventSheet(date: date, profile: profile),
  );
}

/// 컨트롤러를 시트 수명에 묶어, 닫힘 애니메이션 도중 dispose되지 않게 한다.
class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet({required this.date, required this.profile});

  final DateTime date;
  final CoupleProfile profile;

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _memoController = TextEditingController();
  final _checklistController = TextEditingController();
  final _checklistFocus = FocusNode();

  late DateTime _date = widget.date;
  EventOwner _owner = EventOwner.together;
  EventCategory _category = EventCategory.date;
  bool _allDay = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 13, minute: 0);
  final List<String> _checklist = [];
  bool _addingChecklistItem = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    _checklistController.dispose();
    _checklistFocus.dispose();
    super.dispose();
  }

  int get _durationMinutes =>
      (_endTime.hour * 60 + _endTime.minute) -
      (_startTime.hour * 60 + _startTime.minute);

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      (_allDay || _durationMinutes > 0);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        // 시작을 옮기면 기존 길이를 유지하도록 종료도 함께 민다.
        final length = _durationMinutes > 0 ? _durationMinutes : 60;
        _startTime = picked;
        final endMinutes = (picked.hour * 60 + picked.minute + length).clamp(
          0,
          23 * 60 + 59,
        );
        _endTime = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
      } else {
        _endTime = picked;
      }
    });
  }

  void _startChecklistInput() {
    setState(() => _addingChecklistItem = true);
    _checklistFocus.requestFocus();
  }

  void _submitChecklistItem(String value) {
    final item = value.trim();
    setState(() {
      if (item.isNotEmpty) _checklist.add(item);
      _checklistController.clear();
      _addingChecklistItem = item.isNotEmpty;
    });
    if (item.isNotEmpty) _checklistFocus.requestFocus();
  }

  void _save() {
    if (!_canSave) return;
    final location = _locationController.text.trim();
    final memo = _memoController.text.trim();
    Navigator.pop(
      context,
      Event(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        date: _date,
        owner: _owner,
        category: _category,
        startTime: _allDay ? null : _startTime,
        endTime: _allDay ? null : _endTime,
        location: location.isEmpty ? null : location,
        memo: memo.isEmpty ? null : memo,
        checklist: List.unmodifiable(_checklist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        // 제목 입력 중에는 저장 버튼만 다시 그린다. 입력칸까지 다시 그리면
        // 한글 조합(IME composing)이 끊겨 자모가 분리될 수 있다.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenableBuilder(
              listenable: _titleController,
              builder: (context, _) => SheetHeader(
                title: '새로운 일정 등록',
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
                    _buildTitle(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildOwner(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCategory(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDateTime(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLocation(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildChecklistAndMemo(),
                  ],
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _titleController,
              builder: (context, _) => SheetSubmitBar(
                label: _owner == EventOwner.together ? '우리 일정 등록하기' : '일정 등록하기',
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('일정 이름'),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _titleController,
          autofocus: true,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.headlineMd,
          decoration: filledInputDecoration(
            hint: '어떤 일정인가요? (예: 500일 디너, 드라이브)',
            hintStyle: AppTextStyles.bodyLg,
            radius: AppRadius.xl,
            padding: const EdgeInsets.all(AppSpacing.md),
            fill: AppColors.surfaceContainerLow,
          ),
        ),
      ],
    );
  }

  Widget _buildOwner() {
    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('누구의 일정인가요?'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                for (final owner in EventOwner.values)
                  Expanded(
                    child: _OwnerSegment(
                      label: owner == EventOwner.together
                          ? widget.profile.nameOf(owner)
                          : '${widget.profile.nameOf(owner)} 일정',
                      showHeart: owner == EventOwner.together,
                      selected: _owner == owner,
                      onTap: () => setState(() => _owner = owner),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('카테고리'),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final category in EventCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _CategoryChip(
                    category: category,
                    selected: _category == category,
                    onTap: () => setState(() => _category = category),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTime() {
    final dateText = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_date);
    final duration = _durationMinutes;

    return FormSection(
      child: Column(
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
                  '일시 설정',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '하루 종일',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _allDay,
                  activeTrackColor: AppColors.primaryContainer,
                  inactiveTrackColor: AppColors.surfaceContainerHighest,
                  inactiveThumbColor: AppColors.surfaceContainerLowest,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  onChanged: (v) => setState(() => _allDay = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_allDay)
            _DateTimeRow(label: '날짜', date: dateText, onDateTap: _pickDate)
          else ...[
            _DateTimeRow(
              label: '시작',
              date: dateText,
              time: formatTime(_startTime),
              onDateTap: _pickDate,
              onTimeTap: () => _pickTime(start: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DateTimeRow(
              label: '종료',
              date: dateText,
              time: formatTime(_endTime),
              onDateTap: _pickDate,
              onTimeTap: () => _pickTime(start: false),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  duration > 0 ? Icons.schedule : Icons.error_outline,
                  size: 16,
                  color: duration > 0 ? AppColors.primary : AppColors.error,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    duration > 0
                        ? '총 ${_formatDuration(duration)} 동안의 소중한 시간 💕'
                        : '종료 시간이 시작 시간보다 빨라요',
                    style: AppTextStyles.labelSm.copyWith(
                      color: duration > 0
                          ? AppColors.onSurfaceVariant
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('장소'),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _locationController,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.bodyMd,
          decoration:
              filledInputDecoration(
                hint: '어디서 만나요? (선택)',
                radius: AppRadius.xl,
                padding: const EdgeInsets.all(AppSpacing.md),
                fill: AppColors.surfaceContainerLow,
              ).copyWith(
                prefixIcon: const Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildChecklistAndMemo() {
    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist, size: 20, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '함께 챙길 것 & 메모',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _startChecklistInput,
                child: Text(
                  '+ 항목 추가',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (index, item) in _checklist.indexed)
                _ChecklistChip(
                  text: item,
                  onRemove: () => setState(() => _checklist.removeAt(index)),
                ),
              if (_addingChecklistItem)
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _checklistController,
                    focusNode: _checklistFocus,
                    style: AppTextStyles.labelSm,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _submitChecklistItem,
                    onTapOutside: (_) =>
                        _submitChecklistItem(_checklistController.text),
                    decoration: filledInputDecoration(
                      hint: '챙길 것 입력',
                      hintStyle: AppTextStyles.labelSm,
                      radius: AppRadius.full,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      fill: AppColors.surfaceContainerLowest,
                    ).copyWith(isDense: true),
                  ),
                )
              else
                Material(
                  color: AppColors.surfaceContainer,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: _startChecklistInput,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        '+ 직접 입력',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          TextField(
            controller: _memoController,
            minLines: 2,
            maxLines: 4,
            style: AppTextStyles.bodyMd,
            decoration: filledInputDecoration(
              hint: '둘만의 소소한 약속이나 메모를 남겨보세요.',
              radius: AppRadius.lg,
              padding: const EdgeInsets.all(12),
              fill: AppColors.surfaceContainerLowest,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m분';
    if (m == 0) return '$h시간';
    return '$h시간 $m분';
  }
}

class _OwnerSegment extends StatelessWidget {
  const _OwnerSegment({
    required this.label,
    required this.showHeart,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool showHeart;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : AppColors.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: selected ? AppShadows.card : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showHeart) ...[
                  Icon(Icons.favorite, size: 15, color: color),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMd.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final EventCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: selected ? AppColors.secondaryFixed : AppColors.surfaceContainer,
        shape: const StadiumBorder(),
        shadows: selected ? AppShadows.card : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.emoji, style: AppTextStyles.labelMd),
                const SizedBox(width: 6),
                Text(
                  category.label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: selected
                        ? AppColors.onSecondaryFixedVariant
                        : AppColors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.date,
    required this.onDateTap,
    this.time,
    this.onTimeTap,
  });

  final String label;
  final String date;
  final String? time;
  final VoidCallback onDateTap;
  final VoidCallback? onTimeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            flex: 8,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: onDateTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (time != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onTimeTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    time!,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistChip extends StatelessWidget {
  const _ChecklistChip({required this.text, required this.onRemove});

  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 2, bottom: 2),
      decoration: const ShapeDecoration(
        color: AppColors.surfaceContainerLowest,
        shape: StadiumBorder(),
        shadows: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✓',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(child: Text(text, style: AppTextStyles.labelSm)),
          Tooltip(
            message: '$text 삭제',
            child: InkResponse(
              onTap: onRemove,
              radius: 14,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.close,
                  size: 13,
                  color: AppColors.outlineVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
