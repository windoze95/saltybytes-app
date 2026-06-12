import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:saltybytes_app/models/recipe.dart';

import '../helpers/fixtures.dart';

void main() {
  group('Recipe', () {
    test('fromJson with all fields populated', () {
      final json = testRecipeJson();
      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 'recipe-abc-123');
      expect(recipe.title, 'Classic Margherita Pizza');
      expect(recipe.ownerId, 'user-xyz-456');
      expect(recipe.imageUrl, 'https://cdn.saltybytes.ai/images/pizza.jpg');
      expect(recipe.ingredients, hasLength(3));
      expect(recipe.instructions, hasLength(4));
      expect(recipe.tags, ['pizza', 'italian', 'vegetarian']);
      expect(recipe.cookTimeMinutes, 15);
      expect(recipe.sourceUrl, isNull);
      expect(recipe.unitSystem, 'us_customary');
      expect(recipe.status, 'ready');
      expect(recipe.portions, 4);
      expect(recipe.portionSize, '2 slices');
      expect(recipe.parentRecipeId, isNull);
      expect(recipe.createdAt, isA<DateTime>());
      expect(recipe.updatedAt, isA<DateTime>());
    });

    test('fromJson with minimal/required fields only', () {
      final json = <String, dynamic>{
        'id': 'r-1',
        'title': 'Test',
        'ownerId': 'u-1',
      };
      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 'r-1');
      expect(recipe.title, 'Test');
      expect(recipe.ownerId, 'u-1');
      // Defaults
      expect(recipe.ingredients, isEmpty);
      expect(recipe.instructions, isEmpty);
      expect(recipe.tags, isEmpty);
      expect(recipe.unitSystem, 'us_customary');
      expect(recipe.status, 'ready');
      // Nullable fields
      expect(recipe.imageUrl, isNull);
      expect(recipe.cookTimeMinutes, isNull);
      expect(recipe.sourceUrl, isNull);
      expect(recipe.parentRecipeId, isNull);
      expect(recipe.portions, isNull);
      expect(recipe.portionSize, isNull);
      expect(recipe.createdAt, isNull);
      expect(recipe.updatedAt, isNull);
    });

    test('toJson round-trip preserves data', () {
      final original = Recipe.fromJson(testRecipeJson());
      final jsonString = jsonEncode(original.toJson());
      final roundTripped =
          Recipe.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped.id, original.id);
      expect(roundTripped.title, original.title);
      expect(roundTripped.ownerId, original.ownerId);
      expect(roundTripped.imageUrl, original.imageUrl);
      expect(roundTripped.ingredients.length, original.ingredients.length);
      expect(roundTripped.instructions, original.instructions);
      expect(roundTripped.tags, original.tags);
      expect(roundTripped.cookTimeMinutes, original.cookTimeMinutes);
      expect(roundTripped.unitSystem, original.unitSystem);
      expect(roundTripped.status, original.status);
      expect(roundTripped.portions, original.portions);
      expect(roundTripped.portionSize, original.portionSize);
    });

    test('toJson serialises DateTime fields as ISO-8601 strings', () {
      final recipe = Recipe.fromJson(testRecipeJson());
      final json = recipe.toJson();

      expect(json['createdAt'], isA<String>());
      expect(json['updatedAt'], isA<String>());
      expect(DateTime.parse(json['createdAt'] as String), recipe.createdAt);
    });

    test('fromJson coerces empty imageUrl string to null', () {
      final recipe = Recipe.fromJson(testRecipeJson(imageUrl: ''));

      expect(recipe.imageUrl, isNull);
    });

    test('fromJson keeps non-empty imageUrl', () {
      final recipe = Recipe.fromJson(
          testRecipeJson(imageUrl: 'https://cdn.example.com/a.jpg'));

      expect(recipe.imageUrl, 'https://cdn.example.com/a.jpg');
    });

    test('fromJson normalizes numeric ids to strings', () {
      final json = testRecipeJson();
      json['id'] = 42;
      json['ownerId'] = 7;
      json['parentRecipeId'] = 41;

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, '42');
      expect(recipe.ownerId, '7');
      expect(recipe.parentRecipeId, '41');
    });

    test('fromJson keeps string ids untouched', () {
      final recipe = Recipe.fromJson(
          testRecipeJson(id: 'recipe-1', ownerId: 'user-1'));

      expect(recipe.id, 'recipe-1');
      expect(recipe.ownerId, 'user-1');
      expect(recipe.parentRecipeId, isNull);
    });
  });

  group('Ingredient', () {
    test('fromJson with all fields', () {
      final json = testIngredientJson(
        name: 'butter',
        amount: 2.0,
        unit: 'tbsp',
        originalText: '2 tbsp unsalted butter',
      );
      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, 'butter');
      expect(ingredient.amount, 2.0);
      expect(ingredient.unit, 'tbsp');
      expect(ingredient.originalText, '2 tbsp unsalted butter');
    });

    test('fromJson with minimal fields', () {
      final json = <String, dynamic>{'name': 'salt'};
      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, 'salt');
      expect(ingredient.amount, isNull);
      expect(ingredient.unit, isNull);
      expect(ingredient.originalText, isNull);
    });

    test('toJson round-trip', () {
      final original = Ingredient.fromJson(testIngredientJson());
      final jsonString = jsonEncode(original.toJson());
      final roundTripped =
          Ingredient.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped.name, original.name);
      expect(roundTripped.amount, original.amount);
      expect(roundTripped.unit, original.unit);
    });
  });

  group('RecipeNode', () {
    test('fromJson with children', () {
      final json = testRecipeNodeJson(
        id: 1,
        branchName: 'original',
        summary: 'Initial recipe',
        type: 'chat',
        isActive: true,
        children: [
          testRecipeNodeJson(
            id: 2,
            parentId: 1,
            branchName: 'original',
            summary: 'Added jalapeños',
            type: 'regen_chat',
            isActive: false,
          ),
          testRecipeNodeJson(
            id: 3,
            parentId: 1,
            branchName: 'vegan-fork',
            summary: 'Made vegan',
            type: 'fork',
            isActive: false,
          ),
        ],
      );
      final node = RecipeNode.fromJson(json);

      expect(node.id, 1);
      expect(node.branchName, 'original');
      expect(node.isActive, true);
      expect(node.children, hasLength(2));
      expect(node.children[0].id, 2);
      expect(node.children[0].parentId, 1);
      expect(node.children[0].summary, 'Added jalapeños');
      expect(node.children[1].branchName, 'vegan-fork');
      expect(node.children[1].type, 'fork');
    });

    test('fromJson with no children defaults to empty list', () {
      final json = <String, dynamic>{
        'id': 1,
        'branch_name': 'original',
      };
      final node = RecipeNode.fromJson(json);

      expect(node.children, isEmpty);
      expect(node.parentId, isNull);
      expect(node.isActive, false);
    });
  });

  group('RecipeSearchResult', () {
    test('fromJson parses list of recipes', () {
      final json = <String, dynamic>{
        'recipes': [
          testRecipeJson(id: 'r-1', title: 'Pizza'),
          testRecipeJson(id: 'r-2', title: 'Pasta'),
        ],
        'total': 42,
        'page': 1,
        'pageSize': 20,
      };
      final result = RecipeSearchResult.fromJson(json);

      expect(result.recipes, hasLength(2));
      expect(result.recipes[0].id, 'r-1');
      expect(result.recipes[1].title, 'Pasta');
      expect(result.total, 42);
      expect(result.page, 1);
      expect(result.pageSize, 20);
    });
  });
}
