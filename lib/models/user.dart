import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String username,
    required String email,
    String? displayName,
    String? avatarUrl,
    @Default(UserSettings()) UserSettings settings,
    @Default(Personalization()) Personalization personalization,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default('system') String themeMode,
    @Default('metric') String measurementSystem,
    @Default(4) int defaultServings,
    @Default(true) bool notificationsEnabled,
    @Default(true) bool cookingModeWakelock,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}

@freezed
class Personalization with _$Personalization {
  const factory Personalization({
    @Default([]) List<String> dietaryRestrictions,
    @Default([]) List<String> cuisinePreferences,
    @Default('intermediate') String skillLevel,
    @Default([]) List<String> allergens,
  }) = _Personalization;

  factory Personalization.fromJson(Map<String, dynamic> json) =>
      _$PersonalizationFromJson(json);
}
