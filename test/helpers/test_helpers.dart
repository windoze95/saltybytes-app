import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/storage/secure_storage.dart';

class MockDio extends Mock implements Dio {}

class MockSecureStorage extends Mock implements SecureStorage {}

class MockApiClient extends Mock implements ApiClient {}

/// Creates a [ProviderContainer] with common overrides for testing.
///
/// Pass additional [overrides] to customise individual providers.
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: overrides,
  );
  return container;
}

/// Convenience: build a [Response] with the given [data] and [statusCode].
Response<T> fakeResponse<T>(
  T data, {
  int statusCode = 200,
  RequestOptions? requestOptions,
}) {
  return Response<T>(
    data: data,
    statusCode: statusCode,
    requestOptions: requestOptions ?? RequestOptions(path: '/test'),
  );
}
