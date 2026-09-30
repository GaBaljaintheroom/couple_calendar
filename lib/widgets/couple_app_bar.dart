import 'package:flutter/material.dart';

import '../models/couple_profile.dart';
import '../theme/app_theme.dart';
import 'soft_components.dart';

/// 앱 공통 상단바: 캘린더 이름, D+일수, 내 프로필 버튼.
class CoupleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CoupleAppBar({super.key, required this.profile, this.onProfileTap});

  final CoupleProfile profile;

  /// 프로필 버튼을 누르면 내 프로필 수정 화면으로 간다.
  final VoidCallback? onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final dayCount = profile.dayCountOn(DateTime.now());
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: AppColors.surface.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: AppSpacing.margin,
      title: Row(
        children: [
          Flexible(
            child: Text(
              profile.calendarName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          PillLabel(
            text: 'D+$dayCount',
            background: AppColors.secondaryFixed,
            foreground: AppColors.onSecondaryFixedVariant,
          ),
        ],
      ),
      actions: [
        _ProfileButton(onTap: onProfileTap),
        const SizedBox(width: AppSpacing.margin),
      ],
    );
  }
}

/// 내 프로필 버튼.
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '내 프로필',
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 2),
            boxShadow: AppShadows.card,
          ),
          child: const Icon(
            Icons.person_outline,
            size: 18,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}
