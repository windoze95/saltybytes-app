import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/allergen.dart';
import '../../models/recipe.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../utils/unit_converter.dart';

class PreviewException implements Exception {
  const PreviewException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Thrown when a preview request discovers a multi-recipe page.
/// The caller should expand the individual cards into the results list.
class MultiRecipeException implements Exception {
  const MultiRecipeException({
    required this.sourceResult,
    required this.resolution,
  });

  final WebSearchResult sourceResult;
  final MultiRecipeResolution resolution;

  @override
  String toString() =>
      'Multi-recipe page detected: ${resolution.recipes.length} recipes';
}

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
    // The backend serializes image_url without omitempty, so hits with no
    // thumbnail arrive as "" — coerce to null so render sites fall back to
    // the placeholder instead of feeding an empty URL to the image widget.
    final imageUrl = json['image_url'] as String?;
    return WebSearchResult(
      title: json['title'] as String? ?? 'Untitled',
      sourceUrl: json['source_url'] as String?,
      sourceDomain: json['source_domain'] as String?,
      imageUrl: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
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

/// A single recipe card from a resolved multi-recipe page.
class MultiRecipeCard {
  const MultiRecipeCard({
    required this.title,
    this.imageUrl,
    this.description,
    this.sourceUrl,
    required this.extractionStatus,
  });

  final String title;
  final String? imageUrl;
  final String? description;
  final String? sourceUrl;
  final String extractionStatus; // "pending", "extracting", "done", "failed"

  factory MultiRecipeCard.fromJson(Map<String, dynamic> json) {
    return MultiRecipeCard(
      title: json['title'] as String? ?? 'Untitled',
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      sourceUrl: json['source_url'] as String?,
      extractionStatus: json['extraction_status'] as String? ?? 'pending',
    );
  }

  /// Convert to a WebSearchResult for display in the card stack.
  WebSearchResult toSearchResult() {
    String? domain;
    if (sourceUrl != null) {
      try {
        domain = Uri.parse(sourceUrl!).host.replaceFirst('www.', '');
      } catch (_) {}
    }
    return WebSearchResult(
      title: title,
      sourceUrl: sourceUrl,
      sourceDomain: domain,
      imageUrl: imageUrl,
      description: description,
    );
  }
}

/// Resolution state for a multi-recipe page.
class MultiRecipeResolution {
  const MultiRecipeResolution({
    required this.multiId,
    required this.sourceUrl,
    required this.status,
    this.recipes = const [],
  });

  final String multiId;
  final String sourceUrl;
  final String status; // "resolving", "resolved", "failed"
  final List<MultiRecipeCard> recipes;

  factory MultiRecipeResolution.fromJson(Map<String, dynamic> json) {
    return MultiRecipeResolution(
      multiId: json['multi_id'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      status: json['status'] as String? ?? 'resolving',
      recipes: (json['recipes'] as List?)
              ?.map((e) => MultiRecipeCard.fromJson(e as Map<String, dynamic>))
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
    this.unitSystem,
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
  final String? unitSystem;

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
      instructions:
          (json['instructions'] as List?)?.map((e) => e as String).toList() ??
              [],
      cookTime: json['cook_time'] as int?,
      portions: json['portions'] as int?,
      portionSize: json['portion_size'] as String?,
      sourceUrl: json['source_url'] as String?,
      hashtags:
          (json['hashtags'] as List?)?.map((e) => e as String).toList() ?? [],
      imagePrompt: json['image_prompt'] as String?,
      linkedSuggestions: (json['linked_recipe_suggestions'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      unitSystem: json['unit_system'] as String?,
    );
  }

  /// Builds the snake_case manualImportRequest body for
  /// POST /v1/recipes/import/manual, preserving the source's detected
  /// unit system and metric measurements (contract C6).
  Map<String, dynamic> toManualImportJson({String? imageUrl}) {
    return {
      'title': title,
      'ingredients': ingredients
          .map((i) => {
                'name': i.name,
                'unit': i.unit,
                'amount': i.amount,
                if (i.metricUnit != null) 'metric_unit': i.metricUnit,
                if (i.metricAmount != null) 'metric_amount': i.metricAmount,
                if (i.originalText != null) 'original_text': i.originalText,
              })
          .toList(),
      'instructions': instructions,
      'cook_time': cookTime ?? 0,
      'portions': portions ?? 0,
      'portion_size': portionSize ?? '',
      'hashtags': hashtags,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (unitSystem != null && unitSystem!.isNotEmpty)
        'unit_system': unitSystem,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    };
  }
}

class PreviewIngredient {
  const PreviewIngredient({
    required this.name,
    this.unit,
    this.amount,
    this.metricUnit,
    this.metricAmount,
    this.originalText,
  });

  final String name;
  final String? unit;
  final double? amount;
  final String? metricUnit;
  final double? metricAmount;
  final String? originalText;

  factory PreviewIngredient.fromJson(Map<String, dynamic> json) {
    return PreviewIngredient(
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      metricUnit: json['metric_unit'] as String?,
      metricAmount: (json['metric_amount'] as num?)?.toDouble(),
      originalText: json['original_text'] as String?,
    );
  }

  String get displayText {
    // Pre-import preview shows the source measurement, formatted consistently
    // with the recipe screen (cooking fractions for US volume, clean decimals
    // for metric). No viewer-system alternate yet — that resolves after import.
    final qty = formatIngredientQuantity(Ingredient(
      name: name,
      amount: amount,
      unit: unit,
      metricUnit: metricUnit,
      metricAmount: metricAmount,
      originalText: originalText,
    ));
    return qty.isEmpty ? name : '$qty $name';
  }
}

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
    this.nextOffset = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final String query;
  final List<WebSearchResult> results;
  final bool isLoading;
  final String? error;
  final bool hasSearched;
  final int nextOffset;
  final bool hasMore;
  final bool isLoadingMore;

  SearchState copyWith({
    String? query,
    List<WebSearchResult>? results,
    bool? isLoading,
    String? error,
    bool? hasSearched,
    int? nextOffset,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasSearched: hasSearched ?? this.hasSearched,
      nextOffset: nextOffset ?? this.nextOffset,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
      nextOffset: 0,
      hasMore: true,
      isLoadingMore: false,
    );

    try {
      final response = await _apiClient.get(
        ApiEndpoints.search,
        queryParameters: {'q': query},
      );

      final data = response.data;
      List<WebSearchResult> results = [];
      bool hasMore = false;

      if (data is Map<String, dynamic>) {
        if (data['results'] is List) {
          results = (data['results'] as List)
              .map((r) => WebSearchResult.fromJson(r as Map<String, dynamic>))
              .toList();
        }
        hasMore = data['has_more'] as bool? ?? false;
      } else if (data is List) {
        results = data
            .map((r) => WebSearchResult.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      state = state.copyWith(
        results: results,
        isLoading: false,
        nextOffset: results.length,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.query.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _apiClient.get(
        ApiEndpoints.search,
        queryParameters: {
          'q': state.query,
          'offset': state.nextOffset.toString(),
        },
      );

      final data = response.data;
      List<WebSearchResult> newResults = [];
      bool hasMore = false;

      if (data is Map<String, dynamic>) {
        if (data['results'] is List) {
          newResults = (data['results'] as List)
              .map((r) => WebSearchResult.fromJson(r as Map<String, dynamic>))
              .toList();
        }
        hasMore = data['has_more'] as bool? ?? false;
      }

      // Advance offset by the raw page size before dedup so we don't
      // re-request the same range when duplicates are removed.
      final fetchedCount = newResults.length;

      // Deduplicate by sourceUrl
      final existingUrls =
          state.results.map((r) => r.sourceUrl).whereType<String>().toSet();
      newResults.removeWhere(
          (r) => r.sourceUrl != null && existingUrls.contains(r.sourceUrl));

      state = state.copyWith(
        results: [...state.results, ...newResults],
        isLoadingMore: false,
        nextOffset: state.nextOffset + fetchedCount,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Preview a search result. If the backend detects multiple recipes on the
  /// page, throws a [MultiRecipeException] with the individual cards so the
  /// caller can expand them into the results list.
  Future<RecipePreview> previewResult(WebSearchResult result) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.previewFromUrl,
        data: {'url': result.sourceUrl},
        options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
      );
      final data = response.data as Map<String, dynamic>;

      // Check for multi-recipe response
      if (data['is_multi'] == true) {
        final resolution = MultiRecipeResolution.fromJson(data);
        throw MultiRecipeException(
          sourceResult: result,
          resolution: resolution,
        );
      }

      final recipe = data['recipe'] as Map<String, dynamic>;
      return RecipePreview.fromJson(recipe);
    } on MultiRecipeException {
      rethrow;
    } on DioException catch (e) {
      final apiError = e.error;
      if (apiError is ApiError) {
        switch (apiError.errorCode) {
          case 'site_blocked':
            throw const PreviewException(
              message:
                  'This website blocks automated access. Try copying the recipe text and using Import from Text instead.',
              code: 'site_blocked',
            );
          case 'not_found':
            throw const PreviewException(
              message: 'Recipe page not found. The URL may have changed.',
              code: 'not_found',
            );
          case 'fetch_failed':
            throw PreviewException(
              message: 'Could not reach the recipe website. Please try again.',
              code: apiError.errorCode,
            );
          default:
            throw PreviewException(
              message: apiError.message,
              code: apiError.errorCode,
            );
        }
      }
      rethrow;
    }
  }

  Future<Recipe> importPreview(RecipePreview preview,
      {String? imageUrl}) async {
    final response = await _apiClient.post(
      ApiEndpoints.importManual,
      data: preview.toManualImportJson(imageUrl: imageUrl),
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    final data = response.data as Map<String, dynamic>;
    final recipe = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipe);
  }

  Future<Recipe> importResult(WebSearchResult result) async {
    final response = await _apiClient.post(
      ApiEndpoints.importFromUrl,
      data: {'url': result.sourceUrl},
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    final data = response.data as Map<String, dynamic>;
    final recipe = data['recipe'] as Map<String, dynamic>;
    return Recipe.fromJson(recipe);
  }

  /// Replace a multi-recipe card with its individual recipe cards.
  /// Returns the index of the first expanded card, or null if nothing changed.
  int? replaceWithExpanded(
      WebSearchResult original, MultiRecipeResolution resolution) {
    if (resolution.recipes.isEmpty) return null;

    final newCards = resolution.recipes.map((c) => c.toSearchResult()).toList();

    final updatedResults = <WebSearchResult>[];
    int insertedAt = 0;
    for (final r in state.results) {
      if (r.sourceUrl == original.sourceUrl) {
        insertedAt = updatedResults.length;
        updatedResults.addAll(newCards);
      } else {
        updatedResults.add(r);
      }
    }

    state = state.copyWith(results: updatedResults);
    return insertedAt;
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
