import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/finder_session.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'auth_provider.dart';

/// The user's saved agent (finder) search sessions, newest first.
final finderHistoryProvider =
    AsyncNotifierProvider<FinderHistoryNotifier, List<FinderSession>>(
  FinderHistoryNotifier.new,
);

class FinderHistoryNotifier extends AsyncNotifier<List<FinderSession>> {
  late ApiClient _apiClient;

  /// Drops stale (out-of-order) refresh responses after an optimistic delete.
  int _fetchGeneration = 0;

  @override
  Future<List<FinderSession>> build() async {
    _apiClient = ref.watch(apiClientProvider);

    final authStatus = ref.watch(authStateProvider).valueOrNull;
    if (authStatus != AuthStatus.authenticated) {
      return [];
    }

    return _fetchSessions();
  }

  Future<List<FinderSession>> _fetchSessions({
    int page = 1,
    int pageSize = 30,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.finderSessions,
      queryParameters: {'page': page, 'page_size': pageSize},
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['sessions'] is List) {
      return (data['sessions'] as List)
          .map((s) => FinderSession.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data
          .map((s) => FinderSession.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> refresh() async {
    final generation = ++_fetchGeneration;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(_fetchSessions);
    if (generation == _fetchGeneration) {
      state = result;
    }
  }

  /// Optimistically removes the session, then DELETEs it; reverts on failure.
  Future<void> delete(int id) async {
    final current = state.valueOrNull ?? [];
    // Bump the generation so any in-flight refresh that predates the delete is
    // discarded instead of resurrecting the removed session.
    _fetchGeneration++;
    state = AsyncData(current.where((s) => s.id != id).toList());

    try {
      await _apiClient.delete(ApiEndpoints.finderSession(id));
    } catch (e) {
      _fetchGeneration++;
      state = AsyncData(current);
      rethrow;
    }
  }
}

/// A single saved session by id (used if a detail view is needed).
final finderSessionDetailProvider =
    FutureProvider.family<FinderSession, int>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.finderSession(id));
  final data = response.data as Map<String, dynamic>;
  final session = (data['session'] as Map<String, dynamic>?) ?? data;
  return FinderSession.fromJson(session);
});
