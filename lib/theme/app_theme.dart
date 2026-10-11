import 'package:flutter/material.dart';

/// Google Stitch "Warm Modern Romantic" 디자인 시스템의 토큰.
/// (Stitch 프로젝트: Couple Shared Calendar App)

const _fontFamily = 'PlusJakartaSans';

abstract final class AppColors {
  static const surface = Color(0xFFFFF8F6);
  static const surfaceDim = Color(0xFFE2D8D6);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFCF1EF);
  static const surfaceContainer = Color(0xFFF6ECEA);
  static const surfaceContainerHigh = Color(0xFFF0E6E4);
  static const surfaceContainerHighest = Color(0xFFEAE0DE);
  static const onSurface = Color(0xFF1F1B1A);
  static const onSurfaceVariant = Color(0xFF55423E);
  static const inverseSurface = Color(0xFF352F2E);
  static const inverseOnSurface = Color(0xFFF9EEEC);
  static const outline = Color(0xFF88726D);
  static const outlineVariant = Color(0xFFDBC1BA);

  static const primary = Color(0xFF9A442D);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFE07A5F);
  static const onPrimaryContainer = Color(0xFF5B1604);
  static const inversePrimary = Color(0xFFFFB4A1);
  static const primaryFixed = Color(0xFFFFDBD2);
  static const onPrimaryFixedVariant = Color(0xFF7C2E19);

  static const secondary = Color(0xFF82514F);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFFBFBC);
  static const onSecondaryContainer = Color(0xFF7B4B49);
  static const secondaryFixed = Color(0xFFFFDAD8);
  static const onSecondaryFixedVariant = Color(0xFF673A39);

  static const tertiary = Color(0xFF695C54);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFA2938B);
  static const onTertiaryContainer = Color(0xFF372D26);
  static const tertiaryFixed = Color(0xFFF1DFD5);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const gutter = 12.0;
  static const md = 16.0;
  static const margin = 20.0;
  static const lg = 24.0;
  static const xl = 36.0;
}

abstract final class AppRadius {
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const full = 9999.0;
}

abstract final class AppShadows {
  /// Level 1: 카드
  static const card = [
    BoxShadow(color: Color(0x0A2B2625), blurRadius: 20, offset: Offset(0, 4)),
  ];

  /// Level 3: 플로팅 버튼·모달
  static const floating = [
    BoxShadow(color: Color(0x2EE07A5F), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

abstract final class AppTextStyles {
  static const displayLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    letterSpacing: -0.42,
  );
  static const headlineLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 30 / 24,
    letterSpacing: -0.24,
  );
  static const headlineMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 26 / 20,
  );
  static const bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );
  static const bodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );
  static const labelMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.24,
  );
  static const labelSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 14 / 11,
    letterSpacing: 0.33,
  );
}

/// 작은 버튼·이름표처럼 글자가 상자 가운데에 와야 할 때 쓰는 줄 높이.
///
/// 한글은 앱 글꼴에 없어 시스템 글꼴로 대신 그려지는데, 그 글꼴의 위아래 치수로
/// 줄 높이를 잡으면 iOS에서 글자가 1pt쯤 위로 뜬다. 앱 글꼴 기준으로 고정한다.
StrutStyle centeredStrut(TextStyle style) => StrutStyle.fromTextStyle(
  style.copyWith(leadingDistribution: TextLeadingDistribution.even),
  forceStrutHeight: true,
);

abstract final class AppTheme {
  static const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceDim: AppColors.surfaceDim,
    surfaceBright: AppColors.surface,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
    surfaceTint: AppColors.primary,
  );

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: const TextTheme(
      displaySmall: AppTextStyles.displayLg,
      headlineMedium: AppTextStyles.headlineLg,
      headlineSmall: AppTextStyles.headlineMd,
      titleLarge: AppTextStyles.headlineMd,
      bodyLarge: AppTextStyles.bodyLg,
      bodyMedium: AppTextStyles.bodyMd,
      labelLarge: AppTextStyles.labelMd,
      labelMedium: AppTextStyles.labelMd,
      labelSmall: AppTextStyles.labelSm,
    ).apply(bodyColor: AppColors.onSurface, displayColor: AppColors.onSurface),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceContainerLowest,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: Color(0xFFDDA19E)),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: Color(0xFFEBE5E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.primaryContainer),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainerLowest,
      indicatorColor: AppColors.primaryFixed,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTextStyles.labelSm.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
