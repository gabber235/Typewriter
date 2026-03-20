// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timeline_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimelinePreview {

 String get id; TimelineInteractionMode get mode; int get originalStartFrame; int get originalEndFrame; int get startFrame; int get endFrame;
/// Create a copy of TimelinePreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelinePreviewCopyWith<TimelinePreview> get copyWith => _$TimelinePreviewCopyWithImpl<TimelinePreview>(this as TimelinePreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelinePreview&&(identical(other.id, id) || other.id == id)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.originalStartFrame, originalStartFrame) || other.originalStartFrame == originalStartFrame)&&(identical(other.originalEndFrame, originalEndFrame) || other.originalEndFrame == originalEndFrame)&&(identical(other.startFrame, startFrame) || other.startFrame == startFrame)&&(identical(other.endFrame, endFrame) || other.endFrame == endFrame));
}


@override
int get hashCode => Object.hash(runtimeType,id,mode,originalStartFrame,originalEndFrame,startFrame,endFrame);

@override
String toString() {
  return 'TimelinePreview(id: $id, mode: $mode, originalStartFrame: $originalStartFrame, originalEndFrame: $originalEndFrame, startFrame: $startFrame, endFrame: $endFrame)';
}


}

/// @nodoc
abstract mixin class $TimelinePreviewCopyWith<$Res>  {
  factory $TimelinePreviewCopyWith(TimelinePreview value, $Res Function(TimelinePreview) _then) = _$TimelinePreviewCopyWithImpl;
@useResult
$Res call({
 String id, TimelineInteractionMode mode, int originalStartFrame, int originalEndFrame, int startFrame, int endFrame
});




}
/// @nodoc
class _$TimelinePreviewCopyWithImpl<$Res>
    implements $TimelinePreviewCopyWith<$Res> {
  _$TimelinePreviewCopyWithImpl(this._self, this._then);

  final TimelinePreview _self;
  final $Res Function(TimelinePreview) _then;

/// Create a copy of TimelinePreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mode = null,Object? originalStartFrame = null,Object? originalEndFrame = null,Object? startFrame = null,Object? endFrame = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as TimelineInteractionMode,originalStartFrame: null == originalStartFrame ? _self.originalStartFrame : originalStartFrame // ignore: cast_nullable_to_non_nullable
as int,originalEndFrame: null == originalEndFrame ? _self.originalEndFrame : originalEndFrame // ignore: cast_nullable_to_non_nullable
as int,startFrame: null == startFrame ? _self.startFrame : startFrame // ignore: cast_nullable_to_non_nullable
as int,endFrame: null == endFrame ? _self.endFrame : endFrame // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TimelinePreview].
extension TimelinePreviewPatterns on TimelinePreview {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimelinePreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimelinePreview() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimelinePreview value)  $default,){
final _that = this;
switch (_that) {
case _TimelinePreview():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimelinePreview value)?  $default,){
final _that = this;
switch (_that) {
case _TimelinePreview() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TimelineInteractionMode mode,  int originalStartFrame,  int originalEndFrame,  int startFrame,  int endFrame)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimelinePreview() when $default != null:
return $default(_that.id,_that.mode,_that.originalStartFrame,_that.originalEndFrame,_that.startFrame,_that.endFrame);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TimelineInteractionMode mode,  int originalStartFrame,  int originalEndFrame,  int startFrame,  int endFrame)  $default,) {final _that = this;
switch (_that) {
case _TimelinePreview():
return $default(_that.id,_that.mode,_that.originalStartFrame,_that.originalEndFrame,_that.startFrame,_that.endFrame);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TimelineInteractionMode mode,  int originalStartFrame,  int originalEndFrame,  int startFrame,  int endFrame)?  $default,) {final _that = this;
switch (_that) {
case _TimelinePreview() when $default != null:
return $default(_that.id,_that.mode,_that.originalStartFrame,_that.originalEndFrame,_that.startFrame,_that.endFrame);case _:
  return null;

}
}

}

/// @nodoc


class _TimelinePreview implements TimelinePreview {
  const _TimelinePreview({required this.id, required this.mode, required this.originalStartFrame, required this.originalEndFrame, required this.startFrame, required this.endFrame});
  

@override final  String id;
@override final  TimelineInteractionMode mode;
@override final  int originalStartFrame;
@override final  int originalEndFrame;
@override final  int startFrame;
@override final  int endFrame;

/// Create a copy of TimelinePreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimelinePreviewCopyWith<_TimelinePreview> get copyWith => __$TimelinePreviewCopyWithImpl<_TimelinePreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimelinePreview&&(identical(other.id, id) || other.id == id)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.originalStartFrame, originalStartFrame) || other.originalStartFrame == originalStartFrame)&&(identical(other.originalEndFrame, originalEndFrame) || other.originalEndFrame == originalEndFrame)&&(identical(other.startFrame, startFrame) || other.startFrame == startFrame)&&(identical(other.endFrame, endFrame) || other.endFrame == endFrame));
}


@override
int get hashCode => Object.hash(runtimeType,id,mode,originalStartFrame,originalEndFrame,startFrame,endFrame);

@override
String toString() {
  return 'TimelinePreview(id: $id, mode: $mode, originalStartFrame: $originalStartFrame, originalEndFrame: $originalEndFrame, startFrame: $startFrame, endFrame: $endFrame)';
}


}

/// @nodoc
abstract mixin class _$TimelinePreviewCopyWith<$Res> implements $TimelinePreviewCopyWith<$Res> {
  factory _$TimelinePreviewCopyWith(_TimelinePreview value, $Res Function(_TimelinePreview) _then) = __$TimelinePreviewCopyWithImpl;
@override @useResult
$Res call({
 String id, TimelineInteractionMode mode, int originalStartFrame, int originalEndFrame, int startFrame, int endFrame
});




}
/// @nodoc
class __$TimelinePreviewCopyWithImpl<$Res>
    implements _$TimelinePreviewCopyWith<$Res> {
  __$TimelinePreviewCopyWithImpl(this._self, this._then);

  final _TimelinePreview _self;
  final $Res Function(_TimelinePreview) _then;

/// Create a copy of TimelinePreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mode = null,Object? originalStartFrame = null,Object? originalEndFrame = null,Object? startFrame = null,Object? endFrame = null,}) {
  return _then(_TimelinePreview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as TimelineInteractionMode,originalStartFrame: null == originalStartFrame ? _self.originalStartFrame : originalStartFrame // ignore: cast_nullable_to_non_nullable
as int,originalEndFrame: null == originalEndFrame ? _self.originalEndFrame : originalEndFrame // ignore: cast_nullable_to_non_nullable
as int,startFrame: null == startFrame ? _self.startFrame : startFrame // ignore: cast_nullable_to_non_nullable
as int,endFrame: null == endFrame ? _self.endFrame : endFrame // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
