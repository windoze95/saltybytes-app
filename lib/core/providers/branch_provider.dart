import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

final recipeBranchesProvider =
    FutureProvider.family<List<RecipeNode>, String>((ref, recipeId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.recipeVersions(recipeId));

  final data = response.data;
  if (data is Map<String, dynamic> && data['nodes'] is List) {
    return (data['nodes'] as List)
        .map((n) => RecipeNode.fromJson(n as Map<String, dynamic>))
        .toList();
  }
  if (data is List) {
    return data
        .map((n) => RecipeNode.fromJson(n as Map<String, dynamic>))
        .toList();
  }
  return [];
});

final branchOperationsProvider = Provider<BranchOperations>((ref) {
  return BranchOperations(apiClient: ref.watch(apiClientProvider));
});

class BranchOperations {
  const BranchOperations({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Recipe> createBranch(
    String recipeId, {
    required String branchName,
    String? fromBranch,
    int? fromVersion,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.recipeBranch(recipeId),
      data: {
        'branch': branchName,
        if (fromBranch != null) 'from_branch': fromBranch,
        if (fromVersion != null) 'from_version': fromVersion,
      },
    );
    return Recipe.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> setActiveBranch(String recipeId, String branch) async {
    await _apiClient.put(
      ApiEndpoints.recipeBranch(recipeId),
      data: {'branch': branch},
    );
  }
}
