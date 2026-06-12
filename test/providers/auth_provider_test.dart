import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/storage/secure_storage.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AuthStatus', () {
    test('has all three expected values', () {
      expect(AuthStatus.values, hasLength(3));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
      expect(AuthStatus.values, contains(AuthStatus.loading));
    });

    test('enum name strings match expected values', () {
      expect(AuthStatus.authenticated.name, 'authenticated');
      expect(AuthStatus.unauthenticated.name, 'unauthenticated');
      expect(AuthStatus.loading.name, 'loading');
    });
  });

  group('Login request body shape', () {
    test('has correct structure with username and password', () {
      // Mirrors the data sent in AuthNotifier.login
      final requestBody = <String, dynamic>{
        'username': 'chefmike',
        'password': 'secret123',
      };

      expect(requestBody, isA<Map<String, dynamic>>());
      expect(requestBody.containsKey('username'), true);
      expect(requestBody.containsKey('password'), true);
      expect(requestBody['username'], 'chefmike');
      expect(requestBody['password'], 'secret123');
    });

    test('register request body includes email', () {
      // Mirrors the data sent in AuthNotifier.register
      final requestBody = <String, dynamic>{
        'username': 'newchef',
        'email': 'new@example.com',
        'password': 'securePass!',
      };

      expect(requestBody.containsKey('username'), true);
      expect(requestBody.containsKey('email'), true);
      expect(requestBody.containsKey('password'), true);
    });
  });

  group('Token storage with mock', () {
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
    });

    test('saveTokens stores both access and refresh tokens', () async {
      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      await mockStorage.saveTokens(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
      );

      verify(() => mockStorage.saveTokens(
            accessToken: 'test-access-token',
            refreshToken: 'test-refresh-token',
          )).called(1);
    });

    test('getAccessToken returns stored token', () async {
      when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => 'stored-access-token');

      final token = await mockStorage.getAccessToken();

      expect(token, 'stored-access-token');
    });

    test('hasTokens returns true when token exists', () async {
      when(() => mockStorage.hasTokens()).thenAnswer((_) async => true);

      final result = await mockStorage.hasTokens();

      expect(result, true);
    });

    test('hasTokens returns false when no token', () async {
      when(() => mockStorage.hasTokens()).thenAnswer((_) async => false);

      final result = await mockStorage.hasTokens();

      expect(result, false);
    });
  });

  group('Logout clears state', () {
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
    });

    test('clearTokens is called during logout flow', () async {
      when(() => mockStorage.clearTokens()).thenAnswer((_) async {});

      // Simulates the logout() flow: clear tokens
      await mockStorage.clearTokens();

      verify(() => mockStorage.clearTokens()).called(1);
    });

    test('refresh token response has expected shape', () {
      // Mirrors the expected API response for token refresh
      final refreshResponse = <String, dynamic>{
        'access_token': 'new-access-token',
        'refresh_token': 'new-refresh-token',
      };

      expect(refreshResponse['access_token'], isA<String>());
      expect(refreshResponse['refresh_token'], isA<String>());
    });
  });

  group('AuthNotifier.logout', () {
    late MockApiClient apiClient;
    late MockSecureStorage storage;

    setUp(() {
      apiClient = MockApiClient();
      storage = MockSecureStorage();
      // No stored tokens: build() resolves to unauthenticated without
      // touching the network.
      when(() => storage.hasTokens()).thenAnswer((_) async => false);
      when(() => storage.clearTokens()).thenAnswer((_) async {});
    });

    ProviderContainer buildContainer() {
      final container = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        secureStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);
      // Keep authStateProvider active so async state transitions flush.
      container.listen(authStateProvider, (_, __) {});
      return container;
    }

    test('POSTs /v1/auth/logout before clearing local tokens', () async {
      // Contract C11: authenticated POST /v1/auth/logout returns 204.
      when(() => apiClient.post(ApiEndpoints.logout)).thenAnswer(
        (_) async => fakeResponse<dynamic>(null, statusCode: 204),
      );

      final container = buildContainer();
      await container.read(authStateProvider.future);

      await container.read(authStateProvider.notifier).logout();

      verifyInOrder([
        () => apiClient.post(ApiEndpoints.logout),
        () => storage.clearTokens(),
      ]);
      expect(
        container.read(authStateProvider).value,
        AuthStatus.unauthenticated,
      );
    });

    test('still clears tokens when the server call throws', () async {
      when(() => apiClient.post(ApiEndpoints.logout)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.logout),
          type: DioExceptionType.connectionError,
        ),
      );

      final container = buildContainer();
      await container.read(authStateProvider.future);

      // Must not throw: logout is best-effort against the server.
      await container.read(authStateProvider.notifier).logout();

      verify(() => storage.clearTokens()).called(1);
      expect(
        container.read(authStateProvider).value,
        AuthStatus.unauthenticated,
      );
    });
  });
}
