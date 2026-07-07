import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show PurchaseStatus;
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/iap/iap_products.dart';
import 'package:saltybytes_app/core/iap/purchase_controller.dart';
import 'package:saltybytes_app/core/iap/store_platform.dart';
import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
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

/// The plan cards sit below the fold at the default 800x600 test viewport; use
/// a taller surface so the whole ListView builds.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Products the paywall renders localized prices from.
StoreProducts _fakeStoreProducts() => StoreProducts(
      available: true,
      byId: {
        IapProducts.plusMonthly: fakeProductDetails(
          id: IapProducts.plusMonthly,
          price: r'$1.49',
          rawPrice: 1.49,
        ),
        IapProducts.premiumMonthly: fakeProductDetails(
          id: IapProducts.premiumMonthly,
          price: r'$5.49',
          rawPrice: 5.49,
        ),
        IapProducts.premiumYearly: fakeProductDetails(
          id: IapProducts.premiumYearly,
          price: r'$39.99',
          rawPrice: 39.99,
        ),
      },
    );

List<Override> _overrides({
  required MockApiClient apiClient,
  FakeIapGateway? gateway,
  StorePlatform platform =
      const StorePlatform(kind: StoreKind.apple, canPurchase: true),
  StoreProducts? products,
}) {
  return [
    apiClientProvider.overrideWithValue(apiClient),
    authStateProvider.overrideWith(FakeAuthNotifier.new),
    iapGatewayProvider.overrideWithValue(gateway ?? FakeIapGateway()),
    storePlatformProvider.overrideWithValue(platform),
    if (products != null)
      storeProductsProvider.overrideWith((ref) async => products),
  ];
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

    test('parses the additive store + account_token envelope siblings', () {
      final sub = SubscriptionInfo.fromJson(
        testSubscriptionJson(tier: 'premium'),
        storeJson: testStoreJson(
          platform: 'apple',
          productId: IapProducts.premiumMonthly,
          autoRenew: true,
        ),
        accountToken: 'acct-xyz',
      );

      expect(sub.hasStoreSubscription, isTrue);
      expect(sub.store!.isApple, isTrue);
      expect(sub.store!.productId, IapProducts.premiumMonthly);
      expect(sub.store!.autoRenew, isTrue);
      expect(sub.store!.expiresAt, isNotNull);
      expect(sub.accountToken, 'acct-xyz');
    });

    test('reads store + account_token inlined in the subscription object', () {
      final sub = SubscriptionInfo.fromJson(testSubscriptionJson(
        tier: 'premium',
        store: testStoreJson(
          platform: 'google',
          productId: IapProducts.premiumYearly,
          autoRenew: false,
        ),
        accountToken: 'acct-embedded',
      ));

      expect(sub.store!.isGoogle, isTrue);
      expect(sub.store!.autoRenew, isFalse);
      expect(sub.accountToken, 'acct-embedded');
    });

    test('tolerates a missing store / account_token (free accounts)', () {
      final sub = SubscriptionInfo.fromJson(testSubscriptionJson(tier: 'free'));
      expect(sub.hasStoreSubscription, isFalse);
      expect(sub.store, isNull);
      expect(sub.accountToken, isNull);
    });
  });

  group('subscriptionProvider', () {
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

    test('threads store + account_token from the GET envelope', () async {
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(tier: 'premium'),
                'limits': const {'ai_generations': 30},
                'store': testStoreJson(
                  platform: 'apple',
                  productId: IapProducts.premiumMonthly,
                ),
                'account_token': 'acct-999',
              }));
      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        authStateProvider.overrideWith(FakeAuthNotifier.new),
      ]);
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final sub = await container.read(subscriptionProvider.future);

      expect(sub.store!.productId, IapProducts.premiumMonthly);
      expect(sub.accountToken, 'acct-999');
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
                'limits': const {
                  'ai_generations': 10,
                  'web_searches': 10,
                  'allergen_analyses': 3,
                  'video_imports': 1,
                  'ai_imports': 10,
                },
              }));

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides: _overrides(apiClient: apiClient, products: _fakeStoreProducts()),
      ));
      await _settle(tester);

      expect(find.text('Free Plan'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget); // allergen analyses
      expect(find.text('7 / 10'), findsOneWidget); // agent searches
      expect(find.text('9 / 10'), findsOneWidget); // AI generations
      expect(find.text('Get Plus'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(find.textContaining('Unlimited Plan'), findsNothing);
    });

    testWidgets('renders localized store prices, restore, and legal links',
        (tester) async {
      _useTallViewport(tester);
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(tier: 'free'),
                'limits': const {'ai_generations': 10},
              }));

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides:
            _overrides(apiClient: apiClient, products: _fakeStoreProducts()),
      ));
      await _settle(tester);

      // Prices come from ProductDetails, not the hardcoded fallbacks.
      expect(find.text('\$1.49/mo'), findsOneWidget); // Plus
      expect(find.text('\$5.49/mo'), findsOneWidget); // Premium monthly default
      // App Store requirements: restore + legal links.
      expect(find.text('Restore Purchases'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
    });

    testWidgets('premium period toggle switches the displayed price',
        (tester) async {
      _useTallViewport(tester);
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(tier: 'free'),
                'limits': const {'ai_generations': 10},
              }));

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides:
            _overrides(apiClient: apiClient, products: _fakeStoreProducts()),
      ));
      await _settle(tester);

      expect(find.text('\$5.49/mo'), findsOneWidget);
      expect(find.text('\$39.99/yr'), findsNothing);

      await tester.tap(find.text('Yearly'));
      await _settle(tester);

      expect(find.text('\$39.99/yr'), findsOneWidget);
    });

    testWidgets('tapping Get Plus starts a purchase for the plus product',
        (tester) async {
      _useTallViewport(tester);
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(tier: 'free'),
                'limits': const {'ai_generations': 10},
                'account_token': 'acct-1',
              }));
      final gateway = FakeIapGateway();

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides: _overrides(
          apiClient: apiClient,
          gateway: gateway,
          products: _fakeStoreProducts(),
        ),
      ));
      await _settle(tester);

      await tester.tap(find.text('Get Plus'));
      await _settle(tester);

      expect(gateway.buyParams.single.productDetails.id,
          IapProducts.plusMonthly);
      expect(gateway.buyParams.single.applicationUserName, 'acct-1');
    });

    testWidgets('buy buttons are disabled while a purchase is in flight',
        (tester) async {
      _useTallViewport(tester);
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(tier: 'free'),
                'limits': const {'ai_generations': 10},
              }));
      final gateway = FakeIapGateway();

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides: _overrides(
          apiClient: apiClient,
          gateway: gateway,
          products: _fakeStoreProducts(),
        ),
      ));
      await _settle(tester);

      // A pending Plus purchase makes the controller busy.
      gateway.emit([
        fakePurchaseDetails(
          productID: IapProducts.plusMonthly,
          status: PurchaseStatus.pending,
        ),
      ]);
      await _settle(tester);

      final premiumButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Upgrade to Premium'),
      );
      expect(premiumButton.onPressed, isNull);
    });

    testWidgets('shows Manage Subscription when the tier is store-backed',
        (tester) async {
      _useTallViewport(tester);
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(tier: 'premium'),
                'limits': const {'ai_generations': 30},
                'store': testStoreJson(
                  platform: 'apple',
                  productId: IapProducts.premiumMonthly,
                ),
                'account_token': 'acct-1',
              }));

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides:
            _overrides(apiClient: apiClient, products: _fakeStoreProducts()),
      ));
      await _settle(tester);

      expect(find.text('Manage Subscription'), findsOneWidget);
      // Premium already: no upgrade cards.
      expect(find.text('Get Plus'), findsNothing);
      expect(find.text('Upgrade to Premium'), findsNothing);
    });

    testWidgets('an iOS-too-old device blocks buying with an explanation',
        (tester) async {
      _useTallViewport(tester);
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.subscription))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'subscription': testSubscriptionJson(tier: 'free'),
                'limits': const {'ai_generations': 10},
              }));

      await tester.pumpWidget(testAppScaffold(
        const SubscriptionScreen(),
        overrides: _overrides(
          apiClient: apiClient,
          platform: const StorePlatform(
            kind: StoreKind.apple,
            canPurchase: false,
            blockedReason: 'In-app purchases require iOS 15 or newer.',
          ),
          // No products override: storeProductsProvider resolves unavailable
          // from the blocked platform and surfaces the reason.
        ),
      ));
      await _settle(tester);

      expect(find.textContaining('iOS 15'), findsOneWidget);
      // Fallback prices still shown so the plans read.
      expect(find.text('\$1.99/mo'), findsOneWidget);
      // Store unavailable -> no Restore button.
      expect(find.text('Restore Purchases'), findsNothing);
    });
  });
}
