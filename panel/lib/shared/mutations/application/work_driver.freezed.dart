// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_driver.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkReviewContent {

 Widget get body; VoidCallback? get dispose;
/// Create a copy of WorkReviewContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkReviewContentCopyWith<WorkReviewContent> get copyWith => _$WorkReviewContentCopyWithImpl<WorkReviewContent>(this as WorkReviewContent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkReviewContent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkReviewContent&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.dispose, _this.dispose) || other.dispose == _this.dispose));
}


@override
int get hashCode {
  final _this = this as WorkReviewContent;
  return Object.hash(runtimeType,_this.body,_this.dispose);
}

@override
String toString() {
  final _this = this as WorkReviewContent;
  return 'WorkReviewContent(body: ${_this.body}, dispose: ${_this.dispose})';
}


}

/// @nodoc
abstract mixin class $WorkReviewContentCopyWith<$Res>  {
  factory $WorkReviewContentCopyWith(WorkReviewContent value, $Res Function(WorkReviewContent) _then) = _$WorkReviewContentCopyWithImpl;
@useResult
$Res call({
 Widget body, VoidCallback? dispose
});




}
/// @nodoc
class _$WorkReviewContentCopyWithImpl<$Res>
    implements $WorkReviewContentCopyWith<$Res> {
  _$WorkReviewContentCopyWithImpl(this._self, this._then);

  final WorkReviewContent _self;
  final $Res Function(WorkReviewContent) _then;

/// Create a copy of WorkReviewContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,Object? dispose = freezed,}) {
  return _then(WorkReviewContent(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as Widget,dispose: freezed == dispose ? _self.dispose : dispose // ignore: cast_nullable_to_non_nullable
as VoidCallback?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkReviewContent].
extension WorkReviewContentPatterns on WorkReviewContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkReviewContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkReviewContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkReviewContent value)  $default,){
final _that = this;
switch (_that) {
case _WorkReviewContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkReviewContent value)?  $default,){
final _that = this;
switch (_that) {
case _WorkReviewContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Widget body,  VoidCallback? dispose)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkReviewContent() when $default != null:
return $default(_that.body,_that.dispose);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Widget body,  VoidCallback? dispose)  $default,) {final _that = this;
switch (_that) {
case _WorkReviewContent():
return $default(_that.body,_that.dispose);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Widget body,  VoidCallback? dispose)?  $default,) {final _that = this;
switch (_that) {
case _WorkReviewContent() when $default != null:
return $default(_that.body,_that.dispose);case _:
  return null;

}
}

}

/// @nodoc


class _WorkReviewContent implements WorkReviewContent {
  const _WorkReviewContent({required this.body, this.dispose});
  

@override final  Widget body;
@override final  VoidCallback? dispose;

/// Create a copy of WorkReviewContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkReviewContentCopyWith<_WorkReviewContent> get copyWith => __$WorkReviewContentCopyWithImpl<_WorkReviewContent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkReviewContent&&(identical(other.body, body) || other.body == body)&&(identical(other.dispose, dispose) || other.dispose == dispose));
}


@override
int get hashCode {
    return Object.hash(runtimeType,body,dispose);
}

@override
String toString() {
    return 'WorkReviewContent(body: $body, dispose: $dispose)';
}


}

/// @nodoc
abstract mixin class _$WorkReviewContentCopyWith<$Res> implements $WorkReviewContentCopyWith<$Res> {
  factory _$WorkReviewContentCopyWith(_WorkReviewContent value, $Res Function(_WorkReviewContent) _then) = __$WorkReviewContentCopyWithImpl;
@override @useResult
$Res call({
 Widget body, VoidCallback? dispose
});




}
/// @nodoc
class __$WorkReviewContentCopyWithImpl<$Res>
    implements _$WorkReviewContentCopyWith<$Res> {
  __$WorkReviewContentCopyWithImpl(this._self, this._then);

  final _WorkReviewContent _self;
  final $Res Function(_WorkReviewContent) _then;

/// Create a copy of WorkReviewContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? dispose = freezed,}) {
  return _then(_WorkReviewContent(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as Widget,dispose: freezed == dispose ? _self.dispose : dispose // ignore: cast_nullable_to_non_nullable
as VoidCallback?,
  ));
}


}

// dart format on
