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

ProviderContainer _buildContainer(
  MockApiClient apiClient, {
  AuthStatus authStatus = AuthStatus.authenticated,
}) {
  final container = ProviderContainer(overrides: [
    apiClientProvider.overrideWithValue(apiClient),
    authStateProvider.overrideWith(() => FakeAuthNotifier(authStatus)),
  ]);
  return container;
}

void main() {
  group('RecipeListNotifier fetch (real notifier)', () {
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
    Future<void> primeAuth() => container.read(authStateProvider.future);

    void stubList(dynamic responseData) {
      when(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => fakeResponse<dynamic>(responseData));
    }

    test('parses the {recipes: [...]} envelope and sends default pagination '
        'params (page=1, page_size=20, no q)', () async {
      stubList({
        'recipes': [
          testRecipeJson(id: 'r-1', title: 'Pizza'),
          testRecipeJson(id: 'r-2', title: 'Pasta'),
        ],
      });

      await primeAuth();
      final recipes = await container.read(recipeListProvider.future);

      expect(recipes, hasLength(2));
      expect(recipes[0].id, 'r-1');
      expect(recipes[1].id, 'r-2');

      final params = verify(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(params, {'page': 1, 'page_size': 20});
      expect(params.containsKey('q'), isFalse);
    });

    test('parses a bare [...] payload', () async {
      stubList([
        testRecipeJson(id: 'r-1', title: 'Pizza'),
        testRecipeJson(id: 'r-2', title: 'Pasta'),
        testRecipeJson(id: 'r-3', title: 'Salad'),
      ]);

      await primeAuth();
      final recipes = await container.read(recipeListProvider.future);

      expect(recipes, hasLength(3));
      expect(recipes[2].title, 'Salad');
    });

    test('returns an empty list for an unexpected payload shape', () async {
      stubList('unexpected string response');

      await primeAuth();
      final recipes = await container.read(recipeListProvider.future);

      expect(recipes, isEmpty);
    });

    test('returns an empty list when the recipes key is an empty list',
        () async {
      stubList({'recipes': <dynamic>[]});

      await primeAuth();
      final recipes = await container.read(recipeListProvider.future);

      expect(recipes, isEmpty);
    });

    test('returns [] without hitting the network when unauthenticated',
        () async {
      final unauthContainer = _buildContainer(
        apiClient,
        authStatus: AuthStatus.unauthenticated,
      );
      addTearDown(unauthContainer.dispose);

      await unauthContainer.read(authStateProvider.future);
      final recipes =
          await unauthContainer.read(recipeListProvider.future);

      expect(recipes, isEmpty);
      verifyNever(() => apiClient.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ));
    });

    test('dedupes recipes by id when setting state', () async {
      stubList({
        'recipes': [
          testRecipeJson(id: 'r-1', title: 'Pizza'),
          testRecipeJson(id: 'r-1', title: 'Pizza (dup)'),
          testRecipeJson(id: 'r-2', title: 'Pasta'),
        ],
      });

      await primeAuth();
      final recipes = await container.read(recipeListProvider.future);

      expect(recipes, hasLength(2));
      expect(recipes.map((r) => r.id), ['r-1', 'r-2']);
      // First occurrence wins
      expect(recipes[0].title, 'Pizza');
    });

    test('search sends q while refresh omits it', () async {
      stubList({'recipes': <dynamic>[]});

      await primeAuth();
      await container.read(recipeListProvider.future);
      final notifier = container.read(recipeListProvider.notifier);
      clearInteractions(apiClient);

      await notifier.search('pizza');
      var params = verify(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(params['q'], 'pizza');
      expect(params['page'], 1);
      expect(params['page_size'], 20);

      await notifier.refresh();
      params = verify(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(params.containsKey('q'), isFalse);
    });

    test('search with an empty query omits q (matches refresh semantics)',
        () async {
      stubList({'recipes': <dynamic>[]});

      await primeAuth();
      await container.read(recipeListProvider.future);
      clearInteractions(apiClient);

      await container.read(recipeListProvider.notifier).search('');

      final params = verify(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(params.containsKey('q'), isFalse);
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

  group('RecipeListNotifier.deleteRecipe (real notifier)', () {
    late MockApiClient apiClient;
    late ProviderContainer container;

    setUp(() {
      apiClient = MockApiClient();
      container = _buildContainer(apiClient);
      addTearDown(container.dispose);

      when(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'recipes': [
              testRecipeJson(id: 'r-1', title: 'Keep'),
              testRecipeJson(id: 'r-2', title: 'Delete Me'),
              testRecipeJson(id: 'r-3', title: 'Also Keep'),
            ],
          }));
    });

    Future<RecipeListNotifier> primedNotifier() async {
      await container.read(authStateProvider.future);
      await container.read(recipeListProvider.future);
      return container.read(recipeListProvider.notifier);
    }

    test('optimistically removes the recipe and DELETEs it on the server',
        () async {
      when(() => apiClient.delete(ApiEndpoints.recipeById('r-2')))
          .thenAnswer((_) async => fakeResponse<dynamic>(null, statusCode: 204));

      final notifier = await primedNotifier();
      await notifier.deleteRecipe('r-2');

      final recipes = container.read(recipeListProvider).value!;
      expect(recipes.map((r) => r.id), ['r-1', 'r-3']);
      expect(recipes.map((r) => r.title), ['Keep', 'Also Keep']);
      verify(() => apiClient.delete('/v1/recipes/r-2')).called(1);
    });

    test('reverts the optimistic removal and rethrows when the server '
        'call fails', () async {
      when(() => apiClient.delete(ApiEndpoints.recipeById('r-2'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/recipes/r-2'),
          type: DioExceptionType.connectionError,
        ),
      );

      final notifier = await primedNotifier();
      await expectLater(
        notifier.deleteRecipe('r-2'),
        throwsA(isA<DioException>()),
      );

      final recipes = container.read(recipeListProvider).value!;
      expect(recipes.map((r) => r.id), ['r-1', 'r-2', 'r-3']);
    });

    test('an in-flight refresh cannot resurrect a recipe deleted while it '
        'was running', () async {
      final slowRefresh = Completer<Response<dynamic>>();
      when(() => apiClient.delete(ApiEndpoints.recipeById('r-2')))
          .thenAnswer((_) async => fakeResponse<dynamic>(null, statusCode: 204));

      final notifier = await primedNotifier();

      // Refresh stalls server-side with a response that predates the delete.
      when(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) => slowRefresh.future);
      final refresh = notifier.refresh();

      await notifier.deleteRecipe('r-2');

      slowRefresh.complete(fakeResponse<dynamic>({
        'recipes': [
          testRecipeJson(id: 'r-1', title: 'Keep'),
          testRecipeJson(id: 'r-2', title: 'Delete Me'),
          testRecipeJson(id: 'r-3', title: 'Also Keep'),
        ],
      }));
      await refresh;

      // The stale fetch result must be discarded, not re-include r-2.
      expect(
        container.read(recipeListProvider).value!.map((r) => r.id),
        ['r-1', 'r-3'],
      );
    });

    test('deleting a non-existent id leaves the list unchanged', () async {
      when(() => apiClient.delete(ApiEndpoints.recipeById('r-999')))
          .thenAnswer((_) async => fakeResponse<dynamic>(null, statusCode: 204));

      final notifier = await primedNotifier();
      await notifier.deleteRecipe('r-999');

      expect(container.read(recipeListProvider).value, hasLength(3));
    });
  });

  group('recipeDetailProvider', () {
    test('fetches GET /v1/recipes/:id and unwraps the {recipe: {...}} '
        'envelope', () async {
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.recipeById('r-detail')))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'recipe': testRecipeJson(
                  id: 'r-detail',
                  title: 'Detailed Recipe',
                  sourceUrl: 'https://example.com/recipe',
                ),
              }));

      final container = createTestContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
      ]);
      addTearDown(container.dispose);
      // Family-provider gotcha: attach a listener before awaiting .future.
      container.listen(recipeDetailProvider('r-detail'), (_, __) {});

      final recipe =
          await container.read(recipeDetailProvider('r-detail').future);

      expect(recipe.id, 'r-detail');
      expect(recipe.title, 'Detailed Recipe');
      expect(recipe.sourceUrl, 'https://example.com/recipe');
      verify(() => apiClient.get('/v1/recipes/r-detail')).called(1);
    });
  });

  group('similarRecipesProvider', () {
    test('parses {similar_recipes: [...]} and tolerates a missing key',
        () async {
      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.recipeSimilar('r-1')))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'similar_recipes': [
                  testRecipeJson(id: 'r-2', title: 'Cousin Pizza'),
                ],
              }));
      when(() => apiClient.get(ApiEndpoints.recipeSimilar('r-9')))
          .thenAnswer((_) async => fakeResponse<dynamic>({'nope': true}));

      final container = createTestContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
      ]);
      addTearDown(container.dispose);
      container.listen(similarRecipesProvider('r-1'), (_, __) {});
      container.listen(similarRecipesProvider('r-9'), (_, __) {});

      final similar =
          await container.read(similarRecipesProvider('r-1').future);
      expect(similar.single.title, 'Cousin Pizza');

      final none = await container.read(similarRecipesProvider('r-9').future);
      expect(none, isEmpty);
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

  group('RecipeCrud video import (async job)', () {
    late MockApiClient apiClient;
    late RecipeCrud crud;

    setUp(() {
      apiClient = MockApiClient();
      crud = RecipeCrud(apiClient: apiClient);
    });

    void stubPost(String path, Map<String, dynamic> data) {
      when(() => apiClient.post(
            path,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer(
          (_) async => fakeResponse<dynamic>(data, statusCode: 202));
    }

    void stubGet(String path, Map<String, dynamic> data) {
      when(() => apiClient.get(path))
          .thenAnswer((_) async => fakeResponse<dynamic>(data));
    }

    test('importFromVideo starts a job, polls to done, returns the recipe',
        () async {
      stubPost(ApiEndpoints.importFromVideo, {
        'job': {
          'id': 5,
          'status': 'queued',
          'platform': 'tiktok',
          'cache_hit': false,
        }
      });
      stubGet(ApiEndpoints.importVideoStatus(5), {
        'job': {'id': 5, 'status': 'done', 'recipe_id': 42, 'cache_hit': false}
      });
      stubGet(ApiEndpoints.recipeById('42'),
          {'recipe': testRecipeJson(id: '42', title: 'Cajun Pasta')});

      final recipe = await crud.importFromVideo(
        'https://www.tiktok.com/@x/video/1',
        pollInterval: Duration.zero,
      );

      expect(recipe.id, '42');
      expect(recipe.title, 'Cajun Pasta');

      final posted = verify(() => apiClient.post(
            ApiEndpoints.importFromVideo,
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured;
      expect(posted[0], {'url': 'https://www.tiktok.com/@x/video/1'});
      expect((posted[1] as Options).receiveTimeout, ApiTimeouts.aiGeneration);
    });

    test('importFromVideo surfaces the job error as a VideoImportException',
        () async {
      stubPost(ApiEndpoints.importFromVideo, {
        'job': {'id': 7, 'status': 'queued'}
      });
      stubGet(ApiEndpoints.importVideoStatus(7), {
        'job': {
          'id': 7,
          'status': 'failed',
          'error': 'could not find a recipe in this video',
        }
      });

      await expectLater(
        crud.importFromVideo('https://www.tiktok.com/@x/video/2',
            pollInterval: Duration.zero),
        throwsA(isA<VideoImportException>().having(
          (e) => e.message,
          'message',
          contains('could not find a recipe'),
        )),
      );
    });

    test('importFromVideo handles a cache hit (done on first poll)', () async {
      stubPost(ApiEndpoints.importFromVideo, {
        'job': {'id': 9, 'status': 'queued', 'cache_hit': false}
      });
      stubGet(ApiEndpoints.importVideoStatus(9), {
        'job': {'id': 9, 'status': 'done', 'recipe_id': 99, 'cache_hit': true}
      });
      stubGet(ApiEndpoints.recipeById('99'),
          {'recipe': testRecipeJson(id: '99', title: 'Cached')});

      final recipe = await crud.importFromVideo(
        'https://www.instagram.com/reel/x/',
        pollInterval: Duration.zero,
      );
      expect(recipe.id, '99');
    });
  });

  group('RecipeCrud regenerate / fork request shapes', () {
    late MockApiClient apiClient;
    late RecipeCrud crud;

    setUp(() {
      apiClient = MockApiClient();
      crud = RecipeCrud(apiClient: apiClient);
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
    test('fromJson parses paginated result (total/page/pageSize)', () {
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
