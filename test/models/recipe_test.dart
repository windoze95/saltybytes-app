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
      expect(recipe.description, 'A simple Italian pizza with fresh tomatoes and mozzarella');
      expect(recipe.ownerId, 'user-xyz-456');
      expect(recipe.imageUrl, 'https://cdn.saltybytes.ai/images/pizza.jpg');
      expect(recipe.ingredients, hasLength(3));
      expect(recipe.instructions, hasLength(4));
      expect(recipe.tags, ['pizza', 'italian', 'vegetarian']);
      expect(recipe.cuisine, 'Italian');
      expect(recipe.difficulty, 'medium');
      expect(recipe.prepTimeMinutes, 30);
      expect(recipe.cookTimeMinutes, 15);
      expect(recipe.servings, 4);
      expect(recipe.sourceUrl, isNull);
      expect(recipe.isPublic, false);
      expect(recipe.allergenTags, ['gluten', 'dairy']);
      expect(recipe.currentBranch, 'main');
      expect(recipe.parentRecipeId, isNull);
      expect(recipe.version, 1);
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
      expect(recipe.servings, 4);
      expect(recipe.isPublic, false);
      expect(recipe.allergenTags, isEmpty);
      expect(recipe.currentBranch, 'main');
      // Nullable fields
      expect(recipe.description, isNull);
      expect(recipe.imageUrl, isNull);
      expect(recipe.cuisine, isNull);
      expect(recipe.difficulty, isNull);
      expect(recipe.prepTimeMinutes, isNull);
      expect(recipe.cookTimeMinutes, isNull);
      expect(recipe.sourceUrl, isNull);
      expect(recipe.parentRecipeId, isNull);
      expect(recipe.version, isNull);
      expect(recipe.createdAt, isNull);
      expect(recipe.updatedAt, isNull);
    });

    test('fromJson with null optional fields does not crash', () {
      final json = <String, dynamic>{
        'id': 'r-1',
        'title': 'Minimal',
        'ownerId': 'u-1',
        'description': null,
        'imageUrl': null,
        'ingredients': null,
        'instructions': null,
        'tags': null,
        'cuisine': null,
        'difficulty': null,
        'prepTimeMinutes': null,
        'cookTimeMinutes': null,
        'sourceUrl': null,
        'allergenTags': null,
        'parentRecipeId': null,
        'version': null,
        'createdAt': null,
        'updatedAt': null,
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 'r-1');
      expect(recipe.ingredients, isEmpty);
      expect(recipe.instructions, isEmpty);
      expect(recipe.tags, isEmpty);
      expect(recipe.allergenTags, isEmpty);
    });

    test('toJson round-trip preserves data', () {
      final original = Recipe.fromJson(testRecipeJson());
      // Encode through JSON string to get pure Maps (not freezed impl types)
      final jsonString = jsonEncode(original.toJson());
      final roundTripped = Recipe.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped.id, original.id);
      expect(roundTripped.title, original.title);
      expect(roundTripped.description, original.description);
      expect(roundTripped.ownerId, original.ownerId);
      expect(roundTripped.imageUrl, original.imageUrl);
      expect(roundTripped.ingredients.length, original.ingredients.length);
      expect(roundTripped.instructions, original.instructions);
      expect(roundTripped.tags, original.tags);
      expect(roundTripped.cuisine, original.cuisine);
      expect(roundTripped.difficulty, original.difficulty);
      expect(roundTripped.prepTimeMinutes, original.prepTimeMinutes);
      expect(roundTripped.cookTimeMinutes, original.cookTimeMinutes);
      expect(roundTripped.servings, original.servings);
      expect(roundTripped.isPublic, original.isPublic);
      expect(roundTripped.allergenTags, original.allergenTags);
      expect(roundTripped.currentBranch, original.currentBranch);
      expect(roundTripped.version, original.version);
    });

    test('toJson serialises DateTime fields as ISO-8601 strings', () {
      final recipe = Recipe.fromJson(testRecipeJson());
      final json = recipe.toJson();

      expect(json['createdAt'], isA<String>());
      expect(json['updatedAt'], isA<String>());
      expect(DateTime.parse(json['createdAt'] as String), recipe.createdAt);
    });
  });

  group('Ingredient', () {
    test('fromJson with all fields', () {
      final json = testIngredientJson(
        name: 'butter',
        quantity: '2',
        unit: 'tbsp',
        notes: 'unsalted',
        optional: true,
        category: 'dairy',
      );
      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, 'butter');
      expect(ingredient.quantity, '2');
      expect(ingredient.unit, 'tbsp');
      expect(ingredient.notes, 'unsalted');
      expect(ingredient.optional, true);
      expect(ingredient.category, 'dairy');
    });

    test('fromJson with minimal fields uses defaults', () {
      final json = <String, dynamic>{'name': 'salt'};
      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, 'salt');
      expect(ingredient.quantity, isNull);
      expect(ingredient.unit, isNull);
      expect(ingredient.notes, isNull);
      expect(ingredient.optional, false);
      expect(ingredient.category, isNull);
    });

    test('toJson round-trip', () {
      final original = Ingredient.fromJson(testIngredientJson());
      final jsonString = jsonEncode(original.toJson());
      final roundTripped = Ingredient.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped.name, original.name);
      expect(roundTripped.quantity, original.quantity);
      expect(roundTripped.unit, original.unit);
      expect(roundTripped.optional, original.optional);
      expect(roundTripped.category, original.category);
    });
  });

  group('RecipeNode', () {
    test('fromJson with children', () {
      final json = testRecipeNodeJson(
        branch: 'main',
        version: 1,
        children: [
          testRecipeNodeJson(
            branch: 'spicy-fork',
            version: 2,
            parentBranch: 'main',
            parentVersion: 1,
            commitMessage: 'Added jalapeños',
          ),
          testRecipeNodeJson(
            branch: 'vegan-fork',
            version: 2,
            parentBranch: 'main',
            parentVersion: 1,
            commitMessage: 'Made vegan with cashew mozzarella',
          ),
        ],
      );
      final node = RecipeNode.fromJson(json);

      expect(node.branch, 'main');
      expect(node.version, 1);
      expect(node.parentBranch, isNull);
      expect(node.children, hasLength(2));
      expect(node.children[0].branch, 'spicy-fork');
      expect(node.children[0].parentBranch, 'main');
      expect(node.children[0].parentVersion, 1);
      expect(node.children[1].branch, 'vegan-fork');
      expect(node.children[1].commitMessage, 'Made vegan with cashew mozzarella');
    });

    test('fromJson with no children defaults to empty list', () {
      final json = <String, dynamic>{
        'branch': 'main',
        'version': 1,
      };
      final node = RecipeNode.fromJson(json);

      expect(node.children, isEmpty);
      expect(node.parentBranch, isNull);
      expect(node.parentVersion, isNull);
      expect(node.commitMessage, isNull);
    });
  });

  group('RecipeDef', () {
    test('fromJson with all fields', () {
      final json = testRecipeDefJson();
      final def = RecipeDef.fromJson(json);

      expect(def.id, 'def-001');
      expect(def.recipeId, 'recipe-abc-123');
      expect(def.branch, 'main');
      expect(def.version, 1);
      expect(def.title, 'Classic Margherita Pizza');
      expect(def.description, 'A simple Italian pizza');
      expect(def.ingredients, hasLength(1));
      expect(def.instructions, hasLength(2));
      expect(def.commitMessage, 'Initial version');
      expect(def.authorId, 'user-xyz-456');
      expect(def.createdAt, isA<DateTime>());
    });

    test('fromJson round-trip', () {
      final original = RecipeDef.fromJson(testRecipeDefJson());
      final jsonString = jsonEncode(original.toJson());
      final roundTripped = RecipeDef.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped.id, original.id);
      expect(roundTripped.recipeId, original.recipeId);
      expect(roundTripped.branch, original.branch);
      expect(roundTripped.version, original.version);
      expect(roundTripped.title, original.title);
      expect(roundTripped.commitMessage, original.commitMessage);
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
