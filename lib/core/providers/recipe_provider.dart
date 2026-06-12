import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'auth_provider.dart';

// Recipe list provider for the home grid
final recipeListProvider =
    AsyncNotifierProvider<RecipeListNotifier, List<Recipe>>(
  RecipeListNotifier.new,
);

class RecipeListNotifier extends AsyncNotifier<List<Recipe>> {
  late ApiClient _apiClient;

  /// Monotonically increasing token used to drop stale (out-of-order)
  /// search/refresh responses.
  int _fetchGeneration = 0;

  @override
  Future<List<Recipe>> build() async {
    _apiClient = ref.watch(apiClientProvider);

    final authStatus = ref.watch(authStateProvider).valueOrNull;
    if (authStatus != AuthStatus.authenticated) {
      return [];
    }

    return _fetchRecipes();
  }

  /// Removes duplicate recipes (by id), keeping the first occurrence.
  static List<Recipe> dedupeById(List<Recipe> recipes) {
    final seen = <String>{};
    return recipes.where((r) => seen.add(r.id)).toList();
  }

  Future<List<Recipe>> _fetchRecipes({
    int page = 1,
    int pageSize = 20,
    String? query,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }

    final response = await _apiClient.get(
      ApiEndpoints.recipes,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['recipes'] is List) {
      return dedupeById((data['recipes'] as List)
          .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
          .toList());
    }

    if (data is List) {
      return dedupeById(data
          .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
          .toList());
    }

    return [];
  }

  Future<void> _guardedFetch({String? query}) async {
    final generation = ++_fetchGeneration;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _fetchRecipes(query: query));
    // Ignore out-of-order responses: only the latest request may set state.
    if (generation == _fetchGeneration) {
      state = result;
    }
  }

  Future<void> refresh() => _guardedFetch();

  Future<void> search(String query) => _guardedFetch(query: query);

  Future<void> deleteRecipe(String id) async {
    final current = state.valueOrNull ?? [];
    // Optimistic removal. Bump the generation so any in-flight
    // refresh/search (whose response predates the delete) is discarded
    // instead of resurrecting the deleted recipe.
    _fetchGeneration++;
    state = AsyncData(current.where((r) => r.id != id).toList());

    try {
      await _apiClient.delete(ApiEndpoints.recipeById(id));
    } catch (e) {
      // Revert on failure
      _fetchGeneration++;
      state = AsyncData(current);
      rethrow;
    }
  }
}

// Similar recipes provider
final similarRecipesProvider =
    FutureProvider.family<List<Recipe>, String>((ref, recipeId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response =
      await apiClient.get(ApiEndpoints.recipeSimilar(recipeId));
  final data = response.data;
  if (data is Map<String, dynamic> && data['similar_recipes'] is List) {
    return (data['similar_recipes'] as List)
        .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
        .toList();
  }
  return [];
});

// Single recipe detail provider
final recipeDetailProvider =
    FutureProvider.family<Recipe, String>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.recipeById(id));
  final data = response.data as Map<String, dynamic>;
  final recipe = data['recipe'] as Map<String, dynamic>;
  return Recipe.fromJson(recipe);
});

// Recipe CRUD operations
final recipeCrudProvider = Provider<RecipeCrud>((ref) {
  return RecipeCrud(apiClient: ref.watch(apiClientProvider));
});

class RecipeCrud {
  const RecipeCrud({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Unwraps the standard `{"recipe": {...}}` envelope (falling back to a
  /// bare object) and parses it into a [Recipe].
  static Recipe parseRecipeEnvelope(Map<String, dynamic> data) {
    return Recipe.fromJson(data.containsKey('recipe')
        ? data['recipe'] as Map<String, dynamic>
        : data);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete(ApiEndpoints.recipeById(id));
  }

  /// Fetches a single recipe by id, unwrapping the {"recipe": ...} envelope.
  Future<Recipe> getById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.recipeById(id));
    return parseRecipeEnvelope(response.data as Map<String, dynamic>);
  }

  /// Generates a brand-new recipe via POST /v1/recipes/chat.
  ///
  /// The backend immediately returns a placeholder recipe with
  /// status == "generating" and finishes asynchronously; callers should
  /// follow up with [waitUntilGenerated].
  Future<Recipe> generate({
    required String userPrompt,
    required bool genImage,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.generateRecipe,
      data: {
        'user_prompt': userPrompt,
        'gen_image': genImage,
      },
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    return parseRecipeEnvelope(response.data as Map<String, dynamic>);
  }

  /// Regenerates an existing recipe via PUT /v1/recipes/:id/chat.
  ///
  /// The backend responds with {"message": "Regenerating recipe"} and
  /// updates the recipe asynchronously.
  Future<void> regenerate(
    String recipeId, {
    required String userPrompt,
    required bool genImage,
  }) async {
    await _apiClient.put(
      ApiEndpoints.recipeChat(recipeId),
      data: {
        'user_prompt': userPrompt,
        'gen_image': genImage,
      },
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
  }

  /// Forks a recipe via POST /v1/recipes/:id/fork.
  ///
  /// Returns the placeholder recipe (status == "generating"); the backend
  /// finishes the fork asynchronously, so callers should follow up with
  /// [waitUntilGenerated].
  Future<Recipe> fork(
    String recipeId, {
    required String userPrompt,
    bool genImage = true,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.recipeFork(recipeId),
      data: {
        'user_prompt': userPrompt,
        'gen_image': genImage,
      },
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    return parseRecipeEnvelope(response.data as Map<String, dynamic>);
  }

  /// Polls GET /v1/recipes/:id until the recipe leaves the "generating"
  /// status, returning the finished recipe.
  ///
  /// The backend deletes recipes whose generation failed, so a 404 while
  /// polling means the generation did not succeed. Throws
  /// [RecipeGenerationException] on failure or timeout.
  Future<Recipe> waitUntilGenerated(
    String recipeId, {
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      await Future<void>.delayed(pollInterval);

      Recipe recipe;
      try {
        recipe = await getById(recipeId);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          throw const RecipeGenerationException(
            'Recipe generation failed. Please try again.',
          );
        }
        rethrow;
      }

      if (recipe.status == 'failed') {
        throw const RecipeGenerationException(
          'Recipe generation failed. Please try again.',
        );
      }
      if (recipe.status != 'generating') {
        return recipe;
      }
      if (DateTime.now().isAfter(deadline)) {
        throw const RecipeGenerationException(
          'Recipe generation timed out. Please try again.',
        );
      }
    }
  }

  /// Polls GET /v1/recipes/:id until its `updatedAt` advances past [since],
  /// returning the updated recipe.
  ///
  /// The regen endpoint (PUT /v1/recipes/:id/chat) returns immediately and
  /// rewrites the recipe asynchronously WITHOUT flipping status to
  /// "generating" (unlike chat/fork), so completion is detected by watching
  /// the recipe's updatedAt timestamp move. Throws
  /// [RecipeGenerationException] on timeout.
  Future<Recipe> waitUntilRegenerated(
    String recipeId, {
    DateTime? since,
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      await Future<void>.delayed(pollInterval);

      final recipe = await getById(recipeId);
      final updatedAt = recipe.updatedAt;
      final hasUpdated = updatedAt != null &&
          (since == null || updatedAt.isAfter(since));
      if (hasUpdated) {
        return recipe;
      }
      if (DateTime.now().isAfter(deadline)) {
        throw const RecipeGenerationException(
          'Recipe regeneration timed out. Please try again.',
        );
      }
    }
  }

  Future<Recipe> importFromUrl(String url) async {
    final response = await _apiClient.post(
      ApiEndpoints.importFromUrl,
      data: {'url': url},
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    return parseRecipeEnvelope(response.data as Map<String, dynamic>);
  }

  Future<Recipe> importFromText(String text) async {
    final response = await _apiClient.post(
      ApiEndpoints.importFromText,
      data: {'text': text},
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    return parseRecipeEnvelope(response.data as Map<String, dynamic>);
  }

  Future<Recipe> importFromPhoto(FormData formData) async {
    final response = await _apiClient.post(
      ApiEndpoints.importFromPhoto,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: ApiTimeouts.aiGeneration,
      ),
    );
    return parseRecipeEnvelope(response.data as Map<String, dynamic>);
  }

  /// Creates a recipe via POST /v1/recipes/import/manual.
  ///
  /// [body] must follow the backend's snake_case manualImportRequest shape:
  /// title, ingredients [{name, unit, amount, metric_unit, metric_amount,
  /// original_text}], instructions, cook_time, portions, portion_size,
  /// hashtags, source_url, and optionally unit_system / image_url.
  Future<Recipe> importManual(Map<String, dynamic> body) async {
    final response = await _apiClient.post(
      ApiEndpoints.importManual,
      data: body,
      options: Options(receiveTimeout: ApiTimeouts.aiGeneration),
    );
    return parseRecipeEnvelope(response.data as Map<String, dynamic>);
  }
}

/// Thrown when an async recipe generation fails or times out.
class RecipeGenerationException implements Exception {
  const RecipeGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}
