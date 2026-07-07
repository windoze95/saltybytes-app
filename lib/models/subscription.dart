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
  });

  final String tier;
  final int allergenAnalysesUsed;
  final int webSearchesUsed;
  final int aiGenerationsUsed;
  final int videoImportsUsed;
  final int aiImportsUsed;
  final DateTime? monthlyResetAt;
  final TierLimits limits;

  bool get isPremium => tier == 'premium';
  bool get isPlus => tier == 'plus';
  bool get isUnlimited => tier == 'unlimited';

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

  factory SubscriptionInfo.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? limitsJson,
  }) {
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null) return value;
      }
      return null;
    }

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
    );
  }
}
