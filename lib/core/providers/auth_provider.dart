import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../storage/secure_storage.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
  loading,
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthStatus> {
  late SecureStorage _secureStorage;
  late ApiClient _apiClient;

  @override
  Future<AuthStatus> build() async {
    _secureStorage = ref.watch(secureStorageProvider);
    _apiClient = ref.watch(apiClientProvider);

    _apiClient.onForceLogout = () {
      _forceLogout();
    };

    final hasTokens = await _secureStorage.hasTokens();
    if (!hasTokens) {
      return AuthStatus.unauthenticated;
    }

    // Validate the existing token by fetching user profile
    try {
      await _apiClient.get(ApiEndpoints.userProfile);
      return AuthStatus.authenticated;
    } on DioException {
      // Token might be expired; try refresh
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken == null) {
          await _secureStorage.clearTokens();
          return AuthStatus.unauthenticated;
        }

        final response = await _apiClient.post(
          ApiEndpoints.refreshToken,
          data: {'refresh_token': refreshToken},
        );

        await _secureStorage.saveTokens(
          accessToken: response.data['access_token'] as String,
          refreshToken: response.data['refresh_token'] as String,
        );
        return AuthStatus.authenticated;
      } catch (_) {
        await _secureStorage.clearTokens();
        return AuthStatus.unauthenticated;
      }
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      await _secureStorage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );

      if (data['user'] != null) {
        try {
          final user = User.fromJson(data['user'] as Map<String, dynamic>);
          await _secureStorage.saveUserId(user.id);
        } catch (_) {
          // User parsing is best-effort; tokens are already saved
        }
      }

      return AuthStatus.authenticated;
    });
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      await _secureStorage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );

      if (data['user'] != null) {
        try {
          final user = User.fromJson(data['user'] as Map<String, dynamic>);
          await _secureStorage.saveUserId(user.id);
        } catch (_) {
          // User parsing is best-effort; tokens are already saved
        }
      }

      return AuthStatus.authenticated;
    });
  }

  void enterDemoMode() {
    state = const AsyncData(AuthStatus.authenticated);
  }

  Future<void> logout() async {
    try {
      // No server-side logout endpoint; just clear local tokens
    } catch (_) {
      // Best-effort server logout
    }
    await _secureStorage.clearTokens();
    state = const AsyncData(AuthStatus.unauthenticated);
  }

  void _forceLogout() async {
    await _secureStorage.clearTokens();
    state = const AsyncData(AuthStatus.unauthenticated);
  }
}
