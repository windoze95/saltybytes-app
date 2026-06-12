import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

/// Fake auth notifier that reports authenticated immediately.
class _FakeAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {
  @override
  Future<AuthStatus> build() async => AuthStatus.authenticated;

  @override
  Future<void> login({required String username, required String password}) async {}

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}
}

ProviderContainer _buildContainer(MockApiClient apiClient) {
  final container = ProviderContainer(overrides: [
    apiClientProvider.overrideWithValue(apiClient),
    authStateProvider.overrideWith(_FakeAuthNotifier.new),
  ]);
  return container;
}

void main() {
  group('Recipe response parsing', () {
    test('parses {recipes: [...]} format', () {
      final data = <String, dynamic>{
        'recipes': [
          testRecipeJson(id: 'r-1', title: 'Pizza'),
          testRecipeJson(id: 'r-2', title: 'Pasta'),
        ],
      };

      // Mirrors the parsing logic in RecipeListNotifier._fetchRecipes
      List<Recipe> recipes = [];
      if (data is Map<String, dynamic> && data['recipes'] is List) {
        recipes = (data['recipes'] as List)
            .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      expect(recipes, hasLength(2));
      expect(recipes[0].id, 'r-1');
      expect(recipes[1].id, 'r-2');
    });

    test('parses bare [...] format', () {
      final data = [
        testRecipeJson(id: 'r-1', title: 'Pizza'),
        testRecipeJson(id: 'r-2', title: 'Pasta'),
        testRecipeJson(id: 'r-3', title: 'Salad'),
      ];

      // Mirrors the parsing logic in RecipeListNotifier._fetchRecipes
      List<Recipe> recipes = [];
      if (data is List) {
        recipes = data
            .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      expect(recipes, hasLength(3));
      expect(recipes[2].title, 'Salad');
    });

    test('returns empty list for unexpected format', () {
      final dynamic data = 'unexpected string response';

      List<Recipe> recipes = [];
      if (data is Map<String, dynamic> && data['recipes'] is List) {
        recipes = (data['recipes'] as List)
            .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
            .toList();
      } else if (data is List) {
        recipes = (data as List)
            .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      expect(recipes, isEmpty);
    });

    test('Recipe.fromJson with actual API response shape', () {
      // Simulates unwrapping { recipe: {...} } as recipeDetailProvider does
      final apiResponse = <String, dynamic>{
        'recipe': testRecipeJson(
          id: 'r-detail',
          title: 'Detailed Recipe',
          sourceUrl: 'https://example.com/recipe',
        ),
      };

      final recipeJson = apiResponse['recipe'] as Map<String, dynamic>;
      final recipe = Recipe.fromJson(recipeJson);

      expect(recipe.id, 'r-detail');
      expect(recipe.title, 'Detailed Recipe');
      expect(recipe.sourceUrl, 'https://example.com/recipe');
    });

    test('handles empty recipe list', () {
      final data = <String, dynamic>{
        'recipes': <dynamic>[],
      };

      final recipes = (data['recipes'] as List)
          .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
          .toList();

      expect(recipes, isEmpty);
    });
  });

  group('Delete optimistic update logic', () {
    test('filters out the deleted recipe by id', () {
      final recipes = [
        Recipe.fromJson(testRecipeJson(id: 'r-1', title: 'Keep')),
        Recipe.fromJson(testRecipeJson(id: 'r-2', title: 'Delete Me')),
        Recipe.fromJson(testRecipeJson(id: 'r-3', title: 'Also Keep')),
      ];

      // Mirrors the optimistic removal in RecipeListNotifier.deleteRecipe
      final idToDelete = 'r-2';
      final afterDelete = recipes.where((r) => r.id != idToDelete).toList();

      expect(afterDelete, hasLength(2));
      expect(afterDelete.map((r) => r.id), isNot(contains('r-2')));
      expect(afterDelete[0].title, 'Keep');
      expect(afterDelete[1].title, 'Also Keep');
    });

    test('deleting non-existent id leaves list unchanged', () {
      final recipes = [
        Recipe.fromJson(testRecipeJson(id: 'r-1')),
        Recipe.fromJson(testRecipeJson(id: 'r-2')),
      ];

      final afterDelete = recipes.where((r) => r.id != 'r-999').toList();

      expect(afterDelete, hasLength(2));
    });
  });

  group('Pagination parameters', () {
    test('query parameters have expected shape', () {
      // Mirrors RecipeListNotifier._fetchRecipes parameter building
      final page = 2;
      final pageSize = 10;
      final query = 'pizza';

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (query.isNotEmpty) {
        queryParams['q'] = query;
      }

      expect(queryParams['page'], 2);
      expect(queryParams['page_size'], 10);
      expect(queryParams['q'], 'pizza');
    });

    test('query parameter omitted when empty', () {
      final query = '';
      final queryParams = <String, dynamic>{
        'page': 1,
        'page_size': 20,
      };
      if (query.isNotEmpty) {
        queryParams['q'] = query;
      }

      expect(queryParams.containsKey('q'), false);
    });
  });

  group('RecipeListNotifier (real notifier)', () {
    late MockApiClient apiClient;
    late ProviderContainer container;

    setUp(() {
      apiClient = MockApiClient();
      container = _buildContainer(apiClient);
      addTearDown(container.dispose);
    });

    /// Resolves auth BEFORE the list provider is first read. Otherwise the
    /// auth dependency flips to authenticated mid-build and marks the list
    /// provider dirty while nothing is listening, parking `.future` forever.
    Future<void> primeAuth() =>
        container.read(authStateProvider.future);

    test('dedupes recipes by id when setting state', () async {
      when(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'recipes': [
              testRecipeJson(id: 'r-1', title: 'Pizza'),
              testRecipeJson(id: 'r-1', title: 'Pizza (dup)'),
              testRecipeJson(id: 'r-2', title: 'Pasta'),
            ],
          }));

      await primeAuth();
      final recipes = await container.read(recipeListProvider.future);

      expect(recipes, hasLength(2));
      expect(recipes.map((r) => r.id), ['r-1', 'r-2']);
      // First occurrence wins
      expect(recipes[0].title, 'Pizza');
    });

    test('ignores stale out-of-order search responses', () async {
      final slowFirst = Completer<Response<dynamic>>();
      final fastSecond = Completer<Response<dynamic>>();

      when(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((invocation) {
        final params = invocation.namedArguments[#queryParameters]
            as Map<String, dynamic>?;
        switch (params?['q']) {
          case 'first':
            return slowFirst.future;
          case 'second':
            return fastSecond.future;
          default:
            return Future.value(
                fakeResponse<dynamic>({'recipes': <dynamic>[]}));
        }
      });

      // Initial build
      await primeAuth();
      await container.read(recipeListProvider.future);
      final notifier = container.read(recipeListProvider.notifier);

      // Fire two overlapping searches; the SECOND completes FIRST.
      final firstSearch = notifier.search('first');
      final secondSearch = notifier.search('second');

      fastSecond.complete(fakeResponse<dynamic>({
        'recipes': [testRecipeJson(id: 'r-2', title: 'Second')],
      }));
      await secondSearch;

      // The stale first response arrives late and must be dropped.
      slowFirst.complete(fakeResponse<dynamic>({
        'recipes': [testRecipeJson(id: 'r-1', title: 'First')],
      }));
      await firstSearch;

      final recipes = container.read(recipeListProvider).value!;
      expect(recipes, hasLength(1));
      expect(recipes.single.title, 'Second');
    });

    test('refresh supersedes an in-flight search', () async {
      final slowSearch = Completer<Response<dynamic>>();

      when(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((invocation) {
        final params = invocation.namedArguments[#queryParameters]
            as Map<String, dynamic>?;
        if (params?['q'] == 'stale') return slowSearch.future;
        return Future.value(fakeResponse<dynamic>({
          'recipes': [testRecipeJson(id: 'r-9', title: 'Fresh')],
        }));
      });

      await primeAuth();
      await container.read(recipeListProvider.future);
      final notifier = container.read(recipeListProvider.notifier);

      final search = notifier.search('stale');
      await notifier.refresh();

      slowSearch.complete(fakeResponse<dynamic>({
        'recipes': [testRecipeJson(id: 'r-1', title: 'Stale')],
      }));
      await search;

      expect(
          container.read(recipeListProvider).value!.single.title, 'Fresh');
    });
  });

  group('RecipeCrud import envelope handling', () {
    late MockApiClient apiClient;
    late RecipeCrud crud;

    setUp(() {
      apiClient = MockApiClient();
      crud = RecipeCrud(apiClient: apiClient);
    });

    void stubPost(String path, Map<String, dynamic> responseData) {
      when(() => apiClient.post(
            path,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => fakeResponse<dynamic>(responseData));
    }

    test('importFromText unwraps the {recipe: {...}} envelope', () async {
      stubPost(ApiEndpoints.importFromText,
          {'recipe': testRecipeJson(id: 'r-text', title: 'From Text')});

      final recipe = await crud.importFromText('Some pasted recipe text');

      expect(recipe.id, 'r-text');
      expect(recipe.title, 'From Text');
    });

    test('importFromPhoto unwraps the {recipe: {...}} envelope', () async {
      stubPost(ApiEndpoints.importFromPhoto,
          {'recipe': testRecipeJson(id: 'r-photo', title: 'From Photo')});

      final formData = FormData.fromMap({
        'image': MultipartFile.fromString('fake-bytes',
            filename: 'recipe_image.jpg'),
      });
      final recipe = await crud.importFromPhoto(formData);

      expect(recipe.id, 'r-photo');
      expect(recipe.title, 'From Photo');
    });

    test('importFromUrl unwraps envelope and uses the 60s AI timeout',
        () async {
      stubPost(ApiEndpoints.importFromUrl,
          {'recipe': testRecipeJson(id: 'r-url', title: 'From URL')});

      final recipe = await crud.importFromUrl('https://example.com/r');
      expect(recipe.id, 'r-url');

      final captured = verify(() => apiClient.post(
            ApiEndpoints.importFromUrl,
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured;
      expect(captured[0], {'url': 'https://example.com/r'});
      expect((captured[1] as Options).receiveTimeout, ApiTimeouts.aiGeneration);
    });

    test('importFromText and importManual use the 60s AI timeout', () async {
      stubPost(ApiEndpoints.importFromText,
          {'recipe': testRecipeJson(id: 'r-1')});
      stubPost(ApiEndpoints.importManual,
          {'recipe': testRecipeJson(id: 'r-2')});

      await crud.importFromText('text');
      await crud.importManual({'title': 'T'});

      final textOptions = verify(() => apiClient.post(
            ApiEndpoints.importFromText,
            data: any(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured.single as Options;
      final manualOptions = verify(() => apiClient.post(
            ApiEndpoints.importManual,
            data: any(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured.single as Options;

      expect(textOptions.receiveTimeout, ApiTimeouts.aiGeneration);
      expect(manualOptions.receiveTimeout, ApiTimeouts.aiGeneration);
    });

    test('importManual posts the body unchanged and parses the envelope',
        () async {
      stubPost(ApiEndpoints.importManual,
          {'recipe': testRecipeJson(id: 'r-manual', title: 'Manual')});

      final body = {
        'title': 'Manual',
        'ingredients': [
          {'name': 'flour', 'unit': 'cup', 'amount': 2.0},
        ],
        'instructions': ['Mix'],
        'cook_time': 10,
        'portions': 4,
      };
      final recipe = await crud.importManual(body);

      expect(recipe.id, 'r-manual');
      final captured = verify(() => apiClient.post(
            ApiEndpoints.importManual,
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single;
      expect(captured, body);
    });
  });

  group('RecipeCrud generate / regenerate / fork request shapes', () {
    late MockApiClient apiClient;
    late RecipeCrud crud;

    setUp(() {
      apiClient = MockApiClient();
      crud = RecipeCrud(apiClient: apiClient);
    });

    test(
        'generate POSTs /v1/recipes/chat with user_prompt + gen_image '
        'and a 60s receive timeout', () async {
      when(() => apiClient.post(
            ApiEndpoints.generateRecipe,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'recipe': testRecipeJson(id: '42', status: 'generating'),
            'message': 'Generating recipe',
          }));

      final recipe = await crud.generate(
        userPrompt: 'A cozy chicken pot pie',
        genImage: true,
      );

      expect(recipe.id, '42');
      expect(recipe.status, 'generating');

      final captured = verify(() => apiClient.post(
            ApiEndpoints.generateRecipe,
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured;
      expect(captured[0], {
        'user_prompt': 'A cozy chicken pot pie',
        'gen_image': true,
      });
      expect(
          (captured[1] as Options).receiveTimeout, ApiTimeouts.aiGeneration);
    });

    test('regenerate PUTs /v1/recipes/:id/chat with user_prompt + gen_image',
        () async {
      when(() => apiClient.put(
            ApiEndpoints.recipeChat('7'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          fakeResponse<dynamic>({'message': 'Regenerating recipe'}));

      await crud.regenerate('7', userPrompt: 'Make it vegan', genImage: false);

      final captured = verify(() => apiClient.put(
            '/v1/recipes/7/chat',
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single;
      expect(captured, {
        'user_prompt': 'Make it vegan',
        'gen_image': false,
      });
    });

    test(
        'fork POSTs /v1/recipes/:id/fork with user_prompt + gen_image '
        'and unwraps the placeholder envelope', () async {
      when(() => apiClient.post(
            ApiEndpoints.recipeFork('7'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'recipe': testRecipeJson(id: '99', status: 'generating'),
            'message': 'Regenerating recipe',
          }));

      final recipe = await crud.fork(
        '7',
        userPrompt: 'Variation name: spicy. Changes: Double the chili',
      );

      expect(recipe.id, '99');

      final captured = verify(() => apiClient.post(
            '/v1/recipes/7/fork',
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single;
      expect(captured, {
        'user_prompt': 'Variation name: spicy. Changes: Double the chili',
        'gen_image': true,
      });
    });
  });

  group('RecipeCrud.waitUntilGenerated', () {
    late MockApiClient apiClient;
    late RecipeCrud crud;

    setUp(() {
      apiClient = MockApiClient();
      crud = RecipeCrud(apiClient: apiClient);
    });

    test('polls until status leaves "generating"', () async {
      var calls = 0;
      when(() => apiClient.get(ApiEndpoints.recipeById('42')))
          .thenAnswer((_) async {
        calls++;
        return fakeResponse<dynamic>({
          'recipe': testRecipeJson(
            id: '42',
            status: calls < 3 ? 'generating' : 'ready',
          ),
        });
      });

      final recipe = await crud.waitUntilGenerated(
        '42',
        pollInterval: const Duration(milliseconds: 1),
      );

      expect(recipe.status, 'ready');
      expect(calls, 3);
    });

    test('throws RecipeGenerationException when status becomes failed',
        () async {
      when(() => apiClient.get(ApiEndpoints.recipeById('42')))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'recipe': testRecipeJson(id: '42', status: 'failed'),
              }));

      await expectLater(
        crud.waitUntilGenerated(
          '42',
          pollInterval: const Duration(milliseconds: 1),
        ),
        throwsA(isA<RecipeGenerationException>()),
      );
    });

    test('throws RecipeGenerationException on 404 (backend deleted the row)',
        () async {
      when(() => apiClient.get(ApiEndpoints.recipeById('42'))).thenAnswer(
        (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/v1/recipes/42'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/recipes/42'),
            statusCode: 404,
          ),
        ),
      );

      await expectLater(
        crud.waitUntilGenerated(
          '42',
          pollInterval: const Duration(milliseconds: 1),
        ),
        throwsA(isA<RecipeGenerationException>()),
      );
    });
  });

  group('RecipeSearchResult', () {
    test('fromJson parses paginated result', () {
      final json = <String, dynamic>{
        'recipes': [
          testRecipeJson(id: 'r-1'),
          testRecipeJson(id: 'r-2'),
        ],
        'total': 50,
        'page': 3,
        'pageSize': 20,
      };
      final result = RecipeSearchResult.fromJson(json);

      expect(result.recipes, hasLength(2));
      expect(result.total, 50);
      expect(result.page, 3);
      expect(result.pageSize, 20);
    });
  });
}
