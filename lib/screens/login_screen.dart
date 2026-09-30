import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      // 성공하면 AuthGate가 로그인 상태를 보고 화면을 바꾼다.
      await widget.authService.signInWithGoogle();
    } on SignInCanceled {
      // 사용자가 창을 닫음
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인하지 못했어요. 잠시 후 다시 시도해 주세요.\n($e)')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryFixed, AppColors.surface],
            stops: [0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.floating,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 40,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '데이로그',
                  style: AppTextStyles.displayLg.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '둘만의 일정과 기념일을\n함께 기록해요',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(flex: 4),
                _GoogleButton(loading: _loading, onPressed: _signIn),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '로그인하면 서비스 이용약관과 개인정보 처리방침에 동의하게 돼요.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        shadows: AppShadows.card,
      ),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerLowest,
          disabledBackgroundColor: AppColors.surfaceContainerLowest,
          foregroundColor: AppColors.onSurface,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.outlineVariant),
          textStyle: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryContainer,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: const Color(0xFF4285F4),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  const Text('Google로 계속하기'),
                ],
              ),
      ),
    );
  }
}
