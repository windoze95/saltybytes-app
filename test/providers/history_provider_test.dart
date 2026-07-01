import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/history_provider.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

/// Opens a container with the given api client + an authenticated fake auth,
/// and primes authStateProvider so the history notifier builds against a
/// resolved auth state (Riverpod gotcha).
Future<ProviderContainer> _openContainer(MockApiClient apiClient) async {
  final container = ProviderContainer(overrides: [
    apiClientProvider.overrideWithValue(apiClient),
    authStateProvider.overrideWith(FakeAuthNotifier.new),
  ]);
  addTearDown(container.dispose);
  await container.read(authStateProvider.future);
  return container;
}

void _stubList(MockApiClient apiClient, List<Map<String, dynamic>> sessions) {
  when(() => apiClient.get(
        ApiEndpoints.finderSessions,
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => fakeResponse<dynamic>({
        'sessions': sessions,
        'total': sessions.length,
        'page': 1,
        'page_size': 30,
      }));
}

void main() {
  group('finderHistoryProvider', () {
    test('loads sessions (newest first as returned by the API)', () async {
      final apiClient = MockApiClient();
      _stubList(apiClient, [
        testFinderSessionJson(id: 2, title: 'pasta night'),
        testFinderSessionJson(id: 1, title: 'chicken dinner'),
      ]);
      final container = await _openContainer(apiClient);

      final list = await container.read(finderHistoryProvider.future);
      expect(list.map((s) => s.id).toList(), [2, 1]);
      expect(list.first.title, 'pasta night');
    });

    test('delete removes the session on success', () async {
      final apiClient = MockApiClient();
      _stubList(apiClient, [
        testFinderSessionJson(id: 1),
        testFinderSessionJson(id: 2),
      ]);
      when(() => apiClient.delete(ApiEndpoints.finderSession(1)))
          .thenAnswer((_) async => fakeResponse<dynamic>({'message': 'ok'}));

      final container = await _openContainer(apiClient);
      await container.read(finderHistoryProvider.future);

      await container.read(finderHistoryProvider.notifier).delete(1);

      expect(
        container.read(finderHistoryProvider).valueOrNull!.map((s) => s.id),
        [2],
      );
    });

    test('delete reverts (and rethrows) when the API fails', () async {
      final apiClient = MockApiClient();
      _stubList(apiClient, [
        testFinderSessionJson(id: 1),
        testFinderSessionJson(id: 2),
      ]);
      when(() => apiClient.delete(ApiEndpoints.finderSession(1))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/x')),
      );

      final container = await _openContainer(apiClient);
      await container.read(finderHistoryProvider.future);
      final notifier = container.read(finderHistoryProvider.notifier);

      await expectLater(notifier.delete(1), throwsA(isA<DioException>()));

      // Reverted to the original list.
      expect(
        container.read(finderHistoryProvider).valueOrNull!.map((s) => s.id),
        [1, 2],
      );
    });
  });
}
