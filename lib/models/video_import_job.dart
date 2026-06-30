// @JsonKey on freezed constructor parameters is the documented freezed
// pattern; the analyzer flags it as invalid_annotation_target regardless.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_import_job.freezed.dart';
part 'video_import_job.g.dart';

/// An async video-link import job returned by POST /v1/recipes/import/video and
/// polled via GET /v1/recipes/import/video/:id. The job JSON is snake_case
/// (`cache_hit`, `recipe_id`), unlike the camelCase recipe envelope.
@freezed
class VideoImportJob with _$VideoImportJob {
  const VideoImportJob._();

  const factory VideoImportJob({
    required int id,
    @Default('queued') String status, // queued | processing | done | failed
    String? platform,
    @JsonKey(name: 'cache_hit') @Default(false) bool cacheHit,
    @JsonKey(name: 'recipe_id') int? recipeId,
    String? error,
  }) = _VideoImportJob;

  factory VideoImportJob.fromJson(Map<String, dynamic> json) =>
      _$VideoImportJobFromJson(json);

  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed';
  bool get isTerminal => isDone || isFailed;
}
