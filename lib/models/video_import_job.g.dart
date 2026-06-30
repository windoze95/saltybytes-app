// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_import_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoImportJobImpl _$$VideoImportJobImplFromJson(Map<String, dynamic> json) =>
    _$VideoImportJobImpl(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String? ?? 'queued',
      platform: json['platform'] as String?,
      cacheHit: json['cache_hit'] as bool? ?? false,
      recipeId: (json['recipe_id'] as num?)?.toInt(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$VideoImportJobImplToJson(
        _$VideoImportJobImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'platform': instance.platform,
      'cache_hit': instance.cacheHit,
      'recipe_id': instance.recipeId,
      'error': instance.error,
    };
