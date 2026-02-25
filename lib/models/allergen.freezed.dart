// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'allergen.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AllergenAnalysis _$AllergenAnalysisFromJson(Map<String, dynamic> json) {
  return _AllergenAnalysis.fromJson(json);
}

/// @nodoc
mixin _$AllergenAnalysis {
  String get recipeId => throw _privateConstructorUsedError;
  List<AllergenInfo> get detectedAllergens =>
      throw _privateConstructorUsedError;
  List<AllergenInfo> get possibleAllergens =>
      throw _privateConstructorUsedError;
  List<FamilySafetyCheck> get familySafetyChecks =>
      throw _privateConstructorUsedError;
  bool get isSafeForAll => throw _privateConstructorUsedError;
  DateTime? get analyzedAt => throw _privateConstructorUsedError;

  /// Serializes this AllergenAnalysis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AllergenAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AllergenAnalysisCopyWith<AllergenAnalysis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AllergenAnalysisCopyWith<$Res> {
  factory $AllergenAnalysisCopyWith(
          AllergenAnalysis value, $Res Function(AllergenAnalysis) then) =
      _$AllergenAnalysisCopyWithImpl<$Res, AllergenAnalysis>;
  @useResult
  $Res call(
      {String recipeId,
      List<AllergenInfo> detectedAllergens,
      List<AllergenInfo> possibleAllergens,
      List<FamilySafetyCheck> familySafetyChecks,
      bool isSafeForAll,
      DateTime? analyzedAt});
}

/// @nodoc
class _$AllergenAnalysisCopyWithImpl<$Res, $Val extends AllergenAnalysis>
    implements $AllergenAnalysisCopyWith<$Res> {
  _$AllergenAnalysisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AllergenAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipeId = null,
    Object? detectedAllergens = null,
    Object? possibleAllergens = null,
    Object? familySafetyChecks = null,
    Object? isSafeForAll = null,
    Object? analyzedAt = freezed,
  }) {
    return _then(_value.copyWith(
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      detectedAllergens: null == detectedAllergens
          ? _value.detectedAllergens
          : detectedAllergens // ignore: cast_nullable_to_non_nullable
              as List<AllergenInfo>,
      possibleAllergens: null == possibleAllergens
          ? _value.possibleAllergens
          : possibleAllergens // ignore: cast_nullable_to_non_nullable
              as List<AllergenInfo>,
      familySafetyChecks: null == familySafetyChecks
          ? _value.familySafetyChecks
          : familySafetyChecks // ignore: cast_nullable_to_non_nullable
              as List<FamilySafetyCheck>,
      isSafeForAll: null == isSafeForAll
          ? _value.isSafeForAll
          : isSafeForAll // ignore: cast_nullable_to_non_nullable
              as bool,
      analyzedAt: freezed == analyzedAt
          ? _value.analyzedAt
          : analyzedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AllergenAnalysisImplCopyWith<$Res>
    implements $AllergenAnalysisCopyWith<$Res> {
  factory _$$AllergenAnalysisImplCopyWith(_$AllergenAnalysisImpl value,
          $Res Function(_$AllergenAnalysisImpl) then) =
      __$$AllergenAnalysisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String recipeId,
      List<AllergenInfo> detectedAllergens,
      List<AllergenInfo> possibleAllergens,
      List<FamilySafetyCheck> familySafetyChecks,
      bool isSafeForAll,
      DateTime? analyzedAt});
}

/// @nodoc
class __$$AllergenAnalysisImplCopyWithImpl<$Res>
    extends _$AllergenAnalysisCopyWithImpl<$Res, _$AllergenAnalysisImpl>
    implements _$$AllergenAnalysisImplCopyWith<$Res> {
  __$$AllergenAnalysisImplCopyWithImpl(_$AllergenAnalysisImpl _value,
      $Res Function(_$AllergenAnalysisImpl) _then)
      : super(_value, _then);

  /// Create a copy of AllergenAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipeId = null,
    Object? detectedAllergens = null,
    Object? possibleAllergens = null,
    Object? familySafetyChecks = null,
    Object? isSafeForAll = null,
    Object? analyzedAt = freezed,
  }) {
    return _then(_$AllergenAnalysisImpl(
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      detectedAllergens: null == detectedAllergens
          ? _value._detectedAllergens
          : detectedAllergens // ignore: cast_nullable_to_non_nullable
              as List<AllergenInfo>,
      possibleAllergens: null == possibleAllergens
          ? _value._possibleAllergens
          : possibleAllergens // ignore: cast_nullable_to_non_nullable
              as List<AllergenInfo>,
      familySafetyChecks: null == familySafetyChecks
          ? _value._familySafetyChecks
          : familySafetyChecks // ignore: cast_nullable_to_non_nullable
              as List<FamilySafetyCheck>,
      isSafeForAll: null == isSafeForAll
          ? _value.isSafeForAll
          : isSafeForAll // ignore: cast_nullable_to_non_nullable
              as bool,
      analyzedAt: freezed == analyzedAt
          ? _value.analyzedAt
          : analyzedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AllergenAnalysisImpl implements _AllergenAnalysis {
  const _$AllergenAnalysisImpl(
      {required this.recipeId,
      final List<AllergenInfo> detectedAllergens = const [],
      final List<AllergenInfo> possibleAllergens = const [],
      final List<FamilySafetyCheck> familySafetyChecks = const [],
      this.isSafeForAll = false,
      this.analyzedAt})
      : _detectedAllergens = detectedAllergens,
        _possibleAllergens = possibleAllergens,
        _familySafetyChecks = familySafetyChecks;

  factory _$AllergenAnalysisImpl.fromJson(Map<String, dynamic> json) =>
      _$$AllergenAnalysisImplFromJson(json);

  @override
  final String recipeId;
  final List<AllergenInfo> _detectedAllergens;
  @override
  @JsonKey()
  List<AllergenInfo> get detectedAllergens {
    if (_detectedAllergens is EqualUnmodifiableListView)
      return _detectedAllergens;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_detectedAllergens);
  }

  final List<AllergenInfo> _possibleAllergens;
  @override
  @JsonKey()
  List<AllergenInfo> get possibleAllergens {
    if (_possibleAllergens is EqualUnmodifiableListView)
      return _possibleAllergens;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_possibleAllergens);
  }

  final List<FamilySafetyCheck> _familySafetyChecks;
  @override
  @JsonKey()
  List<FamilySafetyCheck> get familySafetyChecks {
    if (_familySafetyChecks is EqualUnmodifiableListView)
      return _familySafetyChecks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_familySafetyChecks);
  }

  @override
  @JsonKey()
  final bool isSafeForAll;
  @override
  final DateTime? analyzedAt;

  @override
  String toString() {
    return 'AllergenAnalysis(recipeId: $recipeId, detectedAllergens: $detectedAllergens, possibleAllergens: $possibleAllergens, familySafetyChecks: $familySafetyChecks, isSafeForAll: $isSafeForAll, analyzedAt: $analyzedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AllergenAnalysisImpl &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            const DeepCollectionEquality()
                .equals(other._detectedAllergens, _detectedAllergens) &&
            const DeepCollectionEquality()
                .equals(other._possibleAllergens, _possibleAllergens) &&
            const DeepCollectionEquality()
                .equals(other._familySafetyChecks, _familySafetyChecks) &&
            (identical(other.isSafeForAll, isSafeForAll) ||
                other.isSafeForAll == isSafeForAll) &&
            (identical(other.analyzedAt, analyzedAt) ||
                other.analyzedAt == analyzedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      recipeId,
      const DeepCollectionEquality().hash(_detectedAllergens),
      const DeepCollectionEquality().hash(_possibleAllergens),
      const DeepCollectionEquality().hash(_familySafetyChecks),
      isSafeForAll,
      analyzedAt);

  /// Create a copy of AllergenAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AllergenAnalysisImplCopyWith<_$AllergenAnalysisImpl> get copyWith =>
      __$$AllergenAnalysisImplCopyWithImpl<_$AllergenAnalysisImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AllergenAnalysisImplToJson(
      this,
    );
  }
}

abstract class _AllergenAnalysis implements AllergenAnalysis {
  const factory _AllergenAnalysis(
      {required final String recipeId,
      final List<AllergenInfo> detectedAllergens,
      final List<AllergenInfo> possibleAllergens,
      final List<FamilySafetyCheck> familySafetyChecks,
      final bool isSafeForAll,
      final DateTime? analyzedAt}) = _$AllergenAnalysisImpl;

  factory _AllergenAnalysis.fromJson(Map<String, dynamic> json) =
      _$AllergenAnalysisImpl.fromJson;

  @override
  String get recipeId;
  @override
  List<AllergenInfo> get detectedAllergens;
  @override
  List<AllergenInfo> get possibleAllergens;
  @override
  List<FamilySafetyCheck> get familySafetyChecks;
  @override
  bool get isSafeForAll;
  @override
  DateTime? get analyzedAt;

  /// Create a copy of AllergenAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AllergenAnalysisImplCopyWith<_$AllergenAnalysisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AllergenInfo _$AllergenInfoFromJson(Map<String, dynamic> json) {
  return _AllergenInfo.fromJson(json);
}

/// @nodoc
mixin _$AllergenInfo {
  String get allergen => throw _privateConstructorUsedError;
  String get severity => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  String? get ingredient => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this AllergenInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AllergenInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AllergenInfoCopyWith<AllergenInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AllergenInfoCopyWith<$Res> {
  factory $AllergenInfoCopyWith(
          AllergenInfo value, $Res Function(AllergenInfo) then) =
      _$AllergenInfoCopyWithImpl<$Res, AllergenInfo>;
  @useResult
  $Res call(
      {String allergen,
      String severity,
      String source,
      String? ingredient,
      String? notes});
}

/// @nodoc
class _$AllergenInfoCopyWithImpl<$Res, $Val extends AllergenInfo>
    implements $AllergenInfoCopyWith<$Res> {
  _$AllergenInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AllergenInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allergen = null,
    Object? severity = null,
    Object? source = null,
    Object? ingredient = freezed,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      allergen: null == allergen
          ? _value.allergen
          : allergen // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      ingredient: freezed == ingredient
          ? _value.ingredient
          : ingredient // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AllergenInfoImplCopyWith<$Res>
    implements $AllergenInfoCopyWith<$Res> {
  factory _$$AllergenInfoImplCopyWith(
          _$AllergenInfoImpl value, $Res Function(_$AllergenInfoImpl) then) =
      __$$AllergenInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String allergen,
      String severity,
      String source,
      String? ingredient,
      String? notes});
}

/// @nodoc
class __$$AllergenInfoImplCopyWithImpl<$Res>
    extends _$AllergenInfoCopyWithImpl<$Res, _$AllergenInfoImpl>
    implements _$$AllergenInfoImplCopyWith<$Res> {
  __$$AllergenInfoImplCopyWithImpl(
      _$AllergenInfoImpl _value, $Res Function(_$AllergenInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of AllergenInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allergen = null,
    Object? severity = null,
    Object? source = null,
    Object? ingredient = freezed,
    Object? notes = freezed,
  }) {
    return _then(_$AllergenInfoImpl(
      allergen: null == allergen
          ? _value.allergen
          : allergen // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      ingredient: freezed == ingredient
          ? _value.ingredient
          : ingredient // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AllergenInfoImpl implements _AllergenInfo {
  const _$AllergenInfoImpl(
      {required this.allergen,
      required this.severity,
      required this.source,
      this.ingredient,
      this.notes});

  factory _$AllergenInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AllergenInfoImplFromJson(json);

  @override
  final String allergen;
  @override
  final String severity;
  @override
  final String source;
  @override
  final String? ingredient;
  @override
  final String? notes;

  @override
  String toString() {
    return 'AllergenInfo(allergen: $allergen, severity: $severity, source: $source, ingredient: $ingredient, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AllergenInfoImpl &&
            (identical(other.allergen, allergen) ||
                other.allergen == allergen) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.ingredient, ingredient) ||
                other.ingredient == ingredient) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, allergen, severity, source, ingredient, notes);

  /// Create a copy of AllergenInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AllergenInfoImplCopyWith<_$AllergenInfoImpl> get copyWith =>
      __$$AllergenInfoImplCopyWithImpl<_$AllergenInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AllergenInfoImplToJson(
      this,
    );
  }
}

abstract class _AllergenInfo implements AllergenInfo {
  const factory _AllergenInfo(
      {required final String allergen,
      required final String severity,
      required final String source,
      final String? ingredient,
      final String? notes}) = _$AllergenInfoImpl;

  factory _AllergenInfo.fromJson(Map<String, dynamic> json) =
      _$AllergenInfoImpl.fromJson;

  @override
  String get allergen;
  @override
  String get severity;
  @override
  String get source;
  @override
  String? get ingredient;
  @override
  String? get notes;

  /// Create a copy of AllergenInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AllergenInfoImplCopyWith<_$AllergenInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FamilySafetyCheck _$FamilySafetyCheckFromJson(Map<String, dynamic> json) {
  return _FamilySafetyCheck.fromJson(json);
}

/// @nodoc
mixin _$FamilySafetyCheck {
  String get memberId => throw _privateConstructorUsedError;
  String get memberName => throw _privateConstructorUsedError;
  bool get isSafe => throw _privateConstructorUsedError;
  List<String> get conflicts => throw _privateConstructorUsedError;
  List<String> get warnings => throw _privateConstructorUsedError;

  /// Serializes this FamilySafetyCheck to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FamilySafetyCheck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilySafetyCheckCopyWith<FamilySafetyCheck> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilySafetyCheckCopyWith<$Res> {
  factory $FamilySafetyCheckCopyWith(
          FamilySafetyCheck value, $Res Function(FamilySafetyCheck) then) =
      _$FamilySafetyCheckCopyWithImpl<$Res, FamilySafetyCheck>;
  @useResult
  $Res call(
      {String memberId,
      String memberName,
      bool isSafe,
      List<String> conflicts,
      List<String> warnings});
}

/// @nodoc
class _$FamilySafetyCheckCopyWithImpl<$Res, $Val extends FamilySafetyCheck>
    implements $FamilySafetyCheckCopyWith<$Res> {
  _$FamilySafetyCheckCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FamilySafetyCheck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? memberName = null,
    Object? isSafe = null,
    Object? conflicts = null,
    Object? warnings = null,
  }) {
    return _then(_value.copyWith(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      memberName: null == memberName
          ? _value.memberName
          : memberName // ignore: cast_nullable_to_non_nullable
              as String,
      isSafe: null == isSafe
          ? _value.isSafe
          : isSafe // ignore: cast_nullable_to_non_nullable
              as bool,
      conflicts: null == conflicts
          ? _value.conflicts
          : conflicts // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _value.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FamilySafetyCheckImplCopyWith<$Res>
    implements $FamilySafetyCheckCopyWith<$Res> {
  factory _$$FamilySafetyCheckImplCopyWith(_$FamilySafetyCheckImpl value,
          $Res Function(_$FamilySafetyCheckImpl) then) =
      __$$FamilySafetyCheckImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String memberId,
      String memberName,
      bool isSafe,
      List<String> conflicts,
      List<String> warnings});
}

/// @nodoc
class __$$FamilySafetyCheckImplCopyWithImpl<$Res>
    extends _$FamilySafetyCheckCopyWithImpl<$Res, _$FamilySafetyCheckImpl>
    implements _$$FamilySafetyCheckImplCopyWith<$Res> {
  __$$FamilySafetyCheckImplCopyWithImpl(_$FamilySafetyCheckImpl _value,
      $Res Function(_$FamilySafetyCheckImpl) _then)
      : super(_value, _then);

  /// Create a copy of FamilySafetyCheck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? memberName = null,
    Object? isSafe = null,
    Object? conflicts = null,
    Object? warnings = null,
  }) {
    return _then(_$FamilySafetyCheckImpl(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      memberName: null == memberName
          ? _value.memberName
          : memberName // ignore: cast_nullable_to_non_nullable
              as String,
      isSafe: null == isSafe
          ? _value.isSafe
          : isSafe // ignore: cast_nullable_to_non_nullable
              as bool,
      conflicts: null == conflicts
          ? _value._conflicts
          : conflicts // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilySafetyCheckImpl implements _FamilySafetyCheck {
  const _$FamilySafetyCheckImpl(
      {required this.memberId,
      required this.memberName,
      required this.isSafe,
      final List<String> conflicts = const [],
      final List<String> warnings = const []})
      : _conflicts = conflicts,
        _warnings = warnings;

  factory _$FamilySafetyCheckImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilySafetyCheckImplFromJson(json);

  @override
  final String memberId;
  @override
  final String memberName;
  @override
  final bool isSafe;
  final List<String> _conflicts;
  @override
  @JsonKey()
  List<String> get conflicts {
    if (_conflicts is EqualUnmodifiableListView) return _conflicts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conflicts);
  }

  final List<String> _warnings;
  @override
  @JsonKey()
  List<String> get warnings {
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warnings);
  }

  @override
  String toString() {
    return 'FamilySafetyCheck(memberId: $memberId, memberName: $memberName, isSafe: $isSafe, conflicts: $conflicts, warnings: $warnings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilySafetyCheckImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.memberName, memberName) ||
                other.memberName == memberName) &&
            (identical(other.isSafe, isSafe) || other.isSafe == isSafe) &&
            const DeepCollectionEquality()
                .equals(other._conflicts, _conflicts) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      memberId,
      memberName,
      isSafe,
      const DeepCollectionEquality().hash(_conflicts),
      const DeepCollectionEquality().hash(_warnings));

  /// Create a copy of FamilySafetyCheck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilySafetyCheckImplCopyWith<_$FamilySafetyCheckImpl> get copyWith =>
      __$$FamilySafetyCheckImplCopyWithImpl<_$FamilySafetyCheckImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilySafetyCheckImplToJson(
      this,
    );
  }
}

abstract class _FamilySafetyCheck implements FamilySafetyCheck {
  const factory _FamilySafetyCheck(
      {required final String memberId,
      required final String memberName,
      required final bool isSafe,
      final List<String> conflicts,
      final List<String> warnings}) = _$FamilySafetyCheckImpl;

  factory _FamilySafetyCheck.fromJson(Map<String, dynamic> json) =
      _$FamilySafetyCheckImpl.fromJson;

  @override
  String get memberId;
  @override
  String get memberName;
  @override
  bool get isSafe;
  @override
  List<String> get conflicts;
  @override
  List<String> get warnings;

  /// Create a copy of FamilySafetyCheck
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilySafetyCheckImplCopyWith<_$FamilySafetyCheckImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
