import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/branch_provider.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../helpers/test_helpers.dart';

/// A flat node as serialized by GET /v1/recipes/:id/tree per the contract:
/// snake_case keys, parent_id null for the root, "response" carrying the
/// RecipeDef (ignored by the Flutter node model).
Map<String, dynamic> _flatNodeJson({
  required dynamic id,
  dynamic parentId,
  String branchName = 'original',
  bool isActive = false,
  String type = 'chat',
}) =>
    {
      'id': id,
      'tree_id': 1,
      'parent_id': parentId,
      'branch_name': branchName,
      'is_active': isActive,
      'created_at': '2026-06-01T10:00:00Z',
      'user_prompt': 'make me a recipe',
      'response': {'title': 'Some Recipe'},
      'summary': 'A summary',
      'type': type,
      'is_ephemeral': false,
      'created_by_id': 5,
    };

void main() {
  group('buildRecipeNodeTree', () {
    test('builds a 3-node tree from a flat list via parent_id', () {
      final nodes = [
        RecipeNode.fromJson(_flatNodeJson(id: 1, parentId: null)),
        RecipeNode.fromJson(
            _flatNodeJson(id: 2, parentId: 1, branchName: 'spicy')),
        RecipeNode.fromJson(_flatNodeJson(
            id: 3, parentId: 2, branchName: 'extra-spicy', isActive: true)),
      ];

      final root = buildRecipeNodeTree(nodes, rootNodeId: 1);

      expect(root, isNotNull);
      expect(root!.id, 1);
      expect(root.children, hasLength(1));
      expect(root.children.single.id, 2);
      expect(root.children.single.branchName, 'spicy');
      expect(root.children.single.children, hasLength(1));
      expect(root.children.single.children.single.id, 3);
      expect(root.children.single.children.single.isActive, isTrue);
    });

    test('falls back to the parentless node when rootNodeId is missing', () {
      final nodes = [
        RecipeNode.fromJson(_flatNodeJson(id: 2, parentId: 1)),
        RecipeNode.fromJson(_flatNodeJson(id: 1, parentId: null)),
      ];

      final root = buildRecipeNodeTree(nodes);

      expect(root!.id, 1);
      expect(root.children.single.id, 2);
    });

    test('sorts siblings by id and returns null for an empty list', () {
      expect(buildRecipeNodeTree([]), isNull);

      final nodes = [
        RecipeNode.fromJson(_flatNodeJson(id: 1, parentId: null)),
        RecipeNode.fromJson(_flatNodeJson(id: 5, parentId: 1)),
        RecipeNode.fromJson(_flatNodeJson(id: 3, parentId: 1)),
      ];

      final root = buildRecipeNodeTree(nodes, rootNodeId: 1);
      expect(root!.children.map((c) => c.id), [3, 5]);
    });
  });

  group('RecipeTreeData.fromJson', () {
    test('parses the contract tree envelope with int ids', () {
      final tree = RecipeTreeData.fromJson({
        'tree_id': 10,
        'recipe_id': 7,
        'root_node_id': 1,
        'active_node_id': 3,
        'nodes': [
          _flatNodeJson(id: 1, parentId: null),
          _flatNodeJson(id: 2, parentId: 1, branchName: 'vegan'),
          _flatNodeJson(id: 3, parentId: 1, branchName: 'spicy', isActive: true),
        ],
      });

      expect(tree.treeId, 10);
      expect(tree.recipeId, '7');
      expect(tree.rootNodeId, 1);
      expect(tree.activeNodeId, 3);
      expect(tree.root!.id, 1);
      expect(tree.root!.children.map((c) => c.id), [2, 3]);
    });

    test('normalizes ids that arrive as strings', () {
      final tree = RecipeTreeData.fromJson({
        'tree_id': '10',
        'recipe_id': '7',
        'root_node_id': '1',
        'active_node_id': null,
        'nodes': [
          _flatNodeJson(id: '1', parentId: null),
          _flatNodeJson(id: '2', parentId: '1'),
        ],
      });

      expect(tree.treeId, 10);
      expect(tree.rootNodeId, 1);
      expect(tree.root!.id, 1);
      expect(tree.root!.children.single.id, 2);
    });
  });

  group('recipeBranchesProvider', () {
    test('fetches GET /v1/recipes/:id/tree and parses the {tree: ...} envelope',
        () async {
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.recipeTree('7')))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'tree': {
                  'tree_id': 10,
                  'recipe_id': 7,
                  'root_node_id': 1,
                  'active_node_id': 1,
                  'nodes': [
                    _flatNodeJson(id: 1, parentId: null, isActive: true),
                    _flatNodeJson(id: 2, parentId: 1, branchName: 'fork-1'),
                  ],
                },
              }));

      final container = createTestContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
      ]);
      addTearDown(container.dispose);

      final tree = await container.read(recipeBranchesProvider('7').future);

      expect(tree, isNotNull);
      expect(tree!.root!.id, 1);
      expect(tree.root!.children.single.branchName, 'fork-1');
      verify(() => apiClient.get('/v1/recipes/7/tree')).called(1);
    });

    test('returns null when the envelope is missing', () async {
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.recipeTree('7')))
          .thenAnswer((_) async => fakeResponse<dynamic>({'nope': true}));

      final container = createTestContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
      ]);
      addTearDown(container.dispose);

      final tree = await container.read(recipeBranchesProvider('7').future);
      expect(tree, isNull);
    });
  });

  group('BranchOperations request shapes', () {
    test('createBranch POSTs branch_name + parent_node_id', () async {
      final apiClient = MockApiClient();
      when(() => apiClient.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => fakeResponse<dynamic>({'node': {}}));

      final ops = BranchOperations(apiClient: apiClient);
      await ops.createBranch('7', branchName: 'vegan', parentNodeId: 3);

      final captured = verify(() => apiClient.post(
            '/v1/recipes/7/branch',
            data: captureAny(named: 'data'),
          )).captured.single;
      expect(captured, {'branch_name': 'vegan', 'parent_node_id': 3});
    });

    test('setActiveNode PUTs /v1/recipes/:id/tree/active/:nodeId', () async {
      final apiClient = MockApiClient();
      when(() => apiClient.put(any()))
          .thenAnswer((_) async => fakeResponse<dynamic>({'message': 'ok'}));

      final ops = BranchOperations(apiClient: apiClient);
      await ops.setActiveNode('7', 3);

      verify(() => apiClient.put('/v1/recipes/7/tree/active/3')).called(1);
    });
  });
}
