// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_import_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VideoImportJob _$VideoImportJobFromJson(Map<String, dynamic> json) {
  return _VideoImportJob.fromJson(json);
}

/// @nodoc
mixin _$VideoImportJob {
  int get id => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // queued | processing | done | failed
  String? get platform => throw _privateConstructorUsedError;
  @JsonKey(name: 'cache_hit')
  bool get cacheHit => throw _privateConstructorUsedError;
  @JsonKey(name: 'recipe_id')
  int? get recipeId => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this VideoImportJob to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VideoImportJob
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoImportJobCopyWith<VideoImportJob> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoImportJobCopyWith<$Res> {
  factory $VideoImportJobCopyWith(
          VideoImportJob value, $Res Function(VideoImportJob) then) =
      _$VideoImportJobCopyWithImpl<$Res, VideoImportJob>;
  @useResult
  $Res call(
      {int id,
      String status,
      String? platform,
      @JsonKey(name: 'cache_hit') bool cacheHit,
      @JsonKey(name: 'recipe_id') int? recipeId,
      String? error});
}

/// @nodoc
class _$VideoImportJobCopyWithImpl<$Res, $Val extends VideoImportJob>
    implements $VideoImportJobCopyWith<$Res> {
  _$VideoImportJobCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoImportJob
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? platform = freezed,
    Object? cacheHit = null,
    Object? recipeId = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      platform: freezed == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String?,
      cacheHit: null == cacheHit
          ? _value.cacheHit
          : cacheHit // ignore: cast_nullable_to_non_nullable
              as bool,
      recipeId: freezed == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as int?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VideoImportJobImplCopyWith<$Res>
    implements $VideoImportJobCopyWith<$Res> {
  factory _$$VideoImportJobImplCopyWith(_$VideoImportJobImpl value,
          $Res Function(_$VideoImportJobImpl) then) =
      __$$VideoImportJobImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String status,
      String? platform,
      @JsonKey(name: 'cache_hit') bool cacheHit,
      @JsonKey(name: 'recipe_id') int? recipeId,
      String? error});
}

/// @nodoc
class __$$VideoImportJobImplCopyWithImpl<$Res>
    extends _$VideoImportJobCopyWithImpl<$Res, _$VideoImportJobImpl>
    implements _$$VideoImportJobImplCopyWith<$Res> {
  __$$VideoImportJobImplCopyWithImpl(
      _$VideoImportJobImpl _value, $Res Function(_$VideoImportJobImpl) _then)
      : super(_value, _then);

  /// Create a copy of VideoImportJob
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? platform = freezed,
    Object? cacheHit = null,
    Object? recipeId = freezed,
    Object? error = freezed,
  }) {
    return _then(_$VideoImportJobImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      platform: freezed == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String?,
      cacheHit: null == cacheHit
          ? _value.cacheHit
          : cacheHit // ignore: cast_nullable_to_non_nullable
              as bool,
      recipeId: freezed == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as int?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoImportJobImpl extends _VideoImportJob {
  const _$VideoImportJobImpl(
      {required this.id,
      this.status = 'queued',
      this.platform,
      @JsonKey(name: 'cache_hit') this.cacheHit = false,
      @JsonKey(name: 'recipe_id') this.recipeId,
      this.error})
      : super._();

  factory _$VideoImportJobImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoImportJobImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey()
  final String status;
// queued | processing | done | failed
  @override
  final String? platform;
  @override
  @JsonKey(name: 'cache_hit')
  final bool cacheHit;
  @override
  @JsonKey(name: 'recipe_id')
  final int? recipeId;
  @override
  final String? error;

  @override
  String toString() {
    return 'VideoImportJob(id: $id, status: $status, platform: $platform, cacheHit: $cacheHit, recipeId: $recipeId, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoImportJobImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.cacheHit, cacheHit) ||
                other.cacheHit == cacheHit) &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, status, platform, cacheHit, recipeId, error);

  /// Create a copy of VideoImportJob
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoImportJobImplCopyWith<_$VideoImportJobImpl> get copyWith =>
      __$$VideoImportJobImplCopyWithImpl<_$VideoImportJobImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoImportJobImplToJson(
      this,
    );
  }
}

abstract class _VideoImportJob extends VideoImportJob {
  const factory _VideoImportJob(
      {required final int id,
      final String status,
      final String? platform,
      @JsonKey(name: 'cache_hit') final bool cacheHit,
      @JsonKey(name: 'recipe_id') final int? recipeId,
      final String? error}) = _$VideoImportJobImpl;
  const _VideoImportJob._() : super._();

  factory _VideoImportJob.fromJson(Map<String, dynamic> json) =
      _$VideoImportJobImpl.fromJson;

  @override
  int get id;
  @override
  String get status; // queued | processing | done | failed
  @override
  String? get platform;
  @override
  @JsonKey(name: 'cache_hit')
  bool get cacheHit;
  @override
  @JsonKey(name: 'recipe_id')
  int? get recipeId;
  @override
  String? get error;

  /// Create a copy of VideoImportJob
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoImportJobImplCopyWith<_$VideoImportJobImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
