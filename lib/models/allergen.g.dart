// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AllergenAnalysisImpl _$$AllergenAnalysisImplFromJson(
        Map<String, dynamic> json) =>
    _$AllergenAnalysisImpl(
      recipeId: json['recipe_id'] == null ? '' : _idToString(json['recipe_id']),
      ingredientAnalyses: (json['ingredient_analyses'] as List<dynamic>?)
              ?.map(
                  (e) => IngredientAnalysis.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      containsNuts: json['contains_nuts'] as bool? ?? false,
      containsDairy: json['contains_dairy'] as bool? ?? false,
      containsGluten: json['contains_gluten'] as bool? ?? false,
      containsSoy: json['contains_soy'] as bool? ?? false,
      containsSeedOils: json['contains_seed_oils'] as bool? ?? false,
      containsShellfish: json['contains_shellfish'] as bool? ?? false,
      containsEggs: json['contains_eggs'] as bool? ?? false,
      safeForProfiles: json['safe_for_profiles'] == null
          ? const []
          : _idListToStrings(json['safe_for_profiles']),
      unsafeForProfiles: json['unsafe_for_profiles'] == null
          ? const []
          : _idListToStrings(json['unsafe_for_profiles']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      requiresReview: json['requires_review'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      promptVersion: json['prompt_version'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ?? '',
      analyzedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$AllergenAnalysisImplToJson(
        _$AllergenAnalysisImpl instance) =>
    <String, dynamic>{
      'recipe_id': instance.recipeId,
      'ingredient_analyses': instance.ingredientAnalyses,
      'contains_nuts': instance.containsNuts,
      'contains_dairy': instance.containsDairy,
      'contains_gluten': instance.containsGluten,
      'contains_soy': instance.containsSoy,
      'contains_seed_oils': instance.containsSeedOils,
      'contains_shellfish': instance.containsShellfish,
      'contains_eggs': instance.containsEggs,
      'safe_for_profiles': instance.safeForProfiles,
      'unsafe_for_profiles': instance.unsafeForProfiles,
      'confidence': instance.confidence,
      'requires_review': instance.requiresReview,
      'is_premium': instance.isPremium,
      'prompt_version': instance.promptVersion,
      'disclaimer': instance.disclaimer,
      'updated_at': instance.analyzedAt?.toIso8601String(),
    };

_$IngredientAnalysisImpl _$$IngredientAnalysisImplFromJson(
        Map<String, dynamic> json) =>
    _$IngredientAnalysisImpl(
      ingredientName: json['ingredient_name'] as String? ?? '',
      commonAllergens: (json['common_allergens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      possibleAllergens: (json['possible_allergens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      subIngredients: (json['sub_ingredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      seedOilRisk: json['seed_oil_risk'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$IngredientAnalysisImplToJson(
        _$IngredientAnalysisImpl instance) =>
    <String, dynamic>{
      'ingredient_name': instance.ingredientName,
      'common_allergens': instance.commonAllergens,
      'possible_allergens': instance.possibleAllergens,
      'sub_ingredients': instance.subIngredients,
      'seed_oil_risk': instance.seedOilRisk,
      'confidence': instance.confidence,
    };

_$FamilySafetyCheckImpl _$$FamilySafetyCheckImplFromJson(
        Map<String, dynamic> json) =>
    _$FamilySafetyCheckImpl(
      memberId: json['member_id'] == null ? '' : _idToString(json['member_id']),
      memberName: json['member_name'] as String? ?? '',
      status: json['status'] as String? ?? 'safe',
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$FamilySafetyCheckImplToJson(
        _$FamilySafetyCheckImpl instance) =>
    <String, dynamic>{
      'member_id': instance.memberId,
      'member_name': instance.memberName,
      'status': instance.status,
      'warnings': instance.warnings,
    };
