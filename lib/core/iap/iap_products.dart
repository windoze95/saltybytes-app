/// Store product identifiers for SaltyBytes subscriptions.
///
/// The IDs are identical on the App Store and Google Play so the same set is
/// queried on both platforms. Keep these in lockstep with the backend's
/// product -> tier mapping (POST /v1/iap/verify) and the store listings.
class IapProducts {
  IapProducts._();

  /// Plus, billed monthly ($1.99/mo -> tier `plus`).
  static const String plusMonthly = 'sb_plus_monthly';

  /// Premium, billed monthly ($4.99/mo -> tier `premium`).
  static const String premiumMonthly = 'sb_premium_monthly';

  /// Premium, billed yearly ($39.99/yr -> tier `premium`).
  static const String premiumYearly = 'sb_premium_yearly';

  /// Every identifier to query from the store.
  static const Set<String> ids = {
    plusMonthly,
    premiumMonthly,
    premiumYearly,
  };

  /// The SaltyBytes tier a product grants. Unknown products map to `free` so a
  /// stray identifier never reads as an entitlement.
  static String tierFor(String productId) {
    switch (productId) {
      case plusMonthly:
        return 'plus';
      case premiumMonthly:
      case premiumYearly:
        return 'premium';
      default:
        return 'free';
    }
  }

  /// Whether [productId] is one of ours (guards stray transactions delivered
  /// by the store for products we no longer sell).
  static bool isKnown(String productId) => ids.contains(productId);
}
