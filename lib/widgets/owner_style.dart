import 'package:flutter/material.dart';

import '../models/couple_profile.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

/// 일정 주인 하나의 색 묶음 (캘린더 점, 이름표).
class OwnerStyle {
  const OwnerStyle({
    required this.dot,
    required this.dotOnDark,
    required this.chipBackground,
    required this.chipForeground,
  });

  /// 고른 색 하나로 나머지 색을 만든다. 이름표 배경은 연하게, 글자는 진하게.
  factory OwnerStyle.from(Color base) {
    final hsl = HSLColor.fromColor(base);
    return OwnerStyle(
      dot: base,
      dotOnDark: Color.lerp(base, Colors.white, 0.45)!,
      chipBackground: Color.lerp(base, Colors.white, 0.78)!,
      chipForeground: hsl
          .withLightness(hsl.lightness.clamp(0.0, 0.28))
          .toColor(),
    );
  }

  /// 색을 고르지 않았을 때. 디자인 시스템의 "파트너 점" 규칙을 따른다.
  factory OwnerStyle.defaultOf(EventOwner owner) => switch (owner) {
    EventOwner.together => const OwnerStyle(
      dot: AppColors.primaryContainer,
      dotOnDark: AppColors.inversePrimary,
      chipBackground: AppColors.secondaryFixed,
      chipForeground: AppColors.onSecondaryFixedVariant,
    ),
    EventOwner.me => const OwnerStyle(
      dot: AppColors.secondary,
      dotOnDark: AppColors.secondaryFixed,
      chipBackground: AppColors.surfaceContainer,
      chipForeground: AppColors.onSurfaceVariant,
    ),
    EventOwner.partner => const OwnerStyle(
      dot: AppColors.tertiaryContainer,
      dotOnDark: AppColors.tertiaryFixed,
      chipBackground: AppColors.tertiaryFixed,
      chipForeground: AppColors.onTertiaryContainer,
    ),
  };

  final Color dot;

  /// 선택된 날짜(어두운 배경) 위에 올라가는 점 색.
  final Color dotOnDark;
  final Color chipBackground;
  final Color chipForeground;
}

/// 고를 수 있는 색. 앱의 따뜻한 톤에 어울리면서 서로 잘 구분되는 색으로 골랐다.
const ownerColorChoices = <Color>[
  Color(0xFFE07A5F), // 코랄
  Color(0xFFE5989B), // 로즈
  Color(0xFFD4A373), // 카멜
  Color(0xFFE9C46A), // 머스타드
  Color(0xFF81B29A), // 세이지
  Color(0xFF2A9D8F), // 틸
  Color(0xFF6D9DC5), // 스카이
  Color(0xFF8E7DBE), // 라벤더
  Color(0xFF82514F), // 모카
  Color(0xFF6B705C), // 올리브
];

extension CoupleProfileStyle on CoupleProfile {
  OwnerStyle styleOf(EventOwner owner) {
    final custom = customColorOf(owner);
    return custom == null
        ? OwnerStyle.defaultOf(owner)
        : OwnerStyle.from(custom);
  }
}
