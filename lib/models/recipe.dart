// @JsonKey on freezed constructor parameters is the documented freezed
// pattern; the analyzer flags it as invalid_annotation_target regardless.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

/// Normalizes IDs that may arrive as int or String from the API.
String _idToString(dynamic value) => value?.toString() ?? '';

/// Normalizes nullable IDs that may arrive as int or String from the API.
String? _idToStringOrNull(dynamic value) => value?.toString();

/// The API sends `""` for unset image URLs; coerce empty strings to null so
/// render sites don't feed an empty URL into image widgets.
String? _emptyStringToNull(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}

@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    @JsonKey(fromJson: _idToString) required String id,
    required String title,
    @JsonKey(fromJson: _idToString) required String ownerId,
    @JsonKey(fromJson: _emptyStringToNull) String? imageUrl,
    @Default([]) List<Ingredient> ingredients,
    @Default([]) List<String> instructions,
    @Default([]) List<String> tags,
    int? cookTimeMinutes,
    String? sourceUrl,
    @Default('us_customary') String unitSystem,
    @Default('ready') String status,
    int? portions,
    String? portionSize,
    @JsonKey(fromJson: _idToStringOrNull) String? parentRecipeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
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
    @JsonKey(name: 'measure_kind') String? measureKind,
    @JsonKey(name: 'base_amount') double? baseAmount,
    @JsonKey(name: 'amount_high') double? amountHigh,
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
