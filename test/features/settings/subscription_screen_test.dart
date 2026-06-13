import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/subscription_provider.dart';
import 'package:saltybytes_app/features/settings/subscription_screen.dart';
import 'package:saltybytes_app/models/subscription.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The upgrade card sits below the fold at the default 800x600 test
/// viewport; use a taller surface so the whole ListView builds.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SubscriptionInfo parsing', () {
    test('parses the Go default (PascalCase) field names', () {
      final sub = SubscriptionInfo.fromJson(testSubscriptionJson(
        tier: 'free',
        allergenAnalysesUsed: 2,
        webSearchesUsed: 7,
        aiGenerationsUsed: 12,
      ));

      expect(sub.tier, 'free');
      expect(sub.isPremium, isFalse);
      expect(sub.allergenAnalysesUsed, 2);
      expect(sub.webSearchesUsed, 7);
      expect(sub.aiGenerationsUsed, 12);
      expect(sub.monthlyResetAt, isNotNull);
    });

    test('parses snake_case keys defensively', () {
      final sub = SubscriptionInfo.fromJson({
        'tier': 'premium',
        'allergen_analyses_used': 1,
        'web_searches_used': 2,
        'ai_generations_used': 3,
        'monthly_reset_at': '2026-07-01T00:00:00Z',
      });

      expect(sub.isPremium, isTrue);
      expect(sub.allergenAnalysesUsed, 1);
      expect(sub.webSearchesUsed, 2);
      expect(sub.aiGenerationsUsed, 3);
    });
  });

  group('subscriptionProvider auth scoping', () {
    test('returns defaults without fetching when signed out, so a previous '
        "user's tier/usage cannot leak into the next session", () async {
      final apiClient = MockApiClient();
      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        authStateProvider
            .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
      ]);
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final sub = await container.read(subscriptionProvider.future);

      expect(sub.tier, 'free');
      expect(sub.allergenAnalysesUsed, 0);
      verifyNever(() => apiClient.get(ApiEndpoints.subscription));
    });
  });

  group('SubscriptionScreen', () {
    testWidgets('renders real tier and usage from GET /v1/subscription',
        (tester) async {
      _useTallViewport(tester);
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(
                  tier: 'free',
                  allergenAnalysesUsed: 2,
                  webSearchesUsed: 7,
                  aiGenerationsUsed: 12,
                ),
              }));

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          // subscriptionProvider is auth-scoped; report a signed-in user so
          // it actually fetches.
          authStateProvider.overrideWith(FakeAuthNotifier.new),
        ],
      ));
      await _settle(tester);

      expect(find.text('Free Tier'), findsOneWidget);
      expect(find.text('2 / 5'), findsOneWidget); // allergen analyses
      expect(find.text('7 / 20'), findsOneWidget); // web searches
      expect(find.text('12 / 50'), findsOneWidget); // AI generations
      expect(find.text('Upgrade to Premium'), findsOneWidget);
    });

    testWidgets('premium tier shows unlimited usage and no upgrade card',
        (tester) async {
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(
                  tier: 'premium',
                  aiGenerationsUsed: 120,
                ),
              }));

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          // subscriptionProvider is auth-scoped; report a signed-in user so
          // it actually fetches.
          authStateProvider.overrideWith(FakeAuthNotifier.new),
        ],
      ));
      await _settle(tester);

      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('120 / Unlimited'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsNothing);
    });

    testWidgets('upgrade surfaces the 501 "not yet available" message',
        (tester) async {
      _useTallViewport(tester);
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(tier: 'free'),
              }));
      when(() => apiClient.post(ApiEndpoints.subscriptionUpgrade)).thenAnswer(
        (_) async => throw DioException(
          requestOptions:
              RequestOptions(path: ApiEndpoints.subscriptionUpgrade),
          response: Response(
            requestOptions:
                RequestOptions(path: ApiEndpoints.subscriptionUpgrade),
            statusCode: 501,
          ),
          error: const ApiError(
            message: 'paid plans are not yet available',
            statusCode: 501,
          ),
        ),
      );

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          // subscriptionProvider is auth-scoped; report a signed-in user so
          // it actually fetches.
          authStateProvider.overrideWith(FakeAuthNotifier.new),
        ],
      ));
      await _settle(tester);

      await tester.tap(find.text('Upgrade to Premium'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('paid plans are not yet available'), findsOneWidget);
    });
  });
}
