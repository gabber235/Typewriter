// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_edge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GraphEdge {

 String get id; GraphIdentifier get source; GraphIdentifier get target; Color get color; EdgeSide get sourceSide; EdgeSide get targetSide;
/// Create a copy of GraphEdge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphEdgeCopyWith<GraphEdge> get copyWith => _$GraphEdgeCopyWithImpl<GraphEdge>(this as GraphEdge, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphEdge&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.color, color) || other.color == color)&&(identical(other.sourceSide, sourceSide) || other.sourceSide == sourceSide)&&(identical(other.targetSide, targetSide) || other.targetSide == targetSide));
}


@override
int get hashCode => Object.hash(runtimeType,id,source,target,color,sourceSide,targetSide);

@override
String toString() {
  return 'GraphEdge(id: $id, source: $source, target: $target, color: $color, sourceSide: $sourceSide, targetSide: $targetSide)';
}


}

/// @nodoc
abstract mixin class $GraphEdgeCopyWith<$Res>  {
  factory $GraphEdgeCopyWith(GraphEdge value, $Res Function(GraphEdge) _then) = _$GraphEdgeCopyWithImpl;
@useResult
$Res call({
 String id, GraphIdentifier source, GraphIdentifier target, Color color, EdgeSide sourceSide, EdgeSide targetSide
});




}
/// @nodoc
class _$GraphEdgeCopyWithImpl<$Res>
    implements $GraphEdgeCopyWith<$Res> {
  _$GraphEdgeCopyWithImpl(this._self, this._then);

  final GraphEdge _self;
  final $Res Function(GraphEdge) _then;

/// Create a copy of GraphEdge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? target = null,Object? color = null,Object? sourceSide = null,Object? targetSide = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,sourceSide: null == sourceSide ? _self.sourceSide : sourceSide // ignore: cast_nullable_to_non_nullable
as EdgeSide,targetSide: null == targetSide ? _self.targetSide : targetSide // ignore: cast_nullable_to_non_nullable
as EdgeSide,
  ));
}

}


/// Adds pattern-matching-related methods to [GraphEdge].
extension GraphEdgePatterns on GraphEdge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GraphEdge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GraphEdge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GraphEdge value)  $default,){
final _that = this;
switch (_that) {
case _GraphEdge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GraphEdge value)?  $default,){
final _that = this;
switch (_that) {
case _GraphEdge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GraphIdentifier source,  GraphIdentifier target,  Color color,  EdgeSide sourceSide,  EdgeSide targetSide)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GraphEdge() when $default != null:
return $default(_that.id,_that.source,_that.target,_that.color,_that.sourceSide,_that.targetSide);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GraphIdentifier source,  GraphIdentifier target,  Color color,  EdgeSide sourceSide,  EdgeSide targetSide)  $default,) {final _that = this;
switch (_that) {
case _GraphEdge():
return $default(_that.id,_that.source,_that.target,_that.color,_that.sourceSide,_that.targetSide);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GraphIdentifier source,  GraphIdentifier target,  Color color,  EdgeSide sourceSide,  EdgeSide targetSide)?  $default,) {final _that = this;
switch (_that) {
case _GraphEdge() when $default != null:
return $default(_that.id,_that.source,_that.target,_that.color,_that.sourceSide,_that.targetSide);case _:
  return null;

}
}

}

/// @nodoc


class _GraphEdge extends GraphEdge {
  const _GraphEdge({required this.id, required this.source, required this.target, required this.color, this.sourceSide = EdgeSide.right, this.targetSide = EdgeSide.left}): super._();
  

@override final  String id;
@override final  GraphIdentifier source;
@override final  GraphIdentifier target;
@override final  Color color;
@override@JsonKey() final  EdgeSide sourceSide;
@override@JsonKey() final  EdgeSide targetSide;

/// Create a copy of GraphEdge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GraphEdgeCopyWith<_GraphEdge> get copyWith => __$GraphEdgeCopyWithImpl<_GraphEdge>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GraphEdge&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.color, color) || other.color == color)&&(identical(other.sourceSide, sourceSide) || other.sourceSide == sourceSide)&&(identical(other.targetSide, targetSide) || other.targetSide == targetSide));
}


@override
int get hashCode => Object.hash(runtimeType,id,source,target,color,sourceSide,targetSide);

@override
String toString() {
  return 'GraphEdge(id: $id, source: $source, target: $target, color: $color, sourceSide: $sourceSide, targetSide: $targetSide)';
}


}

/// @nodoc
abstract mixin class _$GraphEdgeCopyWith<$Res> implements $GraphEdgeCopyWith<$Res> {
  factory _$GraphEdgeCopyWith(_GraphEdge value, $Res Function(_GraphEdge) _then) = __$GraphEdgeCopyWithImpl;
@override @useResult
$Res call({
 String id, GraphIdentifier source, GraphIdentifier target, Color color, EdgeSide sourceSide, EdgeSide targetSide
});




}
/// @nodoc
class __$GraphEdgeCopyWithImpl<$Res>
    implements _$GraphEdgeCopyWith<$Res> {
  __$GraphEdgeCopyWithImpl(this._self, this._then);

  final _GraphEdge _self;
  final $Res Function(_GraphEdge) _then;

/// Create a copy of GraphEdge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? target = null,Object? color = null,Object? sourceSide = null,Object? targetSide = null,}) {
  return _then(_GraphEdge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,sourceSide: null == sourceSide ? _self.sourceSide : sourceSide // ignore: cast_nullable_to_non_nullable
as EdgeSide,targetSide: null == targetSide ? _self.targetSide : targetSide // ignore: cast_nullable_to_non_nullable
as EdgeSide,
  ));
}


}

// dart format on
