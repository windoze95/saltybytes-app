import 'package:flutter/material.dart';

import '../../core/widgets/animated_logo.dart';

/// Shown while the stored session is restored on cold start.
///
/// Cold start used to flash the login screen for however long the session
/// check took (a keychain read plus a network round-trip) before landing on
/// home. The router now parks here until auth resolves, then leaves and
/// never comes back.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          // Same gradient as the login/register screens so the handoff
          // between splash and either destination is seamless.
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedLogo(fontSize: 36),
              const SizedBox(height: 28),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
