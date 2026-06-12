import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/subscription.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Fetches GET /v1/subscription -> {"subscription": {...}}.
final subscriptionProvider = FutureProvider<SubscriptionInfo>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.subscription);

  final data = response.data;
  if (data is Map<String, dynamic> &&
      data['subscription'] is Map<String, dynamic>) {
    return SubscriptionInfo.fromJson(
        data['subscription'] as Map<String, dynamic>);
  }
  return const SubscriptionInfo();
});

final subscriptionActionsProvider = Provider<SubscriptionActions>((ref) {
  return SubscriptionActions(apiClient: ref.watch(apiClientProvider));
});

class SubscriptionActions {
  const SubscriptionActions({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// POST /v1/subscription/upgrade.
  ///
  /// Currently returns 501 ("paid plans are not yet available") from the
  /// backend; the DioException's [ApiError] carries that message.
  Future<SubscriptionInfo> upgrade() async {
    final response = await _apiClient.post(ApiEndpoints.subscriptionUpgrade);
    final data = response.data;
    if (data is Map<String, dynamic> &&
        data['subscription'] is Map<String, dynamic>) {
      return SubscriptionInfo.fromJson(
          data['subscription'] as Map<String, dynamic>);
    }
    return const SubscriptionInfo(tier: 'premium');
  }
}
