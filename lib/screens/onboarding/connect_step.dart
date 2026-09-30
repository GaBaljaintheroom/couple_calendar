import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/couple_service.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import 'onboarding_widgets.dart';

/// 온보딩 2단계 (Stitch "온보딩 2단계: 커플 연결").
/// 상대가 코드를 입력하면 커플 문서가 바뀌고, 상위 화면이 다음 단계로 넘어간다.
class ConnectStep extends StatefulWidget {
  const ConnectStep({
    super.key,
    required this.me,
    required this.pendingCouple,
    required this.coupleService,
    required this.onBack,
  });

  final UserProfile me;

  /// 내가 만든, 상대를 기다리는 중인 커플 (없으면 null).
  final Couple? pendingCouple;
  final CoupleService coupleService;
  final VoidCallback onBack;

  @override
  State<ConnectStep> createState() => _ConnectStepState();
}

class _ConnectStepState extends State<ConnectStep> {
  final _codeController = TextEditingController();
  bool _creating = false;
  bool _joining = false;
  String? _joinError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createCode() async {
    setState(() => _creating = true);
    try {
      await widget.coupleService.createInvite(
        widget.me,
        pendingCouple: widget.pendingCouple,
      );
    } catch (e) {
      _showSnack('코드를 만들지 못했어요. ($e)');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _join() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _joining = true;
      _joinError = null;
    });
    try {
      await widget.coupleService.joinWithCode(widget.me, _codeController.text);
    } on InviteException catch (e) {
      setState(() => _joinError = e.message);
    } catch (e) {
      setState(() => _joinError = '연결하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final couple = widget.pendingCouple;
    final code = couple?.inviteCode;
    final expiresAt = couple?.inviteExpiresAt;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(step: 2, onBack: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  0,
                  AppSpacing.margin,
                  AppSpacing.xl,
                ),
                children: [
                  const _StageChip(),
                  const SizedBox(height: AppSpacing.sm),
                  Text('우리 둘을 연결해요 💞', style: AppTextStyles.displayLg),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '한 명이 코드를 만들고, 다른 한 명이 입력하면\n우리의 실시간 캘린더가 열려요.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ConnectionIllustration(me: widget.me),
                  const SizedBox(height: AppSpacing.lg),
                  _MyCodeCard(
                    code: code,
                    expiresAt: expiresAt,
                    creating: _creating,
                    onCreate: _createCode,
                    onCopy: () async {
                      await Clipboard.setData(ClipboardData(text: code!));
                      _showSnack('코드를 복사했어요');
                    },
                    onExpired: () => setState(() {}),
                    onShare: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            '데이로그에서 함께해요 💞\n'
                            '앱에서 초대 코드 [$code] 를 입력해 주세요. (24시간 동안 유효)',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _OrDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  _EnterCodeCard(
                    controller: _codeController,
                    joining: _joining,
                    error: _joinError,
                    onJoin: _join,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondaryFixed,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 14,
              color: AppColors.onSecondaryFixedVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '커플 연결 단계',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSecondaryFixedVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 나 ─ ♡ ─ (미래의 연인)
class _ConnectionIllustration extends StatelessWidget {
  const _ConnectionIllustration({required this.me});

  final UserProfile me;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          const Positioned(
            left: 60,
            right: 60,
            top: 30,
            height: 20,
            child: CustomPaint(painter: _DashedArcPainter()),
          ),
          Align(
            alignment: const Alignment(0, -0.45),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondaryFixed, width: 2),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 18,
                color: AppColors.primaryContainer,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: _Person(
              label: '나 (${me.name})',
              highlighted: true,
              child: ProfileAvatar(
                photoUrl: me.photoUrl,
                size: 80,
                borderWidth: 3,
                borderColor: AppColors.primaryContainer,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: _Person(
              label: '연인',
              highlighted: false,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.outlineVariant, width: 2),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 32,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({
    required this.label,
    required this.highlighted,
    required this.child,
  });

  final String label;
  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm.copyWith(
                  color: highlighted
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedArcPainter extends CustomPainter {
  const _DashedArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryContainer
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width / 2,
        -size.height,
        size.width,
        size.height,
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.margin),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.headlineMd)),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _MyCodeCard extends StatelessWidget {
  const _MyCodeCard({
    required this.code,
    required this.expiresAt,
    required this.creating,
    required this.onCreate,
    required this.onCopy,
    required this.onShare,
    required this.onExpired,
  });

  final String? code;
  final DateTime? expiresAt;
  final bool creating;
  final VoidCallback onCreate;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context) {
    final expired = expiresAt != null && !expiresAt!.isAfter(DateTime.now());
    final hasCode = code != null && !expired;

    return _Card(
      icon: Icons.key_outlined,
      title: '내 초대 코드',
      trailing: hasCode
          ? _CountdownPill(expiresAt: expiresAt!, onExpired: onExpired)
          : null,
      children: hasCode
          ? [
              Row(
                children: [
                  for (final (i, ch) in code!.split('').indexed) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(child: _CodeBox(char: ch)),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(
                          color: AppColors.secondaryContainer,
                        ),
                      ),
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: const Text('코드 복사'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onShare,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('공유하기'),
                    ),
                  ),
                ],
              ),
              const Divider(
                height: AppSpacing.xl,
                color: AppColors.surfaceContainerHigh,
              ),
              const _WaitingIndicator(),
            ]
          : [
              Text(
                expired
                    ? '코드가 만료됐어요. 새 코드를 만들어 상대방에게 보내 주세요.'
                    : '코드를 만들어 상대방에게 보내 주세요. 24시간 동안 유효해요.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: creating ? null : onCreate,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.add, size: 18),
                label: Text(expired ? '새 코드 만들기' : '초대 코드 만들기'),
              ),
            ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.char});

  final String char;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.85,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.secondaryFixed),
        ),
        child: Text(
          char,
          style: AppTextStyles.headlineLg.copyWith(
            color: AppColors.primaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 만료까지 남은 시간을 1초마다 갱신한다.
class _CountdownPill extends StatefulWidget {
  const _CountdownPill({required this.expiresAt, required this.onExpired});

  final DateTime expiresAt;
  final VoidCallback onExpired;

  @override
  State<_CountdownPill> createState() => _CountdownPillState();
}

class _CountdownPillState extends State<_CountdownPill> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!widget.expiresAt.isAfter(DateTime.now())) {
        _timer.cancel();
        widget.onExpired();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var left = widget.expiresAt.difference(DateTime.now());
    if (left.isNegative) left = Duration.zero;
    String two(int n) => n.toString().padLeft(2, '0');
    final text =
        '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 14,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingIndicator extends StatefulWidget {
  const _WaitingIndicator();

  @override
  State<_WaitingIndicator> createState() => _WaitingIndicatorState();
}

class _WaitingIndicatorState extends State<_WaitingIndicator>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            '상대방이 코드를 입력하길 기다리는 중...',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '또는',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
      ],
    );
  }
}

class _EnterCodeCard extends StatelessWidget {
  const _EnterCodeCard({
    required this.controller,
    required this.joining,
    required this.error,
    required this.onJoin,
  });

  final TextEditingController controller;
  final bool joining;
  final String? error;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return _Card(
      icon: Icons.lock_open_outlined,
      title: '상대방 코드 입력',
      children: [
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          maxLength: CoupleService.codeLength,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            _UpperCaseFormatter(),
          ],
          style: AppTextStyles.headlineLg.copyWith(
            letterSpacing: 8,
            color: AppColors.primary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '예: W4X8P2',
            hintStyle: AppTextStyles.headlineMd.copyWith(
              color: AppColors.outlineVariant,
              letterSpacing: 4,
            ),
          ),
          onSubmitted: (_) => onJoin(),
        ),
        const SizedBox(height: 6),
        Text(
          error ?? '* 연인에게 전달받은 영문/숫자 6자리를 적어주세요.',
          style: AppTextStyles.labelSm.copyWith(
            color: error == null ? AppColors.onSurfaceVariant : AppColors.error,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final ready =
                controller.text.length == CoupleService.codeLength && !joining;
            return FilledButton.icon(
              onPressed: ready ? onJoin : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.secondaryFixed,
                disabledForegroundColor: AppColors.onPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: joining
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.favorite_border, size: 18),
              label: const Text('연결하기'),
            );
          },
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
