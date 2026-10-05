import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/couple_profile.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import 'owner_style.dart';
import 'soft_components.dart';

/// 선택한 날짜의 일정을 왼쪽 세로선 + 점이 있는 타임라인으로 보여준다.
/// 카드를 왼쪽으로 밀면 수정·삭제 버튼이 나온다.
class EventTimeline extends StatelessWidget {
  const EventTimeline({
    super.key,
    required this.events,
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Event> events;
  final CoupleProfile profile;
  final ValueChanged<Event> onEdit;
  final ValueChanged<Event> onDelete;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
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
              '일정이 없어요',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 한 번에 하나의 카드만 열려 있게 한다.
    return SlidableAutoCloseBehavior(
      child: Column(
        children: [
          for (final (index, event) in events.indexed)
            _TimelineRow(
              key: ValueKey(event.id),
              event: event,
              ownerName: profile.nameOf(event.owner),
              isFirst: index == 0,
              isLast: index == events.length - 1,
              onEdit: () => onEdit(event),
              onDelete: () => onDelete(event),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    super.key,
    required this.event,
    required this.ownerName,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  final Event event;
  final String ownerName;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _railWidth = 28.0;
  static const _dotTop = 24.0;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railWidth,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: isFirst ? _dotTop : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? _dotTop : null,
                  child: Container(
                    width: 2,
                    color: AppColors.surfaceContainerHigh,
                  ),
                ),
                Positioned(
                  top: _dotTop - 5,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: event.owner.dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.gutter),
              child: Slidable(
                groupTag: 'event-timeline',
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.42,
                  children: [
                    _SwipeAction(
                      label: '수정',
                      icon: Icons.edit_outlined,
                      background: AppColors.surfaceContainerHigh,
                      foreground: AppColors.onSurface,
                      onPressed: onEdit,
                    ),
                    _SwipeAction(
                      label: '삭제',
                      icon: Icons.delete_outline,
                      background: AppColors.error,
                      foreground: AppColors.onError,
                      onPressed: onDelete,
                    ),
                  ],
                ),
                child: _EventCard(event: event, ownerName: ownerName),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드를 밀었을 때 오른쪽에 나오는 둥근 버튼. 누르면 카드를 닫고 [onPressed]를 부른다.
class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // ActionPane의 자식은 Flexible이어야 해서, 카드와의 간격은 안쪽 여백으로 준다.
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Slidable.of(context)?.close();
              onPressed();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: foreground),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.ownerName});

  final Event event;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillLabel(
                text: ownerName,
                background: event.owner.chipBackground,
                foreground: event.owner.chipForeground,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _timeRange(event),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.gutter),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.category.emoji, style: AppTextStyles.bodyLg),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.title,
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (event.memo case final memo?) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.gutter),
              child: Text(
                memo,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (event.location case final location?)
            _DetailRow(icon: Icons.place_outlined, text: location),
          if (event.checklist.isNotEmpty)
            _DetailRow(
              icon: Icons.checklist,
              text:
                  '챙길 것 ${event.checklist.length}개 · '
                  '${event.checklist.join(', ')}',
            ),
        ],
      ),
    );
  }

  static String _timeRange(Event event) {
    final start = event.startTime;
    final end = event.endTime;
    if (event.isMultiDay) {
      final from = _monthDay(event.date);
      final to = _monthDay(event.lastDate);
      if (start == null) return '$from - $to 하루 종일';
      return '$from ${formatTime(start)} - '
          '$to${end == null ? '' : ' ${formatTime(end)}'}';
    }
    if (start == null) return '하루 종일';
    return end == null
        ? formatTime(start)
        : '${formatTime(start)} - ${formatTime(end)}';
  }

  static String _monthDay(DateTime d) => '${d.month}/${d.day}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        right: AppSpacing.gutter,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
