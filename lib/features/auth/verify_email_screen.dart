import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/widgets/animated_logo.dart';

/// Entry screen for the 6-digit signup verification code.
///
/// Reached right after signup (router redirect) and from the home banner
/// while the account is unverified. Skippable — only AI features are gated
/// until verified.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;
  String? _infoMessage;
  int _resendSecondsLeft = 60; // signup just sent one — start cooled down
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _resendSecondsLeft--;
        if (_resendSecondsLeft <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code from the email');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(apiClientProvider).post(
        ApiEndpoints.emailVerificationConfirm,
        data: {'code': code},
      );
      if (!mounted) return;

      ref.read(authStateProvider.notifier).markEmailVerificationHandled();
      // Refresh the cached profile so the home banner disappears.
      unawaited(ref.read(currentUserProvider.notifier).refreshProfile());
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            userFacingErrorMessage(e, 'Could not verify the code. Try again.');
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(apiClientProvider).post(ApiEndpoints.emailVerification);
      if (!mounted) return;
      setState(() {
        _infoMessage = 'Sent! Check your inbox (and spam).';
        _resendSecondsLeft = 60;
      });
      _startResendCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            userFacingErrorMessage(e, 'Could not send the email. Try again.');
      });
    }
  }

  void _skipForNow() {
    ref.read(authStateProvider.notifier).markEmailVerificationHandled();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(currentUserProvider).valueOrNull?.email;
    final canResend = _resendSecondsLeft <= 0;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? const [
                    Colors.white,
                    Color(0xFFFFF0F3),
                    Color(0xFFF5E6FF),
                  ]
                : [
                    theme.colorScheme.surface,
                    const Color(0xFF1E1020),
                    const Color(0xFF181225),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AnimatedLogo(fontSize: 32)),
                  const SizedBox(height: 20),
                  Text(
                    'Check your email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email == null
                        ? 'We sent a 6-digit code to your email address.'
                        : 'We sent a 6-digit code to $email.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (_errorMessage != null) ...[
                    _MessageBox(
                      message: _errorMessage!,
                      color: theme.colorScheme.error,
                      icon: Icons.error_outline,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_infoMessage != null) ...[
                    _MessageBox(
                      message: _infoMessage!,
                      color: theme.colorScheme.primary,
                      icon: Icons.mark_email_read_outlined,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                    ),
                    onSubmitted: (_) => _submitCode(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitCode,
                      child: _submitting
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: canResend ? _resendCode : null,
                    child: Text(
                      canResend
                          ? 'Resend code'
                          : 'Resend code in ${_resendSecondsLeft}s',
                    ),
                  ),
                  TextButton(
                    onPressed: _skipForNow,
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
