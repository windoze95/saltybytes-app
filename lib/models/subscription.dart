/// Subscription info returned by GET /v1/subscription.
///
/// The backend serializes models.Subscription with Go's default field-name
/// keys (PascalCase), so parsing accepts PascalCase, snake_case, and
/// camelCase defensively. The sibling "limits" object (snake_case, additive)
/// carries the tier's monthly allowances so the app never hardcodes them.
class TierLimits {
  const TierLimits({
    this.aiGenerations = 10,
    this.webSearches = 10,
    this.allergenAnalyses = 3,
    this.videoImports = 1,
    this.aiImports = 10,
  });

  /// -1 means unlimited.
  final int aiGenerations;
  final int webSearches;
  final int allergenAnalyses;
  final int videoImports;
  final int aiImports;

  factory TierLimits.fromJson(Map<String, dynamic> json) {
    int pick(String key, int fallback) {
      final v = json[key];
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return TierLimits(
      aiGenerations: pick('ai_generations', 10),
      webSearches: pick('web_searches', 10),
      allergenAnalyses: pick('allergen_analyses', 3),
      videoImports: pick('video_imports', 1),
      aiImports: pick('ai_imports', 10),
    );
  }
}

/// The native store subscription backing the current tier, when it came from
/// an in-app purchase. Mirrors the additive snake_case `store` object the API
/// returns alongside the (PascalCase) subscription. Null for free accounts and
/// tiers granted outside the stores (promo/admin).
class StoreInfo {
  const StoreInfo({
    required this.platform,
    required this.productId,
    this.status,
    this.autoRenew,
    this.expiresAt,
    this.environment,
  });

  /// 'apple' or 'google'.
  final String platform;
  final String productId;
  final String? status;
  final bool? autoRenew;
  final DateTime? expiresAt;

  /// 'Production' / 'Sandbox' (Apple) or 'Production' / 'Test' (Google).
  final String? environment;

  bool get isApple => platform == 'apple';
  bool get isGoogle => platform == 'google';

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    bool? toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return null;
    }

    final expiresRaw = json['expires_at'];
    return StoreInfo(
      platform: (json['platform'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      status: json['status']?.toString(),
      autoRenew: toBool(json['auto_renew']),
      expiresAt:
          expiresRaw == null ? null : DateTime.tryParse(expiresRaw.toString()),
      environment: json['environment']?.toString(),
    );
  }
}

class SubscriptionInfo {
  const SubscriptionInfo({
    this.tier = 'free',
    this.allergenAnalysesUsed = 0,
    this.webSearchesUsed = 0,
    this.aiGenerationsUsed = 0,
    this.videoImportsUsed = 0,
    this.aiImportsUsed = 0,
    this.monthlyResetAt,
    this.limits = const TierLimits(),
    this.store,
    this.accountToken,
  });

  final String tier;
  final int allergenAnalysesUsed;
  final int webSearchesUsed;
  final int aiGenerationsUsed;
  final int videoImportsUsed;
  final int aiImportsUsed;
  final DateTime? monthlyResetAt;
  final TierLimits limits;

  /// The backing store subscription, when the tier came from a native
  /// purchase. Drives the "Manage Subscription" affordance.
  final StoreInfo? store;

  /// Opaque per-account UUID the stores use to bind a purchase to this
  /// SaltyBytes account (passed as `applicationUserName` on every purchase).
  final String? accountToken;

  bool get isPremium => tier == 'premium';
  bool get isPlus => tier == 'plus';
  bool get isUnlimited => tier == 'unlimited';

  /// True when the current tier is backed by a native store subscription.
  bool get hasStoreSubscription => store != null;

  /// Rank for "can this tier still upgrade" decisions. Unknown tiers rank
  /// highest so the screen never offers a downgrade to something it doesn't
  /// understand.
  int get tierRank {
    switch (tier) {
      case 'free':
        return 0;
      case 'plus':
        return 1;
      case 'premium':
        return 2;
      default:
        return 3;
    }
  }

  String get displayName {
    switch (tier) {
      case 'free':
        return 'Free';
      case 'plus':
        return 'Plus';
      case 'premium':
        return 'Premium';
      case 'unlimited':
        return 'Unlimited';
      default:
        return tier.isEmpty
            ? 'Free'
            : tier[0].toUpperCase() + tier.substring(1);
    }
  }

  /// [storeJson] and [accountToken] are envelope-level siblings of the
  /// subscription object (`{"subscription": {...}, "store": {...},
  /// "account_token": "..."}`); they are also read defensively from [json]
  /// itself so callers that inline them still parse.
  factory SubscriptionInfo.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? limitsJson,
    Map<String, dynamic>? storeJson,
    String? accountToken,
  }) {
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null) return value;
      }
      return null;
    }

    final storeRaw = storeJson ??
        (json['store'] is Map<String, dynamic>
            ? json['store'] as Map<String, dynamic>
            : null);
    final resolvedAccountToken = accountToken ??
        pick(['account_token', 'AccountToken', 'accountToken'])?.toString();

    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final resetAtRaw =
        pick(['monthly_reset_at', 'MonthlyResetAt', 'monthlyResetAt']);

    return SubscriptionInfo(
      tier: (pick(['tier', 'Tier']) ?? 'free').toString(),
      allergenAnalysesUsed: toInt(pick([
        'allergen_analyses_used',
        'AllergenAnalysesUsed',
        'allergenAnalysesUsed',
      ])),
      webSearchesUsed: toInt(pick([
        'web_searches_used',
        'WebSearchesUsed',
        'webSearchesUsed',
      ])),
      aiGenerationsUsed: toInt(pick([
        'ai_generations_used',
        'AIGenerationsUsed',
        'aiGenerationsUsed',
      ])),
      videoImportsUsed: toInt(pick([
        'video_imports_used',
        'VideoImportsUsed',
        'videoImportsUsed',
      ])),
      aiImportsUsed: toInt(pick([
        'ai_imports_used',
        'AIImportsUsed',
        'aiImportsUsed',
      ])),
      monthlyResetAt: resetAtRaw == null
          ? null
          : DateTime.tryParse(resetAtRaw.toString()),
      limits: limitsJson == null
          ? const TierLimits()
          : TierLimits.fromJson(limitsJson),
      store: storeRaw != null && (storeRaw['platform'] ?? '') != ''
          ? StoreInfo.fromJson(storeRaw)
          : null,
      accountToken:
          (resolvedAccountToken?.isEmpty ?? true) ? null : resolvedAccountToken,
    );
  }
}
