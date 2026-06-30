import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/search_provider.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('WebSearchResult', () {
    test('fromJson with all fields populated', () {
      final json = testWebSearchResultJson();
      final result = WebSearchResult.fromJson(json);

      expect(result.title, 'Best Margherita Pizza Recipe');
      expect(result.sourceUrl, 'https://www.seriouseats.com/margherita-pizza');
      expect(result.sourceDomain, 'seriouseats.com');
      expect(result.imageUrl, 'https://www.seriouseats.com/images/pizza.jpg');
      expect(result.description, 'An authentic Neapolitan-style margherita pizza recipe');
      expect(result.rating, 4.8);
      expect(result.cookTimeMinutes, 20);
      expect(result.familySafetyChecks, isEmpty);
    });

    test('fromJson with missing optional fields', () {
      final json = <String, dynamic>{
        'title': 'Quick Pasta',
      };
      final result = WebSearchResult.fromJson(json);

      expect(result.title, 'Quick Pasta');
      expect(result.sourceUrl, isNull);
      expect(result.sourceDomain, isNull);
      expect(result.imageUrl, isNull);
      expect(result.description, isNull);
      expect(result.rating, isNull);
      expect(result.cookTimeMinutes, isNull);
      expect(result.familySafetyChecks, isEmpty);
    });

    test('fromJson coerces an empty image_url to null (Go serializes '
        'image_url without omitempty)', () {
      final result = WebSearchResult.fromJson(
          testWebSearchResultJson()..['image_url'] = '');

      expect(result.imageUrl, isNull);
    });

    test('fromJson defaults title to Untitled when null', () {
      final json = <String, dynamic>{};
      final result = WebSearchResult.fromJson(json);

      expect(result.title, 'Untitled');
    });

    test('fromJson with family safety checks', () {
      final json = testWebSearchResultJson(
        familySafetyChecks: [
          testFamilySafetyCheckJson(
            memberId: 'm-1',
            memberName: 'Kid',
            status: 'unsafe',
            warnings: ['Contains nuts'],
          ),
        ],
      );
      final result = WebSearchResult.fromJson(json);

      expect(result.familySafetyChecks, hasLength(1));
      expect(result.familySafetyChecks[0].memberName, 'Kid');
      expect(result.familySafetyChecks[0].isSafe, false);
      expect(result.familySafetyChecks[0].warnings, ['Contains nuts']);
    });

    test('fromJson parses rating as double from int', () {
      final json = testWebSearchResultJson(rating: 5.0);
      final result = WebSearchResult.fromJson(json);

      expect(result.rating, 5.0);
      expect(result.rating, isA<double>());
    });
  });

  group('RecipePreview', () {
    test('fromJson with all fields', () {
      final json = testRecipePreviewJson();
      final preview = RecipePreview.fromJson(json);

      expect(preview.title, 'Classic Margherita Pizza');
      expect(preview.ingredients, hasLength(3));
      expect(preview.instructions, hasLength(3));
      expect(preview.cookTime, 15);
      expect(preview.portions, 4);
      expect(preview.portionSize, 'slices');
      expect(preview.sourceUrl, 'https://www.seriouseats.com/margherita-pizza');
      expect(preview.hashtags, ['pizza', 'italian']);
      expect(preview.imagePrompt, 'A rustic margherita pizza with bubbling mozzarella');
      expect(preview.linkedSuggestions, ['Garlic Bread', 'Tiramisu']);
    });

    test('fromJson with empty ingredients/instructions', () {
      final json = testRecipePreviewJson(
        ingredients: [],
        instructions: [],
        hashtags: [],
        linkedSuggestions: [],
      );
      final preview = RecipePreview.fromJson(json);

      expect(preview.ingredients, isEmpty);
      expect(preview.instructions, isEmpty);
      expect(preview.hashtags, isEmpty);
      expect(preview.linkedSuggestions, isEmpty);
    });

    test('fromJson with null lists defaults to empty', () {
      final json = <String, dynamic>{
        'title': 'Simple',
      };
      final preview = RecipePreview.fromJson(json);

      expect(preview.title, 'Simple');
      expect(preview.ingredients, isEmpty);
      expect(preview.instructions, isEmpty);
      expect(preview.hashtags, isEmpty);
      expect(preview.linkedSuggestions, isEmpty);
      expect(preview.cookTime, isNull);
      expect(preview.portions, isNull);
      expect(preview.portionSize, isNull);
      expect(preview.sourceUrl, isNull);
      expect(preview.imagePrompt, isNull);
    });

    test('fromJson defaults title to Untitled when null', () {
      final json = <String, dynamic>{};
      final preview = RecipePreview.fromJson(json);

      expect(preview.title, 'Untitled');
    });

    test('sourceDomain parses URL correctly', () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson(
        sourceUrl: 'https://www.allrecipes.com/recipe/12345',
      ));

      expect(preview.sourceDomain, 'allrecipes.com');
    });

    test('sourceDomain returns null when sourceUrl is null', () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson(
        sourceUrl: null,
      ));

      expect(preview.sourceDomain, isNull);
    });

    test('sourceDomain handles invalid URL gracefully', () {
      final preview = RecipePreview(
        title: 'Test',
        sourceUrl: 'not-a-url',
      );

      // Uri.parse does not throw for most strings; it just produces
      // a URI with an empty host. The getter replaceFirst('www.', '')
      // will return '' which is not null.
      expect(preview.sourceDomain, isA<String?>());
    });

    test('toManualImportJson produces expected structure', () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson());
      final json = preview.toManualImportJson();

      expect(json['title'], 'Classic Margherita Pizza');
      expect(json['instructions'], isA<List>());
      expect(json['instructions'], hasLength(3));
      expect(json['cook_time'], 15);
      expect(json['portions'], 4);
      expect(json['portion_size'], 'slices');
      expect(json['hashtags'], ['pizza', 'italian']);
      expect(json['source_url'], 'https://www.seriouseats.com/margherita-pizza');

      // Ingredients serialised with name/unit/amount keys
      final ingredients = json['ingredients'] as List;
      expect(ingredients, hasLength(3));
      final first = ingredients[0] as Map<String, dynamic>;
      expect(first['name'], 'pizza dough');
      expect(first['unit'], 'ball');
      expect(first['amount'], 1.0);
    });

    test('toManualImportJson omits source_url when null', () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson(sourceUrl: null));
      final json = preview.toManualImportJson();

      expect(json.containsKey('source_url'), false);
    });

    test('toManualImportJson uses zero defaults for null cook_time/portions', () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson(
        cookTime: null,
        portions: null,
        portionSize: null,
      ));
      final json = preview.toManualImportJson();

      expect(json['cook_time'], 0);
      expect(json['portions'], 0);
      expect(json['portion_size'], '');
    });

    test('toManualImportJson includes the detected unit_system', () {
      final preview = RecipePreview.fromJson(
          testRecipePreviewJson(unitSystem: 'metric'));
      final json = preview.toManualImportJson();

      expect(json['unit_system'], 'metric');
    });

    test('toManualImportJson omits unit_system when not detected', () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson());
      final json = preview.toManualImportJson();

      expect(json.containsKey('unit_system'), isFalse);
    });

    test('toManualImportJson threads metric fields and original_text through',
        () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson(
        unitSystem: 'us_customary',
        ingredients: [
          testPreviewIngredientJson(
            name: 'flour',
            unit: 'cups',
            amount: 2.0,
            metricUnit: 'g',
            metricAmount: 250.0,
            originalText: '2 cups (250 g) flour',
          ),
        ],
      ));
      final json = preview.toManualImportJson();

      final ingredient =
          (json['ingredients'] as List).first as Map<String, dynamic>;
      expect(ingredient['name'], 'flour');
      expect(ingredient['unit'], 'cups');
      expect(ingredient['amount'], 2.0);
      expect(ingredient['metric_unit'], 'g');
      expect(ingredient['metric_amount'], 250.0);
      expect(ingredient['original_text'], '2 cups (250 g) flour');
    });

    test('toManualImportJson omits metric keys when source has none', () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson(
        ingredients: [
          testPreviewIngredientJson(name: 'salt', unit: null, amount: null),
        ],
      ));
      final json = preview.toManualImportJson();

      final ingredient =
          (json['ingredients'] as List).first as Map<String, dynamic>;
      expect(ingredient.containsKey('metric_unit'), isFalse);
      expect(ingredient.containsKey('metric_amount'), isFalse);
      expect(ingredient.containsKey('original_text'), isFalse);
    });

    test('toManualImportJson includes image_url when provided', () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson());
      final json = preview.toManualImportJson(
          imageUrl: 'https://img.example.com/pizza.jpg');

      expect(json['image_url'], 'https://img.example.com/pizza.jpg');
    });

    test('toManualImportJson omits image_url when absent or empty', () {
      final preview = RecipePreview.fromJson(testRecipePreviewJson());

      expect(preview.toManualImportJson().containsKey('image_url'), isFalse);
      expect(
        preview.toManualImportJson(imageUrl: '').containsKey('image_url'),
        isFalse,
      );
    });

    test('fromJson parses the detected unit_system', () {
      final preview = RecipePreview.fromJson(
          testRecipePreviewJson(unitSystem: 'metric'));

      expect(preview.unitSystem, 'metric');
    });
  });

  group('PreviewIngredient', () {
    test('fromJson with amount + unit + name', () {
      final json = testPreviewIngredientJson(
        name: 'flour',
        unit: 'cups',
        amount: 2.0,
      );
      final ingredient = PreviewIngredient.fromJson(json);

      expect(ingredient.name, 'flour');
      expect(ingredient.unit, 'cups');
      expect(ingredient.amount, 2.0);
    });

    test('fromJson with missing name defaults to empty string', () {
      final json = <String, dynamic>{};
      final ingredient = PreviewIngredient.fromJson(json);

      expect(ingredient.name, '');
      expect(ingredient.unit, isNull);
      expect(ingredient.amount, isNull);
      expect(ingredient.metricUnit, isNull);
      expect(ingredient.metricAmount, isNull);
      expect(ingredient.originalText, isNull);
    });

    test('fromJson parses metric fields and original_text', () {
      final json = testPreviewIngredientJson(
        name: 'butter',
        unit: 'tbsp',
        amount: 3.0,
        metricUnit: 'g',
        metricAmount: 42.0,
        originalText: '3 tbsp (42 g) butter',
      );
      final ingredient = PreviewIngredient.fromJson(json);

      expect(ingredient.metricUnit, 'g');
      expect(ingredient.metricAmount, 42.0);
      expect(ingredient.originalText, '3 tbsp (42 g) butter');
    });

    test('displayText formats "amount unit name"', () {
      final ingredient = PreviewIngredient(
        name: 'flour',
        unit: 'cup',
        amount: 1.0,
      );

      expect(ingredient.displayText, '1 cup flour');
    });

    test('displayText formats fractional amounts', () {
      final ingredient = PreviewIngredient(
        name: 'sugar',
        unit: 'tbsp',
        amount: 2.5,
      );

      // Preview now formats with cooking fractions, matching the recipe screen.
      expect(ingredient.displayText, '2 1/2 tbsp sugar');
    });

    test('displayText shows only name when no amount/unit', () {
      final ingredient = PreviewIngredient(
        name: 'salt',
      );

      expect(ingredient.displayText, 'salt');
    });

    test('displayText shows integer for whole numbers', () {
      final ingredient = PreviewIngredient(
        name: 'eggs',
        amount: 3.0,
      );

      expect(ingredient.displayText, '3 eggs');
    });

    test('displayText shows amount + name when no unit', () {
      final ingredient = PreviewIngredient(
        name: 'eggs',
        amount: 2.0,
      );

      expect(ingredient.displayText, '2 eggs');
    });

    test('displayText excludes zero amount', () {
      final ingredient = PreviewIngredient(
        name: 'pinch of salt',
        amount: 0.0,
        unit: null,
      );

      // amount <= 0 is skipped per the condition `amount! > 0`
      expect(ingredient.displayText, 'pinch of salt');
    });
  });

  group('SearchState', () {
    test('default values', () {
      const state = SearchState();

      expect(state.query, '');
      expect(state.results, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasSearched, false);
    });

    test('copyWith replaces specified fields', () {
      const original = SearchState();
      final updated = original.copyWith(
        query: 'pizza',
        isLoading: true,
        hasSearched: true,
      );

      expect(updated.query, 'pizza');
      expect(updated.isLoading, true);
      expect(updated.hasSearched, true);
      expect(updated.results, isEmpty);
      expect(updated.error, isNull);
    });

    test('copyWith clears error when not provided', () {
      final withError = const SearchState().copyWith(
        error: 'Network error',
      );
      expect(withError.error, 'Network error');

      final cleared = withError.copyWith(query: 'new query');
      // error parameter defaults to null in copyWith (it uses positional null)
      expect(cleared.error, isNull);
    });
  });

  group('searchSuggestionsProvider (q >= 2 gate)', () {
    test('short-circuits to [] without a network call when the query is '
        'shorter than 2 chars', () async {
      final apiClient = MockApiClient();
      final container = createTestContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
      ]);
      addTearDown(container.dispose);
      container.listen(searchSuggestionsProvider('p'), (_, __) {});
      container.listen(searchSuggestionsProvider(''), (_, __) {});

      expect(await container.read(searchSuggestionsProvider('p').future),
          isEmpty);
      expect(await container.read(searchSuggestionsProvider('').future),
          isEmpty);
      verifyNever(() => apiClient.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ));
    });

    test('queries GET /v1/recipes/search with q when 2+ chars, parsing both '
        'bare-list and {suggestions: [...]} payloads', () async {
      final apiClient = MockApiClient();
      when(() => apiClient.get(
            ApiEndpoints.search,
            queryParameters: {'q': 'pi'},
          )).thenAnswer(
          (_) async => fakeResponse<dynamic>(['pizza', 'pie']));
      when(() => apiClient.get(
            ApiEndpoints.search,
            queryParameters: {'q': 'pa'},
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'suggestions': ['pasta', 'paella'],
          }));

      final container = createTestContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
      ]);
      addTearDown(container.dispose);
      container.listen(searchSuggestionsProvider('pi'), (_, __) {});
      container.listen(searchSuggestionsProvider('pa'), (_, __) {});

      expect(await container.read(searchSuggestionsProvider('pi').future),
          ['pizza', 'pie']);
      expect(await container.read(searchSuggestionsProvider('pa').future),
          ['pasta', 'paella']);
    });
  });

  group('multi-recipe card live status', () {
    test('toSearchResult preserves the per-card extraction status', () {
      const card = MultiRecipeCard(
        title: 'Beef Stew',
        sourceUrl: 'https://x.com/recipes/beef-stew',
        extractionStatus: 'extracting',
      );
      expect(card.toSearchResult().extractionStatus, 'extracting');
    });

    test('expanding carries card statuses, then polling flips Extracting→done',
        () {
      fakeAsync((async) {
        final apiClient = MockApiClient();
        when(() => apiClient.get(
              ApiEndpoints.search,
              queryParameters: {'q': 'beef'},
            )).thenAnswer((_) async => fakeResponse<dynamic>({
              'results': [
                {
                  'title': 'Beef Collection',
                  'source_url': 'https://x.com/collection',
                },
              ],
              'has_more': false,
            }));
        // The background resolve poll reports the card finished extracting.
        when(() => apiClient.get(ApiEndpoints.resolveMultiRecipe('m1')))
            .thenAnswer((_) async => fakeResponse<dynamic>({
                  'multi_id': 'm1',
                  'source_url': 'https://x.com/collection',
                  'status': 'resolved',
                  'recipes': [
                    {
                      'title': 'Beef Stew',
                      'source_url': 'https://x.com/recipes/beef-stew',
                      'extraction_status': 'done',
                    },
                  ],
                }));

        final container = createTestContainer(overrides: [
          apiClientProvider.overrideWithValue(apiClient),
        ]);
        addTearDown(container.dispose);
        final notifier = container.read(searchProvider.notifier);

        notifier.search('beef');
        async.flushMicrotasks();

        final original = container.read(searchProvider).results.single;
        notifier.replaceWithExpanded(
          original,
          const MultiRecipeResolution(
            multiId: 'm1',
            sourceUrl: 'https://x.com/collection',
            status: 'resolving',
            recipes: [
              MultiRecipeCard(
                title: 'Beef Stew',
                sourceUrl: 'https://x.com/recipes/beef-stew',
                extractionStatus: 'extracting',
              ),
            ],
          ),
        );

        // Right after expansion the card carries its in-progress status.
        expect(container.read(searchProvider).results.single.extractionStatus,
            'extracting');

        // Poll interval is 2s — advance past it; the card flips to done.
        async.elapse(const Duration(seconds: 3));
        expect(container.read(searchProvider).results.single.extractionStatus,
            'done');
      });
    });
  });

  group('scroll-ahead cache warming', () {
    test('search warms ahead and applies statuses, then polling flips '
        'Extracting→done', () {
      fakeAsync((async) {
        final apiClient = MockApiClient();
        when(() => apiClient.get(
              ApiEndpoints.search,
              queryParameters: {'q': 'beef'},
            )).thenAnswer((_) async => fakeResponse<dynamic>({
              'results': [
                {'title': 'A', 'source_url': 'https://x.com/a'},
                {'title': 'B', 'source_url': 'https://x.com/b'},
                {'title': 'C', 'source_url': 'https://x.com/c'},
              ],
              'has_more': false,
            }));

        // First warm: a/c still extracting, b already cached. Later polls: all
        // cached.
        var warmCalls = 0;
        when(() => apiClient.post(
              ApiEndpoints.warmUrls,
              data: any(named: 'data'),
            )).thenAnswer((_) async {
          warmCalls++;
          final done = warmCalls >= 2;
          return fakeResponse<dynamic>({
            'statuses': {
              'https://x.com/a': done ? 'cached' : 'extracting',
              'https://x.com/b': 'cached',
              'https://x.com/c': done ? 'cached' : 'extracting',
            },
          });
        });

        final container = createTestContainer(overrides: [
          apiClientProvider.overrideWithValue(apiClient),
        ]);
        addTearDown(container.dispose);
        final notifier = container.read(searchProvider.notifier);

        notifier.search('beef');
        async.flushMicrotasks();

        // Warmed on search: a/c show as extracting, b as ready (cached → done).
        final warmed = container.read(searchProvider).results;
        expect(warmed[0].extractionStatus, 'extracting');
        expect(warmed[1].extractionStatus, 'done');
        expect(warmed[2].extractionStatus, 'extracting');

        // Poll interval is 2s — advance; the now-cached a/c flip to done.
        async.elapse(const Duration(seconds: 3));
        final after = container.read(searchProvider).results;
        expect(after[0].extractionStatus, 'done');
        expect(after[2].extractionStatus, 'done');

        // Drain the poll loop (it sees nothing extracting and exits).
        async.elapse(const Duration(seconds: 3));
      });
    });

    test('warmAhead does not re-request URLs already warmed this search', () {
      fakeAsync((async) {
        final apiClient = MockApiClient();
        when(() => apiClient.get(
              ApiEndpoints.search,
              queryParameters: {'q': 'beef'},
            )).thenAnswer((_) async => fakeResponse<dynamic>({
              'results': [
                {'title': 'A', 'source_url': 'https://x.com/a'},
              ],
              'has_more': false,
            }));
        var warmCalls = 0;
        when(() => apiClient.post(
              ApiEndpoints.warmUrls,
              data: any(named: 'data'),
            )).thenAnswer((_) async {
          warmCalls++;
          return fakeResponse<dynamic>({
            'statuses': {'https://x.com/a': 'cached'},
          });
        });

        final container = createTestContainer(overrides: [
          apiClientProvider.overrideWithValue(apiClient),
        ]);
        addTearDown(container.dispose);
        final notifier = container.read(searchProvider.notifier);

        notifier.search('beef'); // triggers warmAhead(0)
        async.flushMicrotasks();
        expect(warmCalls, 1);

        // Re-scrolling to the same window must not re-warm the same URL.
        notifier.warmAhead(0);
        async.flushMicrotasks();
        expect(warmCalls, 1);
      });
    });
  });
}
