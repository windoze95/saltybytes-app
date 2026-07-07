import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/subscription.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'auth_provider.dart';

/// Fetches GET /v1/subscription -> {"subscription": {...}}.
///
/// Watches auth state so the cached tier/usage counters reset on logout and
/// refetch for the next signed-in account instead of leaking across users.
final subscriptionProvider = FutureProvider<SubscriptionInfo>((ref) async {
  final apiClient = ref.watch(apiClientProvider);

  final authStatus = ref.watch(authStateProvider).valueOrNull;
  if (authStatus != AuthStatus.authenticated) {
    return const SubscriptionInfo();
  }

  final response = await apiClient.get(ApiEndpoints.subscription);

  final data = response.data;
  if (data is Map<String, dynamic> &&
      data['subscription'] is Map<String, dynamic>) {
    return SubscriptionInfo.fromJson(
      data['subscription'] as Map<String, dynamic>,
      limitsJson: data['limits'] is Map<String, dynamic>
          ? data['limits'] as Map<String, dynamic>
          : null,
    );
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
