import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/auth/register_screen.dart';

import '../../helpers/test_helpers.dart';

/// Records register() calls so tests can assert on what was submitted.
class _RecordingAuthNotifier extends FakeAuthNotifier {
  _RecordingAuthNotifier() : super(AuthStatus.unauthenticated);

  final List<Map<String, String>> registerCalls = [];

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    registerCalls.add({
      'username': username,
      'email': email,
      'password': password,
    });
  }
}

/// Leaves the auth state in AsyncError with an ApiError after register(),
/// mirroring what AuthNotifier does when the backend rejects the signup.
class _ErroringAuthNotifier extends FakeAuthNotifier {
  _ErroringAuthNotifier() : super(AuthStatus.unauthenticated);

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = AsyncError(
      const ApiError(message: 'Username already taken', statusCode: 409),
      StackTrace.current,
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    AuthNotifier Function() notifierFactory,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(notifierFactory),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String username = 'chefmike',
    String email = 'mike@example.com',
    String password = 'Password1',
    String? confirmPassword,
  }) async {
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), username);
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), password);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        confirmPassword ?? password);
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.widgetWithText(ElevatedButton, 'Create Account');
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('RegisterScreen validation', () {
    testWidgets('blocks submit when all fields are empty', (tester) async {
      final notifier = _RecordingAuthNotifier();
      await pumpScreen(tester, () => notifier);

      await submit(tester);

      expect(find.text('Please enter a username'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(notifier.registerCalls, isEmpty);
    });

    testWidgets('rejects an invalid email address', (tester) async {
      final notifier = _RecordingAuthNotifier();
      await pumpScreen(tester, () => notifier);

      await fillForm(tester, email: 'not-an-email');
      await submit(tester);

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(notifier.registerCalls, isEmpty);
    });

    testWidgets('rejects a weak password', (tester) async {
      final notifier = _RecordingAuthNotifier();
      await pumpScreen(tester, () => notifier);

      await fillForm(tester, password: 'short');
      await submit(tester);

      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(notifier.registerCalls, isEmpty);
    });

    testWidgets('rejects a password without an uppercase letter',
        (tester) async {
      final notifier = _RecordingAuthNotifier();
      await pumpScreen(tester, () => notifier);

      await fillForm(tester, password: 'password1');
      await submit(tester);

      expect(
          find.text('Include at least one uppercase letter'), findsOneWidget);
      expect(notifier.registerCalls, isEmpty);
    });

    testWidgets('rejects mismatched confirm password', (tester) async {
      final notifier = _RecordingAuthNotifier();
      await pumpScreen(tester, () => notifier);

      await fillForm(tester,
          password: 'Password1', confirmPassword: 'Password2');
      await submit(tester);

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(notifier.registerCalls, isEmpty);
    });
  });

  group('RegisterScreen submission', () {
    testWidgets('valid form calls register with trimmed values',
        (tester) async {
      final notifier = _RecordingAuthNotifier();
      await pumpScreen(tester, () => notifier);

      await fillForm(
        tester,
        username: '  chefmike  ',
        email: ' mike@example.com ',
        password: 'Password1',
      );
      await submit(tester);

      expect(notifier.registerCalls, hasLength(1));
      expect(notifier.registerCalls.single['username'], 'chefmike');
      expect(notifier.registerCalls.single['email'], 'mike@example.com');
      // Password is sent verbatim (never trimmed).
      expect(notifier.registerCalls.single['password'], 'Password1');
    });

    testWidgets('shows the API error message when registration fails',
        (tester) async {
      await pumpScreen(tester, _ErroringAuthNotifier.new);

      await fillForm(tester);
      await submit(tester);

      expect(find.text('Username already taken'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
