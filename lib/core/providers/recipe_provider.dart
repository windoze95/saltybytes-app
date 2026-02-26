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

  @override
  Future<List<Recipe>> build() async {
    _apiClient = ref.watch(apiClientProvider);

    final authStatus = ref.watch(authStateProvider).valueOrNull;
    if (authStatus != AuthStatus.authenticated) {
      return [];
    }

    return _fetchRecipes();
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
      return (data['recipes'] as List)
          .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    if (data is List) {
      return data
          .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchRecipes());
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchRecipes(query: query));
  }

  Future<void> deleteRecipe(String id) async {
    final current = state.valueOrNull ?? [];
    // Optimistic removal
    state = AsyncData(current.where((r) => r.id != id).toList());

    try {
      await _apiClient.delete(ApiEndpoints.recipeById(id));
    } catch (e) {
      // Revert on failure
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

  Future<Recipe> create(Recipe recipe) async {
    final response = await _apiClient.post(
      ApiEndpoints.recipes,
      data: recipe.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Recipe.fromJson(
        data.containsKey('recipe') ? data['recipe'] as Map<String, dynamic> : data);
  }

  Future<Recipe> update(Recipe recipe) async {
    final response = await _apiClient.put(
      ApiEndpoints.recipeById(recipe.id),
      data: recipe.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Recipe.fromJson(
        data.containsKey('recipe') ? data['recipe'] as Map<String, dynamic> : data);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete(ApiEndpoints.recipeById(id));
  }

  Future<Recipe> fork(String recipeId, {String? branchName}) async {
    final response = await _apiClient.post(
      ApiEndpoints.recipeFork(recipeId),
      data: branchName != null ? {'branch': branchName} : null,
    );
    final data = response.data as Map<String, dynamic>;
    return Recipe.fromJson(
        data.containsKey('recipe') ? data['recipe'] as Map<String, dynamic> : data);
  }

  Future<Recipe> importFromUrl(String url) async {
    final response = await _apiClient.post(
      ApiEndpoints.importFromUrl,
      data: {'url': url},
    );
    final data = response.data as Map<String, dynamic>;
    return Recipe.fromJson(
        data.containsKey('recipe') ? data['recipe'] as Map<String, dynamic> : data);
  }
}
