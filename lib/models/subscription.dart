/// Subscription info returned by GET /v1/subscription.
///
/// The backend serializes models.Subscription with Go's default field-name
/// keys (PascalCase), so parsing accepts PascalCase, snake_case, and
/// camelCase defensively.
class SubscriptionInfo {
  const SubscriptionInfo({
    this.tier = 'free',
    this.allergenAnalysesUsed = 0,
    this.webSearchesUsed = 0,
    this.aiGenerationsUsed = 0,
    this.monthlyResetAt,
  });

  final String tier;
  final int allergenAnalysesUsed;
  final int webSearchesUsed;
  final int aiGenerationsUsed;
  final DateTime? monthlyResetAt;

  /// Free-tier monthly limits (mirrors the backend's Subscription.CanUse*).
  static const int freeAllergenAnalysesLimit = 5;
  static const int freeWebSearchesLimit = 20;
  static const int freeAiGenerationsLimit = 50;

  bool get isPremium => tier == 'premium';

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
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
      monthlyResetAt: resetAtRaw == null
          ? null
          : DateTime.tryParse(resetAtRaw.toString()),
    );
  }
}
