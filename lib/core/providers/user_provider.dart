import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'auth_provider.dart';

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, User?>(CurrentUserNotifier.new);

class CurrentUserNotifier extends AsyncNotifier<User?> {
  late ApiClient _apiClient;

  @override
  Future<User?> build() async {
    _apiClient = ref.watch(apiClientProvider);

    final authStatus = ref.watch(authStateProvider).valueOrNull;
    if (authStatus != AuthStatus.authenticated) {
      return null;
    }

    return _fetchProfile();
  }

  Future<User?> _fetchProfile() async {
    final response = await _apiClient.get(ApiEndpoints.userProfile);
    final data = response.data as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }

  Future<void> updateSettings(UserSettings settings) async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;

    state = AsyncData(currentUser.copyWith(settings: settings));

    await AsyncValue.guard(() async {
      await _apiClient.put(
        ApiEndpoints.userSettings,
        data: settings.toJson(),
      );
      return currentUser.copyWith(settings: settings);
    });
  }

  Future<void> updatePersonalization(Personalization personalization) async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;

    state = AsyncData(
      currentUser.copyWith(personalization: personalization),
    );

    await AsyncValue.guard(() async {
      await _apiClient.put(
        ApiEndpoints.userPersonalization,
        data: personalization.toJson(),
      );
      return currentUser.copyWith(personalization: personalization);
    });
  }
}
