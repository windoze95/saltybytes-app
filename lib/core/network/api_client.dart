import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

const _saltyId = String.fromEnvironment('SALTYBYTES_ID');

/// Timeouts shared across the app.
///
/// The Dio client uses a 15s receive timeout globally, but import and
/// AI-generation requests (Haiku extraction, Firecrawl fetches, full recipe
/// generation) routinely take longer. Those calls must override the receive
/// timeout per-request with [ApiTimeouts.aiGeneration] so the client does not
/// give up (and the user retry, duplicating rows) while the server is still
/// working.
class ApiTimeouts {
  ApiTimeouts._();

  /// Per-request receive timeout for import / AI-generation endpoints.
  static const Duration aiGeneration = Duration(seconds: 60);
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: secureStorage);
});

class ApiClient {
  /// [refreshDio] lets tests inject the Dio used for the token-refresh call
  /// (which deliberately bypasses this client's interceptors). When null, a
  /// plain Dio pointed at [ApiEndpoints.baseUrl] is built on demand.
  ApiClient({
    required SecureStorage secureStorage,
    @visibleForTesting Dio? refreshDio,
  }) : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_saltyId.isNotEmpty) 'X-SaltyBytes-Identifier': _saltyId,
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(
        dio: _dio,
        secureStorage: _secureStorage,
        onAuthFailure: _onAuthFailure,
        refreshDio: refreshDio,
      ),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  late final Dio _dio;
  final SecureStorage _secureStorage;

  void Function()? onForceLogout;

  void _onAuthFailure() {
    onForceLogout?.call();
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required Dio dio,
    required SecureStorage secureStorage,
    required VoidCallback onAuthFailure,
    Dio? refreshDio,
  })  : _dio = dio,
        _secureStorage = secureStorage,
        _onAuthFailure = onAuthFailure,
        _refreshDio = refreshDio;

  final Dio _dio;
  final SecureStorage _secureStorage;
  final VoidCallback _onAuthFailure;
  final Dio? _refreshDio;

  /// In-flight refresh shared by every request that 401s while it runs, so
  /// a burst of expired calls costs one refresh round-trip instead of N
  /// (the server rate-limits the refresh endpoint per IP, and concurrent
  /// 401s used to fail outright instead of waiting for the refresh).
  Future<_RefreshResult>? _refreshFuture;

  /// Marks a request that was already retried once with a fresh token, so a
  /// second 401 propagates instead of looping refresh -> retry forever.
  static const _retriedKey = 'auth_retried';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // A 401 from the refresh endpoint itself is a definitive rejection.
    if (err.requestOptions.path == ApiEndpoints.refreshToken) {
      _onAuthFailure();
      handler.next(err);
      return;
    }

    // Already retried with a fresh token and still 401 — give up.
    if (err.requestOptions.extra[_retriedKey] == true) {
      handler.next(err);
      return;
    }

    final result = await (_refreshFuture ??=
        _refresh().whenComplete(() => _refreshFuture = null));

    final newAccessToken = result.accessToken;
    if (newAccessToken == null) {
      final cause = result.transientCause;
      if (cause != null) {
        // The refresh failed for a reason that says nothing about the
        // session (offline, rate-limited, server error). Surface THAT
        // instead of the original 401 so callers don't read a network blip
        // as an expired login and wipe the session.
        handler.next(DioException(
          requestOptions: err.requestOptions,
          response: cause.response,
          type: cause.type,
          error: cause.error,
          message: cause.message,
        ));
      } else {
        handler.next(err);
      }
      return;
    }

    // Retry the original request with the new token
    final options = err.requestOptions;
    options.extra[_retriedKey] = true;
    options.headers['Authorization'] = 'Bearer $newAccessToken';
    try {
      final retryResponse = await _dio.fetch(options);
      handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  /// Runs one refresh round-trip. Forces logout ONLY when the server
  /// definitively rejects the session (missing refresh token, or a
  /// 400/401/403 response) — never for transient failures, which used to
  /// wipe tokens whenever the app cold-started offline or hit the rate
  /// limiter.
  Future<_RefreshResult> _refresh() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) {
      _onAuthFailure();
      return _RefreshResult.rejected();
    }

    final refreshDio = _refreshDio ??
        Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (_saltyId.isNotEmpty) 'X-SaltyBytes-Identifier': _saltyId,
          },
        ));

    try {
      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String;
      await _secureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return _RefreshResult.success(newAccessToken);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        _onAuthFailure();
        return _RefreshResult.rejected();
      }
      return _RefreshResult.transient(e);
    } catch (_) {
      // Malformed refresh response (server bug) — treat as transient; the
      // session may well still be valid.
      return _RefreshResult.transient(null);
    }
  }
}

/// Outcome of a token-refresh attempt: a new access token, a definitive
/// rejection, or a transient failure carrying its cause.
class _RefreshResult {
  _RefreshResult.success(this.accessToken) : transientCause = null;
  _RefreshResult.rejected()
      : accessToken = null,
        transientCause = null;
  _RefreshResult.transient(this.transientCause) : accessToken = null;

  final String? accessToken;
  final DioException? transientCause;
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '>> ${options.method} ${options.uri}',
      name: 'API',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '<< ${response.statusCode} ${response.requestOptions.uri}',
      name: 'API',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '!! ${err.response?.statusCode ?? 'NETWORK'} '
      '${err.requestOptions.uri} - ${err.message}',
      name: 'API',
      error: err,
    );
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiError = ApiError.fromDioException(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiError,
        message: apiError.message,
      ),
    );
  }
}

/// Extracts a user-facing message from a caught error for snackbars and
/// inline error text: unwraps the [ApiError] that [_ErrorInterceptor] puts
/// on every [DioException], falling back to [fallback] for anything else
/// (so raw exception plumbing never reaches the UI).
String userFacingErrorMessage(Object error, String fallback) {
  final unwrapped = error is DioException ? error.error : error;
  return unwrapped is ApiError ? unwrapped.message : fallback;
}

class ApiError {
  const ApiError({
    required this.message,
    required this.statusCode,
    this.errorCode,
    this.details,
  });

  factory ApiError.fromDioException(DioException exception) {
    final response = exception.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 0;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // The API emits machine codes under "error_code"; older endpoints
        // used "code".
        final errorCode =
            data['error_code'] as String? ?? data['code'] as String?;
        final serverMessage =
            data['message'] as String? ?? data['error'] as String?;
        return ApiError(
          message: _friendlyMessage(errorCode, statusCode, serverMessage),
          statusCode: statusCode,
          errorCode: errorCode,
          details: data['details'] as Map<String, dynamic>?,
        );
      }
      return ApiError(
        message: _friendlyMessage(null, statusCode, null),
        statusCode: statusCode,
      );
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiError(
          message: 'Connection timed out. Please check your internet.',
          statusCode: 0,
        );
      case DioExceptionType.connectionError:
        return const ApiError(
          message: 'No internet connection.',
          statusCode: 0,
        );
      default:
        return ApiError(
          message: exception.message ?? 'An unexpected error occurred',
          statusCode: 0,
        );
    }
  }

  final String message;
  final int statusCode;
  final String? errorCode;
  final Map<String, dynamic>? details;

  /// Turns machine failures into copy a person can act on. Known machine
  /// codes and "not your fault" statuses (rate limits, server errors) get a
  /// warm "we're on it" voice; everything else keeps the server's own
  /// message, which is written for users.
  static String _friendlyMessage(
      String? errorCode, int statusCode, String? serverMessage) {
    switch (errorCode) {
      case 'ai_budget_exhausted':
        return "Our AI kitchen is at full capacity right now — we're on it! "
            'Please try again a little later.';
      case 'email_unverified':
        return 'Verify your email to unlock AI features — it takes 30 '
            'seconds from the banner on your home screen.';
      case 'at_capacity':
        return "This feature is taking a quick breather — we're working on "
            'it. Try again soon!';
    }
    if (statusCode == 429) {
      return "We're getting a lot of love right now — please try again in "
          'a minute.';
    }
    if (statusCode >= 500) {
      return "Something hiccuped on our side — we're working on it. "
          'Please try again.';
    }
    return serverMessage ?? 'An error occurred';
  }

  @override
  String toString() => 'ApiError($statusCode): $message';
}

typedef VoidCallback = void Function();
