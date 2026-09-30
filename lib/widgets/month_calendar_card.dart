import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/event.dart';
import '../theme/app_theme.dart';
import 'owner_style.dart';
import 'soft_components.dart';

/// 월간 캘린더 카드. 날짜 아래에 일정 주인별 점을 찍는다.
class MonthCalendarCard extends StatefulWidget {
  const MonthCalendarCard({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.eventLoader,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<Event> Function(DateTime day) eventLoader;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  @override
  State<MonthCalendarCard> createState() => _MonthCalendarCardState();
}

class _MonthCalendarCardState extends State<MonthCalendarCard> {
  PageController? _pageController;

  static const _pageDuration = Duration(milliseconds: 300);

  void _goToToday() {
    final now = DateTime.now();
    widget.onDaySelected(now, now);
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            focusedDay: widget.focusedDay,
            onToday: _goToToday,
            onPrevious: () => _pageController?.previousPage(
              duration: _pageDuration,
              curve: Curves.easeOut,
            ),
            onNext: () => _pageController?.nextPage(
              duration: _pageDuration,
              curve: Curves.easeOut,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TableCalendar<Event>(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: widget.focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, widget.selectedDay),
            eventLoader: widget.eventLoader,
            headerVisible: false,
            availableGestures: AvailableGestures.horizontalSwipe,
            daysOfWeekHeight: 28,
            rowHeight: 52,
            onCalendarCreated: (controller) => _pageController = controller,
            onDaySelected: widget.onDaySelected,
            onPageChanged: widget.onPageChanged,
            calendarBuilders: CalendarBuilders<Event>(
              dowBuilder: (context, day) => _DowLabel(day: day),
              defaultBuilder: (context, day, _) =>
                  _buildCell(day, _CellKind.normal),
              todayBuilder: (context, day, _) =>
                  _buildCell(day, _CellKind.today),
              selectedBuilder: (context, day, _) =>
                  _buildCell(day, _CellKind.selected),
              outsideBuilder: (context, day, _) =>
                  _buildCell(day, _CellKind.outside),
              // 점은 셀 안에서 직접 그린다.
              markerBuilder: (context, day, events) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(DateTime day, _CellKind kind) {
    final owners = widget.eventLoader(day).map((e) => e.owner).toSet();
    return _DayCell(day: day, kind: kind, owners: owners);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.focusedDay,
    required this.onToday,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime focusedDay;
  final VoidCallback onToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          DateFormat('yyyy. MM').format(focusedDay),
          style: AppTextStyles.headlineMd.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Material(
          color: AppColors.surfaceContainer,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onToday,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Text('오늘', style: AppTextStyles.labelSm),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: '이전 달',
          visualDensity: VisualDensity.compact,
          color: AppColors.onSurfaceVariant,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        IconButton(
          tooltip: '다음 달',
          visualDensity: VisualDensity.compact,
          color: AppColors.onSurfaceVariant,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}

class _DowLabel extends StatelessWidget {
  const _DowLabel({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final color = switch (day.weekday) {
      DateTime.sunday => AppColors.error,
      DateTime.saturday => AppColors.primary,
      _ => AppColors.outline,
    };
    return Center(
      child: Text(
        DateFormat.E('ko_KR').format(day),
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum _CellKind { normal, today, selected, outside }

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.kind, required this.owners});

  final DateTime day;
  final _CellKind kind;
  final Set<EventOwner> owners;

  @override
  Widget build(BuildContext context) {
    final selected = kind == _CellKind.selected;

    final numberColor = selected
        ? AppColors.inverseOnSurface
        : switch (day.weekday) {
            DateTime.sunday => AppColors.error,
            DateTime.saturday => AppColors.primary,
            _ => AppColors.onSurface,
          };

    final decoration = switch (kind) {
      _CellKind.selected => BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      _CellKind.today => BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      _ => null,
    };

    final cell = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: decoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: AppTextStyles.bodyMd.copyWith(
              color: numberColor,
              fontWeight: switch (kind) {
                _CellKind.selected => FontWeight.w700,
                _CellKind.today => FontWeight.w600,
                _ => FontWeight.w400,
              },
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final owner in EventOwner.values)
                  if (owners.contains(owner))
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: selected ? owner.dotColorOnDark : owner.dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );

    return kind == _CellKind.outside
        ? Opacity(opacity: 0.35, child: cell)
        : cell;
  }
}
