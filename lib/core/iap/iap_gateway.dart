import 'package:in_app_purchase/in_app_purchase.dart';

export 'package:in_app_purchase/in_app_purchase.dart'
    show ProductDetails, ProductDetailsResponse, PurchaseDetails, PurchaseParam;

/// Thin seam over the `in_app_purchase` plugin.
///
/// Everything the app needs from the store goes through this interface so the
/// purchase controller can be driven by a fake in tests (the real plugin talks
/// to platform channels that don't exist in the Flutter test host). The plugin
/// value types ([ProductDetails], [PurchaseDetails], [PurchaseParam]) are plain
/// data classes, so they cross the boundary directly.
abstract class IapGateway {
  /// Whether the device can make payments (store configured, signed in, etc.).
  Future<bool> isAvailable();

  /// Purchase / restore updates for the app's lifetime. Emits queued and
  /// interrupted transactions once listened to.
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Looks up localized store metadata (price, title) for [identifiers].
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  /// Starts the buy flow for a subscription. Returns whether the flow was
  /// launched; the outcome arrives on [purchaseStream].
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});

  /// Re-delivers the account's active purchases onto [purchaseStream] as
  /// `restored` updates. [applicationUserName] binds them to this account.
  Future<void> restorePurchases({String? applicationUserName});

  /// Finalizes a delivered purchase. On Android this acknowledges it (an
  /// unacknowledged purchase is refunded after three days), so it must run only
  /// after the server has granted the entitlement.
  Future<void> completePurchase(PurchaseDetails purchase);
}

/// [IapGateway] backed by the real `in_app_purchase` plugin (StoreKit 2 on
/// iOS, Play Billing on Android).
class InAppPurchaseGateway implements IapGateway {
  InAppPurchaseGateway([InAppPurchase? inAppPurchase])
      : _iap = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
          Set<String> identifiers) =>
      _iap.queryProductDetails(identifiers);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _iap.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases({String? applicationUserName}) =>
      _iap.restorePurchases(applicationUserName: applicationUserName);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}
