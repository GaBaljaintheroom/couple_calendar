import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/couple_profile.dart';
import '../theme/app_theme.dart';
import 'soft_components.dart';

/// 다음 100일 단위 기념일까지 남은 날과 진행률.
class MilestoneCard extends StatelessWidget {
  const MilestoneCard({super.key, required this.profile, required this.today});

  final CoupleProfile profile;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final dayCount = profile.dayCountOn(today);
    final milestone = profile.nextHundredDayMilestone(today);
    final milestoneDate = profile.dateOfDay(milestone);
    final remaining = milestone - dayCount;
    final progress = (dayCount % 100) / 100;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$milestone일 기념일',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PillLabel(
                text: 'D-$remaining',
                background: AppColors.primaryFixed,
                foreground: AppColors.onPrimaryFixedVariant,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$dayCount일째 기록 중',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ),
              Text(
                '$milestone일 (${DateFormat('yyyy. MM. dd').format(milestoneDate)})',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
