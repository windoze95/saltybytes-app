import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/iap/iap_products.dart';
import 'package:saltybytes_app/core/iap/purchase_controller.dart';
import 'package:saltybytes_app/core/iap/store_platform.dart';
import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/subscription_provider.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

/// A DioException whose `.error` is an [ApiError], as the app's ErrorInterceptor
/// produces before it reaches callers.
DioException _apiException({
  required int statusCode,
  required String errorCode,
  required String message,
}) {
  final options = RequestOptions(path: ApiEndpoints.iapVerify);
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: statusCode),
    error: ApiError(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  late FakeIapGateway gateway;
  late MockApiClient apiClient;
  late ProviderContainer container;
  late List<String> log;

  const accountToken = 'acct-123';

  /// Stubs GET /v1/subscription with an account token so the controller can
  /// bind purchases and refresh the tier after verifying.
  void stubSubscriptionGet() {
    when(() => apiClient.get(ApiEndpoints.subscription))
        .thenAnswer((_) async => fakeResponse<dynamic>({
              'subscription': testSubscriptionJson(tier: 'free'),
              'limits': const {'ai_generations': 10},
              'account_token': accountToken,
            }));
  }

  Future<ProviderContainer> makeContainer({
    StoreKind kind = StoreKind.apple,
    bool canPurchase = true,
  }) async {
    final c = ProviderContainer(overrides: [
      iapGatewayProvider.overrideWithValue(gateway),
      apiClientProvider.overrideWithValue(apiClient),
      storePlatformProvider.overrideWithValue(
        StorePlatform(kind: kind, canPurchase: canPurchase),
      ),
      authStateProvider.overrideWith(FakeAuthNotifier.new),
    ]);
    // Prime auth, then subscription, so account_token is available before the
    // controller reads it (Riverpod async-provider ordering gotcha).
    await c.read(authStateProvider.future);
    await c.read(subscriptionProvider.future);
    return c;
  }

  setUp(() {
    gateway = FakeIapGateway();
    apiClient = MockApiClient();
    log = [];
    stubSubscriptionGet();
    // Record completion order so tests can prove verify-before-complete.
    gateway.onCompletePurchase =
        (p) => log.add('complete:${p.productID}');
  });

  tearDown(() {
    container.dispose();
    gateway.dispose();
  });

  /// Stubs POST /v1/iap/verify to succeed, recording the verify in [log].
  void stubVerifySuccess() {
    when(() => apiClient.post(ApiEndpoints.iapVerify,
        data: any(named: 'data'))).thenAnswer((invocation) async {
      final data = invocation.namedArguments[#data] as Map<String, dynamic>;
      log.add('verify:${data['product_id']}');
      return fakeResponse<dynamic>({
        'subscription': testSubscriptionJson(tier: 'premium'),
        'limits': const {'ai_generations': 30},
        'account_token': accountToken,
      });
    });
  }

  test('exposes pending state without verifying', () async {
    container = await makeContainer();
    // Build the controller so it subscribes before we emit.
    container.read(purchaseControllerProvider.notifier);

    gateway.emit([
      fakePurchaseDetails(
        productID: IapProducts.premiumMonthly,
        status: PurchaseStatus.pending,
      ),
    ]);
    await pumpEventQueue();

    final state = container.read(purchaseControllerProvider);
    expect(state.phase, PurchasePhase.pending);
    expect(state.activeProductId, IapProducts.premiumMonthly);
    verifyNever(
        () => apiClient.post(ApiEndpoints.iapVerify, data: any(named: 'data')));
  });

  test('purchased: verifies BEFORE completing, refreshes tier, shows success',
      () async {
    stubVerifySuccess();
    container = await makeContainer();
    container.read(purchaseControllerProvider.notifier);

    gateway.emit([
      fakePurchaseDetails(
        productID: IapProducts.premiumMonthly,
        status: PurchaseStatus.purchased,
        serverVerificationData: 'the-jws',
      ),
    ]);
    await pumpEventQueue();

    // Verify ran, then complete ran — never the reverse.
    expect(log, ['verify:${IapProducts.premiumMonthly}',
        'complete:${IapProducts.premiumMonthly}']);
    expect(gateway.completed.single.productID, IapProducts.premiumMonthly);

    // The verify payload carried the platform + the JWS/token verbatim.
    final captured = verify(() => apiClient.post(ApiEndpoints.iapVerify,
        data: captureAny(named: 'data'))).captured.single as Map<String, dynamic>;
    expect(captured['platform'], 'apple');
    expect(captured['product_id'], IapProducts.premiumMonthly);
    expect(captured['verification_data'], 'the-jws');

    final state = container.read(purchaseControllerProvider);
    expect(state.phase, PurchasePhase.idle);
    expect(state.notice, isNotNull);
    expect(state.notice!.isError, isFalse);
    expect(state.notice!.message, contains('Premium'));
  });

  test('verification_failed does NOT complete the purchase', () async {
    when(() => apiClient.post(ApiEndpoints.iapVerify, data: any(named: 'data')))
        .thenThrow(_apiException(
      statusCode: 400,
      errorCode: 'verification_failed',
      message: 'Purchase verification failed.',
    ));
    container = await makeContainer();
    container.read(purchaseControllerProvider.notifier);

    gateway.emit([
      fakePurchaseDetails(
        productID: IapProducts.premiumMonthly,
        status: PurchaseStatus.purchased,
      ),
    ]);
    await pumpEventQueue();

    // Not completed — the store re-delivers so a real purchase isn't lost.
    expect(gateway.completed, isEmpty);
    final state = container.read(purchaseControllerProvider);
    expect(state.phase, PurchasePhase.idle);
    expect(state.notice!.isError, isTrue);
    expect(state.notice!.message, contains('verification failed'));
  });

  test('409 linked-to-other-account DOES complete but surfaces the error',
      () async {
    when(() => apiClient.post(ApiEndpoints.iapVerify, data: any(named: 'data')))
        .thenThrow(_apiException(
      statusCode: 409,
      errorCode: 'subscription_linked_to_other_account',
      message: 'This subscription is already linked to another account.',
    ));
    container = await makeContainer();
    container.read(purchaseControllerProvider.notifier);

    gateway.emit([
      fakePurchaseDetails(
        productID: IapProducts.premiumMonthly,
        status: PurchaseStatus.purchased,
      ),
    ]);
    await pumpEventQueue();

    // The purchase is real (just bound elsewhere) so it IS finished...
    expect(gateway.completed.single.productID, IapProducts.premiumMonthly);
    // ...but the conflict is surfaced.
    final state = container.read(purchaseControllerProvider);
    expect(state.notice!.isError, isTrue);
    expect(state.notice!.message, contains('another'));
  });

  test('restored purchases flow through verify and complete', () async {
    stubVerifySuccess();
    container = await makeContainer();
    container.read(purchaseControllerProvider.notifier);

    gateway.emit([
      fakePurchaseDetails(
        productID: IapProducts.premiumYearly,
        status: PurchaseStatus.restored,
      ),
    ]);
    await pumpEventQueue();

    expect(log, ['verify:${IapProducts.premiumYearly}',
        'complete:${IapProducts.premiumYearly}']);
    final state = container.read(purchaseControllerProvider);
    expect(state.notice!.isError, isFalse);
    expect(state.notice!.message, contains('restored'));
  });

  test('buy passes the account token as applicationUserName and goes pending',
      () async {
    stubVerifySuccess();
    container = await makeContainer();
    final controller = container.read(purchaseControllerProvider.notifier);

    final product = fakeProductDetails(
      id: IapProducts.premiumMonthly,
      price: r'$4.99',
    );
    await controller.buy(product);

    expect(gateway.buyParams.single.applicationUserName, accountToken);
    expect(gateway.buyParams.single.productDetails.id,
        IapProducts.premiumMonthly);
    expect(container.read(purchaseControllerProvider).phase,
        PurchasePhase.pending);
  });

  test('buy is blocked with a message when the store cannot purchase',
      () async {
    container = await makeContainer(canPurchase: false);
    final controller = container.read(purchaseControllerProvider.notifier);

    await controller.buy(
        fakeProductDetails(id: IapProducts.plusMonthly, price: r'$1.99'));

    expect(gateway.buyParams, isEmpty);
    final state = container.read(purchaseControllerProvider);
    expect(state.phase, PurchasePhase.idle);
    expect(state.notice!.isError, isTrue);
  });

  test('canceled clears the busy state silently (no error notice)', () async {
    container = await makeContainer();
    container.read(purchaseControllerProvider.notifier);

    gateway.emit([
      fakePurchaseDetails(
        productID: IapProducts.premiumMonthly,
        status: PurchaseStatus.pending,
      ),
    ]);
    await pumpEventQueue();
    expect(
        container.read(purchaseControllerProvider).phase, PurchasePhase.pending);

    gateway.emit([
      fakePurchaseDetails(
        productID: IapProducts.premiumMonthly,
        status: PurchaseStatus.canceled,
      ),
    ]);
    await pumpEventQueue();

    final state = container.read(purchaseControllerProvider);
    expect(state.phase, PurchasePhase.idle);
    expect(state.notice, isNull);
  });

  test('a product we do not sell is finished and never verified', () async {
    container = await makeContainer();
    container.read(purchaseControllerProvider.notifier);

    gateway.emit([
      fakePurchaseDetails(
        productID: 'sb_legacy_lifetime',
        status: PurchaseStatus.purchased,
      ),
    ]);
    await pumpEventQueue();

    verifyNever(
        () => apiClient.post(ApiEndpoints.iapVerify, data: any(named: 'data')));
    expect(gateway.completed.single.productID, 'sb_legacy_lifetime');
    expect(container.read(purchaseControllerProvider).phase,
        PurchasePhase.idle);
  });

  test('restore() re-delivers active purchases through the verify pipeline',
      () async {
    stubVerifySuccess();
    container = await makeContainer();
    final controller = container.read(purchaseControllerProvider.notifier);

    // The fake redelivers a restored purchase when asked.
    gateway.restoredWithAccountToken = null;
    final future = controller.restore();
    gateway.emit([
      fakePurchaseDetails(
        productID: IapProducts.premiumMonthly,
        status: PurchaseStatus.restored,
      ),
    ]);
    await future;
    await pumpEventQueue();

    expect(gateway.restoreCalled, isTrue);
    expect(gateway.restoredWithAccountToken, accountToken);
    expect(log, contains('verify:${IapProducts.premiumMonthly}'));
    expect(container.read(purchaseControllerProvider).phase,
        PurchasePhase.idle);
  });
}
