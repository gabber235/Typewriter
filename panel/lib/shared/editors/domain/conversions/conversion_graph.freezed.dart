// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversion_graph.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversionPath {

 ResolvedTypeRef get type; List<ConversionDefinition> get edges; Set<ResolvedTypeRef> get visited; int get cost;
/// Create a copy of _ConversionPath
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversionPathCopyWith<_ConversionPath> get copyWith => __$ConversionPathCopyWithImpl<_ConversionPath>(this as _ConversionPath, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversionPath&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.edges, edges)&&const DeepCollectionEquality().equals(other.visited, visited)&&(identical(other.cost, cost) || other.cost == cost));
}


@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(edges),const DeepCollectionEquality().hash(visited),cost);

@override
String toString() {
  return '_ConversionPath(type: $type, edges: $edges, visited: $visited, cost: $cost)';
}


}

/// @nodoc
abstract mixin class _$ConversionPathCopyWith<$Res>  {
  factory _$ConversionPathCopyWith(_ConversionPath value, $Res Function(_ConversionPath) _then) = __$ConversionPathCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef type, List<ConversionDefinition> edges, Set<ResolvedTypeRef> visited, int cost
});


$ResolvedTypeRefCopyWith<$Res> get type;

}
/// @nodoc
class __$ConversionPathCopyWithImpl<$Res>
    implements _$ConversionPathCopyWith<$Res> {
  __$ConversionPathCopyWithImpl(this._self, this._then);

  final _ConversionPath _self;
  final $Res Function(_ConversionPath) _then;

/// Create a copy of _ConversionPath
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? edges = null,Object? visited = null,Object? cost = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,edges: null == edges ? _self.edges : edges // ignore: cast_nullable_to_non_nullable
as List<ConversionDefinition>,visited: null == visited ? _self.visited : visited // ignore: cast_nullable_to_non_nullable
as Set<ResolvedTypeRef>,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of _ConversionPath
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get type {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}


/// Adds pattern-matching-related methods to [_ConversionPath].
extension _ConversionPathPatterns on _ConversionPath {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversionPathValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversionPathValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversionPathValue value)  $default,){
final _that = this;
switch (_that) {
case _ConversionPathValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversionPathValue value)?  $default,){
final _that = this;
switch (_that) {
case _ConversionPathValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTypeRef type,  List<ConversionDefinition> edges,  Set<ResolvedTypeRef> visited,  int cost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversionPathValue() when $default != null:
return $default(_that.type,_that.edges,_that.visited,_that.cost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTypeRef type,  List<ConversionDefinition> edges,  Set<ResolvedTypeRef> visited,  int cost)  $default,) {final _that = this;
switch (_that) {
case _ConversionPathValue():
return $default(_that.type,_that.edges,_that.visited,_that.cost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTypeRef type,  List<ConversionDefinition> edges,  Set<ResolvedTypeRef> visited,  int cost)?  $default,) {final _that = this;
switch (_that) {
case _ConversionPathValue() when $default != null:
return $default(_that.type,_that.edges,_that.visited,_that.cost);case _:
  return null;

}
}

}

/// @nodoc


class _ConversionPathValue implements _ConversionPath {
  const _ConversionPathValue({required this.type, required final  List<ConversionDefinition> edges, required final  Set<ResolvedTypeRef> visited, required this.cost}): _edges = edges,_visited = visited;
  

@override final  ResolvedTypeRef type;
 final  List<ConversionDefinition> _edges;
@override List<ConversionDefinition> get edges {
  if (_edges is EqualUnmodifiableListView) return _edges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_edges);
}

 final  Set<ResolvedTypeRef> _visited;
@override Set<ResolvedTypeRef> get visited {
  if (_visited is EqualUnmodifiableSetView) return _visited;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_visited);
}

@override final  int cost;

/// Create a copy of _ConversionPath
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversionPathValueCopyWith<_ConversionPathValue> get copyWith => __$ConversionPathValueCopyWithImpl<_ConversionPathValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversionPathValue&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._edges, _edges)&&const DeepCollectionEquality().equals(other._visited, _visited)&&(identical(other.cost, cost) || other.cost == cost));
}


@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_edges),const DeepCollectionEquality().hash(_visited),cost);

@override
String toString() {
  return '_ConversionPath(type: $type, edges: $edges, visited: $visited, cost: $cost)';
}


}

/// @nodoc
abstract mixin class _$ConversionPathValueCopyWith<$Res> implements _$ConversionPathCopyWith<$Res> {
  factory _$ConversionPathValueCopyWith(_ConversionPathValue value, $Res Function(_ConversionPathValue) _then) = __$ConversionPathValueCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTypeRef type, List<ConversionDefinition> edges, Set<ResolvedTypeRef> visited, int cost
});


@override $ResolvedTypeRefCopyWith<$Res> get type;

}
/// @nodoc
class __$ConversionPathValueCopyWithImpl<$Res>
    implements _$ConversionPathValueCopyWith<$Res> {
  __$ConversionPathValueCopyWithImpl(this._self, this._then);

  final _ConversionPathValue _self;
  final $Res Function(_ConversionPathValue) _then;

/// Create a copy of _ConversionPath
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? edges = null,Object? visited = null,Object? cost = null,}) {
  return _then(_ConversionPathValue(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,edges: null == edges ? _self._edges : edges // ignore: cast_nullable_to_non_nullable
as List<ConversionDefinition>,visited: null == visited ? _self._visited : visited // ignore: cast_nullable_to_non_nullable
as Set<ResolvedTypeRef>,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of _ConversionPath
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get type {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

// dart format on
