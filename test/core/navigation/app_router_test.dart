import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saltybytes_app/core/navigation/app_router.dart';
import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/auth/login_screen.dart';
import 'package:saltybytes_app/features/auth/splash_screen.dart';
import 'package:saltybytes_app/features/auth/verify_email_screen.dart';

import '../../helpers/test_helpers.dart';

/// Auth notifier whose build() stays pending until the test completes it,
/// and which can emit loading/error/data states on demand — the shapes the
/// real AuthNotifier goes through during cold start and login attempts.
class _ControlledAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {

  @override
  bool needsEmailVerification = false;

  @override
  void markEmailVerificationHandled() {
    needsEmailVerification = false;
  }
  _ControlledAuthNotifier(this._initial);

  final Completer<AuthStatus> _initial;

  @override
  Future<AuthStatus> build() => _initial.future;

  void emitLoading() => state = const AsyncValue<AuthStatus>.loading();

  void emitError(Object error) =>
      state = AsyncValue<AuthStatus>.error(error, StackTrace.current);

  void emitData(AuthStatus status) => state = AsyncValue.data(status);

  @override
  Future<void> login(
      {required String username, required String password}) async {}

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  (ProviderContainer, _ControlledAuthNotifier) buildHarness() {
    final completer = Completer<AuthStatus>();
    final notifier = _ControlledAuthNotifier(completer);
    final api = MockApiClient();
    when(() => api.get(any())).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/stub'),
      type: DioExceptionType.connectionError,
    ));
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith(() => notifier),
      apiClientProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    return (container, notifier);
  }

  Future<void> pumpApp(WidgetTester tester, ProviderContainer container) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(routerProvider),
        ),
      ),
    );
  }

  testWidgets(
      'cold start holds the splash screen while the session restore is '
      'pending — the login screen must never flash', (tester) async {
    final (container, notifier) = buildHarness();
    await pumpApp(tester, container);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    // Simulate a slow session check (keychain + network): still splash.
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    notifier._initial.complete(AuthStatus.unauthenticated);
    await tester.pump();
    // Ride out the page transition (can't pumpAndSettle: AnimatedLogo
    // repeats forever), then one more frame so the outgoing page unmounts.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets(
      'login/register emissions do not tear down the login screen '
      '(the old router rebuild swallowed every error message)',
      (tester) async {
    final (container, notifier) = buildHarness();
    await pumpApp(tester, container);
    notifier._initial.complete(AuthStatus.unauthenticated);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LoginScreen), findsOneWidget);

    final stateBefore = tester.state(find.byType(LoginScreen));

    // A login attempt emits loading, then (on bad credentials) an error.
    notifier.emitLoading();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(LoginScreen), findsOneWidget);

    notifier.emitError(Exception('invalid credentials'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(LoginScreen), findsOneWidget);

    // Same State object: the screen was never disposed, so it can still
    // show the error and keep the typed form values.
    expect(tester.state(find.byType(LoginScreen)), same(stateBefore));
  });

  testWidgets(
      'a fresh unverified signup is routed to the verify-email screen '
      'instead of home', (tester) async {
    final (container, notifier) = buildHarness();
    await pumpApp(tester, container);
    notifier._initial.complete(AuthStatus.unauthenticated);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LoginScreen), findsOneWidget);

    // Register succeeds for an account with an unverified email.
    notifier.needsEmailVerification = true;
    notifier.emitData(AuthStatus.authenticated);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('a signed-out emission bounces protected routes to login',
      (tester) async {
    final (container, notifier) = buildHarness();
    await pumpApp(tester, container);
    notifier._initial.complete(AuthStatus.unauthenticated);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Errors leave value null -> treated as signed out; stays on login.
    notifier.emitError(Exception('boom'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
