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

class RecipePreview {
  const RecipePreview({
    required this.title,
    this.ingredients = const [],
    this.instructions = const [],
    this.cookTime,
    this.portions,
    this.portionSize,
    this.sourceUrl,
    this.hashtags = const [],
    this.imagePrompt,
    this.linkedSuggestions = const [],
  });

  final String title;
  final List<PreviewIngredient> ingredients;
  final List<String> instructions;
  final int? cookTime;
  final int? portions;
  final String? portionSize;
  final String? sourceUrl;
  final List<String> hashtags;
  final String? imagePrompt;
  final List<String> linkedSuggestions;

  String? get sourceDomain {
    if (sourceUrl == null) return null;
    try {
      return Uri.parse(sourceUrl!).host.replaceFirst('www.', '');
    } catch (_) {
      return null;
    }
  }

  factory RecipePreview.fromJson(Map<String, dynamic> json) {
    return RecipePreview(
      title: json['title'] as String? ?? 'Untitled',
      ingredients: (json['ingredients'] as List?)
              ?.map(
                (e) => PreviewIngredient.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      instructions: (json['instructions'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      cookTime: json['cook_time'] as int?,
      portions: json['portions'] as int?,
      portionSize: json['portion_size'] as String?,
      sourceUrl: json['source_url'] as String?,
      hashtags: (json['hashtags'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      imagePrompt: json['image_prompt'] as String?,
      linkedSuggestions: (json['linked_recipe_suggestions'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toManualImportJson() {
    return {
      'title': title,
      'ingredients': ingredients
          .map((i) => {
                'name': i.name,
                'unit': i.unit,
                'amount': i.amount,
              })
          .toList(),
      'instructions': instructions,
      'cook_time': cookTime ?? 0,
      'portions': portions ?? 0,
      'portion_size': portionSize ?? '',
      'hashtags': hashtags,
      if (sourceUrl != null) 'source_url': sourceUrl,
    };
  }
}

class PreviewIngredient {
  const PreviewIngredient({
    required this.name,
    this.unit,
    this.amount,
  });

  final String name;
  final String? unit;
  final double? amount;

  factory PreviewIngredient.fromJson(Map<String, dynamic> json) {
    return PreviewIngredient(
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  String get displayText {
    final parts = <String>[];
    if (amount != null && amount! > 0) {
      // Format as integer if whole number
      parts.add(amount! == amount!.roundToDouble()
          ? amount!.toInt().toString()
          : amount.toString());
    }
    if (unit != null && unit!.isNotEmpty) {
      parts.add(unit!);
    }
    parts.add(name);
    return parts.join(' ');
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

  Future<RecipePreview> previewResult(WebSearchResult result) async {
    final response = await _apiClient.post(
      ApiEndpoints.previewFromUrl,
      data: {'url': result.sourceUrl},
    );
    final data = response.data as Map<String, dynamic>;
    final recipe = data['recipe'] as Map<String, dynamic>;
    return RecipePreview.fromJson(recipe);
  }

  Future<Recipe> importPreview(RecipePreview preview) async {
    final response = await _apiClient.post(
      ApiEndpoints.importManual,
      data: preview.toManualImportJson(),
    );
    final data = response.data as Map<String, dynamic>;
    final recipe = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipe);
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
    ApiEndpoints.search,
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
