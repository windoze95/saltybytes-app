import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/navigation/app_router.dart';
import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/auth/login_screen.dart';
import 'package:saltybytes_app/features/home/home_screen.dart';
import 'package:saltybytes_app/features/search/search_preview_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

/// Controllable auth notifier: build() resolves when the test says so, and
/// login-style emissions can be pushed at any time (mirrors app_router_test).
class _ControlledAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {
  _ControlledAuthNotifier(this._initial);

  final Completer<AuthStatus> _initial;

  @override
  bool needsEmailVerification = false;

  @override
  void markEmailVerificationHandled() {
    needsEmailVerification = false;
  }

  @override
  Future<AuthStatus> build() => _initial.future;

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

  const sourceUrl = 'https://pinchofyum.com/bang-bang-salmon';
  final encoded = Uri.encodeQueryComponent(sourceUrl);

  (ProviderContainer, _ControlledAuthNotifier) buildHarness() {
    final completer = Completer<AuthStatus>();
    final notifier = _ControlledAuthNotifier(completer);
    final api = MockApiClient();
    when(() => api.get(any())).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/stub'),
      type: DioExceptionType.connectionError,
    ));
    when(() => api.post(
          ApiEndpoints.previewFromUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => fakeResponse<dynamic>({
          'recipe': testRecipePreviewJson(
            title: 'Bang Bang Salmon',
            sourceUrl: sourceUrl,
          ),
        }));
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith(() => notifier),
      apiClientProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    return (container, notifier);
  }

  Future<void> pumpApp(WidgetTester tester, ProviderContainer container) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(routerProvider),
        ),
      ),
    );
  }

  /// Rides out a go_router page transition (no pumpAndSettle: AnimatedLogo
  /// repeats forever).
  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('deep link /preview?u= opens the preview screen when signed in',
      (tester) async {
    final (container, notifier) = buildHarness();
    await pumpApp(tester, container);
    notifier._initial.complete(AuthStatus.authenticated);
    await settleRoute(tester);

    container.read(routerProvider).go('/preview?u=$encoded');
    await settleRoute(tester);

    expect(find.byType(SearchPreviewScreen), findsOneWidget);
    // The app bar titles the shared link with the source domain (it also
    // appears in the preview body's source line).
    expect(find.text('pinchofyum.com'), findsWidgets);
  });

  testWidgets('deep link without a u parameter lands on home', (tester) async {
    final (container, notifier) = buildHarness();
    await pumpApp(tester, container);
    notifier._initial.complete(AuthStatus.authenticated);
    await settleRoute(tester);

    container.read(routerProvider).go('/preview');
    await settleRoute(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SearchPreviewScreen), findsNothing);
  });

  testWidgets(
      'a deep link that arrives signed out is replayed after login instead '
      'of being dropped on /home', (tester) async {
    final (container, notifier) = buildHarness();
    await pumpApp(tester, container);
    notifier._initial.complete(AuthStatus.unauthenticated);
    await settleRoute(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    // The shared link arrives while signed out: stays on login (stashed).
    container.read(routerProvider).go('/preview?u=$encoded');
    await settleRoute(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    // Signing in resumes the stashed link rather than landing on /home.
    notifier.emitData(AuthStatus.authenticated);
    await settleRoute(tester);

    expect(find.byType(SearchPreviewScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
}
