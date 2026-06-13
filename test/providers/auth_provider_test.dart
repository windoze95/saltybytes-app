import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/storage/secure_storage.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

DioException _httpError(String path, int statusCode,
    [Map<String, dynamic>? body]) {
  final requestOptions = RequestOptions(path: path);
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: body,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  late MockApiClient apiClient;
  late MockSecureStorage storage;

  setUp(() {
    apiClient = MockApiClient();
    storage = MockSecureStorage();
    when(() => storage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
    when(() => storage.saveUserId(any())).thenAnswer((_) async {});
    when(() => storage.clearTokens()).thenAnswer((_) async {});
  });

  /// Builds a container with the mocks installed and a listener attached so
  /// async state transitions flush (Riverpod gotcha: without a listener the
  /// provider is never kept alive).
  ProviderContainer buildContainer() {
    final container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      secureStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    container.listen(authStateProvider, (_, __) {});
    return container;
  }

  group('AuthNotifier.build (startup session restore)', () {
    test('resolves unauthenticated when no tokens are stored, without '
        'touching the network', () async {
      when(() => storage.hasTokens()).thenAnswer((_) async => false);

      final container = buildContainer();
      final status = await container.read(authStateProvider.future);

      expect(status, AuthStatus.unauthenticated);
      verifyNever(() => apiClient.get(any()));
    });

    test('resolves authenticated when stored token validates against '
        'GET /v1/users/me', () async {
      when(() => storage.hasTokens()).thenAnswer((_) async => true);
      when(() => apiClient.get(ApiEndpoints.userProfile)).thenAnswer(
          (_) async => fakeResponse<dynamic>({'user': testUserJson()}));

      final container = buildContainer();
      final status = await container.read(authStateProvider.future);

      expect(status, AuthStatus.authenticated);
    });

    test('refreshes an expired token and persists the new pair', () async {
      when(() => storage.hasTokens()).thenAnswer((_) async => true);
      when(() => apiClient.get(ApiEndpoints.userProfile))
          .thenThrow(_httpError(ApiEndpoints.userProfile, 401));
      when(() => storage.getRefreshToken())
          .thenAnswer((_) async => 'old-refresh');
      when(() => apiClient.post(
            ApiEndpoints.refreshToken,
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          }));

      final container = buildContainer();
      final status = await container.read(authStateProvider.future);

      expect(status, AuthStatus.authenticated);
      final body = verify(() => apiClient.post(
            ApiEndpoints.refreshToken,
            data: captureAny(named: 'data'),
          )).captured.single;
      expect(body, {'refresh_token': 'old-refresh'});
      verify(() => storage.saveTokens(
            accessToken: 'new-access',
            refreshToken: 'new-refresh',
          )).called(1);
    });

    test('clears tokens and resolves unauthenticated when the refresh '
        'is rejected', () async {
      when(() => storage.hasTokens()).thenAnswer((_) async => true);
      when(() => apiClient.get(ApiEndpoints.userProfile))
          .thenThrow(_httpError(ApiEndpoints.userProfile, 401));
      when(() => storage.getRefreshToken())
          .thenAnswer((_) async => 'stale-refresh');
      when(() => apiClient.post(
            ApiEndpoints.refreshToken,
            data: any(named: 'data'),
          )).thenThrow(_httpError(ApiEndpoints.refreshToken, 401));

      final container = buildContainer();
      final status = await container.read(authStateProvider.future);

      expect(status, AuthStatus.unauthenticated);
      verify(() => storage.clearTokens()).called(1);
    });

    test('clears tokens when the access token is invalid and no refresh '
        'token exists', () async {
      when(() => storage.hasTokens()).thenAnswer((_) async => true);
      when(() => apiClient.get(ApiEndpoints.userProfile))
          .thenThrow(_httpError(ApiEndpoints.userProfile, 401));
      when(() => storage.getRefreshToken()).thenAnswer((_) async => null);

      final container = buildContainer();
      final status = await container.read(authStateProvider.future);

      expect(status, AuthStatus.unauthenticated);
      verify(() => storage.clearTokens()).called(1);
      verifyNever(() => apiClient.post(
            ApiEndpoints.refreshToken,
            data: any(named: 'data'),
          ));
    });
  });

  group('AuthNotifier.login', () {
    setUp(() {
      // No stored tokens: build() resolves unauthenticated offline.
      when(() => storage.hasTokens()).thenAnswer((_) async => false);
    });

    test('success persists tokens + user id and lands on authenticated',
        () async {
      when(() => apiClient.post(
            ApiEndpoints.login,
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'access_token': 'acc-1',
            'refresh_token': 'ref-1',
            'user': testUserJson(id: 'u-42', username: 'chefmike'),
          }));

      final container = buildContainer();
      await container.read(authStateProvider.future);

      await container
          .read(authStateProvider.notifier)
          .login(username: 'chefmike', password: 'secret123');

      final body = verify(() => apiClient.post(
            ApiEndpoints.login,
            data: captureAny(named: 'data'),
          )).captured.single;
      expect(body, {'username': 'chefmike', 'password': 'secret123'});
      verify(() => storage.saveTokens(
            accessToken: 'acc-1',
            refreshToken: 'ref-1',
          )).called(1);
      verify(() => storage.saveUserId('u-42')).called(1);
      expect(
        container.read(authStateProvider).value,
        AuthStatus.authenticated,
      );
    });

    test('still authenticates when the response has no user object',
        () async {
      when(() => apiClient.post(
            ApiEndpoints.login,
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'access_token': 'acc-1',
            'refresh_token': 'ref-1',
          }));

      final container = buildContainer();
      await container.read(authStateProvider.future);

      await container
          .read(authStateProvider.notifier)
          .login(username: 'chefmike', password: 'secret123');

      expect(
        container.read(authStateProvider).value,
        AuthStatus.authenticated,
      );
      verifyNever(() => storage.saveUserId(any()));
    });

    test('user parsing is best-effort: a malformed user object does not '
        'fail the login', () async {
      when(() => apiClient.post(
            ApiEndpoints.login,
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'access_token': 'acc-1',
            'refresh_token': 'ref-1',
            'user': {'bogus': true}, // missing id/username/email/createdAt
          }));

      final container = buildContainer();
      await container.read(authStateProvider.future);

      await container
          .read(authStateProvider.notifier)
          .login(username: 'chefmike', password: 'secret123');

      expect(
        container.read(authStateProvider).value,
        AuthStatus.authenticated,
      );
      verify(() => storage.saveTokens(
            accessToken: 'acc-1',
            refreshToken: 'ref-1',
          )).called(1);
      verifyNever(() => storage.saveUserId(any()));
    });

    test('401 from the server lands in an error state without saving tokens',
        () async {
      when(() => apiClient.post(
            ApiEndpoints.login,
            data: any(named: 'data'),
          )).thenThrow(_httpError(
        ApiEndpoints.login,
        401,
        {'error': 'invalid credentials'},
      ));

      final container = buildContainer();
      await container.read(authStateProvider.future);

      await container
          .read(authStateProvider.notifier)
          .login(username: 'chefmike', password: 'wrong');

      final state = container.read(authStateProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<DioException>());
      verifyNever(() => storage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });

    test('malformed response (missing tokens) lands in an error state',
        () async {
      when(() => apiClient.post(
            ApiEndpoints.login,
            data: any(named: 'data'),
          )).thenAnswer(
              (_) async => fakeResponse<dynamic>({'unexpected': 'shape'}));

      final container = buildContainer();
      await container.read(authStateProvider.future);

      await container
          .read(authStateProvider.notifier)
          .login(username: 'chefmike', password: 'secret123');

      expect(container.read(authStateProvider).hasError, isTrue);
      verifyNever(() => storage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });
  });

  group('AuthNotifier.register', () {
    setUp(() {
      when(() => storage.hasTokens()).thenAnswer((_) async => false);
    });

    test('POSTs username/email/password, persists tokens, authenticates',
        () async {
      when(() => apiClient.post(
            ApiEndpoints.register,
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'access_token': 'acc-new',
            'refresh_token': 'ref-new',
            'user': testUserJson(id: 'u-new', username: 'newchef'),
          }));

      final container = buildContainer();
      await container.read(authStateProvider.future);

      await container.read(authStateProvider.notifier).register(
            username: 'newchef',
            email: 'new@example.com',
            password: 'securePass!',
          );

      final body = verify(() => apiClient.post(
            ApiEndpoints.register,
            data: captureAny(named: 'data'),
          )).captured.single;
      expect(body, {
        'username': 'newchef',
        'email': 'new@example.com',
        'password': 'securePass!',
      });
      verify(() => storage.saveTokens(
            accessToken: 'acc-new',
            refreshToken: 'ref-new',
          )).called(1);
      verify(() => storage.saveUserId('u-new')).called(1);
      expect(
        container.read(authStateProvider).value,
        AuthStatus.authenticated,
      );
    });

    test('409 (username taken) lands in an error state', () async {
      when(() => apiClient.post(
            ApiEndpoints.register,
            data: any(named: 'data'),
          )).thenThrow(_httpError(
        ApiEndpoints.register,
        409,
        {'error': 'username already exists'},
      ));

      final container = buildContainer();
      await container.read(authStateProvider.future);

      await container.read(authStateProvider.notifier).register(
            username: 'taken',
            email: 'taken@example.com',
            password: 'pw',
          );

      expect(container.read(authStateProvider).hasError, isTrue);
      verifyNever(() => storage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });
  });

  group('AuthNotifier.logout', () {
    setUp(() {
      // No stored tokens: build() resolves to unauthenticated without
      // touching the network.
      when(() => storage.hasTokens()).thenAnswer((_) async => false);
    });

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
