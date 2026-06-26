// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecipeImpl _$$RecipeImplFromJson(Map<String, dynamic> json) => _$RecipeImpl(
      id: _idToString(json['id']),
      title: json['title'] as String,
      ownerId: _idToString(json['ownerId']),
      imageUrl: _emptyStringToNull(json['imageUrl']),
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
      cookTimeMinutes: (json['cookTimeMinutes'] as num?)?.toInt(),
      sourceUrl: json['sourceUrl'] as String?,
      unitSystem: json['unitSystem'] as String? ?? 'us_customary',
      status: json['status'] as String? ?? 'ready',
      portions: (json['portions'] as num?)?.toInt(),
      portionSize: json['portionSize'] as String?,
      parentRecipeId: _idToStringOrNull(json['parentRecipeId']),
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
      'ownerId': instance.ownerId,
      'imageUrl': instance.imageUrl,
      'ingredients': instance.ingredients,
      'instructions': instance.instructions,
      'tags': instance.tags,
      'cookTimeMinutes': instance.cookTimeMinutes,
      'sourceUrl': instance.sourceUrl,
      'unitSystem': instance.unitSystem,
      'status': instance.status,
      'portions': instance.portions,
      'portionSize': instance.portionSize,
      'parentRecipeId': instance.parentRecipeId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$IngredientImpl _$$IngredientImplFromJson(Map<String, dynamic> json) =>
    _$IngredientImpl(
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      metricUnit: json['metric_unit'] as String?,
      metricAmount: (json['metric_amount'] as num?)?.toDouble(),
      originalText: json['original_text'] as String?,
      measureKind: json['measure_kind'] as String?,
      baseAmount: (json['base_amount'] as num?)?.toDouble(),
      amountHigh: (json['amount_high'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$IngredientImplToJson(_$IngredientImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'amount': instance.amount,
      'unit': instance.unit,
      'metric_unit': instance.metricUnit,
      'metric_amount': instance.metricAmount,
      'original_text': instance.originalText,
      'measure_kind': instance.measureKind,
      'base_amount': instance.baseAmount,
      'amount_high': instance.amountHigh,
    };

_$RecipeNodeImpl _$$RecipeNodeImplFromJson(Map<String, dynamic> json) =>
    _$RecipeNodeImpl(
      id: (json['id'] as num).toInt(),
      parentId: (json['parent_id'] as num?)?.toInt(),
      branchName: json['branch_name'] as String? ?? 'original',
      summary: json['summary'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      isEphemeral: json['is_ephemeral'] as bool? ?? false,
      createdById: (json['created_by_id'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => RecipeNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$RecipeNodeImplToJson(_$RecipeNodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parent_id': instance.parentId,
      'branch_name': instance.branchName,
      'summary': instance.summary,
      'type': instance.type,
      'is_active': instance.isActive,
      'is_ephemeral': instance.isEphemeral,
      'created_by_id': instance.createdById,
      'created_at': instance.createdAt?.toIso8601String(),
      'children': instance.children,
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
