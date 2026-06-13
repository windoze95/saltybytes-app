import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/auth/login_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildLoginScreen() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_FakeAuthNotifier.new),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders username/email text field', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // The label is "Username or Email"
      expect(find.text('Username or Email'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('renders password text field with obscure toggle',
        (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      // The obscure toggle icon (initially visibility_off since _obscurePassword starts true)
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('renders Sign In button and no demo mode button',
        (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      // Demo mode authenticated without tokens, causing a 401 force-logout
      // loop; the button was removed.
      expect(find.text('Browse Demo'), findsNothing);
    });
  });
}

/// Fake auth notifier that stays unauthenticated.
class _FakeAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {
  @override
  Future<AuthStatus> build() async {
    return AuthStatus.unauthenticated;
  }

  @override
  Future<void> login({required String username, required String password}) async {}

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}
}
