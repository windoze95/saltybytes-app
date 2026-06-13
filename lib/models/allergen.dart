// @JsonKey on freezed constructor parameters is the documented freezed
// pattern; the analyzer flags it as invalid_annotation_target regardless.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'allergen.freezed.dart';
part 'allergen.g.dart';

/// Normalizes IDs that may arrive as int or String from the API.
String _idToString(dynamic value) => value?.toString() ?? '';

/// Normalizes a list of IDs (ints or Strings) into Strings.
List<String> _idListToStrings(dynamic value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  return const [];
}

/// Allergen analysis result for a recipe.
///
/// Mirrors the backend `AllergenAnalysisResponse` (an embedded
/// `models.AllergenAnalysis` plus a `disclaimer`), which serializes with
/// snake_case keys and arrives wrapped in an `{"analysis": ...}` envelope.
@freezed
class AllergenAnalysis with _$AllergenAnalysis {
  const AllergenAnalysis._();

  const factory AllergenAnalysis({
    @JsonKey(name: 'recipe_id', fromJson: _idToString)
    @Default('')
    String recipeId,
    @JsonKey(name: 'ingredient_analyses')
    @Default([])
    List<IngredientAnalysis> ingredientAnalyses,
    @JsonKey(name: 'contains_nuts') @Default(false) bool containsNuts,
    @JsonKey(name: 'contains_dairy') @Default(false) bool containsDairy,
    @JsonKey(name: 'contains_gluten') @Default(false) bool containsGluten,
    @JsonKey(name: 'contains_soy') @Default(false) bool containsSoy,
    @JsonKey(name: 'contains_seed_oils') @Default(false) bool containsSeedOils,
    @JsonKey(name: 'contains_shellfish')
    @Default(false)
    bool containsShellfish,
    @JsonKey(name: 'contains_eggs') @Default(false) bool containsEggs,
    @JsonKey(name: 'safe_for_profiles', fromJson: _idListToStrings)
    @Default([])
    List<String> safeForProfiles,
    @JsonKey(name: 'unsafe_for_profiles', fromJson: _idListToStrings)
    @Default([])
    List<String> unsafeForProfiles,
    @Default(0.0) double confidence,
    @JsonKey(name: 'requires_review') @Default(false) bool requiresReview,
    @JsonKey(name: 'is_premium') @Default(false) bool isPremium,
    @JsonKey(name: 'prompt_version') @Default('') String promptVersion,
    @Default('') String disclaimer,
    @JsonKey(name: 'updated_at') DateTime? analyzedAt,
  }) = _AllergenAnalysis;

  factory AllergenAnalysis.fromJson(Map<String, dynamic> json) =>
      _$AllergenAnalysisFromJson(json);

  /// Human-readable labels for the `contains_*` flags that are set.
  List<String> get detectedAllergens => [
        if (containsNuts) 'Nuts',
        if (containsDairy) 'Dairy',
        if (containsGluten) 'Gluten',
        if (containsSoy) 'Soy',
        if (containsSeedOils) 'Seed Oils',
        if (containsShellfish) 'Shellfish',
        if (containsEggs) 'Eggs',
      ];

  /// Whether any major allergen flag is set.
  bool get hasDetectedAllergens => detectedAllergens.isNotEmpty;

  /// Whether the recipe is flagged unsafe for any family member.
  bool get hasUnsafeMembers => unsafeForProfiles.isNotEmpty;
}

/// Per-ingredient allergen breakdown (backend `IngredientAnalysis`).
@freezed
class IngredientAnalysis with _$IngredientAnalysis {
  const factory IngredientAnalysis({
    @JsonKey(name: 'ingredient_name') @Default('') String ingredientName,
    @JsonKey(name: 'common_allergens')
    @Default([])
    List<String> commonAllergens,
    @JsonKey(name: 'possible_allergens')
    @Default([])
    List<String> possibleAllergens,
    @JsonKey(name: 'sub_ingredients') @Default([]) List<String> subIngredients,
    @JsonKey(name: 'seed_oil_risk') @Default(false) bool seedOilRisk,
    @Default(0.0) double confidence,
  }) = _IngredientAnalysis;

  factory IngredientAnalysis.fromJson(Map<String, dynamic> json) =>
      _$IngredientAnalysisFromJson(json);
}

/// Per-member safety result (backend `MemberAllergenResult` from the
/// check-family endpoint; also used for web search result safety badges).
@freezed
class FamilySafetyCheck with _$FamilySafetyCheck {
  const FamilySafetyCheck._();

  const factory FamilySafetyCheck({
    @JsonKey(name: 'member_id', fromJson: _idToString)
    @Default('')
    String memberId,
    @JsonKey(name: 'member_name') @Default('') String memberName,
    @Default('safe') String status,
    @Default([]) List<String> warnings,
  }) = _FamilySafetyCheck;

  factory FamilySafetyCheck.fromJson(Map<String, dynamic> json) =>
      _$FamilySafetyCheckFromJson(json);

  bool get isSafe => status == 'safe';
}
