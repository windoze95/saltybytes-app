import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

final recipeBranchesProvider =
    FutureProvider.family<RecipeNode?, String>((ref, recipeId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.recipeTree(recipeId));

  final data = response.data;
  if (data is Map<String, dynamic> && data['root_node'] is Map<String, dynamic>) {
    return RecipeNode.fromJson(data['root_node'] as Map<String, dynamic>);
  }
  return null;
});

final branchOperationsProvider = Provider<BranchOperations>((ref) {
  return BranchOperations(apiClient: ref.watch(apiClientProvider));
});

class BranchOperations {
  const BranchOperations({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> createBranch(
    String recipeId, {
    required String branchName,
    required int parentNodeId,
  }) async {
    await _apiClient.post(
      ApiEndpoints.recipeBranch(recipeId),
      data: {
        'branch_name': branchName,
        'parent_node_id': parentNodeId,
      },
    );
  }

  Future<void> setActiveNode(String recipeId, int nodeId) async {
    await _apiClient.put(
      '${ApiEndpoints.recipeTree(recipeId)}/active/$nodeId',
    );
  }
}
