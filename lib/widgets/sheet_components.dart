import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// 등록 바텀시트(일정·기념일)가 함께 쓰는 구성 요소.

/// 테두리 없이 채워진 입력칸 스타일.
InputDecoration filledInputDecoration({
  required String hint,
  required double radius,
  required EdgeInsets padding,
  required Color fill,
  TextStyle hintStyle = AppTextStyles.bodyMd,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide.none,
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: hintStyle.copyWith(color: AppColors.outlineVariant),
    filled: true,
    fillColor: fill,
    contentPadding: padding,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: AppColors.primaryContainer.withValues(alpha: 0.5),
      ),
    ),
  );
}

/// 드래그 핸들 + 닫기 / 제목 / 저장 헤더.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    required this.canSave,
    required this.onClose,
    required this.onSave,
  });

  final String title;
  final bool canSave;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.gutter,
        AppSpacing.margin,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              IconButton(
                tooltip: '닫기',
                onPressed: onClose,
                color: AppColors.onSurfaceVariant,
                icon: const Icon(Icons.close, size: 22),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineMd.copyWith(
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: canSave
                    ? AppColors.primaryFixed
                    : AppColors.surfaceContainer,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: canSave ? onSave : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Text(
                      '저장',
                      style: AppTextStyles.labelMd.copyWith(
                        color: canSave
                            ? AppColors.onPrimaryFixedVariant
                            : AppColors.outline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 시트 하단에 고정되는 큰 등록 버튼.
class SheetSubmitBar extends StatelessWidget {
  const SheetSubmitBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.favorite,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.margin,
        AppSpacing.gutter,
        AppSpacing.margin,
        AppSpacing.margin + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F2B2625),
            blurRadius: 20,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x47E07A5F),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.surfaceContainerHigh,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            textStyle: AppTextStyles.headlineMd.copyWith(fontSize: 18),
          ),
          icon: Icon(icon, size: 22),
          label: Text(label),
        ),
      ),
    );
  }
}

/// 연한 배경의 둥근 묶음 영역.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: child,
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
    );
  }
}
