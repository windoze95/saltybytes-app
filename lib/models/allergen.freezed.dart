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
  @JsonKey(name: 'recipe_id', fromJson: _idToString)
  String get recipeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'ingredient_analyses')
  List<IngredientAnalysis> get ingredientAnalyses =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'contains_nuts')
  bool get containsNuts => throw _privateConstructorUsedError;
  @JsonKey(name: 'contains_dairy')
  bool get containsDairy => throw _privateConstructorUsedError;
  @JsonKey(name: 'contains_gluten')
  bool get containsGluten => throw _privateConstructorUsedError;
  @JsonKey(name: 'contains_soy')
  bool get containsSoy => throw _privateConstructorUsedError;
  @JsonKey(name: 'contains_seed_oils')
  bool get containsSeedOils => throw _privateConstructorUsedError;
  @JsonKey(name: 'contains_shellfish')
  bool get containsShellfish => throw _privateConstructorUsedError;
  @JsonKey(name: 'contains_eggs')
  bool get containsEggs => throw _privateConstructorUsedError;
  @JsonKey(name: 'safe_for_profiles', fromJson: _idListToStrings)
  List<String> get safeForProfiles => throw _privateConstructorUsedError;
  @JsonKey(name: 'unsafe_for_profiles', fromJson: _idListToStrings)
  List<String> get unsafeForProfiles => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  @JsonKey(name: 'requires_review')
  bool get requiresReview => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_premium')
  bool get isPremium => throw _privateConstructorUsedError;
  @JsonKey(name: 'prompt_version')
  String get promptVersion => throw _privateConstructorUsedError;
  String get disclaimer => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
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
      {@JsonKey(name: 'recipe_id', fromJson: _idToString) String recipeId,
      @JsonKey(name: 'ingredient_analyses')
      List<IngredientAnalysis> ingredientAnalyses,
      @JsonKey(name: 'contains_nuts') bool containsNuts,
      @JsonKey(name: 'contains_dairy') bool containsDairy,
      @JsonKey(name: 'contains_gluten') bool containsGluten,
      @JsonKey(name: 'contains_soy') bool containsSoy,
      @JsonKey(name: 'contains_seed_oils') bool containsSeedOils,
      @JsonKey(name: 'contains_shellfish') bool containsShellfish,
      @JsonKey(name: 'contains_eggs') bool containsEggs,
      @JsonKey(name: 'safe_for_profiles', fromJson: _idListToStrings)
      List<String> safeForProfiles,
      @JsonKey(name: 'unsafe_for_profiles', fromJson: _idListToStrings)
      List<String> unsafeForProfiles,
      double confidence,
      @JsonKey(name: 'requires_review') bool requiresReview,
      @JsonKey(name: 'is_premium') bool isPremium,
      @JsonKey(name: 'prompt_version') String promptVersion,
      String disclaimer,
      @JsonKey(name: 'updated_at') DateTime? analyzedAt});
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
    Object? ingredientAnalyses = null,
    Object? containsNuts = null,
    Object? containsDairy = null,
    Object? containsGluten = null,
    Object? containsSoy = null,
    Object? containsSeedOils = null,
    Object? containsShellfish = null,
    Object? containsEggs = null,
    Object? safeForProfiles = null,
    Object? unsafeForProfiles = null,
    Object? confidence = null,
    Object? requiresReview = null,
    Object? isPremium = null,
    Object? promptVersion = null,
    Object? disclaimer = null,
    Object? analyzedAt = freezed,
  }) {
    return _then(_value.copyWith(
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      ingredientAnalyses: null == ingredientAnalyses
          ? _value.ingredientAnalyses
          : ingredientAnalyses // ignore: cast_nullable_to_non_nullable
              as List<IngredientAnalysis>,
      containsNuts: null == containsNuts
          ? _value.containsNuts
          : containsNuts // ignore: cast_nullable_to_non_nullable
              as bool,
      containsDairy: null == containsDairy
          ? _value.containsDairy
          : containsDairy // ignore: cast_nullable_to_non_nullable
              as bool,
      containsGluten: null == containsGluten
          ? _value.containsGluten
          : containsGluten // ignore: cast_nullable_to_non_nullable
              as bool,
      containsSoy: null == containsSoy
          ? _value.containsSoy
          : containsSoy // ignore: cast_nullable_to_non_nullable
              as bool,
      containsSeedOils: null == containsSeedOils
          ? _value.containsSeedOils
          : containsSeedOils // ignore: cast_nullable_to_non_nullable
              as bool,
      containsShellfish: null == containsShellfish
          ? _value.containsShellfish
          : containsShellfish // ignore: cast_nullable_to_non_nullable
              as bool,
      containsEggs: null == containsEggs
          ? _value.containsEggs
          : containsEggs // ignore: cast_nullable_to_non_nullable
              as bool,
      safeForProfiles: null == safeForProfiles
          ? _value.safeForProfiles
          : safeForProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      unsafeForProfiles: null == unsafeForProfiles
          ? _value.unsafeForProfiles
          : unsafeForProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      requiresReview: null == requiresReview
          ? _value.requiresReview
          : requiresReview // ignore: cast_nullable_to_non_nullable
              as bool,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      promptVersion: null == promptVersion
          ? _value.promptVersion
          : promptVersion // ignore: cast_nullable_to_non_nullable
              as String,
      disclaimer: null == disclaimer
          ? _value.disclaimer
          : disclaimer // ignore: cast_nullable_to_non_nullable
              as String,
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
      {@JsonKey(name: 'recipe_id', fromJson: _idToString) String recipeId,
      @JsonKey(name: 'ingredient_analyses')
      List<IngredientAnalysis> ingredientAnalyses,
      @JsonKey(name: 'contains_nuts') bool containsNuts,
      @JsonKey(name: 'contains_dairy') bool containsDairy,
      @JsonKey(name: 'contains_gluten') bool containsGluten,
      @JsonKey(name: 'contains_soy') bool containsSoy,
      @JsonKey(name: 'contains_seed_oils') bool containsSeedOils,
      @JsonKey(name: 'contains_shellfish') bool containsShellfish,
      @JsonKey(name: 'contains_eggs') bool containsEggs,
      @JsonKey(name: 'safe_for_profiles', fromJson: _idListToStrings)
      List<String> safeForProfiles,
      @JsonKey(name: 'unsafe_for_profiles', fromJson: _idListToStrings)
      List<String> unsafeForProfiles,
      double confidence,
      @JsonKey(name: 'requires_review') bool requiresReview,
      @JsonKey(name: 'is_premium') bool isPremium,
      @JsonKey(name: 'prompt_version') String promptVersion,
      String disclaimer,
      @JsonKey(name: 'updated_at') DateTime? analyzedAt});
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
    Object? ingredientAnalyses = null,
    Object? containsNuts = null,
    Object? containsDairy = null,
    Object? containsGluten = null,
    Object? containsSoy = null,
    Object? containsSeedOils = null,
    Object? containsShellfish = null,
    Object? containsEggs = null,
    Object? safeForProfiles = null,
    Object? unsafeForProfiles = null,
    Object? confidence = null,
    Object? requiresReview = null,
    Object? isPremium = null,
    Object? promptVersion = null,
    Object? disclaimer = null,
    Object? analyzedAt = freezed,
  }) {
    return _then(_$AllergenAnalysisImpl(
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      ingredientAnalyses: null == ingredientAnalyses
          ? _value._ingredientAnalyses
          : ingredientAnalyses // ignore: cast_nullable_to_non_nullable
              as List<IngredientAnalysis>,
      containsNuts: null == containsNuts
          ? _value.containsNuts
          : containsNuts // ignore: cast_nullable_to_non_nullable
              as bool,
      containsDairy: null == containsDairy
          ? _value.containsDairy
          : containsDairy // ignore: cast_nullable_to_non_nullable
              as bool,
      containsGluten: null == containsGluten
          ? _value.containsGluten
          : containsGluten // ignore: cast_nullable_to_non_nullable
              as bool,
      containsSoy: null == containsSoy
          ? _value.containsSoy
          : containsSoy // ignore: cast_nullable_to_non_nullable
              as bool,
      containsSeedOils: null == containsSeedOils
          ? _value.containsSeedOils
          : containsSeedOils // ignore: cast_nullable_to_non_nullable
              as bool,
      containsShellfish: null == containsShellfish
          ? _value.containsShellfish
          : containsShellfish // ignore: cast_nullable_to_non_nullable
              as bool,
      containsEggs: null == containsEggs
          ? _value.containsEggs
          : containsEggs // ignore: cast_nullable_to_non_nullable
              as bool,
      safeForProfiles: null == safeForProfiles
          ? _value._safeForProfiles
          : safeForProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      unsafeForProfiles: null == unsafeForProfiles
          ? _value._unsafeForProfiles
          : unsafeForProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      requiresReview: null == requiresReview
          ? _value.requiresReview
          : requiresReview // ignore: cast_nullable_to_non_nullable
              as bool,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      promptVersion: null == promptVersion
          ? _value.promptVersion
          : promptVersion // ignore: cast_nullable_to_non_nullable
              as String,
      disclaimer: null == disclaimer
          ? _value.disclaimer
          : disclaimer // ignore: cast_nullable_to_non_nullable
              as String,
      analyzedAt: freezed == analyzedAt
          ? _value.analyzedAt
          : analyzedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AllergenAnalysisImpl extends _AllergenAnalysis {
  const _$AllergenAnalysisImpl(
      {@JsonKey(name: 'recipe_id', fromJson: _idToString) this.recipeId = '',
      @JsonKey(name: 'ingredient_analyses')
      final List<IngredientAnalysis> ingredientAnalyses = const [],
      @JsonKey(name: 'contains_nuts') this.containsNuts = false,
      @JsonKey(name: 'contains_dairy') this.containsDairy = false,
      @JsonKey(name: 'contains_gluten') this.containsGluten = false,
      @JsonKey(name: 'contains_soy') this.containsSoy = false,
      @JsonKey(name: 'contains_seed_oils') this.containsSeedOils = false,
      @JsonKey(name: 'contains_shellfish') this.containsShellfish = false,
      @JsonKey(name: 'contains_eggs') this.containsEggs = false,
      @JsonKey(name: 'safe_for_profiles', fromJson: _idListToStrings)
      final List<String> safeForProfiles = const [],
      @JsonKey(name: 'unsafe_for_profiles', fromJson: _idListToStrings)
      final List<String> unsafeForProfiles = const [],
      this.confidence = 0.0,
      @JsonKey(name: 'requires_review') this.requiresReview = false,
      @JsonKey(name: 'is_premium') this.isPremium = false,
      @JsonKey(name: 'prompt_version') this.promptVersion = '',
      this.disclaimer = '',
      @JsonKey(name: 'updated_at') this.analyzedAt})
      : _ingredientAnalyses = ingredientAnalyses,
        _safeForProfiles = safeForProfiles,
        _unsafeForProfiles = unsafeForProfiles,
        super._();

  factory _$AllergenAnalysisImpl.fromJson(Map<String, dynamic> json) =>
      _$$AllergenAnalysisImplFromJson(json);

  @override
  @JsonKey(name: 'recipe_id', fromJson: _idToString)
  final String recipeId;
  final List<IngredientAnalysis> _ingredientAnalyses;
  @override
  @JsonKey(name: 'ingredient_analyses')
  List<IngredientAnalysis> get ingredientAnalyses {
    if (_ingredientAnalyses is EqualUnmodifiableListView)
      return _ingredientAnalyses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredientAnalyses);
  }

  @override
  @JsonKey(name: 'contains_nuts')
  final bool containsNuts;
  @override
  @JsonKey(name: 'contains_dairy')
  final bool containsDairy;
  @override
  @JsonKey(name: 'contains_gluten')
  final bool containsGluten;
  @override
  @JsonKey(name: 'contains_soy')
  final bool containsSoy;
  @override
  @JsonKey(name: 'contains_seed_oils')
  final bool containsSeedOils;
  @override
  @JsonKey(name: 'contains_shellfish')
  final bool containsShellfish;
  @override
  @JsonKey(name: 'contains_eggs')
  final bool containsEggs;
  final List<String> _safeForProfiles;
  @override
  @JsonKey(name: 'safe_for_profiles', fromJson: _idListToStrings)
  List<String> get safeForProfiles {
    if (_safeForProfiles is EqualUnmodifiableListView) return _safeForProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_safeForProfiles);
  }

  final List<String> _unsafeForProfiles;
  @override
  @JsonKey(name: 'unsafe_for_profiles', fromJson: _idListToStrings)
  List<String> get unsafeForProfiles {
    if (_unsafeForProfiles is EqualUnmodifiableListView)
      return _unsafeForProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unsafeForProfiles);
  }

  @override
  @JsonKey()
  final double confidence;
  @override
  @JsonKey(name: 'requires_review')
  final bool requiresReview;
  @override
  @JsonKey(name: 'is_premium')
  final bool isPremium;
  @override
  @JsonKey(name: 'prompt_version')
  final String promptVersion;
  @override
  @JsonKey()
  final String disclaimer;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? analyzedAt;

  @override
  String toString() {
    return 'AllergenAnalysis(recipeId: $recipeId, ingredientAnalyses: $ingredientAnalyses, containsNuts: $containsNuts, containsDairy: $containsDairy, containsGluten: $containsGluten, containsSoy: $containsSoy, containsSeedOils: $containsSeedOils, containsShellfish: $containsShellfish, containsEggs: $containsEggs, safeForProfiles: $safeForProfiles, unsafeForProfiles: $unsafeForProfiles, confidence: $confidence, requiresReview: $requiresReview, isPremium: $isPremium, promptVersion: $promptVersion, disclaimer: $disclaimer, analyzedAt: $analyzedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AllergenAnalysisImpl &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            const DeepCollectionEquality()
                .equals(other._ingredientAnalyses, _ingredientAnalyses) &&
            (identical(other.containsNuts, containsNuts) ||
                other.containsNuts == containsNuts) &&
            (identical(other.containsDairy, containsDairy) ||
                other.containsDairy == containsDairy) &&
            (identical(other.containsGluten, containsGluten) ||
                other.containsGluten == containsGluten) &&
            (identical(other.containsSoy, containsSoy) ||
                other.containsSoy == containsSoy) &&
            (identical(other.containsSeedOils, containsSeedOils) ||
                other.containsSeedOils == containsSeedOils) &&
            (identical(other.containsShellfish, containsShellfish) ||
                other.containsShellfish == containsShellfish) &&
            (identical(other.containsEggs, containsEggs) ||
                other.containsEggs == containsEggs) &&
            const DeepCollectionEquality()
                .equals(other._safeForProfiles, _safeForProfiles) &&
            const DeepCollectionEquality()
                .equals(other._unsafeForProfiles, _unsafeForProfiles) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.requiresReview, requiresReview) ||
                other.requiresReview == requiresReview) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.promptVersion, promptVersion) ||
                other.promptVersion == promptVersion) &&
            (identical(other.disclaimer, disclaimer) ||
                other.disclaimer == disclaimer) &&
            (identical(other.analyzedAt, analyzedAt) ||
                other.analyzedAt == analyzedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      recipeId,
      const DeepCollectionEquality().hash(_ingredientAnalyses),
      containsNuts,
      containsDairy,
      containsGluten,
      containsSoy,
      containsSeedOils,
      containsShellfish,
      containsEggs,
      const DeepCollectionEquality().hash(_safeForProfiles),
      const DeepCollectionEquality().hash(_unsafeForProfiles),
      confidence,
      requiresReview,
      isPremium,
      promptVersion,
      disclaimer,
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

abstract class _AllergenAnalysis extends AllergenAnalysis {
  const factory _AllergenAnalysis(
      {@JsonKey(name: 'recipe_id', fromJson: _idToString) final String recipeId,
      @JsonKey(name: 'ingredient_analyses')
      final List<IngredientAnalysis> ingredientAnalyses,
      @JsonKey(name: 'contains_nuts') final bool containsNuts,
      @JsonKey(name: 'contains_dairy') final bool containsDairy,
      @JsonKey(name: 'contains_gluten') final bool containsGluten,
      @JsonKey(name: 'contains_soy') final bool containsSoy,
      @JsonKey(name: 'contains_seed_oils') final bool containsSeedOils,
      @JsonKey(name: 'contains_shellfish') final bool containsShellfish,
      @JsonKey(name: 'contains_eggs') final bool containsEggs,
      @JsonKey(name: 'safe_for_profiles', fromJson: _idListToStrings)
      final List<String> safeForProfiles,
      @JsonKey(name: 'unsafe_for_profiles', fromJson: _idListToStrings)
      final List<String> unsafeForProfiles,
      final double confidence,
      @JsonKey(name: 'requires_review') final bool requiresReview,
      @JsonKey(name: 'is_premium') final bool isPremium,
      @JsonKey(name: 'prompt_version') final String promptVersion,
      final String disclaimer,
      @JsonKey(name: 'updated_at')
      final DateTime? analyzedAt}) = _$AllergenAnalysisImpl;
  const _AllergenAnalysis._() : super._();

  factory _AllergenAnalysis.fromJson(Map<String, dynamic> json) =
      _$AllergenAnalysisImpl.fromJson;

  @override
  @JsonKey(name: 'recipe_id', fromJson: _idToString)
  String get recipeId;
  @override
  @JsonKey(name: 'ingredient_analyses')
  List<IngredientAnalysis> get ingredientAnalyses;
  @override
  @JsonKey(name: 'contains_nuts')
  bool get containsNuts;
  @override
  @JsonKey(name: 'contains_dairy')
  bool get containsDairy;
  @override
  @JsonKey(name: 'contains_gluten')
  bool get containsGluten;
  @override
  @JsonKey(name: 'contains_soy')
  bool get containsSoy;
  @override
  @JsonKey(name: 'contains_seed_oils')
  bool get containsSeedOils;
  @override
  @JsonKey(name: 'contains_shellfish')
  bool get containsShellfish;
  @override
  @JsonKey(name: 'contains_eggs')
  bool get containsEggs;
  @override
  @JsonKey(name: 'safe_for_profiles', fromJson: _idListToStrings)
  List<String> get safeForProfiles;
  @override
  @JsonKey(name: 'unsafe_for_profiles', fromJson: _idListToStrings)
  List<String> get unsafeForProfiles;
  @override
  double get confidence;
  @override
  @JsonKey(name: 'requires_review')
  bool get requiresReview;
  @override
  @JsonKey(name: 'is_premium')
  bool get isPremium;
  @override
  @JsonKey(name: 'prompt_version')
  String get promptVersion;
  @override
  String get disclaimer;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get analyzedAt;

  /// Create a copy of AllergenAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AllergenAnalysisImplCopyWith<_$AllergenAnalysisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IngredientAnalysis _$IngredientAnalysisFromJson(Map<String, dynamic> json) {
  return _IngredientAnalysis.fromJson(json);
}

/// @nodoc
mixin _$IngredientAnalysis {
  @JsonKey(name: 'ingredient_name')
  String get ingredientName => throw _privateConstructorUsedError;
  @JsonKey(name: 'common_allergens')
  List<String> get commonAllergens => throw _privateConstructorUsedError;
  @JsonKey(name: 'possible_allergens')
  List<String> get possibleAllergens => throw _privateConstructorUsedError;
  @JsonKey(name: 'sub_ingredients')
  List<String> get subIngredients => throw _privateConstructorUsedError;
  @JsonKey(name: 'seed_oil_risk')
  bool get seedOilRisk => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this IngredientAnalysis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IngredientAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IngredientAnalysisCopyWith<IngredientAnalysis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IngredientAnalysisCopyWith<$Res> {
  factory $IngredientAnalysisCopyWith(
          IngredientAnalysis value, $Res Function(IngredientAnalysis) then) =
      _$IngredientAnalysisCopyWithImpl<$Res, IngredientAnalysis>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ingredient_name') String ingredientName,
      @JsonKey(name: 'common_allergens') List<String> commonAllergens,
      @JsonKey(name: 'possible_allergens') List<String> possibleAllergens,
      @JsonKey(name: 'sub_ingredients') List<String> subIngredients,
      @JsonKey(name: 'seed_oil_risk') bool seedOilRisk,
      double confidence});
}

/// @nodoc
class _$IngredientAnalysisCopyWithImpl<$Res, $Val extends IngredientAnalysis>
    implements $IngredientAnalysisCopyWith<$Res> {
  _$IngredientAnalysisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IngredientAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ingredientName = null,
    Object? commonAllergens = null,
    Object? possibleAllergens = null,
    Object? subIngredients = null,
    Object? seedOilRisk = null,
    Object? confidence = null,
  }) {
    return _then(_value.copyWith(
      ingredientName: null == ingredientName
          ? _value.ingredientName
          : ingredientName // ignore: cast_nullable_to_non_nullable
              as String,
      commonAllergens: null == commonAllergens
          ? _value.commonAllergens
          : commonAllergens // ignore: cast_nullable_to_non_nullable
              as List<String>,
      possibleAllergens: null == possibleAllergens
          ? _value.possibleAllergens
          : possibleAllergens // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subIngredients: null == subIngredients
          ? _value.subIngredients
          : subIngredients // ignore: cast_nullable_to_non_nullable
              as List<String>,
      seedOilRisk: null == seedOilRisk
          ? _value.seedOilRisk
          : seedOilRisk // ignore: cast_nullable_to_non_nullable
              as bool,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IngredientAnalysisImplCopyWith<$Res>
    implements $IngredientAnalysisCopyWith<$Res> {
  factory _$$IngredientAnalysisImplCopyWith(_$IngredientAnalysisImpl value,
          $Res Function(_$IngredientAnalysisImpl) then) =
      __$$IngredientAnalysisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ingredient_name') String ingredientName,
      @JsonKey(name: 'common_allergens') List<String> commonAllergens,
      @JsonKey(name: 'possible_allergens') List<String> possibleAllergens,
      @JsonKey(name: 'sub_ingredients') List<String> subIngredients,
      @JsonKey(name: 'seed_oil_risk') bool seedOilRisk,
      double confidence});
}

/// @nodoc
class __$$IngredientAnalysisImplCopyWithImpl<$Res>
    extends _$IngredientAnalysisCopyWithImpl<$Res, _$IngredientAnalysisImpl>
    implements _$$IngredientAnalysisImplCopyWith<$Res> {
  __$$IngredientAnalysisImplCopyWithImpl(_$IngredientAnalysisImpl _value,
      $Res Function(_$IngredientAnalysisImpl) _then)
      : super(_value, _then);

  /// Create a copy of IngredientAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ingredientName = null,
    Object? commonAllergens = null,
    Object? possibleAllergens = null,
    Object? subIngredients = null,
    Object? seedOilRisk = null,
    Object? confidence = null,
  }) {
    return _then(_$IngredientAnalysisImpl(
      ingredientName: null == ingredientName
          ? _value.ingredientName
          : ingredientName // ignore: cast_nullable_to_non_nullable
              as String,
      commonAllergens: null == commonAllergens
          ? _value._commonAllergens
          : commonAllergens // ignore: cast_nullable_to_non_nullable
              as List<String>,
      possibleAllergens: null == possibleAllergens
          ? _value._possibleAllergens
          : possibleAllergens // ignore: cast_nullable_to_non_nullable
              as List<String>,
      subIngredients: null == subIngredients
          ? _value._subIngredients
          : subIngredients // ignore: cast_nullable_to_non_nullable
              as List<String>,
      seedOilRisk: null == seedOilRisk
          ? _value.seedOilRisk
          : seedOilRisk // ignore: cast_nullable_to_non_nullable
              as bool,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientAnalysisImpl implements _IngredientAnalysis {
  const _$IngredientAnalysisImpl(
      {@JsonKey(name: 'ingredient_name') this.ingredientName = '',
      @JsonKey(name: 'common_allergens')
      final List<String> commonAllergens = const [],
      @JsonKey(name: 'possible_allergens')
      final List<String> possibleAllergens = const [],
      @JsonKey(name: 'sub_ingredients')
      final List<String> subIngredients = const [],
      @JsonKey(name: 'seed_oil_risk') this.seedOilRisk = false,
      this.confidence = 0.0})
      : _commonAllergens = commonAllergens,
        _possibleAllergens = possibleAllergens,
        _subIngredients = subIngredients;

  factory _$IngredientAnalysisImpl.fromJson(Map<String, dynamic> json) =>
      _$$IngredientAnalysisImplFromJson(json);

  @override
  @JsonKey(name: 'ingredient_name')
  final String ingredientName;
  final List<String> _commonAllergens;
  @override
  @JsonKey(name: 'common_allergens')
  List<String> get commonAllergens {
    if (_commonAllergens is EqualUnmodifiableListView) return _commonAllergens;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_commonAllergens);
  }

  final List<String> _possibleAllergens;
  @override
  @JsonKey(name: 'possible_allergens')
  List<String> get possibleAllergens {
    if (_possibleAllergens is EqualUnmodifiableListView)
      return _possibleAllergens;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_possibleAllergens);
  }

  final List<String> _subIngredients;
  @override
  @JsonKey(name: 'sub_ingredients')
  List<String> get subIngredients {
    if (_subIngredients is EqualUnmodifiableListView) return _subIngredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subIngredients);
  }

  @override
  @JsonKey(name: 'seed_oil_risk')
  final bool seedOilRisk;
  @override
  @JsonKey()
  final double confidence;

  @override
  String toString() {
    return 'IngredientAnalysis(ingredientName: $ingredientName, commonAllergens: $commonAllergens, possibleAllergens: $possibleAllergens, subIngredients: $subIngredients, seedOilRisk: $seedOilRisk, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientAnalysisImpl &&
            (identical(other.ingredientName, ingredientName) ||
                other.ingredientName == ingredientName) &&
            const DeepCollectionEquality()
                .equals(other._commonAllergens, _commonAllergens) &&
            const DeepCollectionEquality()
                .equals(other._possibleAllergens, _possibleAllergens) &&
            const DeepCollectionEquality()
                .equals(other._subIngredients, _subIngredients) &&
            (identical(other.seedOilRisk, seedOilRisk) ||
                other.seedOilRisk == seedOilRisk) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      ingredientName,
      const DeepCollectionEquality().hash(_commonAllergens),
      const DeepCollectionEquality().hash(_possibleAllergens),
      const DeepCollectionEquality().hash(_subIngredients),
      seedOilRisk,
      confidence);

  /// Create a copy of IngredientAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IngredientAnalysisImplCopyWith<_$IngredientAnalysisImpl> get copyWith =>
      __$$IngredientAnalysisImplCopyWithImpl<_$IngredientAnalysisImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IngredientAnalysisImplToJson(
      this,
    );
  }
}

abstract class _IngredientAnalysis implements IngredientAnalysis {
  const factory _IngredientAnalysis(
      {@JsonKey(name: 'ingredient_name') final String ingredientName,
      @JsonKey(name: 'common_allergens') final List<String> commonAllergens,
      @JsonKey(name: 'possible_allergens') final List<String> possibleAllergens,
      @JsonKey(name: 'sub_ingredients') final List<String> subIngredients,
      @JsonKey(name: 'seed_oil_risk') final bool seedOilRisk,
      final double confidence}) = _$IngredientAnalysisImpl;

  factory _IngredientAnalysis.fromJson(Map<String, dynamic> json) =
      _$IngredientAnalysisImpl.fromJson;

  @override
  @JsonKey(name: 'ingredient_name')
  String get ingredientName;
  @override
  @JsonKey(name: 'common_allergens')
  List<String> get commonAllergens;
  @override
  @JsonKey(name: 'possible_allergens')
  List<String> get possibleAllergens;
  @override
  @JsonKey(name: 'sub_ingredients')
  List<String> get subIngredients;
  @override
  @JsonKey(name: 'seed_oil_risk')
  bool get seedOilRisk;
  @override
  double get confidence;

  /// Create a copy of IngredientAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IngredientAnalysisImplCopyWith<_$IngredientAnalysisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FamilySafetyCheck _$FamilySafetyCheckFromJson(Map<String, dynamic> json) {
  return _FamilySafetyCheck.fromJson(json);
}

/// @nodoc
mixin _$FamilySafetyCheck {
  @JsonKey(name: 'member_id', fromJson: _idToString)
  String get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_name')
  String get memberName => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
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
      {@JsonKey(name: 'member_id', fromJson: _idToString) String memberId,
      @JsonKey(name: 'member_name') String memberName,
      String status,
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
    Object? status = null,
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
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
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
      {@JsonKey(name: 'member_id', fromJson: _idToString) String memberId,
      @JsonKey(name: 'member_name') String memberName,
      String status,
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
    Object? status = null,
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
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      warnings: null == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilySafetyCheckImpl extends _FamilySafetyCheck {
  const _$FamilySafetyCheckImpl(
      {@JsonKey(name: 'member_id', fromJson: _idToString) this.memberId = '',
      @JsonKey(name: 'member_name') this.memberName = '',
      this.status = 'safe',
      final List<String> warnings = const []})
      : _warnings = warnings,
        super._();

  factory _$FamilySafetyCheckImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilySafetyCheckImplFromJson(json);

  @override
  @JsonKey(name: 'member_id', fromJson: _idToString)
  final String memberId;
  @override
  @JsonKey(name: 'member_name')
  final String memberName;
  @override
  @JsonKey()
  final String status;
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
    return 'FamilySafetyCheck(memberId: $memberId, memberName: $memberName, status: $status, warnings: $warnings)';
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
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, memberId, memberName, status,
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

abstract class _FamilySafetyCheck extends FamilySafetyCheck {
  const factory _FamilySafetyCheck(
      {@JsonKey(name: 'member_id', fromJson: _idToString) final String memberId,
      @JsonKey(name: 'member_name') final String memberName,
      final String status,
      final List<String> warnings}) = _$FamilySafetyCheckImpl;
  const _FamilySafetyCheck._() : super._();

  factory _FamilySafetyCheck.fromJson(Map<String, dynamic> json) =
      _$FamilySafetyCheckImpl.fromJson;

  @override
  @JsonKey(name: 'member_id', fromJson: _idToString)
  String get memberId;
  @override
  @JsonKey(name: 'member_name')
  String get memberName;
  @override
  String get status;
  @override
  List<String> get warnings;

  /// Create a copy of FamilySafetyCheck
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilySafetyCheckImplCopyWith<_$FamilySafetyCheckImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
