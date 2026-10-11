import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/demo_profile.dart';
import '../data/event_repository.dart';
import '../models/couple_profile.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/couple_app_bar.dart';
import '../widgets/event_timeline.dart';
import '../widgets/milestone_card.dart';
import '../widgets/month_calendar_card.dart';
import '../widgets/owner_style.dart';
import '../widgets/soft_components.dart';

/// 필터 칩 값. null이면 전체.
typedef OwnerFilter = EventOwner?;

class CalendarScreen extends StatefulWidget {
  CalendarScreen({
    super.key,
    CoupleProfile? profile,
    this.repository,
    this.onProfileTap,
  }) : profile = profile ?? demoCoupleProfile;

  final CoupleProfile profile;

  /// 없으면 예시 일정이 든 메모리 저장소를 쓴다 (테스트·미리보기용).
  final EventRepository? repository;
  final VoidCallback? onProfileTap;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  EventRepository? _fallbackRepository;
  EventRepository get _repository =>
      widget.repository ?? (_fallbackRepository ??= EventRepository.demo());
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  OwnerFilter _filter;

  /// 날짜를 누르면 이 위치(선택한 날 제목)까지 내려가 일정 목록을 보여준다.
  final _dayHeaderKey = GlobalKey();

  void _scrollToEvents(DateTime day) {
    if (_eventsOn(day).isEmpty) return;
    // 목록이 새 날짜로 다시 그려진 뒤에 움직인다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _dayHeaderKey.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _fallbackRepository?.dispose();
    super.dispose();
  }

  List<Event> _eventsOn(DateTime day) =>
      _repository.eventsOn(day, owners: _filter == null ? null : {_filter!});

  Future<void> _addEvent() async {
    final event = await showAddEventSheet(
      context,
      date: _selectedDay,
      profile: widget.profile,
    );
    if (event != null) _save(_repository.add(event));
  }

  Future<void> _editEvent(Event event) async {
    final edited = await showEditEventSheet(
      context,
      event: event,
      profile: widget.profile,
    );
    if (edited != null) _save(_repository.update(edited));
  }

  Future<void> _confirmDelete(Event event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('일정을 삭제하시겠습니까?', style: AppTextStyles.headlineMd),
        content: Text(
          '\'${event.title}\' 일정이 두 사람의 캘린더에서 모두 사라져요.',
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
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) _save(_repository.remove(event.id));
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

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return Scaffold(
      appBar: CoupleAppBar(profile: profile, onProfileTap: widget.onProfileTap),
      body: ListenableBuilder(
        listenable: _repository,
        builder: (context, _) {
          final selectedEvents = _eventsOn(_selectedDay);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.sm,
              AppSpacing.margin,
              AppSpacing.xl,
            ),
            children: [
              _OwnerFilterChips(
                profile: profile,
                selected: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: AppSpacing.md),
              MilestoneCard(profile: profile, today: DateTime.now()),
              const SizedBox(height: AppSpacing.md),
              MonthCalendarCard(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                profile: profile,
                eventLoader: _eventsOn,
                onDaySelected: (selected, focused) => setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                }),
                onDayTapped: _scrollToEvents,
                onPageChanged: (focused) =>
                    setState(() => _focusedDay = focused),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DayHeader(
                key: _dayHeaderKey,
                day: _selectedDay,
                count: selectedEvents.length,
                onAdd: _addEvent,
              ),
              const SizedBox(height: AppSpacing.gutter),
              EventTimeline(
                events: selectedEvents,
                profile: profile,
                onEdit: _editEvent,
                onDelete: _confirmDelete,
              ),
              const SizedBox(height: AppSpacing.lg),
              _QuickAddBar(onTap: _addEvent),
            ],
          );
        },
      ),
    );
  }
}

class _OwnerFilterChips extends StatelessWidget {
  const _OwnerFilterChips({
    required this.profile,
    required this.selected,
    required this.onSelected,
  });

  final CoupleProfile profile;
  final OwnerFilter selected;
  final ValueChanged<OwnerFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(label: '전체', value: null),
          for (final owner in EventOwner.values)
            _chip(label: profile.nameOf(owner), value: owner),
        ],
      ),
    );
  }

  Widget _chip({required String label, required OwnerFilter value}) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onSelected(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: profile.styleOf(value).dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: isSelected
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
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

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    super.key,
    required this.day,
    required this.count,
    required this.onAdd,
  });

  final DateTime day;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  DateFormat('M월 d일 EEEE', 'ko_KR').format(day),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PillLabel(
                text: '$count개의 일정',
                background: AppColors.secondaryFixed,
                foreground: AppColors.onSecondaryFixedVariant,
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('추가'),
        ),
      ],
    );
  }
}

/// 화면 하단의 빠른 기록 바.
class _QuickAddBar extends StatelessWidget {
  const _QuickAddBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppColors.surfaceContainerLowest,
        shape: StadiumBorder(),
        shadows: AppShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.margin, 6, 6, 6),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_calendar_outlined,
                  size: 20,
                  color: AppColors.outline,
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: Text(
                    '새로운 데이트나 일정 기록...',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ),
                Tooltip(
                  message: '일정 추가',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.floating,
                    ),
                    child: const Icon(Icons.add, color: AppColors.onPrimary),
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
