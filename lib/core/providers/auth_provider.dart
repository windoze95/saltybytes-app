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

    // Validate the session by fetching the profile. The ApiClient already
    // handles an expired access token internally (401 -> refresh -> retry),
    // so a 401/403 surfacing HERE means the refresh was definitively
    // rejected: the session is over. Anything else — offline, rate-limited,
    // server down — says nothing about the session, so keep the user signed
    // in and let per-request refresh recover when the network does.
    //
    // The old behavior (wipe tokens on ANY failure, then run a second,
    // racing refresh here) logged users out every time a cold start hit a
    // network blip or the rate limiter.
    try {
      await _apiClient.get(ApiEndpoints.userProfile);
      return AuthStatus.authenticated;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await _secureStorage.clearTokens();
        return AuthStatus.unauthenticated;
      }
      return AuthStatus.authenticated;
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

  Future<void> logout() async {
    // Best-effort server-side logout: POST /v1/auth/logout (contract C11)
    // revokes all of the user's refresh tokens by bumping the token version.
    // Errors are swallowed deliberately — logout must always succeed locally,
    // even when offline or the server is unreachable.
    try {
      await _apiClient
          .post(ApiEndpoints.logout)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore network/server failures; local logout proceeds regardless.
    }
    await _secureStorage.clearTokens();
    state = const AsyncData(AuthStatus.unauthenticated);
  }

  void _forceLogout() async {
    await _secureStorage.clearTokens();
    state = const AsyncData(AuthStatus.unauthenticated);
  }
}
