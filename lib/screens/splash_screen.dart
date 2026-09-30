import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

/// 네이티브 스플래시(같은 배경·같은 크기의 로고)에서 이어지는 시작 애니메이션.
/// 끝나면 [child]로 부드럽게 넘어간다.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _done
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : BrandSplash(
              key: const ValueKey('splash'),
              onFinished: () => setState(() => _done = true),
            ),
    );
  }
}

/// 로고가 살짝 커지며 한 번 두근거리고, 아래 문구가 떠오른다.
/// [onFinished]가 없으면 애니메이션 없이 멈춘 화면 (데이터 불러오는 중에 쓴다).
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key, this.onFinished, this.showProgress = false});

  final VoidCallback? onFinished;
  final bool showProgress;

  /// 네이티브 스플래시 로고와 같은 크기 (splash_logo.png 512px ÷ 4배율).
  static const logoSize = 128.0;

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  // 0.00–0.35 로고가 살짝 떠오름, 0.40–0.62 두근, 0.30–0.70 문구, 0.2–0.8 배경 빛.
  late final _lift = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.35, curve: Curves.easeOutBack),
  );
  late final _beat =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1, end: 1.09), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.09, end: 0.98), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0.98, end: 1), weight: 1),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.62, curve: Curves.easeInOut),
        ),
      );
  late final _text = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
  );
  late final _glow = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.onFinished == null) {
      _controller.value = 1;
    } else {
      _controller.forward().whenComplete(() {
        if (mounted) widget.onFinished!();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.splashBackground,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final lift = _lift.value;
          // 화면 전체를 기준으로 가운데 정렬해야 네이티브 스플래시 로고와 같은 자리에 온다.
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // 로고 뒤로 번지는 코랄빛
              Center(
                child: Opacity(
                  opacity: _glow.value,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryFixed,
                          AppColors.primaryFixed.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 로고는 네이티브 스플래시와 같은 자리(화면 정중앙)에서 시작한다.
              Center(
                child: Transform.translate(
                  offset: Offset(0, -18 * lift),
                  child: Transform.scale(
                    scale: (0.96 + 0.04 * lift) * _beat.value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          BrandSplash.logoSize * 0.23,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD9654A)
                                .withValues(alpha: 0.2 * lift.clamp(0, 1)),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const AppLogo(size: BrandSplash.logoSize),
                    ),
                  ),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(
                    0,
                    BrandSplash.logoSize / 2 + 44 - 12 * _text.value,
                  ),
                  child: Opacity(
                    opacity: _text.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '둘만의 일정과 기념일을 함께',
                          style: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.showProgress) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
