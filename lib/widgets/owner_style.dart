import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/app_theme.dart';

/// 일정 주인별 색. 디자인 시스템의 "파트너 점" 규칙을 따른다.
extension EventOwnerStyle on EventOwner {
  Color get dotColor => switch (this) {
    EventOwner.together => AppColors.primaryContainer,
    EventOwner.me => AppColors.secondary,
    EventOwner.partner => AppColors.tertiaryContainer,
  };

  /// 선택된 날짜(어두운 배경) 위에 올라가는 점 색.
  Color get dotColorOnDark => switch (this) {
    EventOwner.together => AppColors.inversePrimary,
    EventOwner.me => AppColors.secondaryFixed,
    EventOwner.partner => AppColors.tertiaryFixed,
  };

  Color get chipBackground => switch (this) {
    EventOwner.together => AppColors.secondaryFixed,
    EventOwner.me => AppColors.surfaceContainer,
    EventOwner.partner => AppColors.tertiaryFixed,
  };

  Color get chipForeground => switch (this) {
    EventOwner.together => AppColors.onSecondaryFixedVariant,
    EventOwner.me => AppColors.onSurfaceVariant,
    EventOwner.partner => AppColors.onTertiaryContainer,
  };
}
