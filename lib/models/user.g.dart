// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      emailVerified: json['email_verified'] as bool? ?? true,
      firstName: json['first_name'] as String?,
      settings: json['settings'] == null
          ? const UserSettings()
          : UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
      personalization: json['personalization'] == null
          ? const Personalization()
          : Personalization.fromJson(
              json['personalization'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'email_verified': instance.emailVerified,
      'first_name': instance.firstName,
      'settings': instance.settings,
      'personalization': instance.personalization,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      keepScreenAwake: json['keep_screen_awake'] as bool? ?? true,
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'keep_screen_awake': instance.keepScreenAwake,
    };

_$PersonalizationImpl _$$PersonalizationImplFromJson(
        Map<String, dynamic> json) =>
    _$PersonalizationImpl(
      unitSystem: json['unit_system'] as String? ?? 'us_customary',
      requirements: json['requirements'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
    );

Map<String, dynamic> _$$PersonalizationImplToJson(
        _$PersonalizationImpl instance) =>
    <String, dynamic>{
      'unit_system': instance.unitSystem,
      'requirements': instance.requirements,
      'uid': instance.uid,
    };
