import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

const onboardingStepCount = 3;

/// 상단: (뒤로가기 또는 앱 이름) + "n / 3" + 진행 막대.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.step,
    this.onBack,
    this.stepLabels,
  });

  /// 1부터 시작.
  final int step;
  final VoidCallback? onBack;

  /// 진행 막대 아래 단계 이름 (선택).
  final List<String>? stepLabels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.margin,
        AppSpacing.sm,
        AppSpacing.margin,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    tooltip: '뒤로',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                    ),
                  )
                else
                  Text(
                    '데이로그',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$step',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                        const TextSpan(text: ' / $onboardingStepCount'),
                      ],
                    ),
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 1; i <= onboardingStepCount; i++) ...[
                if (i > 1) const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: i <= step
                              ? AppColors.primaryContainer
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      if (stepLabels case final labels?) ...[
                        const SizedBox(height: 6),
                        Text(
                          labels[i - 1],
                          style: AppTextStyles.labelSm.copyWith(
                            color: i == step
                                ? AppColors.primary
                                : AppColors.outline,
                            fontWeight: i == step
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 두 줄 제목. 둘째 줄은 강조색.
class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle({
    super.key,
    required this.line1,
    required this.line2,
    required this.subtitle,
  });

  final String line1;
  final String line2;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line1, style: AppTextStyles.displayLg),
        Text(
          line2,
          style: AppTextStyles.displayLg.copyWith(
            color: AppColors.primaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 화면 하단에 고정되는 큰 버튼.
class OnboardingButton extends StatelessWidget {
  const OnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.margin,
        AppSpacing.sm,
        AppSpacing.margin,
        AppSpacing.margin,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: enabled ? AppShadows.floating : null,
        ),
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.surfaceContainerHigh,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            textStyle: AppTextStyles.headlineMd.copyWith(fontSize: 18),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label),
                    if (icon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(icon, size: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// 원형 프로필 사진. 사진이 없으면 사람 아이콘.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    this.size = 48,
    this.borderWidth = 2,
    this.borderColor = AppColors.surfaceContainerLowest,
  });

  final String? photoUrl;
  final double size;
  final double borderWidth;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(color: borderColor, shape: BoxShape.circle),
      child: CircleAvatar(
        backgroundColor: AppColors.primaryFixed,
        foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
        // 사진을 못 불러오면 아래 기본 아이콘이 그대로 보인다.
        onForegroundImageError: photoUrl == null ? null : (_, _) {},
        child: Icon(Icons.person, size: size * 0.45, color: AppColors.primary),
      ),
    );
  }
}

/// 흰 입력 카드: 작은 라벨 + 내용.
class LabeledCard extends StatelessWidget {
  const LabeledCard({
    super.key,
    required this.label,
    required this.child,
    this.labelColor = AppColors.onSurfaceVariant,
    this.onTap,
  });

  final String label;
  final Widget child;
  final Color labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margin,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(color: labelColor),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
