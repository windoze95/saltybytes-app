import 'package:freezed_annotation/freezed_annotation.dart';

part 'family.freezed.dart';
part 'family.g.dart';

@freezed
class Family with _$Family {
  const factory Family({
    required String id,
    required String name,
    required String ownerId,
    String? description,
    @Default([]) List<FamilyMember> members,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Family;

  factory Family.fromJson(Map<String, dynamic> json) =>
      _$FamilyFromJson(json);
}

@freezed
class FamilyMember with _$FamilyMember {
  const factory FamilyMember({
    required String id,
    required String name,
    String? userId,
    @Default('member') String role,
    @Default(DietaryProfile()) DietaryProfile dietaryProfile,
    DateTime? createdAt,
  }) = _FamilyMember;

  factory FamilyMember.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberFromJson(json);
}

@freezed
class DietaryProfile with _$DietaryProfile {
  const factory DietaryProfile({
    @Default([]) List<String> allergies,
    @Default([]) List<String> intolerances,
    @Default([]) List<String> dietaryRestrictions,
    @Default([]) List<String> dislikedIngredients,
    String? notes,
  }) = _DietaryProfile;

  factory DietaryProfile.fromJson(Map<String, dynamic> json) =>
      _$DietaryProfileFromJson(json);
}
