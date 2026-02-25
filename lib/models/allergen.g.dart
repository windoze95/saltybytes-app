// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AllergenAnalysisImpl _$$AllergenAnalysisImplFromJson(
        Map<String, dynamic> json) =>
    _$AllergenAnalysisImpl(
      recipeId: json['recipeId'] as String,
      detectedAllergens: (json['detectedAllergens'] as List<dynamic>?)
              ?.map((e) => AllergenInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      possibleAllergens: (json['possibleAllergens'] as List<dynamic>?)
              ?.map((e) => AllergenInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      familySafetyChecks: (json['familySafetyChecks'] as List<dynamic>?)
              ?.map(
                  (e) => FamilySafetyCheck.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isSafeForAll: json['isSafeForAll'] as bool? ?? false,
      analyzedAt: json['analyzedAt'] == null
          ? null
          : DateTime.parse(json['analyzedAt'] as String),
    );

Map<String, dynamic> _$$AllergenAnalysisImplToJson(
        _$AllergenAnalysisImpl instance) =>
    <String, dynamic>{
      'recipeId': instance.recipeId,
      'detectedAllergens': instance.detectedAllergens,
      'possibleAllergens': instance.possibleAllergens,
      'familySafetyChecks': instance.familySafetyChecks,
      'isSafeForAll': instance.isSafeForAll,
      'analyzedAt': instance.analyzedAt?.toIso8601String(),
    };

_$AllergenInfoImpl _$$AllergenInfoImplFromJson(Map<String, dynamic> json) =>
    _$AllergenInfoImpl(
      allergen: json['allergen'] as String,
      severity: json['severity'] as String,
      source: json['source'] as String,
      ingredient: json['ingredient'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$AllergenInfoImplToJson(_$AllergenInfoImpl instance) =>
    <String, dynamic>{
      'allergen': instance.allergen,
      'severity': instance.severity,
      'source': instance.source,
      'ingredient': instance.ingredient,
      'notes': instance.notes,
    };

_$FamilySafetyCheckImpl _$$FamilySafetyCheckImplFromJson(
        Map<String, dynamic> json) =>
    _$FamilySafetyCheckImpl(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      isSafe: json['isSafe'] as bool,
      conflicts: (json['conflicts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$FamilySafetyCheckImplToJson(
        _$FamilySafetyCheckImpl instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'memberName': instance.memberName,
      'isSafe': instance.isSafe,
      'conflicts': instance.conflicts,
      'warnings': instance.warnings,
    };
