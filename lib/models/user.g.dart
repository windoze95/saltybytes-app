// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
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
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'settings': instance.settings,
      'personalization': instance.personalization,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      themeMode: json['themeMode'] as String? ?? 'system',
      measurementSystem: json['measurementSystem'] as String? ?? 'metric',
      defaultServings: (json['defaultServings'] as num?)?.toInt() ?? 4,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      cookingModeWakelock: json['cookingModeWakelock'] as bool? ?? true,
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'themeMode': instance.themeMode,
      'measurementSystem': instance.measurementSystem,
      'defaultServings': instance.defaultServings,
      'notificationsEnabled': instance.notificationsEnabled,
      'cookingModeWakelock': instance.cookingModeWakelock,
    };

_$PersonalizationImpl _$$PersonalizationImplFromJson(
        Map<String, dynamic> json) =>
    _$PersonalizationImpl(
      dietaryRestrictions: (json['dietaryRestrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      cuisinePreferences: (json['cuisinePreferences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      skillLevel: json['skillLevel'] as String? ?? 'intermediate',
      allergens: (json['allergens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PersonalizationImplToJson(
        _$PersonalizationImpl instance) =>
    <String, dynamic>{
      'dietaryRestrictions': instance.dietaryRestrictions,
      'cuisinePreferences': instance.cuisinePreferences,
      'skillLevel': instance.skillLevel,
      'allergens': instance.allergens,
    };
