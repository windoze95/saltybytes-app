import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';

import '../../helpers/test_helpers.dart';

/// These tests run the REAL ApiClient interceptor chain (auth header
/// injection, 401 -> refresh -> retry, force logout, ApiError wrapping)
/// against [FakeHttpClientAdapter]s, fully offline.
void main() {
  late MockSecureStorage storage;

  /// Mutable token state behind the storage mock so the retry path reads
  /// the refreshed token like the real keychain would.
  String? currentAccessToken;
  String? currentRefreshToken;

  setUp(() {
    storage = MockSecureStorage();
    currentAccessToken = null;
    currentRefreshToken = null;
    when(() => storage.getAccessToken())
        .thenAnswer((_) async => currentAccessToken);
    when(() => storage.getRefreshToken())
        .thenAnswer((_) async => currentRefreshToken);
    when(() => storage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((invocation) async {
      currentAccessToken =
          invocation.namedArguments[#accessToken] as String;
      currentRefreshToken =
          invocation.namedArguments[#refreshToken] as String;
    });
  });

  /// Builds an ApiClient whose main Dio and refresh Dio are both served by
  /// fake adapters.
  ({ApiClient client, FakeHttpClientAdapter main, FakeHttpClientAdapter refresh})
      buildClient({
    required Future<ResponseBody> Function(RequestOptions) mainHandler,
    Future<ResponseBody> Function(RequestOptions)? refreshHandler,
  }) {
    final mainAdapter = FakeHttpClientAdapter(mainHandler);
    final refreshAdapter = FakeHttpClientAdapter(refreshHandler ??
        (_) async => jsonResponseBody({'error': 'unexpected refresh call'},
            statusCode: 500));

    final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl))
      ..httpClientAdapter = refreshAdapter;

    final client = ApiClient(secureStorage: storage, refreshDio: refreshDio);
    client.dio.httpClientAdapter = mainAdapter;

    return (client: client, main: mainAdapter, refresh: refreshAdapter);
  }

  group('request headers', () {
    test('attaches Authorization: Bearer <token> when a token is stored',
        () async {
      currentAccessToken = 'tok-123';
      final harness = buildClient(
        mainHandler: (_) async => jsonResponseBody({'ok': true}),
      );

      await harness.client.get('/v1/test');

      final sent = harness.main.requests.single;
      expect(sent.headers['Authorization'], 'Bearer tok-123');
    });

    test('omits the Authorization header when no token is stored', () async {
      final harness = buildClient(
        mainHandler: (_) async => jsonResponseBody({'ok': true}),
      );

      await harness.client.get('/v1/test');

      final sent = harness.main.requests.single;
      expect(sent.headers.containsKey('Authorization'), isFalse);
    });

    test('omits X-SaltyBytes-Identifier when the SALTYBYTES_ID dart-define '
        'is not set (presence requires --dart-define, untestable here)',
        () async {
      final harness = buildClient(
        mainHandler: (_) async => jsonResponseBody({'ok': true}),
      );

      await harness.client.get('/v1/test');

      final sent = harness.main.requests.single;
      expect(sent.headers.containsKey('X-SaltyBytes-Identifier'), isFalse);
      // JSON defaults always apply.
      expect(sent.headers['Accept'], 'application/json');
    });
  });

  group('401 -> token refresh flow', () {
    test('refresh succeeds: new tokens persisted, original request retried '
        'with the new token, response resolves', () async {
      currentAccessToken = 'stale-access';
      currentRefreshToken = 'refresh-1';

      final harness = buildClient(
        mainHandler: (options) async {
          if (options.headers['Authorization'] == 'Bearer stale-access') {
            return jsonResponseBody(
              {'error': 'token expired'},
              statusCode: 401,
            );
          }
          return jsonResponseBody({'ok': true});
        },
        refreshHandler: (options) async {
          expect(options.path, ApiEndpoints.refreshToken);
          expect(options.method, 'POST');
          expect(options.data, {'refresh_token': 'refresh-1'});
          return jsonResponseBody({
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          });
        },
      );

      var forcedLogout = false;
      harness.client.onForceLogout = () => forcedLogout = true;

      final response = await harness.client.get('/v1/test');

      expect(response.statusCode, 200);
      expect(response.data, {'ok': true});

      // One refresh call, and the retry carried the refreshed token.
      expect(harness.refresh.requests, hasLength(1));
      expect(harness.main.requests, hasLength(2));
      expect(
        harness.main.requests.last.headers['Authorization'],
        'Bearer new-access',
      );
      verify(() => storage.saveTokens(
            accessToken: 'new-access',
            refreshToken: 'new-refresh',
          )).called(1);
      expect(forcedLogout, isFalse);
    });

    test('refresh rejected with 401: forces logout and surfaces the '
        'original error as ApiError', () async {
      currentAccessToken = 'stale-access';
      currentRefreshToken = 'revoked-refresh';

      final harness = buildClient(
        mainHandler: (_) async =>
            jsonResponseBody({'error': 'token expired'}, statusCode: 401),
        refreshHandler: (_) async =>
            jsonResponseBody({'error': 'refresh revoked'}, statusCode: 401),
      );

      var forcedLogout = false;
      harness.client.onForceLogout = () => forcedLogout = true;

      await expectLater(
        harness.client.get('/v1/test'),
        throwsA(isA<DioException>().having(
          (e) => (e.error as ApiError).statusCode,
          'wrapped ApiError statusCode',
          401,
        )),
      );

      expect(forcedLogout, isTrue);
      expect(harness.refresh.requests, hasLength(1));
      // The original request must NOT be retried.
      expect(harness.main.requests, hasLength(1));
      verifyNever(() => storage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });

    test('401 from the refresh endpoint itself forces logout without '
        'attempting another refresh', () async {
      currentAccessToken = 'whatever';
      currentRefreshToken = 'refresh-1';

      final harness = buildClient(
        mainHandler: (_) async =>
            jsonResponseBody({'error': 'invalid'}, statusCode: 401),
      );

      var forcedLogout = false;
      harness.client.onForceLogout = () => forcedLogout = true;

      await expectLater(
        harness.client.post(
          ApiEndpoints.refreshToken,
          data: {'refresh_token': 'refresh-1'},
        ),
        throwsA(isA<DioException>()),
      );

      expect(forcedLogout, isTrue);
      expect(harness.refresh.requests, isEmpty);
    });

    test('401 with no stored refresh token forces logout without a '
        'refresh attempt', () async {
      currentAccessToken = 'stale-access';
      currentRefreshToken = null;

      final harness = buildClient(
        mainHandler: (_) async =>
            jsonResponseBody({'error': 'token expired'}, statusCode: 401),
      );

      var forcedLogout = false;
      harness.client.onForceLogout = () => forcedLogout = true;

      await expectLater(
        harness.client.get('/v1/test'),
        throwsA(isA<DioException>()),
      );

      expect(forcedLogout, isTrue);
      expect(harness.refresh.requests, isEmpty);
    });

    test('transient refresh failure (429) does NOT force logout and '
        'surfaces the transient status instead of the original 401',
        () async {
      currentAccessToken = 'stale-access';
      currentRefreshToken = 'refresh-1';

      final harness = buildClient(
        mainHandler: (_) async =>
            jsonResponseBody({'error': 'token expired'}, statusCode: 401),
        refreshHandler: (_) async =>
            jsonResponseBody({'error': 'Too many requests'}, statusCode: 429),
      );

      var forcedLogout = false;
      harness.client.onForceLogout = () => forcedLogout = true;

      await expectLater(
        harness.client.get('/v1/test'),
        throwsA(isA<DioException>().having(
          (e) => (e.error as ApiError).statusCode,
          'wrapped ApiError statusCode',
          429,
        )),
      );

      // A rate limiter blip says nothing about the session.
      expect(forcedLogout, isFalse);
      verifyNever(() => storage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });

    test('refresh network failure does NOT force logout (offline cold '
        'start must not wipe the session)', () async {
      currentAccessToken = 'stale-access';
      currentRefreshToken = 'refresh-1';

      final harness = buildClient(
        mainHandler: (_) async =>
            jsonResponseBody({'error': 'token expired'}, statusCode: 401),
        refreshHandler: (options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        },
      );

      var forcedLogout = false;
      harness.client.onForceLogout = () => forcedLogout = true;

      await expectLater(
        harness.client.get('/v1/test'),
        throwsA(isA<DioException>().having(
          (e) => (e.error as ApiError).message,
          'wrapped ApiError message',
          'No internet connection.',
        )),
      );

      expect(forcedLogout, isFalse);
    });

    test('concurrent 401s share a single refresh round-trip and all retry '
        'with the new token', () async {
      currentAccessToken = 'stale-access';
      currentRefreshToken = 'refresh-1';

      final harness = buildClient(
        mainHandler: (options) async {
          if (options.headers['Authorization'] == 'Bearer stale-access') {
            return jsonResponseBody(
              {'error': 'token expired'},
              statusCode: 401,
            );
          }
          return jsonResponseBody({'ok': true});
        },
        refreshHandler: (_) async => jsonResponseBody({
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
        }),
      );

      final responses = await Future.wait([
        harness.client.get('/v1/a'),
        harness.client.get('/v1/b'),
        harness.client.get('/v1/c'),
      ]);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      // One refresh for the whole burst — not one per request.
      expect(harness.refresh.requests, hasLength(1));
      // 3 original attempts + 3 retries.
      expect(harness.main.requests, hasLength(6));
    });

    test('a retried request that 401s again propagates instead of looping '
        'refresh -> retry forever', () async {
      currentAccessToken = 'stale-access';
      currentRefreshToken = 'refresh-1';

      final harness = buildClient(
        // Always 401, even with the fresh token.
        mainHandler: (_) async =>
            jsonResponseBody({'error': 'nope'}, statusCode: 401),
        refreshHandler: (_) async => jsonResponseBody({
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
        }),
      );

      await expectLater(
        harness.client.get('/v1/test'),
        throwsA(isA<DioException>()),
      );

      // Original + exactly one retry; one refresh. No loop.
      expect(harness.main.requests, hasLength(2));
      expect(harness.refresh.requests, hasLength(1));
    });

    test('non-401 errors pass straight through without touching refresh',
        () async {
      currentAccessToken = 'tok-123';

      final harness = buildClient(
        mainHandler: (_) async =>
            jsonResponseBody({'message': 'nope'}, statusCode: 403),
      );

      var forcedLogout = false;
      harness.client.onForceLogout = () => forcedLogout = true;

      await expectLater(
        harness.client.get('/v1/test'),
        throwsA(isA<DioException>().having(
          (e) => (e.error as ApiError).statusCode,
          'wrapped ApiError statusCode',
          403,
        )),
      );

      expect(forcedLogout, isFalse);
      expect(harness.refresh.requests, isEmpty);
    });
  });

  group('ApiError wrapping (_ErrorInterceptor semantics)', () {
    test('server JSON error body maps message/code/details onto ApiError',
        () async {
      final harness = buildClient(
        mainHandler: (_) async => jsonResponseBody({
          'message': 'Title is required',
          'code': 'invalid_input',
          'details': {'field': 'title'},
        }, statusCode: 400),
      );

      try {
        await harness.client.get('/v1/test');
        fail('expected a DioException');
      } on DioException catch (e) {
        final apiError = e.error as ApiError;
        expect(apiError.message, 'Title is required');
        expect(apiError.statusCode, 400);
        expect(apiError.errorCode, 'invalid_input');
        expect(apiError.details, {'field': 'title'});
        // The interceptor also mirrors the message onto the exception.
        expect(e.message, 'Title is required');
        expect(apiError.toString(), 'ApiError(400): Title is required');
      }
    });

    test('falls back to the "error" key when "message" is absent', () async {
      final harness = buildClient(
        mainHandler: (_) async =>
            jsonResponseBody({'error': 'recipe not found'}, statusCode: 404),
      );

      try {
        await harness.client.get('/v1/recipes/999');
        fail('expected a DioException');
      } on DioException catch (e) {
        final apiError = e.error as ApiError;
        expect(apiError.message, 'recipe not found');
        expect(apiError.statusCode, 404);
        expect(apiError.errorCode, isNull);
      }
    });

    test('uses a generic message for JSON bodies with neither key, and '
        '"Server error" for non-map bodies', () {
      final emptyBody = ApiError.fromDioException(DioException(
        requestOptions: RequestOptions(path: '/v1/test'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/v1/test'),
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      ));
      expect(emptyBody.message, 'An error occurred');
      expect(emptyBody.statusCode, 500);

      final htmlBody = ApiError.fromDioException(DioException(
        requestOptions: RequestOptions(path: '/v1/test'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/v1/test'),
          statusCode: 502,
          data: '<html>Bad Gateway</html>',
        ),
      ));
      expect(htmlBody.message, 'Server error');
      expect(htmlBody.statusCode, 502);
    });

    test('maps timeout and connectivity failures to friendly messages', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final apiError = ApiError.fromDioException(DioException(
          requestOptions: RequestOptions(path: '/v1/test'),
          type: type,
        ));
        expect(apiError.message,
            'Connection timed out. Please check your internet.');
        expect(apiError.statusCode, 0);
      }

      final offline = ApiError.fromDioException(DioException(
        requestOptions: RequestOptions(path: '/v1/test'),
        type: DioExceptionType.connectionError,
      ));
      expect(offline.message, 'No internet connection.');
      expect(offline.statusCode, 0);
    });

    test('falls back to the exception message for unknown failure types', () {
      final apiError = ApiError.fromDioException(DioException(
        requestOptions: RequestOptions(path: '/v1/test'),
        type: DioExceptionType.unknown,
        message: 'something odd happened',
      ));
      expect(apiError.message, 'something odd happened');
      expect(apiError.statusCode, 0);
    });
  });
}
