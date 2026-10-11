import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'owner_style.dart';
import 'soft_components.dart';

/// 색 고르기 결과. [color]가 null이면 기본 색으로 되돌린다.
class ColorChoice {
  const ColorChoice(this.color);

  final Color? color;
}

/// 일정 주인 색을 고르는 바텀시트. 닫으면 null, 고르면 [ColorChoice]를 반환한다.
Future<ColorChoice?> showOwnerColorSheet(
  BuildContext context, {
  required String title,
  required String previewLabel,
  required Color? current,
  required OwnerStyle defaultStyle,
}) {
  return showModalBottomSheet<ColorChoice>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => _OwnerColorSheet(
      title: title,
      previewLabel: previewLabel,
      current: current,
      defaultStyle: defaultStyle,
    ),
  );
}

class _OwnerColorSheet extends StatelessWidget {
  const _OwnerColorSheet({
    required this.title,
    required this.previewLabel,
    required this.current,
    required this.defaultStyle,
  });

  final String title;
  final String previewLabel;
  final Color? current;
  final OwnerStyle defaultStyle;

  @override
  Widget build(BuildContext context) {
    final style = current == null ? defaultStyle : OwnerStyle.from(current!);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          0,
          AppSpacing.margin,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AppTextStyles.headlineMd)),
                PillLabel(
                  text: previewLabel,
                  background: style.chipBackground,
                  foreground: style.chipForeground,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '캘린더 점과 일정 이름표에 이 색이 쓰여요.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.gutter,
              runSpacing: AppSpacing.gutter,
              children: [
                _Swatch(
                  color: defaultStyle.dot,
                  label: '기본',
                  selected: current == null,
                  onTap: () => Navigator.pop(context, const ColorChoice(null)),
                ),
                for (final color in ownerColorChoices)
                  _Swatch(
                    color: color,
                    selected: current?.toARGB32() == color.toARGB32(),
                    onTap: () => Navigator.pop(context, ColorChoice(color)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label ?? '색',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: selected
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : label == null
                  ? null
                  : Text(
                      label!,
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
