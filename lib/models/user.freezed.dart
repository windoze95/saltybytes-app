// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  UserSettings get settings => throw _privateConstructorUsedError;
  Personalization get personalization => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call(
      {String id,
      String username,
      String email,
      String? displayName,
      String? avatarUrl,
      UserSettings settings,
      Personalization personalization,
      DateTime createdAt,
      DateTime? updatedAt});

  $UserSettingsCopyWith<$Res> get settings;
  $PersonalizationCopyWith<$Res> get personalization;
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? settings = null,
    Object? personalization = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as UserSettings,
      personalization: null == personalization
          ? _value.personalization
          : personalization // ignore: cast_nullable_to_non_nullable
              as Personalization,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserSettingsCopyWith<$Res> get settings {
    return $UserSettingsCopyWith<$Res>(_value.settings, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PersonalizationCopyWith<$Res> get personalization {
    return $PersonalizationCopyWith<$Res>(_value.personalization, (value) {
      return _then(_value.copyWith(personalization: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
          _$UserImpl value, $Res Function(_$UserImpl) then) =
      __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String username,
      String email,
      String? displayName,
      String? avatarUrl,
      UserSettings settings,
      Personalization personalization,
      DateTime createdAt,
      DateTime? updatedAt});

  @override
  $UserSettingsCopyWith<$Res> get settings;
  @override
  $PersonalizationCopyWith<$Res> get personalization;
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
      : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
    Object? settings = null,
    Object? personalization = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$UserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as UserSettings,
      personalization: null == personalization
          ? _value.personalization
          : personalization // ignore: cast_nullable_to_non_nullable
              as Personalization,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl(
      {required this.id,
      required this.username,
      required this.email,
      this.displayName,
      this.avatarUrl,
      this.settings = const UserSettings(),
      this.personalization = const Personalization(),
      required this.createdAt,
      this.updatedAt});

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final String id;
  @override
  final String username;
  @override
  final String email;
  @override
  final String? displayName;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final UserSettings settings;
  @override
  @JsonKey()
  final Personalization personalization;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, displayName: $displayName, avatarUrl: $avatarUrl, settings: $settings, personalization: $personalization, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.personalization, personalization) ||
                other.personalization == personalization) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, username, email, displayName,
      avatarUrl, settings, personalization, createdAt, updatedAt);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(
      this,
    );
  }
}

abstract class _User implements User {
  const factory _User(
      {required final String id,
      required final String username,
      required final String email,
      final String? displayName,
      final String? avatarUrl,
      final UserSettings settings,
      final Personalization personalization,
      required final DateTime createdAt,
      final DateTime? updatedAt}) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get id;
  @override
  String get username;
  @override
  String get email;
  @override
  String? get displayName;
  @override
  String? get avatarUrl;
  @override
  UserSettings get settings;
  @override
  Personalization get personalization;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
  String get themeMode => throw _privateConstructorUsedError;
  String get measurementSystem => throw _privateConstructorUsedError;
  int get defaultServings => throw _privateConstructorUsedError;
  bool get notificationsEnabled => throw _privateConstructorUsedError;
  bool get cookingModeWakelock => throw _privateConstructorUsedError;

  /// Serializes this UserSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
          UserSettings value, $Res Function(UserSettings) then) =
      _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call(
      {String themeMode,
      String measurementSystem,
      int defaultServings,
      bool notificationsEnabled,
      bool cookingModeWakelock});
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? measurementSystem = null,
    Object? defaultServings = null,
    Object? notificationsEnabled = null,
    Object? cookingModeWakelock = null,
  }) {
    return _then(_value.copyWith(
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      measurementSystem: null == measurementSystem
          ? _value.measurementSystem
          : measurementSystem // ignore: cast_nullable_to_non_nullable
              as String,
      defaultServings: null == defaultServings
          ? _value.defaultServings
          : defaultServings // ignore: cast_nullable_to_non_nullable
              as int,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      cookingModeWakelock: null == cookingModeWakelock
          ? _value.cookingModeWakelock
          : cookingModeWakelock // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
          _$UserSettingsImpl value, $Res Function(_$UserSettingsImpl) then) =
      __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String themeMode,
      String measurementSystem,
      int defaultServings,
      bool notificationsEnabled,
      bool cookingModeWakelock});
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
      _$UserSettingsImpl _value, $Res Function(_$UserSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? measurementSystem = null,
    Object? defaultServings = null,
    Object? notificationsEnabled = null,
    Object? cookingModeWakelock = null,
  }) {
    return _then(_$UserSettingsImpl(
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      measurementSystem: null == measurementSystem
          ? _value.measurementSystem
          : measurementSystem // ignore: cast_nullable_to_non_nullable
              as String,
      defaultServings: null == defaultServings
          ? _value.defaultServings
          : defaultServings // ignore: cast_nullable_to_non_nullable
              as int,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      cookingModeWakelock: null == cookingModeWakelock
          ? _value.cookingModeWakelock
          : cookingModeWakelock // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl(
      {this.themeMode = 'system',
      this.measurementSystem = 'metric',
      this.defaultServings = 4,
      this.notificationsEnabled = true,
      this.cookingModeWakelock = true});

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

  @override
  @JsonKey()
  final String themeMode;
  @override
  @JsonKey()
  final String measurementSystem;
  @override
  @JsonKey()
  final int defaultServings;
  @override
  @JsonKey()
  final bool notificationsEnabled;
  @override
  @JsonKey()
  final bool cookingModeWakelock;

  @override
  String toString() {
    return 'UserSettings(themeMode: $themeMode, measurementSystem: $measurementSystem, defaultServings: $defaultServings, notificationsEnabled: $notificationsEnabled, cookingModeWakelock: $cookingModeWakelock)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.measurementSystem, measurementSystem) ||
                other.measurementSystem == measurementSystem) &&
            (identical(other.defaultServings, defaultServings) ||
                other.defaultServings == defaultServings) &&
            (identical(other.notificationsEnabled, notificationsEnabled) ||
                other.notificationsEnabled == notificationsEnabled) &&
            (identical(other.cookingModeWakelock, cookingModeWakelock) ||
                other.cookingModeWakelock == cookingModeWakelock));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, themeMode, measurementSystem,
      defaultServings, notificationsEnabled, cookingModeWakelock);

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(
      this,
    );
  }
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings(
      {final String themeMode,
      final String measurementSystem,
      final int defaultServings,
      final bool notificationsEnabled,
      final bool cookingModeWakelock}) = _$UserSettingsImpl;

  factory _UserSettings.fromJson(Map<String, dynamic> json) =
      _$UserSettingsImpl.fromJson;

  @override
  String get themeMode;
  @override
  String get measurementSystem;
  @override
  int get defaultServings;
  @override
  bool get notificationsEnabled;
  @override
  bool get cookingModeWakelock;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Personalization _$PersonalizationFromJson(Map<String, dynamic> json) {
  return _Personalization.fromJson(json);
}

/// @nodoc
mixin _$Personalization {
  List<String> get dietaryRestrictions => throw _privateConstructorUsedError;
  List<String> get cuisinePreferences => throw _privateConstructorUsedError;
  String get skillLevel => throw _privateConstructorUsedError;
  List<String> get allergens => throw _privateConstructorUsedError;

  /// Serializes this Personalization to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Personalization
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersonalizationCopyWith<Personalization> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalizationCopyWith<$Res> {
  factory $PersonalizationCopyWith(
          Personalization value, $Res Function(Personalization) then) =
      _$PersonalizationCopyWithImpl<$Res, Personalization>;
  @useResult
  $Res call(
      {List<String> dietaryRestrictions,
      List<String> cuisinePreferences,
      String skillLevel,
      List<String> allergens});
}

/// @nodoc
class _$PersonalizationCopyWithImpl<$Res, $Val extends Personalization>
    implements $PersonalizationCopyWith<$Res> {
  _$PersonalizationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Personalization
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dietaryRestrictions = null,
    Object? cuisinePreferences = null,
    Object? skillLevel = null,
    Object? allergens = null,
  }) {
    return _then(_value.copyWith(
      dietaryRestrictions: null == dietaryRestrictions
          ? _value.dietaryRestrictions
          : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      cuisinePreferences: null == cuisinePreferences
          ? _value.cuisinePreferences
          : cuisinePreferences // ignore: cast_nullable_to_non_nullable
              as List<String>,
      skillLevel: null == skillLevel
          ? _value.skillLevel
          : skillLevel // ignore: cast_nullable_to_non_nullable
              as String,
      allergens: null == allergens
          ? _value.allergens
          : allergens // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PersonalizationImplCopyWith<$Res>
    implements $PersonalizationCopyWith<$Res> {
  factory _$$PersonalizationImplCopyWith(_$PersonalizationImpl value,
          $Res Function(_$PersonalizationImpl) then) =
      __$$PersonalizationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String> dietaryRestrictions,
      List<String> cuisinePreferences,
      String skillLevel,
      List<String> allergens});
}

/// @nodoc
class __$$PersonalizationImplCopyWithImpl<$Res>
    extends _$PersonalizationCopyWithImpl<$Res, _$PersonalizationImpl>
    implements _$$PersonalizationImplCopyWith<$Res> {
  __$$PersonalizationImplCopyWithImpl(
      _$PersonalizationImpl _value, $Res Function(_$PersonalizationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Personalization
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dietaryRestrictions = null,
    Object? cuisinePreferences = null,
    Object? skillLevel = null,
    Object? allergens = null,
  }) {
    return _then(_$PersonalizationImpl(
      dietaryRestrictions: null == dietaryRestrictions
          ? _value._dietaryRestrictions
          : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      cuisinePreferences: null == cuisinePreferences
          ? _value._cuisinePreferences
          : cuisinePreferences // ignore: cast_nullable_to_non_nullable
              as List<String>,
      skillLevel: null == skillLevel
          ? _value.skillLevel
          : skillLevel // ignore: cast_nullable_to_non_nullable
              as String,
      allergens: null == allergens
          ? _value._allergens
          : allergens // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonalizationImpl implements _Personalization {
  const _$PersonalizationImpl(
      {final List<String> dietaryRestrictions = const [],
      final List<String> cuisinePreferences = const [],
      this.skillLevel = 'intermediate',
      final List<String> allergens = const []})
      : _dietaryRestrictions = dietaryRestrictions,
        _cuisinePreferences = cuisinePreferences,
        _allergens = allergens;

  factory _$PersonalizationImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonalizationImplFromJson(json);

  final List<String> _dietaryRestrictions;
  @override
  @JsonKey()
  List<String> get dietaryRestrictions {
    if (_dietaryRestrictions is EqualUnmodifiableListView)
      return _dietaryRestrictions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dietaryRestrictions);
  }

  final List<String> _cuisinePreferences;
  @override
  @JsonKey()
  List<String> get cuisinePreferences {
    if (_cuisinePreferences is EqualUnmodifiableListView)
      return _cuisinePreferences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cuisinePreferences);
  }

  @override
  @JsonKey()
  final String skillLevel;
  final List<String> _allergens;
  @override
  @JsonKey()
  List<String> get allergens {
    if (_allergens is EqualUnmodifiableListView) return _allergens;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allergens);
  }

  @override
  String toString() {
    return 'Personalization(dietaryRestrictions: $dietaryRestrictions, cuisinePreferences: $cuisinePreferences, skillLevel: $skillLevel, allergens: $allergens)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalizationImpl &&
            const DeepCollectionEquality()
                .equals(other._dietaryRestrictions, _dietaryRestrictions) &&
            const DeepCollectionEquality()
                .equals(other._cuisinePreferences, _cuisinePreferences) &&
            (identical(other.skillLevel, skillLevel) ||
                other.skillLevel == skillLevel) &&
            const DeepCollectionEquality()
                .equals(other._allergens, _allergens));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_dietaryRestrictions),
      const DeepCollectionEquality().hash(_cuisinePreferences),
      skillLevel,
      const DeepCollectionEquality().hash(_allergens));

  /// Create a copy of Personalization
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalizationImplCopyWith<_$PersonalizationImpl> get copyWith =>
      __$$PersonalizationImplCopyWithImpl<_$PersonalizationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonalizationImplToJson(
      this,
    );
  }
}

abstract class _Personalization implements Personalization {
  const factory _Personalization(
      {final List<String> dietaryRestrictions,
      final List<String> cuisinePreferences,
      final String skillLevel,
      final List<String> allergens}) = _$PersonalizationImpl;

  factory _Personalization.fromJson(Map<String, dynamic> json) =
      _$PersonalizationImpl.fromJson;

  @override
  List<String> get dietaryRestrictions;
  @override
  List<String> get cuisinePreferences;
  @override
  String get skillLevel;
  @override
  List<String> get allergens;

  /// Create a copy of Personalization
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersonalizationImplCopyWith<_$PersonalizationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
