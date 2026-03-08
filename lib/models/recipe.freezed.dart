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
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  List<Ingredient> get ingredients => throw _privateConstructorUsedError;
  List<String> get instructions => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String? get cuisine => throw _privateConstructorUsedError;
  String? get difficulty => throw _privateConstructorUsedError;
  int? get prepTimeMinutes => throw _privateConstructorUsedError;
  int? get cookTimeMinutes => throw _privateConstructorUsedError;
  int get servings => throw _privateConstructorUsedError;
  String? get sourceUrl => throw _privateConstructorUsedError;
  bool get isPublic => throw _privateConstructorUsedError;
  List<String> get allergenTags => throw _privateConstructorUsedError;
  String get unitSystem => throw _privateConstructorUsedError;
  String get currentBranch => throw _privateConstructorUsedError;
  String? get parentRecipeId => throw _privateConstructorUsedError;
  int? get version => throw _privateConstructorUsedError;
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
      {String id,
      String title,
      String? description,
      String ownerId,
      String? imageUrl,
      List<Ingredient> ingredients,
      List<String> instructions,
      List<String> tags,
      String? cuisine,
      String? difficulty,
      int? prepTimeMinutes,
      int? cookTimeMinutes,
      int servings,
      String? sourceUrl,
      bool isPublic,
      List<String> allergenTags,
      String unitSystem,
      String currentBranch,
      String? parentRecipeId,
      int? version,
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
    Object? description = freezed,
    Object? ownerId = null,
    Object? imageUrl = freezed,
    Object? ingredients = null,
    Object? instructions = null,
    Object? tags = null,
    Object? cuisine = freezed,
    Object? difficulty = freezed,
    Object? prepTimeMinutes = freezed,
    Object? cookTimeMinutes = freezed,
    Object? servings = null,
    Object? sourceUrl = freezed,
    Object? isPublic = null,
    Object? allergenTags = null,
    Object? unitSystem = null,
    Object? currentBranch = null,
    Object? parentRecipeId = freezed,
    Object? version = freezed,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
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
      cuisine: freezed == cuisine
          ? _value.cuisine
          : cuisine // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      prepTimeMinutes: freezed == prepTimeMinutes
          ? _value.prepTimeMinutes
          : prepTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      cookTimeMinutes: freezed == cookTimeMinutes
          ? _value.cookTimeMinutes
          : cookTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      servings: null == servings
          ? _value.servings
          : servings // ignore: cast_nullable_to_non_nullable
              as int,
      sourceUrl: freezed == sourceUrl
          ? _value.sourceUrl
          : sourceUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      allergenTags: null == allergenTags
          ? _value.allergenTags
          : allergenTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      unitSystem: null == unitSystem
          ? _value.unitSystem
          : unitSystem // ignore: cast_nullable_to_non_nullable
              as String,
      currentBranch: null == currentBranch
          ? _value.currentBranch
          : currentBranch // ignore: cast_nullable_to_non_nullable
              as String,
      parentRecipeId: freezed == parentRecipeId
          ? _value.parentRecipeId
          : parentRecipeId // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int?,
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
      {String id,
      String title,
      String? description,
      String ownerId,
      String? imageUrl,
      List<Ingredient> ingredients,
      List<String> instructions,
      List<String> tags,
      String? cuisine,
      String? difficulty,
      int? prepTimeMinutes,
      int? cookTimeMinutes,
      int servings,
      String? sourceUrl,
      bool isPublic,
      List<String> allergenTags,
      String unitSystem,
      String currentBranch,
      String? parentRecipeId,
      int? version,
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
    Object? description = freezed,
    Object? ownerId = null,
    Object? imageUrl = freezed,
    Object? ingredients = null,
    Object? instructions = null,
    Object? tags = null,
    Object? cuisine = freezed,
    Object? difficulty = freezed,
    Object? prepTimeMinutes = freezed,
    Object? cookTimeMinutes = freezed,
    Object? servings = null,
    Object? sourceUrl = freezed,
    Object? isPublic = null,
    Object? allergenTags = null,
    Object? unitSystem = null,
    Object? currentBranch = null,
    Object? parentRecipeId = freezed,
    Object? version = freezed,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
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
      cuisine: freezed == cuisine
          ? _value.cuisine
          : cuisine // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      prepTimeMinutes: freezed == prepTimeMinutes
          ? _value.prepTimeMinutes
          : prepTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      cookTimeMinutes: freezed == cookTimeMinutes
          ? _value.cookTimeMinutes
          : cookTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      servings: null == servings
          ? _value.servings
          : servings // ignore: cast_nullable_to_non_nullable
              as int,
      sourceUrl: freezed == sourceUrl
          ? _value.sourceUrl
          : sourceUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      allergenTags: null == allergenTags
          ? _value._allergenTags
          : allergenTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      unitSystem: null == unitSystem
          ? _value.unitSystem
          : unitSystem // ignore: cast_nullable_to_non_nullable
              as String,
      currentBranch: null == currentBranch
          ? _value.currentBranch
          : currentBranch // ignore: cast_nullable_to_non_nullable
              as String,
      parentRecipeId: freezed == parentRecipeId
          ? _value.parentRecipeId
          : parentRecipeId // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int?,
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
      {required this.id,
      required this.title,
      this.description,
      required this.ownerId,
      this.imageUrl,
      final List<Ingredient> ingredients = const [],
      final List<String> instructions = const [],
      final List<String> tags = const [],
      this.cuisine,
      this.difficulty,
      this.prepTimeMinutes,
      this.cookTimeMinutes,
      this.servings = 4,
      this.sourceUrl,
      this.isPublic = false,
      final List<String> allergenTags = const [],
      this.unitSystem = 'us_customary',
      this.currentBranch = 'main',
      this.parentRecipeId,
      this.version,
      this.createdAt,
      this.updatedAt})
      : _ingredients = ingredients,
        _instructions = instructions,
        _tags = tags,
        _allergenTags = allergenTags;

  factory _$RecipeImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String ownerId;
  @override
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
  final String? cuisine;
  @override
  final String? difficulty;
  @override
  final int? prepTimeMinutes;
  @override
  final int? cookTimeMinutes;
  @override
  @JsonKey()
  final int servings;
  @override
  final String? sourceUrl;
  @override
  @JsonKey()
  final bool isPublic;
  final List<String> _allergenTags;
  @override
  @JsonKey()
  List<String> get allergenTags {
    if (_allergenTags is EqualUnmodifiableListView) return _allergenTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allergenTags);
  }

  @override
  @JsonKey()
  final String unitSystem;
  @override
  @JsonKey()
  final String currentBranch;
  @override
  final String? parentRecipeId;
  @override
  final int? version;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, description: $description, ownerId: $ownerId, imageUrl: $imageUrl, ingredients: $ingredients, instructions: $instructions, tags: $tags, cuisine: $cuisine, difficulty: $difficulty, prepTimeMinutes: $prepTimeMinutes, cookTimeMinutes: $cookTimeMinutes, servings: $servings, sourceUrl: $sourceUrl, isPublic: $isPublic, allergenTags: $allergenTags, unitSystem: $unitSystem, currentBranch: $currentBranch, parentRecipeId: $parentRecipeId, version: $version, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._ingredients, _ingredients) &&
            const DeepCollectionEquality()
                .equals(other._instructions, _instructions) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.cuisine, cuisine) || other.cuisine == cuisine) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.prepTimeMinutes, prepTimeMinutes) ||
                other.prepTimeMinutes == prepTimeMinutes) &&
            (identical(other.cookTimeMinutes, cookTimeMinutes) ||
                other.cookTimeMinutes == cookTimeMinutes) &&
            (identical(other.servings, servings) ||
                other.servings == servings) &&
            (identical(other.sourceUrl, sourceUrl) ||
                other.sourceUrl == sourceUrl) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            const DeepCollectionEquality()
                .equals(other._allergenTags, _allergenTags) &&
            (identical(other.unitSystem, unitSystem) ||
                other.unitSystem == unitSystem) &&
            (identical(other.currentBranch, currentBranch) ||
                other.currentBranch == currentBranch) &&
            (identical(other.parentRecipeId, parentRecipeId) ||
                other.parentRecipeId == parentRecipeId) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        title,
        description,
        ownerId,
        imageUrl,
        const DeepCollectionEquality().hash(_ingredients),
        const DeepCollectionEquality().hash(_instructions),
        const DeepCollectionEquality().hash(_tags),
        cuisine,
        difficulty,
        prepTimeMinutes,
        cookTimeMinutes,
        servings,
        sourceUrl,
        isPublic,
        const DeepCollectionEquality().hash(_allergenTags),
        unitSystem,
        currentBranch,
        parentRecipeId,
        version,
        createdAt,
        updatedAt
      ]);

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
      {required final String id,
      required final String title,
      final String? description,
      required final String ownerId,
      final String? imageUrl,
      final List<Ingredient> ingredients,
      final List<String> instructions,
      final List<String> tags,
      final String? cuisine,
      final String? difficulty,
      final int? prepTimeMinutes,
      final int? cookTimeMinutes,
      final int servings,
      final String? sourceUrl,
      final bool isPublic,
      final List<String> allergenTags,
      final String unitSystem,
      final String currentBranch,
      final String? parentRecipeId,
      final int? version,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$RecipeImpl;

  factory _Recipe.fromJson(Map<String, dynamic> json) = _$RecipeImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get ownerId;
  @override
  String? get imageUrl;
  @override
  List<Ingredient> get ingredients;
  @override
  List<String> get instructions;
  @override
  List<String> get tags;
  @override
  String? get cuisine;
  @override
  String? get difficulty;
  @override
  int? get prepTimeMinutes;
  @override
  int? get cookTimeMinutes;
  @override
  int get servings;
  @override
  String? get sourceUrl;
  @override
  bool get isPublic;
  @override
  List<String> get allergenTags;
  @override
  String get unitSystem;
  @override
  String get currentBranch;
  @override
  String? get parentRecipeId;
  @override
  int? get version;
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
  @JsonKey(name: 'original_text')
  String? get originalText => throw _privateConstructorUsedError;
  bool get optional => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;

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
      @JsonKey(name: 'original_text') String? originalText,
      bool optional,
      String? notes,
      String? category});
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
    Object? originalText = freezed,
    Object? optional = null,
    Object? notes = freezed,
    Object? category = freezed,
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
      originalText: freezed == originalText
          ? _value.originalText
          : originalText // ignore: cast_nullable_to_non_nullable
              as String?,
      optional: null == optional
          ? _value.optional
          : optional // ignore: cast_nullable_to_non_nullable
              as bool,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
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
      @JsonKey(name: 'original_text') String? originalText,
      bool optional,
      String? notes,
      String? category});
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
    Object? originalText = freezed,
    Object? optional = null,
    Object? notes = freezed,
    Object? category = freezed,
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
      originalText: freezed == originalText
          ? _value.originalText
          : originalText // ignore: cast_nullable_to_non_nullable
              as String?,
      optional: null == optional
          ? _value.optional
          : optional // ignore: cast_nullable_to_non_nullable
              as bool,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
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
      @JsonKey(name: 'original_text') this.originalText,
      this.optional = false,
      this.notes,
      this.category});

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
  @JsonKey(name: 'original_text')
  final String? originalText;
  @override
  @JsonKey()
  final bool optional;
  @override
  final String? notes;
  @override
  final String? category;

  @override
  String toString() {
    return 'Ingredient(name: $name, amount: $amount, unit: $unit, originalText: $originalText, optional: $optional, notes: $notes, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.originalText, originalText) ||
                other.originalText == originalText) &&
            (identical(other.optional, optional) ||
                other.optional == optional) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, amount, unit, originalText, optional, notes, category);

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
      @JsonKey(name: 'original_text') final String? originalText,
      final bool optional,
      final String? notes,
      final String? category}) = _$IngredientImpl;

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
  @JsonKey(name: 'original_text')
  String? get originalText;
  @override
  bool get optional;
  @override
  String? get notes;
  @override
  String? get category;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IngredientImplCopyWith<_$IngredientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeDef _$RecipeDefFromJson(Map<String, dynamic> json) {
  return _RecipeDef.fromJson(json);
}

/// @nodoc
mixin _$RecipeDef {
  String get id => throw _privateConstructorUsedError;
  String get recipeId => throw _privateConstructorUsedError;
  String get branch => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<Ingredient> get ingredients => throw _privateConstructorUsedError;
  List<String> get instructions => throw _privateConstructorUsedError;
  String? get commitMessage => throw _privateConstructorUsedError;
  String? get authorId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RecipeDef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecipeDef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipeDefCopyWith<RecipeDef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeDefCopyWith<$Res> {
  factory $RecipeDefCopyWith(RecipeDef value, $Res Function(RecipeDef) then) =
      _$RecipeDefCopyWithImpl<$Res, RecipeDef>;
  @useResult
  $Res call(
      {String id,
      String recipeId,
      String branch,
      int version,
      String title,
      String? description,
      List<Ingredient> ingredients,
      List<String> instructions,
      String? commitMessage,
      String? authorId,
      DateTime? createdAt});
}

/// @nodoc
class _$RecipeDefCopyWithImpl<$Res, $Val extends RecipeDef>
    implements $RecipeDefCopyWith<$Res> {
  _$RecipeDefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecipeDef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recipeId = null,
    Object? branch = null,
    Object? version = null,
    Object? title = null,
    Object? description = freezed,
    Object? ingredients = null,
    Object? instructions = null,
    Object? commitMessage = freezed,
    Object? authorId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      branch: null == branch
          ? _value.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredients: null == ingredients
          ? _value.ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      instructions: null == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      commitMessage: freezed == commitMessage
          ? _value.commitMessage
          : commitMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      authorId: freezed == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeDefImplCopyWith<$Res>
    implements $RecipeDefCopyWith<$Res> {
  factory _$$RecipeDefImplCopyWith(
          _$RecipeDefImpl value, $Res Function(_$RecipeDefImpl) then) =
      __$$RecipeDefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String recipeId,
      String branch,
      int version,
      String title,
      String? description,
      List<Ingredient> ingredients,
      List<String> instructions,
      String? commitMessage,
      String? authorId,
      DateTime? createdAt});
}

/// @nodoc
class __$$RecipeDefImplCopyWithImpl<$Res>
    extends _$RecipeDefCopyWithImpl<$Res, _$RecipeDefImpl>
    implements _$$RecipeDefImplCopyWith<$Res> {
  __$$RecipeDefImplCopyWithImpl(
      _$RecipeDefImpl _value, $Res Function(_$RecipeDefImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecipeDef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recipeId = null,
    Object? branch = null,
    Object? version = null,
    Object? title = null,
    Object? description = freezed,
    Object? ingredients = null,
    Object? instructions = null,
    Object? commitMessage = freezed,
    Object? authorId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$RecipeDefImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      branch: null == branch
          ? _value.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredients: null == ingredients
          ? _value._ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      instructions: null == instructions
          ? _value._instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      commitMessage: freezed == commitMessage
          ? _value.commitMessage
          : commitMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      authorId: freezed == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeDefImpl implements _RecipeDef {
  const _$RecipeDefImpl(
      {required this.id,
      required this.recipeId,
      required this.branch,
      required this.version,
      required this.title,
      this.description,
      final List<Ingredient> ingredients = const [],
      final List<String> instructions = const [],
      this.commitMessage,
      this.authorId,
      this.createdAt})
      : _ingredients = ingredients,
        _instructions = instructions;

  factory _$RecipeDefImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeDefImplFromJson(json);

  @override
  final String id;
  @override
  final String recipeId;
  @override
  final String branch;
  @override
  final int version;
  @override
  final String title;
  @override
  final String? description;
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

  @override
  final String? commitMessage;
  @override
  final String? authorId;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'RecipeDef(id: $id, recipeId: $recipeId, branch: $branch, version: $version, title: $title, description: $description, ingredients: $ingredients, instructions: $instructions, commitMessage: $commitMessage, authorId: $authorId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeDefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            (identical(other.branch, branch) || other.branch == branch) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._ingredients, _ingredients) &&
            const DeepCollectionEquality()
                .equals(other._instructions, _instructions) &&
            (identical(other.commitMessage, commitMessage) ||
                other.commitMessage == commitMessage) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      recipeId,
      branch,
      version,
      title,
      description,
      const DeepCollectionEquality().hash(_ingredients),
      const DeepCollectionEquality().hash(_instructions),
      commitMessage,
      authorId,
      createdAt);

  /// Create a copy of RecipeDef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeDefImplCopyWith<_$RecipeDefImpl> get copyWith =>
      __$$RecipeDefImplCopyWithImpl<_$RecipeDefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeDefImplToJson(
      this,
    );
  }
}

abstract class _RecipeDef implements RecipeDef {
  const factory _RecipeDef(
      {required final String id,
      required final String recipeId,
      required final String branch,
      required final int version,
      required final String title,
      final String? description,
      final List<Ingredient> ingredients,
      final List<String> instructions,
      final String? commitMessage,
      final String? authorId,
      final DateTime? createdAt}) = _$RecipeDefImpl;

  factory _RecipeDef.fromJson(Map<String, dynamic> json) =
      _$RecipeDefImpl.fromJson;

  @override
  String get id;
  @override
  String get recipeId;
  @override
  String get branch;
  @override
  int get version;
  @override
  String get title;
  @override
  String? get description;
  @override
  List<Ingredient> get ingredients;
  @override
  List<String> get instructions;
  @override
  String? get commitMessage;
  @override
  String? get authorId;
  @override
  DateTime? get createdAt;

  /// Create a copy of RecipeDef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipeDefImplCopyWith<_$RecipeDefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeNode _$RecipeNodeFromJson(Map<String, dynamic> json) {
  return _RecipeNode.fromJson(json);
}

/// @nodoc
mixin _$RecipeNode {
  String get branch => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  String? get parentBranch => throw _privateConstructorUsedError;
  int? get parentVersion => throw _privateConstructorUsedError;
  List<RecipeNode> get children => throw _privateConstructorUsedError;
  String? get commitMessage => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

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
      {String branch,
      int version,
      String? parentBranch,
      int? parentVersion,
      List<RecipeNode> children,
      String? commitMessage,
      DateTime? createdAt});
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
    Object? branch = null,
    Object? version = null,
    Object? parentBranch = freezed,
    Object? parentVersion = freezed,
    Object? children = null,
    Object? commitMessage = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      branch: null == branch
          ? _value.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      parentBranch: freezed == parentBranch
          ? _value.parentBranch
          : parentBranch // ignore: cast_nullable_to_non_nullable
              as String?,
      parentVersion: freezed == parentVersion
          ? _value.parentVersion
          : parentVersion // ignore: cast_nullable_to_non_nullable
              as int?,
      children: null == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as List<RecipeNode>,
      commitMessage: freezed == commitMessage
          ? _value.commitMessage
          : commitMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
      {String branch,
      int version,
      String? parentBranch,
      int? parentVersion,
      List<RecipeNode> children,
      String? commitMessage,
      DateTime? createdAt});
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
    Object? branch = null,
    Object? version = null,
    Object? parentBranch = freezed,
    Object? parentVersion = freezed,
    Object? children = null,
    Object? commitMessage = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$RecipeNodeImpl(
      branch: null == branch
          ? _value.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      parentBranch: freezed == parentBranch
          ? _value.parentBranch
          : parentBranch // ignore: cast_nullable_to_non_nullable
              as String?,
      parentVersion: freezed == parentVersion
          ? _value.parentVersion
          : parentVersion // ignore: cast_nullable_to_non_nullable
              as int?,
      children: null == children
          ? _value._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<RecipeNode>,
      commitMessage: freezed == commitMessage
          ? _value.commitMessage
          : commitMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeNodeImpl implements _RecipeNode {
  const _$RecipeNodeImpl(
      {required this.branch,
      required this.version,
      this.parentBranch,
      this.parentVersion,
      final List<RecipeNode> children = const [],
      this.commitMessage,
      this.createdAt})
      : _children = children;

  factory _$RecipeNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeNodeImplFromJson(json);

  @override
  final String branch;
  @override
  final int version;
  @override
  final String? parentBranch;
  @override
  final int? parentVersion;
  final List<RecipeNode> _children;
  @override
  @JsonKey()
  List<RecipeNode> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  @override
  final String? commitMessage;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'RecipeNode(branch: $branch, version: $version, parentBranch: $parentBranch, parentVersion: $parentVersion, children: $children, commitMessage: $commitMessage, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeNodeImpl &&
            (identical(other.branch, branch) || other.branch == branch) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.parentBranch, parentBranch) ||
                other.parentBranch == parentBranch) &&
            (identical(other.parentVersion, parentVersion) ||
                other.parentVersion == parentVersion) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            (identical(other.commitMessage, commitMessage) ||
                other.commitMessage == commitMessage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      branch,
      version,
      parentBranch,
      parentVersion,
      const DeepCollectionEquality().hash(_children),
      commitMessage,
      createdAt);

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
      {required final String branch,
      required final int version,
      final String? parentBranch,
      final int? parentVersion,
      final List<RecipeNode> children,
      final String? commitMessage,
      final DateTime? createdAt}) = _$RecipeNodeImpl;

  factory _RecipeNode.fromJson(Map<String, dynamic> json) =
      _$RecipeNodeImpl.fromJson;

  @override
  String get branch;
  @override
  int get version;
  @override
  String? get parentBranch;
  @override
  int? get parentVersion;
  @override
  List<RecipeNode> get children;
  @override
  String? get commitMessage;
  @override
  DateTime? get createdAt;

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
