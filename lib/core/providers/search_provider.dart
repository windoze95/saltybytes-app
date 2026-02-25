import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/allergen.dart';
import '../../models/recipe.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class WebSearchResult {
  const WebSearchResult({
    required this.title,
    this.sourceUrl,
    this.sourceDomain,
    this.imageUrl,
    this.description,
    this.rating,
    this.cookTimeMinutes,
    this.familySafetyChecks = const [],
  });

  final String title;
  final String? sourceUrl;
  final String? sourceDomain;
  final String? imageUrl;
  final String? description;
  final double? rating;
  final int? cookTimeMinutes;
  final List<FamilySafetyCheck> familySafetyChecks;

  factory WebSearchResult.fromJson(Map<String, dynamic> json) {
    return WebSearchResult(
      title: json['title'] as String? ?? 'Untitled',
      sourceUrl: json['source_url'] as String?,
      sourceDomain: json['source_domain'] as String?,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      cookTimeMinutes: json['cook_time_minutes'] as int?,
      familySafetyChecks: (json['family_safety_checks'] as List?)
              ?.map(
                (e) => FamilySafetyCheck.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
  });

  final String query;
  final List<WebSearchResult> results;
  final bool isLoading;
  final String? error;
  final bool hasSearched;

  SearchState copyWith({
    String? query,
    List<WebSearchResult>? results,
    bool? isLoading,
    String? error,
    bool? hasSearched,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchNotifier(apiClient: apiClient);
});

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const SearchState());

  final ApiClient _apiClient;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(
      query: query,
      isLoading: true,
      error: null,
      hasSearched: true,
    );

    try {
      final response = await _apiClient.get(
        ApiEndpoints.search,
        queryParameters: {'q': query},
      );

      final data = response.data;
      List<WebSearchResult> results = [];

      if (data is Map<String, dynamic> && data['results'] is List) {
        results = (data['results'] as List)
            .map((r) => WebSearchResult.fromJson(r as Map<String, dynamic>))
            .toList();
      } else if (data is List) {
        results = data
            .map((r) => WebSearchResult.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Recipe> importResult(WebSearchResult result) async {
    final response = await _apiClient.post(
      ApiEndpoints.importFromUrl,
      data: {'url': result.sourceUrl},
    );
    return Recipe.fromJson(response.data as Map<String, dynamic>);
  }

  void clear() {
    state = const SearchState();
  }
}

final searchSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return [];

  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(
    ApiEndpoints.searchSuggestions,
    queryParameters: {'q': query},
  );

  final data = response.data;
  if (data is List) {
    return data.map((e) => e.toString()).toList();
  }
  if (data is Map<String, dynamic> && data['suggestions'] is List) {
    return (data['suggestions'] as List).map((e) => e.toString()).toList();
  }
  return [];
});
