// @JsonKey on freezed constructor parameters is the documented freezed
// pattern; the analyzer flags it as invalid_annotation_target regardless.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'family.freezed.dart';
part 'family.g.dart';

/// Normalizes IDs that may arrive as int or String from the API.
String _idToString(dynamic value) => value?.toString() ?? '';

/// Normalizes nullable IDs that may arrive as int or String from the API.
String? _idToStringOrNull(dynamic value) => value?.toString();

/// The backend sends `"dietary_profile": null` for members without a
/// profile; coerce that to an empty profile so the UI can render defaults.
DietaryProfile _profileFromJson(dynamic value) {
  if (value is Map<String, dynamic>) return DietaryProfile.fromJson(value);
  return const DietaryProfile();
}

@freezed
class Family with _$Family {
  const factory Family({
    @JsonKey(fromJson: _idToString) required String id,
    required String name,
    @JsonKey(name: 'owner_id', fromJson: _idToString)
    @Default('')
    String ownerId,
    @Default([]) List<FamilyMember> members,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Family;

  factory Family.fromJson(Map<String, dynamic> json) =>
      _$FamilyFromJson(json);
}

@freezed
class FamilyMember with _$FamilyMember {
  const factory FamilyMember({
    @JsonKey(fromJson: _idToString) required String id,
    required String name,
    @JsonKey(name: 'family_id', fromJson: _idToStringOrNull) String? familyId,
    @JsonKey(name: 'user_id', fromJson: _idToStringOrNull) String? userId,
    @Default('') String relationship,
    @JsonKey(name: 'dietary_profile', fromJson: _profileFromJson)
    @Default(DietaryProfile())
    DietaryProfile dietaryProfile,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _FamilyMember;

  factory FamilyMember.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberFromJson(json);
}

@freezed
class DietaryProfile with _$DietaryProfile {
  const factory DietaryProfile({
    @Default([]) List<Allergy> allergies,
    @Default([]) List<String> intolerances,
    @Default([]) List<String> restrictions,
    @Default([]) List<String> preferences,
    @JsonKey(name: 'medical_notes') String? medicalNotes,
  }) = _DietaryProfile;

  factory DietaryProfile.fromJson(Map<String, dynamic> json) =>
      _$DietaryProfileFromJson(json);
}

@freezed
class Allergy with _$Allergy {
  const factory Allergy({
    required String name,
    @Default('') String severity,
    @JsonKey(name: 'sub_forms') @Default([]) List<String> subForms,
    @Default('') String notes,
  }) = _Allergy;

  factory Allergy.fromJson(Map<String, dynamic> json) =>
      _$AllergyFromJson(json);
}
