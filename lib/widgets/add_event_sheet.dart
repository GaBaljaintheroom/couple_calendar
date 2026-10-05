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
}) => _showEventSheet(context, date: date, profile: profile);

/// [event]의 내용을 채운 수정 시트. 저장하면 같은 id의 [Event]를, 닫으면 null을 반환한다.
Future<Event?> showEditEventSheet(
  BuildContext context, {
  required Event event,
  required CoupleProfile profile,
}) => _showEventSheet(
  context,
  date: event.date,
  profile: profile,
  initial: event,
);

Future<Event?> _showEventSheet(
  BuildContext context, {
  required DateTime date,
  required CoupleProfile profile,
  Event? initial,
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
    builder: (context) =>
        _AddEventSheet(date: date, profile: profile, initial: initial),
  );
}

/// 컨트롤러를 시트 수명에 묶어, 닫힘 애니메이션 도중 dispose되지 않게 한다.
class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet({
    required this.date,
    required this.profile,
    this.initial,
  });

  final DateTime date;
  final CoupleProfile profile;

  /// 수정할 일정. null이면 새 일정 등록.
  final Event? initial;

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _memoController = TextEditingController();
  final _checklistController = TextEditingController();
  final _checklistFocus = FocusNode();

  late DateTime _startDate = DateUtils.dateOnly(widget.date);
  late DateTime _endDate = _startDate;
  EventOwner _owner = EventOwner.together;
  EventCategory _category = EventCategory.date;
  bool _allDay = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 13, minute: 0);
  final List<String> _checklist = [];
  bool _addingChecklistItem = false;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final event = widget.initial;
    if (event == null) return;
    _titleController.text = event.title;
    _locationController.text = event.location ?? '';
    _memoController.text = event.memo ?? '';
    _startDate = DateUtils.dateOnly(event.date);
    _endDate = DateUtils.dateOnly(event.lastDate);
    _owner = event.owner;
    _category = event.category;
    _allDay = event.startTime == null;
    if (event.startTime case final start?) _startTime = start;
    if (event.endTime case final end?) _endTime = end;
    _checklist.addAll(event.checklist);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    _checklistController.dispose();
    _checklistFocus.dispose();
    super.dispose();
  }

  static DateTime _at(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  DateTime get _start => _at(_startDate, _startTime);
  DateTime get _end => _at(_endDate, _endTime);

  int get _durationMinutes => _end.difference(_start).inMinutes;

  /// 시작일과 종료일을 모두 포함한 날 수.
  int get _dayCount =>
      DateTime.utc(_endDate.year, _endDate.month, _endDate.day)
          .difference(
            DateTime.utc(_startDate.year, _startDate.month, _startDate.day),
          )
          .inDays +
      1;

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      (_allDay ? _dayCount >= 1 : _durationMinutes > 0);

  /// 시작을 [newStart]로 옮기면서 기존 길이를 유지하도록 종료도 함께 민다.
  void _moveStart(DateTime newStart) {
    final length = _durationMinutes > 0 ? _durationMinutes : 60;
    final end = newStart.add(Duration(minutes: length));
    _startDate = DateUtils.dateOnly(newStart);
    _startTime = TimeOfDay.fromDateTime(newStart);
    _endDate = DateUtils.dateOnly(end);
    _endTime = TimeOfDay.fromDateTime(end);
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      // 종료일은 시작일 이전으로 고를 수 없다.
      firstDate: start ? DateTime(2020) : _startDate,
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _moveStart(_at(picked, _startTime));
      } else {
        _endDate = DateUtils.dateOnly(picked);
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _moveStart(_at(_startDate, picked));
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
        id:
            widget.initial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        date: _startDate,
        endDate: _dayCount > 1 ? _endDate : null,
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
                title: _editing ? '일정 수정' : '새로운 일정 등록',
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
                label: _editing
                    ? '수정 완료'
                    : _owner == EventOwner.together
                    ? '우리 일정 등록하기'
                    : '일정 등록하기',
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
          // 수정할 때는 내용을 먼저 볼 수 있게 키보드를 띄우지 않는다.
          autofocus: !_editing,
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
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
    final duration = _durationMinutes;
    final days = _dayCount;

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
          _DateTimeRow(
            label: '시작',
            date: dateFormat.format(_startDate),
            time: _allDay ? null : formatTime(_startTime),
            onDateTap: () => _pickDate(start: true),
            onTimeTap: () => _pickTime(start: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DateTimeRow(
            label: '종료',
            date: dateFormat.format(_endDate),
            time: _allDay ? null : formatTime(_endTime),
            onDateTap: () => _pickDate(start: false),
            onTimeTap: () => _pickTime(start: false),
          ),
          if (_allDay && days > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '총 $days일 동안의 소중한 시간 💕',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!_allDay) ...[
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
                        : '종료 일시가 시작 일시보다 빨라요',
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
    final d = minutes ~/ (24 * 60);
    final h = minutes % (24 * 60) ~/ 60;
    final m = minutes % 60;
    return [
      if (d > 0) '$d일',
      if (h > 0) '$h시간',
      if (m > 0 || (d == 0 && h == 0)) '$m분',
    ].join(' ');
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
