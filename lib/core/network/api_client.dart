import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

const _saltyId = String.fromEnvironment('SALTYBYTES_ID');

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: secureStorage);
});

class ApiClient {
  ApiClient({required SecureStorage secureStorage})
      : _secureStorage = secureStorage {
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
  })  : _dio = dio,
        _secureStorage = secureStorage,
        _onAuthFailure = onAuthFailure;

  final Dio _dio;
  final SecureStorage _secureStorage;
  final VoidCallback _onAuthFailure;
  bool _isRefreshing = false;

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

    // Don't retry refresh endpoint itself
    if (err.requestOptions.path == ApiEndpoints.refreshToken) {
      _onAuthFailure();
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        _onAuthFailure();
        handler.next(err);
        return;
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_saltyId.isNotEmpty) 'X-SaltyBytes-Identifier': _saltyId,
        },
      ));

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

      // Retry the original request with the new token
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(options);
      handler.resolve(retryResponse);
    } on DioException {
      _onAuthFailure();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
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
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ApiError(
          message: data['message'] as String? ??
              data['error'] as String? ??
              'An error occurred',
          statusCode: response.statusCode ?? 0,
          errorCode: data['code'] as String?,
          details: data['details'] as Map<String, dynamic>?,
        );
      }
      return ApiError(
        message: 'Server error',
        statusCode: response.statusCode ?? 0,
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

  @override
  String toString() => 'ApiError($statusCode): $message';
}

typedef VoidCallback = void Function();
