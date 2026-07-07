import 'dart:io' show Platform;

/// The billing back end a device talks to.
enum StoreKind {
  /// Apple App Store (StoreKit).
  apple,

  /// Google Play Billing.
  google,

  /// No native store (desktop, web, or a simulator without a store) — the
  /// paywall shows read-only prices and disables buying.
  none,
}

/// Describes the store the running device uses and whether a native purchase
/// can actually be attempted.
///
/// The backend verifies Apple purchases from the StoreKit 2 signed-transaction
/// JWS, which only exists on iOS 15+. On older iOS the `in_app_purchase` plugin
/// falls back to StoreKit 1 (whose receipt the backend does not verify), so we
/// block purchasing there with an explanatory message rather than take money we
/// can't validate.
class StorePlatform {
  const StorePlatform({
    required this.kind,
    required this.canPurchase,
    this.blockedReason,
  });

  final StoreKind kind;

  /// True when a purchase can be initiated on this device.
  final bool canPurchase;

  /// User-facing reason purchasing is unavailable, when [canPurchase] is
  /// false but the device is otherwise a store device (e.g. iOS < 15).
  final String? blockedReason;

  /// The `platform` value POST /v1/iap/verify expects, or null off-store.
  String? get apiPlatform {
    switch (kind) {
      case StoreKind.apple:
        return 'apple';
      case StoreKind.google:
        return 'google';
      case StoreKind.none:
        return null;
    }
  }

  bool get isApple => kind == StoreKind.apple;
  bool get isGoogle => kind == StoreKind.google;
}

/// Minimum iOS version whose StoreKit 2 signed-transaction JWS the backend can
/// verify.
const int kMinStoreKit2IosMajor = 15;

/// Resolves the store platform for the current device.
StorePlatform detectStorePlatform() {
  return storePlatformFrom(
    isIOS: Platform.isIOS,
    isAndroid: Platform.isAndroid,
    osVersion: Platform.operatingSystemVersion,
  );
}

/// Pure resolver behind [detectStorePlatform], split out so the version-gating
/// logic is unit-testable without a real device.
///
/// [osVersion] is the raw `Platform.operatingSystemVersion` string, e.g.
/// `"Version 17.5 (Build 21F79)"` on iOS. When the major version cannot be
/// parsed we assume support — `IapGateway.isAvailable()` still gates at runtime.
StorePlatform storePlatformFrom({
  required bool isIOS,
  required bool isAndroid,
  required String osVersion,
}) {
  if (isIOS) {
    final major = _firstInt(osVersion);
    if (major != null && major < kMinStoreKit2IosMajor) {
      return const StorePlatform(
        kind: StoreKind.apple,
        canPurchase: false,
        blockedReason:
            'In-app purchases require iOS $kMinStoreKit2IosMajor or newer. '
            'Please update iOS to subscribe.',
      );
    }
    return const StorePlatform(kind: StoreKind.apple, canPurchase: true);
  }
  if (isAndroid) {
    return const StorePlatform(kind: StoreKind.google, canPurchase: true);
  }
  return const StorePlatform(kind: StoreKind.none, canPurchase: false);
}

/// First run of digits in [s] as an int, or null when there is none.
int? _firstInt(String s) {
  final match = RegExp(r'\d+').firstMatch(s);
  return match == null ? null : int.tryParse(match.group(0)!);
}
