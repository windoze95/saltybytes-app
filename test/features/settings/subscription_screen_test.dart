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
                  aiGenerationsUsed: 9,
                ),
                'limits': {
                  'ai_generations': 10,
                  'web_searches': 10,
                  'allergen_analyses': 3,
                  'video_imports': 1,
                  'ai_imports': 10,
                },
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

      expect(find.text('Free Plan'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget); // allergen analyses
      expect(find.text('7 / 10'), findsOneWidget); // agent searches
      expect(find.text('9 / 10'), findsOneWidget); // AI generations
      // Free accounts see both upgrade paths — and never the hidden tier.
      expect(find.text('Get Plus'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(find.textContaining('Unlimited Plan'), findsNothing);
    });

    testWidgets('premium tier shows its real caps and no upgrade cards',
        (tester) async {
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(
                  tier: 'premium',
                  aiGenerationsUsed: 12,
                ),
                'limits': {
                  'ai_generations': 30,
                  'web_searches': 50,
                  'allergen_analyses': 12,
                  'video_imports': 20,
                  'ai_imports': 60,
                },
              }));

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith(FakeAuthNotifier.new),
        ],
      ));
      await _settle(tester);

      expect(find.text('Premium Plan'), findsOneWidget);
      expect(find.text('12 / 30'), findsOneWidget); // premium is capped now
      expect(find.text('Upgrade to Premium'), findsNothing);
      expect(find.text('Get Plus'), findsNothing);
    });

    testWidgets('the hidden unlimited tier renders uncapped with no upgrade '
        'cards', (tester) async {
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(
                  tier: 'unlimited',
                  aiGenerationsUsed: 500,
                ),
                'limits': {
                  'ai_generations': -1,
                  'web_searches': -1,
                  'allergen_analyses': -1,
                  'video_imports': -1,
                  'ai_imports': -1,
                },
              }));

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith(FakeAuthNotifier.new),
        ],
      ));
      await _settle(tester);

      expect(find.text('Unlimited Plan'), findsOneWidget);
      expect(find.text('500 / Unlimited'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsNothing);
      expect(find.text('Get Plus'), findsNothing);
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
