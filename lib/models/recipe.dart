import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required String title,
    String? description,
    required String ownerId,
    String? imageUrl,
    @Default([]) List<Ingredient> ingredients,
    @Default([]) List<String> instructions,
    @Default([]) List<String> tags,
    String? cuisine,
    String? difficulty,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    @Default(4) int servings,
    String? sourceUrl,
    @Default(false) bool isPublic,
    @Default([]) List<String> allergenTags,
    @Default('main') String currentBranch,
    String? parentRecipeId,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) =>
      _$RecipeFromJson(json);
}

@freezed
class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String name,
    String? quantity,
    String? unit,
    String? notes,
    @Default(false) bool optional,
    String? category,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}

@freezed
class RecipeDef with _$RecipeDef {
  const factory RecipeDef({
    required String id,
    required String recipeId,
    required String branch,
    required int version,
    required String title,
    String? description,
    @Default([]) List<Ingredient> ingredients,
    @Default([]) List<String> instructions,
    String? commitMessage,
    String? authorId,
    DateTime? createdAt,
  }) = _RecipeDef;

  factory RecipeDef.fromJson(Map<String, dynamic> json) =>
      _$RecipeDefFromJson(json);
}

@freezed
class RecipeNode with _$RecipeNode {
  const factory RecipeNode({
    required String branch,
    required int version,
    String? parentBranch,
    int? parentVersion,
    @Default([]) List<RecipeNode> children,
    String? commitMessage,
    DateTime? createdAt,
  }) = _RecipeNode;

  factory RecipeNode.fromJson(Map<String, dynamic> json) =>
      _$RecipeNodeFromJson(json);
}

@freezed
class RecipeSearchResult with _$RecipeSearchResult {
  const factory RecipeSearchResult({
    required List<Recipe> recipes,
    required int total,
    required int page,
    required int pageSize,
  }) = _RecipeSearchResult;

  factory RecipeSearchResult.fromJson(Map<String, dynamic> json) =>
      _$RecipeSearchResultFromJson(json);
}
