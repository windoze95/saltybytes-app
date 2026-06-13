// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Recipe _$RecipeFromJson(Map<String, dynamic> json) {
  return _Recipe.fromJson(json);
}

/// @nodoc
mixin _$Recipe {
  @JsonKey(fromJson: _idToString)
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _idToString)
  String get ownerId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _emptyStringToNull)
  String? get imageUrl => throw _privateConstructorUsedError;
  List<Ingredient> get ingredients => throw _privateConstructorUsedError;
  List<String> get instructions => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  int? get cookTimeMinutes => throw _privateConstructorUsedError;
  String? get sourceUrl => throw _privateConstructorUsedError;
  String get unitSystem => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int? get portions => throw _privateConstructorUsedError;
  String? get portionSize => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _idToStringOrNull)
  String? get parentRecipeId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Recipe to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipeCopyWith<Recipe> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeCopyWith<$Res> {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) then) =
      _$RecipeCopyWithImpl<$Res, Recipe>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _idToString) String id,
      String title,
      @JsonKey(fromJson: _idToString) String ownerId,
      @JsonKey(fromJson: _emptyStringToNull) String? imageUrl,
      List<Ingredient> ingredients,
      List<String> instructions,
      List<String> tags,
      int? cookTimeMinutes,
      String? sourceUrl,
      String unitSystem,
      String status,
      int? portions,
      String? portionSize,
      @JsonKey(fromJson: _idToStringOrNull) String? parentRecipeId,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$RecipeCopyWithImpl<$Res, $Val extends Recipe>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? ownerId = null,
    Object? imageUrl = freezed,
    Object? ingredients = null,
    Object? instructions = null,
    Object? tags = null,
    Object? cookTimeMinutes = freezed,
    Object? sourceUrl = freezed,
    Object? unitSystem = null,
    Object? status = null,
    Object? portions = freezed,
    Object? portionSize = freezed,
    Object? parentRecipeId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredients: null == ingredients
          ? _value.ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      instructions: null == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      cookTimeMinutes: freezed == cookTimeMinutes
          ? _value.cookTimeMinutes
          : cookTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      sourceUrl: freezed == sourceUrl
          ? _value.sourceUrl
          : sourceUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      unitSystem: null == unitSystem
          ? _value.unitSystem
          : unitSystem // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      portions: freezed == portions
          ? _value.portions
          : portions // ignore: cast_nullable_to_non_nullable
              as int?,
      portionSize: freezed == portionSize
          ? _value.portionSize
          : portionSize // ignore: cast_nullable_to_non_nullable
              as String?,
      parentRecipeId: freezed == parentRecipeId
          ? _value.parentRecipeId
          : parentRecipeId // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$RecipeImplCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$$RecipeImplCopyWith(
          _$RecipeImpl value, $Res Function(_$RecipeImpl) then) =
      __$$RecipeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _idToString) String id,
      String title,
      @JsonKey(fromJson: _idToString) String ownerId,
      @JsonKey(fromJson: _emptyStringToNull) String? imageUrl,
      List<Ingredient> ingredients,
      List<String> instructions,
      List<String> tags,
      int? cookTimeMinutes,
      String? sourceUrl,
      String unitSystem,
      String status,
      int? portions,
      String? portionSize,
      @JsonKey(fromJson: _idToStringOrNull) String? parentRecipeId,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$RecipeImplCopyWithImpl<$Res>
    extends _$RecipeCopyWithImpl<$Res, _$RecipeImpl>
    implements _$$RecipeImplCopyWith<$Res> {
  __$$RecipeImplCopyWithImpl(
      _$RecipeImpl _value, $Res Function(_$RecipeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? ownerId = null,
    Object? imageUrl = freezed,
    Object? ingredients = null,
    Object? instructions = null,
    Object? tags = null,
    Object? cookTimeMinutes = freezed,
    Object? sourceUrl = freezed,
    Object? unitSystem = null,
    Object? status = null,
    Object? portions = freezed,
    Object? portionSize = freezed,
    Object? parentRecipeId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$RecipeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredients: null == ingredients
          ? _value._ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      instructions: null == instructions
          ? _value._instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      cookTimeMinutes: freezed == cookTimeMinutes
          ? _value.cookTimeMinutes
          : cookTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      sourceUrl: freezed == sourceUrl
          ? _value.sourceUrl
          : sourceUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      unitSystem: null == unitSystem
          ? _value.unitSystem
          : unitSystem // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      portions: freezed == portions
          ? _value.portions
          : portions // ignore: cast_nullable_to_non_nullable
              as int?,
      portionSize: freezed == portionSize
          ? _value.portionSize
          : portionSize // ignore: cast_nullable_to_non_nullable
              as String?,
      parentRecipeId: freezed == parentRecipeId
          ? _value.parentRecipeId
          : parentRecipeId // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$RecipeImpl implements _Recipe {
  const _$RecipeImpl(
      {@JsonKey(fromJson: _idToString) required this.id,
      required this.title,
      @JsonKey(fromJson: _idToString) required this.ownerId,
      @JsonKey(fromJson: _emptyStringToNull) this.imageUrl,
      final List<Ingredient> ingredients = const [],
      final List<String> instructions = const [],
      final List<String> tags = const [],
      this.cookTimeMinutes,
      this.sourceUrl,
      this.unitSystem = 'us_customary',
      this.status = 'ready',
      this.portions,
      this.portionSize,
      @JsonKey(fromJson: _idToStringOrNull) this.parentRecipeId,
      this.createdAt,
      this.updatedAt})
      : _ingredients = ingredients,
        _instructions = instructions,
        _tags = tags;

  factory _$RecipeImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeImplFromJson(json);

  @override
  @JsonKey(fromJson: _idToString)
  final String id;
  @override
  final String title;
  @override
  @JsonKey(fromJson: _idToString)
  final String ownerId;
  @override
  @JsonKey(fromJson: _emptyStringToNull)
  final String? imageUrl;
  final List<Ingredient> _ingredients;
  @override
  @JsonKey()
  List<Ingredient> get ingredients {
    if (_ingredients is EqualUnmodifiableListView) return _ingredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredients);
  }

  final List<String> _instructions;
  @override
  @JsonKey()
  List<String> get instructions {
    if (_instructions is EqualUnmodifiableListView) return _instructions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_instructions);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final int? cookTimeMinutes;
  @override
  final String? sourceUrl;
  @override
  @JsonKey()
  final String unitSystem;
  @override
  @JsonKey()
  final String status;
  @override
  final int? portions;
  @override
  final String? portionSize;
  @override
  @JsonKey(fromJson: _idToStringOrNull)
  final String? parentRecipeId;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, ownerId: $ownerId, imageUrl: $imageUrl, ingredients: $ingredients, instructions: $instructions, tags: $tags, cookTimeMinutes: $cookTimeMinutes, sourceUrl: $sourceUrl, unitSystem: $unitSystem, status: $status, portions: $portions, portionSize: $portionSize, parentRecipeId: $parentRecipeId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._ingredients, _ingredients) &&
            const DeepCollectionEquality()
                .equals(other._instructions, _instructions) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.cookTimeMinutes, cookTimeMinutes) ||
                other.cookTimeMinutes == cookTimeMinutes) &&
            (identical(other.sourceUrl, sourceUrl) ||
                other.sourceUrl == sourceUrl) &&
            (identical(other.unitSystem, unitSystem) ||
                other.unitSystem == unitSystem) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.portions, portions) ||
                other.portions == portions) &&
            (identical(other.portionSize, portionSize) ||
                other.portionSize == portionSize) &&
            (identical(other.parentRecipeId, parentRecipeId) ||
                other.parentRecipeId == parentRecipeId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      ownerId,
      imageUrl,
      const DeepCollectionEquality().hash(_ingredients),
      const DeepCollectionEquality().hash(_instructions),
      const DeepCollectionEquality().hash(_tags),
      cookTimeMinutes,
      sourceUrl,
      unitSystem,
      status,
      portions,
      portionSize,
      parentRecipeId,
      createdAt,
      updatedAt);

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeImplCopyWith<_$RecipeImpl> get copyWith =>
      __$$RecipeImplCopyWithImpl<_$RecipeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeImplToJson(
      this,
    );
  }
}

abstract class _Recipe implements Recipe {
  const factory _Recipe(
      {@JsonKey(fromJson: _idToString) required final String id,
      required final String title,
      @JsonKey(fromJson: _idToString) required final String ownerId,
      @JsonKey(fromJson: _emptyStringToNull) final String? imageUrl,
      final List<Ingredient> ingredients,
      final List<String> instructions,
      final List<String> tags,
      final int? cookTimeMinutes,
      final String? sourceUrl,
      final String unitSystem,
      final String status,
      final int? portions,
      final String? portionSize,
      @JsonKey(fromJson: _idToStringOrNull) final String? parentRecipeId,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$RecipeImpl;

  factory _Recipe.fromJson(Map<String, dynamic> json) = _$RecipeImpl.fromJson;

  @override
  @JsonKey(fromJson: _idToString)
  String get id;
  @override
  String get title;
  @override
  @JsonKey(fromJson: _idToString)
  String get ownerId;
  @override
  @JsonKey(fromJson: _emptyStringToNull)
  String? get imageUrl;
  @override
  List<Ingredient> get ingredients;
  @override
  List<String> get instructions;
  @override
  List<String> get tags;
  @override
  int? get cookTimeMinutes;
  @override
  String? get sourceUrl;
  @override
  String get unitSystem;
  @override
  String get status;
  @override
  int? get portions;
  @override
  String? get portionSize;
  @override
  @JsonKey(fromJson: _idToStringOrNull)
  String? get parentRecipeId;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipeImplCopyWith<_$RecipeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Ingredient _$IngredientFromJson(Map<String, dynamic> json) {
  return _Ingredient.fromJson(json);
}

/// @nodoc
mixin _$Ingredient {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount')
  double? get amount => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  @JsonKey(name: 'metric_unit')
  String? get metricUnit => throw _privateConstructorUsedError;
  @JsonKey(name: 'metric_amount')
  double? get metricAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'original_text')
  String? get originalText => throw _privateConstructorUsedError;

  /// Serializes this Ingredient to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IngredientCopyWith<Ingredient> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IngredientCopyWith<$Res> {
  factory $IngredientCopyWith(
          Ingredient value, $Res Function(Ingredient) then) =
      _$IngredientCopyWithImpl<$Res, Ingredient>;
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'amount') double? amount,
      String? unit,
      @JsonKey(name: 'metric_unit') String? metricUnit,
      @JsonKey(name: 'metric_amount') double? metricAmount,
      @JsonKey(name: 'original_text') String? originalText});
}

/// @nodoc
class _$IngredientCopyWithImpl<$Res, $Val extends Ingredient>
    implements $IngredientCopyWith<$Res> {
  _$IngredientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? amount = freezed,
    Object? unit = freezed,
    Object? metricUnit = freezed,
    Object? metricAmount = freezed,
    Object? originalText = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      metricUnit: freezed == metricUnit
          ? _value.metricUnit
          : metricUnit // ignore: cast_nullable_to_non_nullable
              as String?,
      metricAmount: freezed == metricAmount
          ? _value.metricAmount
          : metricAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      originalText: freezed == originalText
          ? _value.originalText
          : originalText // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IngredientImplCopyWith<$Res>
    implements $IngredientCopyWith<$Res> {
  factory _$$IngredientImplCopyWith(
          _$IngredientImpl value, $Res Function(_$IngredientImpl) then) =
      __$$IngredientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'amount') double? amount,
      String? unit,
      @JsonKey(name: 'metric_unit') String? metricUnit,
      @JsonKey(name: 'metric_amount') double? metricAmount,
      @JsonKey(name: 'original_text') String? originalText});
}

/// @nodoc
class __$$IngredientImplCopyWithImpl<$Res>
    extends _$IngredientCopyWithImpl<$Res, _$IngredientImpl>
    implements _$$IngredientImplCopyWith<$Res> {
  __$$IngredientImplCopyWithImpl(
      _$IngredientImpl _value, $Res Function(_$IngredientImpl) _then)
      : super(_value, _then);

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? amount = freezed,
    Object? unit = freezed,
    Object? metricUnit = freezed,
    Object? metricAmount = freezed,
    Object? originalText = freezed,
  }) {
    return _then(_$IngredientImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      metricUnit: freezed == metricUnit
          ? _value.metricUnit
          : metricUnit // ignore: cast_nullable_to_non_nullable
              as String?,
      metricAmount: freezed == metricAmount
          ? _value.metricAmount
          : metricAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      originalText: freezed == originalText
          ? _value.originalText
          : originalText // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientImpl implements _Ingredient {
  const _$IngredientImpl(
      {required this.name,
      @JsonKey(name: 'amount') this.amount,
      this.unit,
      @JsonKey(name: 'metric_unit') this.metricUnit,
      @JsonKey(name: 'metric_amount') this.metricAmount,
      @JsonKey(name: 'original_text') this.originalText});

  factory _$IngredientImpl.fromJson(Map<String, dynamic> json) =>
      _$$IngredientImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'amount')
  final double? amount;
  @override
  final String? unit;
  @override
  @JsonKey(name: 'metric_unit')
  final String? metricUnit;
  @override
  @JsonKey(name: 'metric_amount')
  final double? metricAmount;
  @override
  @JsonKey(name: 'original_text')
  final String? originalText;

  @override
  String toString() {
    return 'Ingredient(name: $name, amount: $amount, unit: $unit, metricUnit: $metricUnit, metricAmount: $metricAmount, originalText: $originalText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.metricUnit, metricUnit) ||
                other.metricUnit == metricUnit) &&
            (identical(other.metricAmount, metricAmount) ||
                other.metricAmount == metricAmount) &&
            (identical(other.originalText, originalText) ||
                other.originalText == originalText));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, amount, unit, metricUnit, metricAmount, originalText);

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IngredientImplCopyWith<_$IngredientImpl> get copyWith =>
      __$$IngredientImplCopyWithImpl<_$IngredientImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IngredientImplToJson(
      this,
    );
  }
}

abstract class _Ingredient implements Ingredient {
  const factory _Ingredient(
          {required final String name,
          @JsonKey(name: 'amount') final double? amount,
          final String? unit,
          @JsonKey(name: 'metric_unit') final String? metricUnit,
          @JsonKey(name: 'metric_amount') final double? metricAmount,
          @JsonKey(name: 'original_text') final String? originalText}) =
      _$IngredientImpl;

  factory _Ingredient.fromJson(Map<String, dynamic> json) =
      _$IngredientImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'amount')
  double? get amount;
  @override
  String? get unit;
  @override
  @JsonKey(name: 'metric_unit')
  String? get metricUnit;
  @override
  @JsonKey(name: 'metric_amount')
  double? get metricAmount;
  @override
  @JsonKey(name: 'original_text')
  String? get originalText;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IngredientImplCopyWith<_$IngredientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeNode _$RecipeNodeFromJson(Map<String, dynamic> json) {
  return _RecipeNode.fromJson(json);
}

/// @nodoc
mixin _$RecipeNode {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_id')
  int? get parentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'branch_name')
  String get branchName => throw _privateConstructorUsedError;
  String get summary => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_ephemeral')
  bool get isEphemeral => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by_id')
  int? get createdById => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  List<RecipeNode> get children => throw _privateConstructorUsedError;

  /// Serializes this RecipeNode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecipeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipeNodeCopyWith<RecipeNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeNodeCopyWith<$Res> {
  factory $RecipeNodeCopyWith(
          RecipeNode value, $Res Function(RecipeNode) then) =
      _$RecipeNodeCopyWithImpl<$Res, RecipeNode>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'parent_id') int? parentId,
      @JsonKey(name: 'branch_name') String branchName,
      String summary,
      String type,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'is_ephemeral') bool isEphemeral,
      @JsonKey(name: 'created_by_id') int? createdById,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      List<RecipeNode> children});
}

/// @nodoc
class _$RecipeNodeCopyWithImpl<$Res, $Val extends RecipeNode>
    implements $RecipeNodeCopyWith<$Res> {
  _$RecipeNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecipeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? parentId = freezed,
    Object? branchName = null,
    Object? summary = null,
    Object? type = null,
    Object? isActive = null,
    Object? isEphemeral = null,
    Object? createdById = freezed,
    Object? createdAt = freezed,
    Object? children = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as int?,
      branchName: null == branchName
          ? _value.branchName
          : branchName // ignore: cast_nullable_to_non_nullable
              as String,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isEphemeral: null == isEphemeral
          ? _value.isEphemeral
          : isEphemeral // ignore: cast_nullable_to_non_nullable
              as bool,
      createdById: freezed == createdById
          ? _value.createdById
          : createdById // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      children: null == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as List<RecipeNode>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeNodeImplCopyWith<$Res>
    implements $RecipeNodeCopyWith<$Res> {
  factory _$$RecipeNodeImplCopyWith(
          _$RecipeNodeImpl value, $Res Function(_$RecipeNodeImpl) then) =
      __$$RecipeNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'parent_id') int? parentId,
      @JsonKey(name: 'branch_name') String branchName,
      String summary,
      String type,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'is_ephemeral') bool isEphemeral,
      @JsonKey(name: 'created_by_id') int? createdById,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      List<RecipeNode> children});
}

/// @nodoc
class __$$RecipeNodeImplCopyWithImpl<$Res>
    extends _$RecipeNodeCopyWithImpl<$Res, _$RecipeNodeImpl>
    implements _$$RecipeNodeImplCopyWith<$Res> {
  __$$RecipeNodeImplCopyWithImpl(
      _$RecipeNodeImpl _value, $Res Function(_$RecipeNodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecipeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? parentId = freezed,
    Object? branchName = null,
    Object? summary = null,
    Object? type = null,
    Object? isActive = null,
    Object? isEphemeral = null,
    Object? createdById = freezed,
    Object? createdAt = freezed,
    Object? children = null,
  }) {
    return _then(_$RecipeNodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as int?,
      branchName: null == branchName
          ? _value.branchName
          : branchName // ignore: cast_nullable_to_non_nullable
              as String,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isEphemeral: null == isEphemeral
          ? _value.isEphemeral
          : isEphemeral // ignore: cast_nullable_to_non_nullable
              as bool,
      createdById: freezed == createdById
          ? _value.createdById
          : createdById // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      children: null == children
          ? _value._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<RecipeNode>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeNodeImpl implements _RecipeNode {
  const _$RecipeNodeImpl(
      {required this.id,
      @JsonKey(name: 'parent_id') this.parentId,
      @JsonKey(name: 'branch_name') this.branchName = 'original',
      this.summary = '',
      this.type = '',
      @JsonKey(name: 'is_active') this.isActive = false,
      @JsonKey(name: 'is_ephemeral') this.isEphemeral = false,
      @JsonKey(name: 'created_by_id') this.createdById,
      @JsonKey(name: 'created_at') this.createdAt,
      final List<RecipeNode> children = const []})
      : _children = children;

  factory _$RecipeNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeNodeImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'parent_id')
  final int? parentId;
  @override
  @JsonKey(name: 'branch_name')
  final String branchName;
  @override
  @JsonKey()
  final String summary;
  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'is_ephemeral')
  final bool isEphemeral;
  @override
  @JsonKey(name: 'created_by_id')
  final int? createdById;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  final List<RecipeNode> _children;
  @override
  @JsonKey()
  List<RecipeNode> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  @override
  String toString() {
    return 'RecipeNode(id: $id, parentId: $parentId, branchName: $branchName, summary: $summary, type: $type, isActive: $isActive, isEphemeral: $isEphemeral, createdById: $createdById, createdAt: $createdAt, children: $children)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeNodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.branchName, branchName) ||
                other.branchName == branchName) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isEphemeral, isEphemeral) ||
                other.isEphemeral == isEphemeral) &&
            (identical(other.createdById, createdById) ||
                other.createdById == createdById) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._children, _children));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      parentId,
      branchName,
      summary,
      type,
      isActive,
      isEphemeral,
      createdById,
      createdAt,
      const DeepCollectionEquality().hash(_children));

  /// Create a copy of RecipeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeNodeImplCopyWith<_$RecipeNodeImpl> get copyWith =>
      __$$RecipeNodeImplCopyWithImpl<_$RecipeNodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeNodeImplToJson(
      this,
    );
  }
}

abstract class _RecipeNode implements RecipeNode {
  const factory _RecipeNode(
      {required final int id,
      @JsonKey(name: 'parent_id') final int? parentId,
      @JsonKey(name: 'branch_name') final String branchName,
      final String summary,
      final String type,
      @JsonKey(name: 'is_active') final bool isActive,
      @JsonKey(name: 'is_ephemeral') final bool isEphemeral,
      @JsonKey(name: 'created_by_id') final int? createdById,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      final List<RecipeNode> children}) = _$RecipeNodeImpl;

  factory _RecipeNode.fromJson(Map<String, dynamic> json) =
      _$RecipeNodeImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'parent_id')
  int? get parentId;
  @override
  @JsonKey(name: 'branch_name')
  String get branchName;
  @override
  String get summary;
  @override
  String get type;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'is_ephemeral')
  bool get isEphemeral;
  @override
  @JsonKey(name: 'created_by_id')
  int? get createdById;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  List<RecipeNode> get children;

  /// Create a copy of RecipeNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipeNodeImplCopyWith<_$RecipeNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeSearchResult _$RecipeSearchResultFromJson(Map<String, dynamic> json) {
  return _RecipeSearchResult.fromJson(json);
}

/// @nodoc
mixin _$RecipeSearchResult {
  List<Recipe> get recipes => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get pageSize => throw _privateConstructorUsedError;

  /// Serializes this RecipeSearchResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecipeSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipeSearchResultCopyWith<RecipeSearchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeSearchResultCopyWith<$Res> {
  factory $RecipeSearchResultCopyWith(
          RecipeSearchResult value, $Res Function(RecipeSearchResult) then) =
      _$RecipeSearchResultCopyWithImpl<$Res, RecipeSearchResult>;
  @useResult
  $Res call({List<Recipe> recipes, int total, int page, int pageSize});
}

/// @nodoc
class _$RecipeSearchResultCopyWithImpl<$Res, $Val extends RecipeSearchResult>
    implements $RecipeSearchResultCopyWith<$Res> {
  _$RecipeSearchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecipeSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipes = null,
    Object? total = null,
    Object? page = null,
    Object? pageSize = null,
  }) {
    return _then(_value.copyWith(
      recipes: null == recipes
          ? _value.recipes
          : recipes // ignore: cast_nullable_to_non_nullable
              as List<Recipe>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeSearchResultImplCopyWith<$Res>
    implements $RecipeSearchResultCopyWith<$Res> {
  factory _$$RecipeSearchResultImplCopyWith(_$RecipeSearchResultImpl value,
          $Res Function(_$RecipeSearchResultImpl) then) =
      __$$RecipeSearchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Recipe> recipes, int total, int page, int pageSize});
}

/// @nodoc
class __$$RecipeSearchResultImplCopyWithImpl<$Res>
    extends _$RecipeSearchResultCopyWithImpl<$Res, _$RecipeSearchResultImpl>
    implements _$$RecipeSearchResultImplCopyWith<$Res> {
  __$$RecipeSearchResultImplCopyWithImpl(_$RecipeSearchResultImpl _value,
      $Res Function(_$RecipeSearchResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecipeSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipes = null,
    Object? total = null,
    Object? page = null,
    Object? pageSize = null,
  }) {
    return _then(_$RecipeSearchResultImpl(
      recipes: null == recipes
          ? _value._recipes
          : recipes // ignore: cast_nullable_to_non_nullable
              as List<Recipe>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeSearchResultImpl implements _RecipeSearchResult {
  const _$RecipeSearchResultImpl(
      {required final List<Recipe> recipes,
      required this.total,
      required this.page,
      required this.pageSize})
      : _recipes = recipes;

  factory _$RecipeSearchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeSearchResultImplFromJson(json);

  final List<Recipe> _recipes;
  @override
  List<Recipe> get recipes {
    if (_recipes is EqualUnmodifiableListView) return _recipes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recipes);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int pageSize;

  @override
  String toString() {
    return 'RecipeSearchResult(recipes: $recipes, total: $total, page: $page, pageSize: $pageSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeSearchResultImpl &&
            const DeepCollectionEquality().equals(other._recipes, _recipes) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_recipes), total, page, pageSize);

  /// Create a copy of RecipeSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeSearchResultImplCopyWith<_$RecipeSearchResultImpl> get copyWith =>
      __$$RecipeSearchResultImplCopyWithImpl<_$RecipeSearchResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeSearchResultImplToJson(
      this,
    );
  }
}

abstract class _RecipeSearchResult implements RecipeSearchResult {
  const factory _RecipeSearchResult(
      {required final List<Recipe> recipes,
      required final int total,
      required final int page,
      required final int pageSize}) = _$RecipeSearchResultImpl;

  factory _RecipeSearchResult.fromJson(Map<String, dynamic> json) =
      _$RecipeSearchResultImpl.fromJson;

  @override
  List<Recipe> get recipes;
  @override
  int get total;
  @override
  int get page;
  @override
  int get pageSize;

  /// Create a copy of RecipeSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipeSearchResultImplCopyWith<_$RecipeSearchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
