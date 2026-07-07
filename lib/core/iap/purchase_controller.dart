import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show PurchaseStatus;
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show ReplacementMode;
import 'package:in_app_purchase_android/in_app_purchase_android.dart'
    show
        ChangeSubscriptionParam,
        GooglePlayPurchaseDetails,
        GooglePlayPurchaseParam;

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../providers/subscription_provider.dart';
import 'iap_gateway.dart';
import 'iap_products.dart';
import 'store_platform.dart';

/// The `in_app_purchase` plugin, wrapped so tests inject a fake.
final iapGatewayProvider = Provider<IapGateway>((ref) => InAppPurchaseGateway());

/// The store the running device talks to (and whether it can buy).
final storePlatformProvider =
    Provider<StorePlatform>((ref) => detectStorePlatform());

/// Localized product metadata (price, title) for the paywall. Resolves to an
/// unavailable result off-store or when the store can't be reached, so the
/// paywall falls back to the backend's static prices.
final storeProductsProvider = FutureProvider<StoreProducts>((ref) async {
  final store = ref.watch(storePlatformProvider);
  if (!store.canPurchase) {
    return StoreProducts.unavailable(reason: store.blockedReason);
  }
  final gateway = ref.watch(iapGatewayProvider);
  if (!await gateway.isAvailable()) {
    return const StoreProducts.unavailable();
  }
  final response = await gateway.queryProductDetails(IapProducts.ids);
  return StoreProducts(
    available: true,
    byId: {for (final p in response.productDetails) p.id: p},
    notFoundIds: response.notFoundIDs.toSet(),
  );
});

/// App-lifetime controller for the store purchase flow. Listens to the plugin's
/// purchase stream, verifies each transaction with the backend, and exposes a
/// busy/notice [PurchaseState] the paywall drives its UI from.
final purchaseControllerProvider =
    NotifierProvider<PurchaseController, PurchaseState>(PurchaseController.new);

/// Localized store products, keyed by product id.
class StoreProducts {
  const StoreProducts({
    required this.available,
    this.byId = const {},
    this.notFoundIds = const {},
    this.reason,
  });

  const StoreProducts.unavailable({this.reason})
      : available = false,
        byId = const {},
        notFoundIds = const {};

  /// Whether the store returned products and can be purchased from.
  final bool available;
  final Map<String, ProductDetails> byId;
  final Set<String> notFoundIds;

  /// Why the store is unavailable (e.g. iOS too old), when known.
  final String? reason;

  ProductDetails? operator [](String id) => byId[id];
  bool get isEmpty => byId.isEmpty;
}

/// Where the purchase flow currently is.
enum PurchasePhase {
  /// Nothing in flight.
  idle,

  /// The store is awaiting the user / parental approval (Ask to Buy).
  pending,

  /// The transaction is being verified with the backend.
  verifying,
}

/// A one-shot outcome to surface (snackbar). A fresh instance is emitted per
/// event so a listener comparing state identity fires even for repeats.
class PurchaseNotice {
  PurchaseNotice.success(this.message) : isError = false;
  PurchaseNotice.error(this.message) : isError = true;

  final String message;
  final bool isError;
}

/// UI state for the purchase flow.
class PurchaseState {
  const PurchaseState({
    this.phase = PurchasePhase.idle,
    this.activeProductId,
    this.notice,
  });

  final PurchasePhase phase;

  /// The product the in-flight purchase is for (drives per-button spinners).
  final String? activeProductId;

  /// The latest outcome to show once; null when there's nothing pending.
  final PurchaseNotice? notice;

  bool get isBusy => phase != PurchasePhase.idle;

  PurchaseState copyWith({
    PurchasePhase? phase,
    String? activeProductId,
    bool clearActiveProductId = false,
    PurchaseNotice? notice,
    bool clearNotice = false,
  }) {
    return PurchaseState(
      phase: phase ?? this.phase,
      activeProductId:
          clearActiveProductId ? null : (activeProductId ?? this.activeProductId),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

class PurchaseController extends Notifier<PurchaseState> {
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// The most recent active store purchase seen this session. Needed as the
  /// `oldPurchaseDetails` when the user changes plans on Android (proration).
  PurchaseDetails? _activeStorePurchase;

  ApiClient get _apiClient => ref.read(apiClientProvider);
  IapGateway get _gateway => ref.read(iapGatewayProvider);

  /// The active store purchase captured this session, if any.
  PurchaseDetails? get activeStorePurchase => _activeStorePurchase;

  @override
  PurchaseState build() {
    try {
      _subscription = _gateway.purchaseStream.listen(
        _onPurchasesUpdated,
        onError: (Object error) {
          state = state.copyWith(
            phase: PurchasePhase.idle,
            clearActiveProductId: true,
            notice: PurchaseNotice.error(
                userFacingErrorMessage(error, 'The store reported an error.')),
          );
        },
      );
      ref.onDispose(() => _subscription?.cancel());
    } catch (_) {
      // No native store on this platform (desktop/web/tests without a fake) —
      // purchasing stays disabled; the paywall shows read-only prices.
    }
    return const PurchaseState();
  }

  /// Starts a subscription purchase for [product]. On Android, pass the user's
  /// current store purchase as [replacing] to upgrade/downgrade with proration.
  Future<void> buy(ProductDetails product, {PurchaseDetails? replacing}) async {
    if (state.isBusy) return;

    final store = ref.read(storePlatformProvider);
    if (!store.canPurchase) {
      state = state.copyWith(
        notice: PurchaseNotice.error(
            store.blockedReason ?? 'Purchases are unavailable on this device.'),
      );
      return;
    }

    state = state.copyWith(
      phase: PurchasePhase.pending,
      activeProductId: product.id,
      clearNotice: true,
    );

    try {
      final accountToken = await _accountToken();
      final param = _buildPurchaseParam(
        product: product,
        accountToken: accountToken,
        replacing: replacing,
        kind: store.kind,
      );
      final started = await _gateway.buyNonConsumable(purchaseParam: param);
      if (!started) {
        state = state.copyWith(
          phase: PurchasePhase.idle,
          clearActiveProductId: true,
          notice: PurchaseNotice.error('Could not start the purchase.'),
        );
      }
      // On success the outcome arrives on the purchase stream.
    } catch (error) {
      state = state.copyWith(
        phase: PurchasePhase.idle,
        clearActiveProductId: true,
        notice: PurchaseNotice.error(
            userFacingErrorMessage(error, 'Could not start the purchase.')),
      );
    }
  }

  /// Re-delivers the account's active purchases. Each arrives on the stream as
  /// a `restored` update and flows through the same verify pipeline. Required
  /// by App Store review.
  Future<void> restore() async {
    if (state.isBusy) return;
    state = state.copyWith(phase: PurchasePhase.verifying, clearNotice: true);
    try {
      final accountToken = await _accountToken();
      await _gateway.restorePurchases(applicationUserName: accountToken);
    } catch (error) {
      state = state.copyWith(
        phase: PurchasePhase.idle,
        notice: PurchaseNotice.error(
            userFacingErrorMessage(error, 'Could not restore purchases.')),
      );
      return;
    }
    // Restored transactions (if any) are processed on the stream; clear the
    // spinner. Any success notice they set is preserved by copyWith.
    if (state.phase == PurchasePhase.verifying) {
      state = state.copyWith(phase: PurchasePhase.idle);
    }
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        state = state.copyWith(
          phase: PurchasePhase.pending,
          activeProductId: purchase.productID,
        );
      case PurchaseStatus.purchased:
        await _verifyAndComplete(purchase, restored: false);
      case PurchaseStatus.restored:
        await _verifyAndComplete(purchase, restored: true);
      case PurchaseStatus.error:
        state = state.copyWith(
          phase: PurchasePhase.idle,
          clearActiveProductId: true,
          notice: PurchaseNotice.error(_pluginErrorMessage(purchase)),
        );
        await _finishIfNeeded(purchase);
      case PurchaseStatus.canceled:
        // Backed out — clear busy silently (no snackbar).
        state = state.copyWith(
          phase: PurchasePhase.idle,
          clearActiveProductId: true,
        );
        await _finishIfNeeded(purchase);
    }
  }

  /// Verifies a delivered purchase server-side, then — only on success or a
  /// definitive "belongs to another account" — finishes it with the store.
  Future<void> _verifyAndComplete(
    PurchaseDetails purchase, {
    required bool restored,
  }) async {
    if (!IapProducts.isKnown(purchase.productID)) {
      // A product we no longer sell: finish it so the queue drains, ignore it.
      await _finishIfNeeded(purchase);
      return;
    }

    final platform = ref.read(storePlatformProvider).apiPlatform;
    if (platform == null) {
      state = state.copyWith(
        phase: PurchasePhase.idle,
        clearActiveProductId: true,
        notice:
            PurchaseNotice.error('Purchases are unavailable on this device.'),
      );
      return;
    }

    state = state.copyWith(
      phase: PurchasePhase.verifying,
      activeProductId: purchase.productID,
    );

    try {
      await _apiClient.post(ApiEndpoints.iapVerify, data: {
        'platform': platform,
        'product_id': purchase.productID,
        'verification_data': purchase.verificationData.serverVerificationData,
      });

      // Verified: remember it for plan changes, refresh the tier, THEN finish.
      _activeStorePurchase = purchase;
      ref.invalidate(subscriptionProvider);
      try {
        await ref.read(subscriptionProvider.future);
      } catch (_) {
        // The tier badge will catch up on the next read; don't fail the flow.
      }
      await _finishIfNeeded(purchase);

      state = state.copyWith(
        phase: PurchasePhase.idle,
        clearActiveProductId: true,
        notice: PurchaseNotice.success(
          restored
              ? 'Your subscription was restored.'
              : "You're now on ${_tierName(IapProducts.tierFor(purchase.productID))}!",
        ),
      );
    } on DioException catch (error) {
      final apiError = error.error is ApiError ? error.error as ApiError : null;
      if (apiError?.errorCode == 'subscription_linked_to_other_account') {
        // Real purchase, bound elsewhere: finish it so it stops redelivering,
        // and surface the conflict.
        await _finishIfNeeded(purchase);
      }
      // On verification_failed (possible tampering) and transient failures we
      // deliberately do NOT finish — the store re-delivers, so a genuine
      // purchase is never dropped and can be recovered via Restore.
      state = state.copyWith(
        phase: PurchasePhase.idle,
        clearActiveProductId: true,
        notice: PurchaseNotice.error(apiError?.message ??
            'Purchase verification failed. If you were charged, tap Restore '
                'Purchases or contact support.'),
      );
    } catch (error) {
      state = state.copyWith(
        phase: PurchasePhase.idle,
        clearActiveProductId: true,
        notice: PurchaseNotice.error(
            userFacingErrorMessage(error, 'Purchase verification failed.')),
      );
    }
  }

  Future<void> _finishIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _gateway.completePurchase(purchase);
    } catch (_) {
      // Finishing is best-effort; the store re-delivers if it didn't take.
    }
  }

  /// Builds the platform purchase parameter, attaching Android proration when
  /// swapping to a different product from an existing store subscription.
  PurchaseParam _buildPurchaseParam({
    required ProductDetails product,
    required String? accountToken,
    required PurchaseDetails? replacing,
    required StoreKind kind,
  }) {
    if (kind == StoreKind.google &&
        replacing is GooglePlayPurchaseDetails &&
        replacing.productID != product.id) {
      return GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: accountToken,
        changeSubscriptionParam: ChangeSubscriptionParam(
          oldPurchaseDetails: replacing,
          replacementMode: ReplacementMode.withTimeProration,
        ),
      );
    }
    return PurchaseParam(
      productDetails: product,
      applicationUserName: accountToken,
    );
  }

  Future<String?> _accountToken() async {
    try {
      final subscription = await ref.read(subscriptionProvider.future);
      return subscription.accountToken;
    } catch (_) {
      return null;
    }
  }

  String _pluginErrorMessage(PurchaseDetails purchase) {
    final message = purchase.error?.message;
    return (message != null && message.isNotEmpty)
        ? message
        : 'The purchase could not be completed.';
  }

  String _tierName(String tier) => tier.isEmpty
      ? 'your new plan'
      : '${tier[0].toUpperCase()}${tier.substring(1)}';
}
