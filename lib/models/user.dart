import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String username,
    required String email,
    // Servers that predate email verification omit the field; treating
    // absent as verified keeps the banner/verify UX dormant against them.
    @JsonKey(name: 'email_verified') @Default(true) bool emailVerified,
    @JsonKey(name: 'first_name') String? firstName,
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
    @JsonKey(name: 'keep_screen_awake') @Default(true) bool keepScreenAwake,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}

@freezed
class Personalization with _$Personalization {
  const factory Personalization({
    @JsonKey(name: 'unit_system') @Default('us_customary') String unitSystem,
    @Default('') String requirements,
    @Default('') String uid,
  }) = _Personalization;

  factory Personalization.fromJson(Map<String, dynamic> json) =>
      _$PersonalizationFromJson(json);
}
