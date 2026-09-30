import 'package:flutter/material.dart';

import '../models/couple_profile.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import 'owner_style.dart';
import 'soft_components.dart';

/// 선택한 날짜의 일정을 왼쪽 세로선 + 점이 있는 타임라인으로 보여준다.
class EventTimeline extends StatelessWidget {
  const EventTimeline({
    super.key,
    required this.events,
    required this.profile,
    required this.onDelete,
  });

  final List<Event> events;
  final CoupleProfile profile;
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

    return Column(
      children: [
        for (final (index, event) in events.indexed)
          _TimelineRow(
            event: event,
            ownerName: profile.nameOf(event.owner),
            isFirst: index == 0,
            isLast: index == events.length - 1,
            onDelete: () => onDelete(event),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.ownerName,
    required this.isFirst,
    required this.isLast,
    required this.onDelete,
  });

  final Event event;
  final String ownerName;
  final bool isFirst;
  final bool isLast;
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
              child: _EventCard(
                event: event,
                ownerName: ownerName,
                onDelete: onDelete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.ownerName,
    required this.onDelete,
  });

  final Event event;
  final String ownerName;
  final VoidCallback onDelete;

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
              PopupMenuButton<void>(
                tooltip: '더보기',
                icon: const Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: AppColors.outline,
                ),
                padding: EdgeInsets.zero,
                itemBuilder: (context) => [
                  PopupMenuItem(onTap: onDelete, child: const Text('삭제')),
                ],
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
    if (start == null) return '하루 종일';
    final end = event.endTime;
    return end == null
        ? formatTime(start)
        : '${formatTime(start)} - ${formatTime(end)}';
  }
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
