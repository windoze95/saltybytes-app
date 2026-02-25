import 'package:freezed_annotation/freezed_annotation.dart';

part 'allergen.freezed.dart';
part 'allergen.g.dart';

@freezed
class AllergenAnalysis with _$AllergenAnalysis {
  const factory AllergenAnalysis({
    required String recipeId,
    @Default([]) List<AllergenInfo> detectedAllergens,
    @Default([]) List<AllergenInfo> possibleAllergens,
    @Default([]) List<FamilySafetyCheck> familySafetyChecks,
    @Default(false) bool isSafeForAll,
    DateTime? analyzedAt,
  }) = _AllergenAnalysis;

  factory AllergenAnalysis.fromJson(Map<String, dynamic> json) =>
      _$AllergenAnalysisFromJson(json);
}

@freezed
class AllergenInfo with _$AllergenInfo {
  const factory AllergenInfo({
    required String allergen,
    required String severity,
    required String source,
    String? ingredient,
    String? notes,
  }) = _AllergenInfo;

  factory AllergenInfo.fromJson(Map<String, dynamic> json) =>
      _$AllergenInfoFromJson(json);
}

@freezed
class FamilySafetyCheck with _$FamilySafetyCheck {
  const factory FamilySafetyCheck({
    required String memberId,
    required String memberName,
    required bool isSafe,
    @Default([]) List<String> conflicts,
    @Default([]) List<String> warnings,
  }) = _FamilySafetyCheck;

  factory FamilySafetyCheck.fromJson(Map<String, dynamic> json) =>
      _$FamilySafetyCheckFromJson(json);
}
