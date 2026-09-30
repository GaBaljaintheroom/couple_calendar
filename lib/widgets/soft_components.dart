import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 흰 카드 + 따뜻한 그림자 (Elevation Level 1).
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// 작은 알약 모양 라벨 (D-day, 주인 표시 등).
class PillLabel extends StatelessWidget {
  const PillLabel({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.bold = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          color: foreground,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
