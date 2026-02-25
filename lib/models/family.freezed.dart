// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Family _$FamilyFromJson(Map<String, dynamic> json) {
  return _Family.fromJson(json);
}

/// @nodoc
mixin _$Family {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<FamilyMember> get members => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Family to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Family
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilyCopyWith<Family> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyCopyWith<$Res> {
  factory $FamilyCopyWith(Family value, $Res Function(Family) then) =
      _$FamilyCopyWithImpl<$Res, Family>;
  @useResult
  $Res call(
      {String id,
      String name,
      String ownerId,
      String? description,
      List<FamilyMember> members,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$FamilyCopyWithImpl<$Res, $Val extends Family>
    implements $FamilyCopyWith<$Res> {
  _$FamilyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Family
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ownerId = null,
    Object? description = freezed,
    Object? members = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<FamilyMember>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FamilyImplCopyWith<$Res> implements $FamilyCopyWith<$Res> {
  factory _$$FamilyImplCopyWith(
          _$FamilyImpl value, $Res Function(_$FamilyImpl) then) =
      __$$FamilyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String ownerId,
      String? description,
      List<FamilyMember> members,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$FamilyImplCopyWithImpl<$Res>
    extends _$FamilyCopyWithImpl<$Res, _$FamilyImpl>
    implements _$$FamilyImplCopyWith<$Res> {
  __$$FamilyImplCopyWithImpl(
      _$FamilyImpl _value, $Res Function(_$FamilyImpl) _then)
      : super(_value, _then);

  /// Create a copy of Family
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ownerId = null,
    Object? description = freezed,
    Object? members = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$FamilyImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<FamilyMember>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyImpl implements _Family {
  const _$FamilyImpl(
      {required this.id,
      required this.name,
      required this.ownerId,
      this.description,
      final List<FamilyMember> members = const [],
      this.createdAt,
      this.updatedAt})
      : _members = members;

  factory _$FamilyImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String ownerId;
  @override
  final String? description;
  final List<FamilyMember> _members;
  @override
  @JsonKey()
  List<FamilyMember> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Family(id: $id, name: $name, ownerId: $ownerId, description: $description, members: $members, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, ownerId, description,
      const DeepCollectionEquality().hash(_members), createdAt, updatedAt);

  /// Create a copy of Family
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyImplCopyWith<_$FamilyImpl> get copyWith =>
      __$$FamilyImplCopyWithImpl<_$FamilyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyImplToJson(
      this,
    );
  }
}

abstract class _Family implements Family {
  const factory _Family(
      {required final String id,
      required final String name,
      required final String ownerId,
      final String? description,
      final List<FamilyMember> members,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$FamilyImpl;

  factory _Family.fromJson(Map<String, dynamic> json) = _$FamilyImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get ownerId;
  @override
  String? get description;
  @override
  List<FamilyMember> get members;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Family
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyImplCopyWith<_$FamilyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FamilyMember _$FamilyMemberFromJson(Map<String, dynamic> json) {
  return _FamilyMember.fromJson(json);
}

/// @nodoc
mixin _$FamilyMember {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  DietaryProfile get dietaryProfile => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FamilyMember to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FamilyMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilyMemberCopyWith<FamilyMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyMemberCopyWith<$Res> {
  factory $FamilyMemberCopyWith(
          FamilyMember value, $Res Function(FamilyMember) then) =
      _$FamilyMemberCopyWithImpl<$Res, FamilyMember>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? userId,
      String role,
      DietaryProfile dietaryProfile,
      DateTime? createdAt});

  $DietaryProfileCopyWith<$Res> get dietaryProfile;
}

/// @nodoc
class _$FamilyMemberCopyWithImpl<$Res, $Val extends FamilyMember>
    implements $FamilyMemberCopyWith<$Res> {
  _$FamilyMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FamilyMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? userId = freezed,
    Object? role = null,
    Object? dietaryProfile = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      dietaryProfile: null == dietaryProfile
          ? _value.dietaryProfile
          : dietaryProfile // ignore: cast_nullable_to_non_nullable
              as DietaryProfile,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of FamilyMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DietaryProfileCopyWith<$Res> get dietaryProfile {
    return $DietaryProfileCopyWith<$Res>(_value.dietaryProfile, (value) {
      return _then(_value.copyWith(dietaryProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FamilyMemberImplCopyWith<$Res>
    implements $FamilyMemberCopyWith<$Res> {
  factory _$$FamilyMemberImplCopyWith(
          _$FamilyMemberImpl value, $Res Function(_$FamilyMemberImpl) then) =
      __$$FamilyMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? userId,
      String role,
      DietaryProfile dietaryProfile,
      DateTime? createdAt});

  @override
  $DietaryProfileCopyWith<$Res> get dietaryProfile;
}

/// @nodoc
class __$$FamilyMemberImplCopyWithImpl<$Res>
    extends _$FamilyMemberCopyWithImpl<$Res, _$FamilyMemberImpl>
    implements _$$FamilyMemberImplCopyWith<$Res> {
  __$$FamilyMemberImplCopyWithImpl(
      _$FamilyMemberImpl _value, $Res Function(_$FamilyMemberImpl) _then)
      : super(_value, _then);

  /// Create a copy of FamilyMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? userId = freezed,
    Object? role = null,
    Object? dietaryProfile = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$FamilyMemberImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      dietaryProfile: null == dietaryProfile
          ? _value.dietaryProfile
          : dietaryProfile // ignore: cast_nullable_to_non_nullable
              as DietaryProfile,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyMemberImpl implements _FamilyMember {
  const _$FamilyMemberImpl(
      {required this.id,
      required this.name,
      this.userId,
      this.role = 'member',
      this.dietaryProfile = const DietaryProfile(),
      this.createdAt});

  factory _$FamilyMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyMemberImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? userId;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey()
  final DietaryProfile dietaryProfile;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'FamilyMember(id: $id, name: $name, userId: $userId, role: $role, dietaryProfile: $dietaryProfile, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyMemberImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.dietaryProfile, dietaryProfile) ||
                other.dietaryProfile == dietaryProfile) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, userId, role, dietaryProfile, createdAt);

  /// Create a copy of FamilyMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyMemberImplCopyWith<_$FamilyMemberImpl> get copyWith =>
      __$$FamilyMemberImplCopyWithImpl<_$FamilyMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyMemberImplToJson(
      this,
    );
  }
}

abstract class _FamilyMember implements FamilyMember {
  const factory _FamilyMember(
      {required final String id,
      required final String name,
      final String? userId,
      final String role,
      final DietaryProfile dietaryProfile,
      final DateTime? createdAt}) = _$FamilyMemberImpl;

  factory _FamilyMember.fromJson(Map<String, dynamic> json) =
      _$FamilyMemberImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get userId;
  @override
  String get role;
  @override
  DietaryProfile get dietaryProfile;
  @override
  DateTime? get createdAt;

  /// Create a copy of FamilyMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyMemberImplCopyWith<_$FamilyMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DietaryProfile _$DietaryProfileFromJson(Map<String, dynamic> json) {
  return _DietaryProfile.fromJson(json);
}

/// @nodoc
mixin _$DietaryProfile {
  List<String> get allergies => throw _privateConstructorUsedError;
  List<String> get intolerances => throw _privateConstructorUsedError;
  List<String> get dietaryRestrictions => throw _privateConstructorUsedError;
  List<String> get dislikedIngredients => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this DietaryProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DietaryProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DietaryProfileCopyWith<DietaryProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DietaryProfileCopyWith<$Res> {
  factory $DietaryProfileCopyWith(
          DietaryProfile value, $Res Function(DietaryProfile) then) =
      _$DietaryProfileCopyWithImpl<$Res, DietaryProfile>;
  @useResult
  $Res call(
      {List<String> allergies,
      List<String> intolerances,
      List<String> dietaryRestrictions,
      List<String> dislikedIngredients,
      String? notes});
}

/// @nodoc
class _$DietaryProfileCopyWithImpl<$Res, $Val extends DietaryProfile>
    implements $DietaryProfileCopyWith<$Res> {
  _$DietaryProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DietaryProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allergies = null,
    Object? intolerances = null,
    Object? dietaryRestrictions = null,
    Object? dislikedIngredients = null,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      allergies: null == allergies
          ? _value.allergies
          : allergies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      intolerances: null == intolerances
          ? _value.intolerances
          : intolerances // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dietaryRestrictions: null == dietaryRestrictions
          ? _value.dietaryRestrictions
          : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dislikedIngredients: null == dislikedIngredients
          ? _value.dislikedIngredients
          : dislikedIngredients // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DietaryProfileImplCopyWith<$Res>
    implements $DietaryProfileCopyWith<$Res> {
  factory _$$DietaryProfileImplCopyWith(_$DietaryProfileImpl value,
          $Res Function(_$DietaryProfileImpl) then) =
      __$$DietaryProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String> allergies,
      List<String> intolerances,
      List<String> dietaryRestrictions,
      List<String> dislikedIngredients,
      String? notes});
}

/// @nodoc
class __$$DietaryProfileImplCopyWithImpl<$Res>
    extends _$DietaryProfileCopyWithImpl<$Res, _$DietaryProfileImpl>
    implements _$$DietaryProfileImplCopyWith<$Res> {
  __$$DietaryProfileImplCopyWithImpl(
      _$DietaryProfileImpl _value, $Res Function(_$DietaryProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of DietaryProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allergies = null,
    Object? intolerances = null,
    Object? dietaryRestrictions = null,
    Object? dislikedIngredients = null,
    Object? notes = freezed,
  }) {
    return _then(_$DietaryProfileImpl(
      allergies: null == allergies
          ? _value._allergies
          : allergies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      intolerances: null == intolerances
          ? _value._intolerances
          : intolerances // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dietaryRestrictions: null == dietaryRestrictions
          ? _value._dietaryRestrictions
          : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dislikedIngredients: null == dislikedIngredients
          ? _value._dislikedIngredients
          : dislikedIngredients // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DietaryProfileImpl implements _DietaryProfile {
  const _$DietaryProfileImpl(
      {final List<String> allergies = const [],
      final List<String> intolerances = const [],
      final List<String> dietaryRestrictions = const [],
      final List<String> dislikedIngredients = const [],
      this.notes})
      : _allergies = allergies,
        _intolerances = intolerances,
        _dietaryRestrictions = dietaryRestrictions,
        _dislikedIngredients = dislikedIngredients;

  factory _$DietaryProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$DietaryProfileImplFromJson(json);

  final List<String> _allergies;
  @override
  @JsonKey()
  List<String> get allergies {
    if (_allergies is EqualUnmodifiableListView) return _allergies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allergies);
  }

  final List<String> _intolerances;
  @override
  @JsonKey()
  List<String> get intolerances {
    if (_intolerances is EqualUnmodifiableListView) return _intolerances;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_intolerances);
  }

  final List<String> _dietaryRestrictions;
  @override
  @JsonKey()
  List<String> get dietaryRestrictions {
    if (_dietaryRestrictions is EqualUnmodifiableListView)
      return _dietaryRestrictions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dietaryRestrictions);
  }

  final List<String> _dislikedIngredients;
  @override
  @JsonKey()
  List<String> get dislikedIngredients {
    if (_dislikedIngredients is EqualUnmodifiableListView)
      return _dislikedIngredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dislikedIngredients);
  }

  @override
  final String? notes;

  @override
  String toString() {
    return 'DietaryProfile(allergies: $allergies, intolerances: $intolerances, dietaryRestrictions: $dietaryRestrictions, dislikedIngredients: $dislikedIngredients, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DietaryProfileImpl &&
            const DeepCollectionEquality()
                .equals(other._allergies, _allergies) &&
            const DeepCollectionEquality()
                .equals(other._intolerances, _intolerances) &&
            const DeepCollectionEquality()
                .equals(other._dietaryRestrictions, _dietaryRestrictions) &&
            const DeepCollectionEquality()
                .equals(other._dislikedIngredients, _dislikedIngredients) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_allergies),
      const DeepCollectionEquality().hash(_intolerances),
      const DeepCollectionEquality().hash(_dietaryRestrictions),
      const DeepCollectionEquality().hash(_dislikedIngredients),
      notes);

  /// Create a copy of DietaryProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DietaryProfileImplCopyWith<_$DietaryProfileImpl> get copyWith =>
      __$$DietaryProfileImplCopyWithImpl<_$DietaryProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DietaryProfileImplToJson(
      this,
    );
  }
}

abstract class _DietaryProfile implements DietaryProfile {
  const factory _DietaryProfile(
      {final List<String> allergies,
      final List<String> intolerances,
      final List<String> dietaryRestrictions,
      final List<String> dislikedIngredients,
      final String? notes}) = _$DietaryProfileImpl;

  factory _DietaryProfile.fromJson(Map<String, dynamic> json) =
      _$DietaryProfileImpl.fromJson;

  @override
  List<String> get allergies;
  @override
  List<String> get intolerances;
  @override
  List<String> get dietaryRestrictions;
  @override
  List<String> get dislikedIngredients;
  @override
  String? get notes;

  /// Create a copy of DietaryProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DietaryProfileImplCopyWith<_$DietaryProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
