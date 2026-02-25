// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecipeImpl _$$RecipeImplFromJson(Map<String, dynamic> json) => _$RecipeImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String,
      imageUrl: json['imageUrl'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      cuisine: json['cuisine'] as String?,
      difficulty: json['difficulty'] as String?,
      prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt(),
      cookTimeMinutes: (json['cookTimeMinutes'] as num?)?.toInt(),
      servings: (json['servings'] as num?)?.toInt() ?? 4,
      sourceUrl: json['sourceUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      allergenTags: (json['allergenTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentBranch: json['currentBranch'] as String? ?? 'main',
      parentRecipeId: json['parentRecipeId'] as String?,
      version: (json['version'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$RecipeImplToJson(_$RecipeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'ownerId': instance.ownerId,
      'imageUrl': instance.imageUrl,
      'ingredients': instance.ingredients,
      'instructions': instance.instructions,
      'tags': instance.tags,
      'cuisine': instance.cuisine,
      'difficulty': instance.difficulty,
      'prepTimeMinutes': instance.prepTimeMinutes,
      'cookTimeMinutes': instance.cookTimeMinutes,
      'servings': instance.servings,
      'sourceUrl': instance.sourceUrl,
      'isPublic': instance.isPublic,
      'allergenTags': instance.allergenTags,
      'currentBranch': instance.currentBranch,
      'parentRecipeId': instance.parentRecipeId,
      'version': instance.version,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$IngredientImpl _$$IngredientImplFromJson(Map<String, dynamic> json) =>
    _$IngredientImpl(
      name: json['name'] as String,
      quantity: json['quantity'] as String?,
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
      optional: json['optional'] as bool? ?? false,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$$IngredientImplToJson(_$IngredientImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'notes': instance.notes,
      'optional': instance.optional,
      'category': instance.category,
    };

_$RecipeDefImpl _$$RecipeDefImplFromJson(Map<String, dynamic> json) =>
    _$RecipeDefImpl(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      branch: json['branch'] as String,
      version: (json['version'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      commitMessage: json['commitMessage'] as String?,
      authorId: json['authorId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$RecipeDefImplToJson(_$RecipeDefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipeId': instance.recipeId,
      'branch': instance.branch,
      'version': instance.version,
      'title': instance.title,
      'description': instance.description,
      'ingredients': instance.ingredients,
      'instructions': instance.instructions,
      'commitMessage': instance.commitMessage,
      'authorId': instance.authorId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$RecipeNodeImpl _$$RecipeNodeImplFromJson(Map<String, dynamic> json) =>
    _$RecipeNodeImpl(
      branch: json['branch'] as String,
      version: (json['version'] as num).toInt(),
      parentBranch: json['parentBranch'] as String?,
      parentVersion: (json['parentVersion'] as num?)?.toInt(),
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => RecipeNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      commitMessage: json['commitMessage'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$RecipeNodeImplToJson(_$RecipeNodeImpl instance) =>
    <String, dynamic>{
      'branch': instance.branch,
      'version': instance.version,
      'parentBranch': instance.parentBranch,
      'parentVersion': instance.parentVersion,
      'children': instance.children,
      'commitMessage': instance.commitMessage,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$RecipeSearchResultImpl _$$RecipeSearchResultImplFromJson(
        Map<String, dynamic> json) =>
    _$RecipeSearchResultImpl(
      recipes: (json['recipes'] as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
    );

Map<String, dynamic> _$$RecipeSearchResultImplToJson(
        _$RecipeSearchResultImpl instance) =>
    <String, dynamic>{
      'recipes': instance.recipes,
      'total': instance.total,
      'page': instance.page,
      'pageSize': instance.pageSize,
    };
