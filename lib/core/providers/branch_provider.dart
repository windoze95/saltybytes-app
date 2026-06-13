import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Parsed result of GET /v1/recipes/:id/tree.
///
/// The backend returns a flat node list; [root] is rebuilt client-side from
/// each node's parent_id (see [buildRecipeNodeTree]).
class RecipeTreeData {
  const RecipeTreeData({
    required this.treeId,
    required this.recipeId,
    this.rootNodeId,
    this.activeNodeId,
    this.root,
  });

  final int treeId;
  final String recipeId;
  final int? rootNodeId;
  final int? activeNodeId;
  final RecipeNode? root;

  factory RecipeTreeData.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'];
    final nodes = rawNodes is List
        ? rawNodes
            .whereType<Map<String, dynamic>>()
            .map((n) => RecipeNode.fromJson(_normalizeNodeJson(n)))
            .toList()
        : <RecipeNode>[];

    final rootNodeId = _toIntOrNull(json['root_node_id']);

    return RecipeTreeData(
      treeId: _toIntOrNull(json['tree_id']) ?? 0,
      recipeId: json['recipe_id']?.toString() ?? '',
      rootNodeId: rootNodeId,
      activeNodeId: _toIntOrNull(json['active_node_id']),
      root: buildRecipeNodeTree(nodes, rootNodeId: rootNodeId),
    );
  }
}

/// Numeric IDs may arrive as int or String; normalize defensively.
int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

/// Pre-normalizes a node's id fields (which may arrive as int or String) so
/// the generated RecipeNode.fromJson can parse them.
Map<String, dynamic> _normalizeNodeJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.of(json);
  normalized['id'] = _toIntOrNull(json['id']) ?? 0;
  normalized['parent_id'] = _toIntOrNull(json['parent_id']);
  normalized['created_by_id'] = _toIntOrNull(json['created_by_id']);
  // The flat contract carries no children; they are rebuilt client-side.
  normalized.remove('children');
  return normalized;
}

/// Builds a tree from a flat node list using each node's parentId.
///
/// The root is the node matching [rootNodeId] when provided, otherwise the
/// first node without a parent. Children are sorted by id (creation order).
/// Returns null when [nodes] is empty.
RecipeNode? buildRecipeNodeTree(List<RecipeNode> nodes, {int? rootNodeId}) {
  if (nodes.isEmpty) return null;

  final childrenByParent = <int, List<RecipeNode>>{};
  for (final node in nodes) {
    final parentId = node.parentId;
    if (parentId != null) {
      childrenByParent.putIfAbsent(parentId, () => []).add(node);
    }
  }

  RecipeNode attachChildren(RecipeNode node) {
    final children = childrenByParent[node.id] ?? const <RecipeNode>[];
    final sorted = [...children]..sort((a, b) => a.id.compareTo(b.id));
    return node.copyWith(children: sorted.map(attachChildren).toList());
  }

  RecipeNode? root;
  if (rootNodeId != null) {
    for (final node in nodes) {
      if (node.id == rootNodeId) {
        root = node;
        break;
      }
    }
  }
  root ??= nodes.where((n) => n.parentId == null).firstOrNull;
  root ??= nodes.first;

  return attachChildren(root);
}

/// Fetches GET /v1/recipes/:id/tree and rebuilds the tree from the flat
/// node list per the API contract:
/// {"tree": {"tree_id", "recipe_id", "root_node_id", "active_node_id",
///   "nodes": [{"id", "tree_id", "parent_id", "branch_name", "is_active",
///   "created_at", "user_prompt", "response", ...}]}}
final recipeBranchesProvider =
    FutureProvider.family<RecipeTreeData?, String>((ref, recipeId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get(ApiEndpoints.recipeTree(recipeId));

  final data = response.data;
  if (data is Map<String, dynamic> && data['tree'] is Map<String, dynamic>) {
    return RecipeTreeData.fromJson(data['tree'] as Map<String, dynamic>);
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
