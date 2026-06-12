// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyImpl _$$FamilyImplFromJson(Map<String, dynamic> json) => _$FamilyImpl(
      id: _idToString(json['id']),
      name: json['name'] as String,
      ownerId: json['owner_id'] == null ? '' : _idToString(json['owner_id']),
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$FamilyImplToJson(_$FamilyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'owner_id': instance.ownerId,
      'members': instance.members,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

_$FamilyMemberImpl _$$FamilyMemberImplFromJson(Map<String, dynamic> json) =>
    _$FamilyMemberImpl(
      id: _idToString(json['id']),
      name: json['name'] as String,
      familyId: _idToStringOrNull(json['family_id']),
      userId: _idToStringOrNull(json['user_id']),
      relationship: json['relationship'] as String? ?? '',
      dietaryProfile: json['dietary_profile'] == null
          ? const DietaryProfile()
          : _profileFromJson(json['dietary_profile']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FamilyMemberImplToJson(_$FamilyMemberImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'family_id': instance.familyId,
      'user_id': instance.userId,
      'relationship': instance.relationship,
      'dietary_profile': instance.dietaryProfile,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_$DietaryProfileImpl _$$DietaryProfileImplFromJson(Map<String, dynamic> json) =>
    _$DietaryProfileImpl(
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => Allergy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      intolerances: (json['intolerances'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      restrictions: (json['restrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      preferences: (json['preferences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      medicalNotes: json['medical_notes'] as String?,
    );

Map<String, dynamic> _$$DietaryProfileImplToJson(
        _$DietaryProfileImpl instance) =>
    <String, dynamic>{
      'allergies': instance.allergies,
      'intolerances': instance.intolerances,
      'restrictions': instance.restrictions,
      'preferences': instance.preferences,
      'medical_notes': instance.medicalNotes,
    };

_$AllergyImpl _$$AllergyImplFromJson(Map<String, dynamic> json) =>
    _$AllergyImpl(
      name: json['name'] as String,
      severity: json['severity'] as String? ?? '',
      subForms: (json['sub_forms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$$AllergyImplToJson(_$AllergyImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'severity': instance.severity,
      'sub_forms': instance.subForms,
      'notes': instance.notes,
    };
