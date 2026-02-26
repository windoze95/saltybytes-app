import 'package:flutter_test/flutter_test.dart';

import 'package:saltybytes_app/models/recipe.dart';

import '../helpers/fixtures.dart';

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
