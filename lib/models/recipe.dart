import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required String title,
    required String ownerId,
    String? imageUrl,
    @Default([]) List<Ingredient> ingredients,
    @Default([]) List<String> instructions,
    @Default([]) List<String> tags,
    int? cookTimeMinutes,
    String? sourceUrl,
    @Default('us_customary') String unitSystem,
    @Default('ready') String status,
    int? portions,
    String? portionSize,
    String? parentRecipeId,
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
    @JsonKey(name: 'amount') double? amount,
    String? unit,
    @JsonKey(name: 'metric_unit') String? metricUnit,
    @JsonKey(name: 'metric_amount') double? metricAmount,
    @JsonKey(name: 'original_text') String? originalText,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}

@freezed
class RecipeNode with _$RecipeNode {
  const factory RecipeNode({
    required int id,
    @JsonKey(name: 'parent_id') int? parentId,
    @JsonKey(name: 'branch_name') @Default('original') String branchName,
    @Default('') String summary,
    @Default('') String type,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'is_ephemeral') @Default(false) bool isEphemeral,
    @JsonKey(name: 'created_by_id') int? createdById,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @Default([]) List<RecipeNode> children,
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
