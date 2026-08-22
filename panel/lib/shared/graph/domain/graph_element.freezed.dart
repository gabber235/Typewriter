// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_element.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GraphElement {

 GraphIdentifier get id; int get x; int get y; int get width; int get height; WidgetBuilder get builder; int get priority;
/// Create a copy of GraphElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphElementCopyWith<GraphElement> get copyWith => _$GraphElementCopyWithImpl<GraphElement>(this as GraphElement, _$identity);







}

/// @nodoc
abstract mixin class $GraphElementCopyWith<$Res>  {
  factory $GraphElementCopyWith(GraphElement value, $Res Function(GraphElement) _then) = _$GraphElementCopyWithImpl;
@useResult
$Res call({
 GraphIdentifier id, int x, int y, int width, int height, WidgetBuilder builder, int priority
});




}
/// @nodoc
class _$GraphElementCopyWithImpl<$Res>
    implements $GraphElementCopyWith<$Res> {
  _$GraphElementCopyWithImpl(this._self, this._then);

  final GraphElement _self;
  final $Res Function(GraphElement) _then;

/// Create a copy of GraphElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? x = null,Object? y = null,Object? width = null,Object? height = null,Object? builder = null,Object? priority = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,builder: null == builder ? _self.builder : builder // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GraphElement].
extension GraphElementPatterns on GraphElement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GraphElement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GraphElement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GraphElement value)  $default,){
final _that = this;
switch (_that) {
case _GraphElement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GraphElement value)?  $default,){
final _that = this;
switch (_that) {
case _GraphElement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GraphIdentifier id,  int x,  int y,  int width,  int height,  WidgetBuilder builder,  int priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GraphElement() when $default != null:
return $default(_that.id,_that.x,_that.y,_that.width,_that.height,_that.builder,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GraphIdentifier id,  int x,  int y,  int width,  int height,  WidgetBuilder builder,  int priority)  $default,) {final _that = this;
switch (_that) {
case _GraphElement():
return $default(_that.id,_that.x,_that.y,_that.width,_that.height,_that.builder,_that.priority);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GraphIdentifier id,  int x,  int y,  int width,  int height,  WidgetBuilder builder,  int priority)?  $default,) {final _that = this;
switch (_that) {
case _GraphElement() when $default != null:
return $default(_that.id,_that.x,_that.y,_that.width,_that.height,_that.builder,_that.priority);case _:
  return null;

}
}

}

/// @nodoc


class _GraphElement extends GraphElement {
  const _GraphElement({required this.id, required this.x, required this.y, required this.width, required this.height, required this.builder, this.priority = 0}): super._();
  

@override final  GraphIdentifier id;
@override final  int x;
@override final  int y;
@override final  int width;
@override final  int height;
@override final  WidgetBuilder builder;
@override@JsonKey() final  int priority;

/// Create a copy of GraphElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GraphElementCopyWith<_GraphElement> get copyWith => __$GraphElementCopyWithImpl<_GraphElement>(this, _$identity);







}

/// @nodoc
abstract mixin class _$GraphElementCopyWith<$Res> implements $GraphElementCopyWith<$Res> {
  factory _$GraphElementCopyWith(_GraphElement value, $Res Function(_GraphElement) _then) = __$GraphElementCopyWithImpl;
@override @useResult
$Res call({
 GraphIdentifier id, int x, int y, int width, int height, WidgetBuilder builder, int priority
});




}
/// @nodoc
class __$GraphElementCopyWithImpl<$Res>
    implements _$GraphElementCopyWith<$Res> {
  __$GraphElementCopyWithImpl(this._self, this._then);

  final _GraphElement _self;
  final $Res Function(_GraphElement) _then;

/// Create a copy of GraphElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? x = null,Object? y = null,Object? width = null,Object? height = null,Object? builder = null,Object? priority = null,}) {
  return _then(_GraphElement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,builder: null == builder ? _self.builder : builder // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
