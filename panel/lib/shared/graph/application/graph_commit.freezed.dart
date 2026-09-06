// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_commit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GraphMoveCommitPayload {

 GraphIdentifier get id; int get x; int get y;
/// Create a copy of GraphMoveCommitPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphMoveCommitPayloadCopyWith<GraphMoveCommitPayload> get copyWith => _$GraphMoveCommitPayloadCopyWithImpl<GraphMoveCommitPayload>(this as GraphMoveCommitPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphMoveCommitPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,id,x,y);

@override
String toString() {
  return 'GraphMoveCommitPayload(id: $id, x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $GraphMoveCommitPayloadCopyWith<$Res>  {
  factory $GraphMoveCommitPayloadCopyWith(GraphMoveCommitPayload value, $Res Function(GraphMoveCommitPayload) _then) = _$GraphMoveCommitPayloadCopyWithImpl;
@useResult
$Res call({
 GraphIdentifier id, int x, int y
});




}
/// @nodoc
class _$GraphMoveCommitPayloadCopyWithImpl<$Res>
    implements $GraphMoveCommitPayloadCopyWith<$Res> {
  _$GraphMoveCommitPayloadCopyWithImpl(this._self, this._then);

  final GraphMoveCommitPayload _self;
  final $Res Function(GraphMoveCommitPayload) _then;

/// Create a copy of GraphMoveCommitPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GraphMoveCommitPayload].
extension GraphMoveCommitPayloadPatterns on GraphMoveCommitPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GraphMoveCommitPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GraphMoveCommitPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GraphMoveCommitPayload value)  $default,){
final _that = this;
switch (_that) {
case _GraphMoveCommitPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GraphMoveCommitPayload value)?  $default,){
final _that = this;
switch (_that) {
case _GraphMoveCommitPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GraphIdentifier id,  int x,  int y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GraphMoveCommitPayload() when $default != null:
return $default(_that.id,_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GraphIdentifier id,  int x,  int y)  $default,) {final _that = this;
switch (_that) {
case _GraphMoveCommitPayload():
return $default(_that.id,_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GraphIdentifier id,  int x,  int y)?  $default,) {final _that = this;
switch (_that) {
case _GraphMoveCommitPayload() when $default != null:
return $default(_that.id,_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc


class _GraphMoveCommitPayload implements GraphMoveCommitPayload {
  const _GraphMoveCommitPayload({required this.id, required this.x, required this.y});
  

@override final  GraphIdentifier id;
@override final  int x;
@override final  int y;

/// Create a copy of GraphMoveCommitPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GraphMoveCommitPayloadCopyWith<_GraphMoveCommitPayload> get copyWith => __$GraphMoveCommitPayloadCopyWithImpl<_GraphMoveCommitPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GraphMoveCommitPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,id,x,y);

@override
String toString() {
  return 'GraphMoveCommitPayload(id: $id, x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$GraphMoveCommitPayloadCopyWith<$Res> implements $GraphMoveCommitPayloadCopyWith<$Res> {
  factory _$GraphMoveCommitPayloadCopyWith(_GraphMoveCommitPayload value, $Res Function(_GraphMoveCommitPayload) _then) = __$GraphMoveCommitPayloadCopyWithImpl;
@override @useResult
$Res call({
 GraphIdentifier id, int x, int y
});




}
/// @nodoc
class __$GraphMoveCommitPayloadCopyWithImpl<$Res>
    implements _$GraphMoveCommitPayloadCopyWith<$Res> {
  __$GraphMoveCommitPayloadCopyWithImpl(this._self, this._then);

  final _GraphMoveCommitPayload _self;
  final $Res Function(_GraphMoveCommitPayload) _then;

/// Create a copy of GraphMoveCommitPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? x = null,Object? y = null,}) {
  return _then(_GraphMoveCommitPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$GraphResizeCommitPayload {

 GraphIdentifier get id; int get width; int get height;
/// Create a copy of GraphResizeCommitPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphResizeCommitPayloadCopyWith<GraphResizeCommitPayload> get copyWith => _$GraphResizeCommitPayloadCopyWithImpl<GraphResizeCommitPayload>(this as GraphResizeCommitPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphResizeCommitPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,id,width,height);

@override
String toString() {
  return 'GraphResizeCommitPayload(id: $id, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $GraphResizeCommitPayloadCopyWith<$Res>  {
  factory $GraphResizeCommitPayloadCopyWith(GraphResizeCommitPayload value, $Res Function(GraphResizeCommitPayload) _then) = _$GraphResizeCommitPayloadCopyWithImpl;
@useResult
$Res call({
 GraphIdentifier id, int width, int height
});




}
/// @nodoc
class _$GraphResizeCommitPayloadCopyWithImpl<$Res>
    implements $GraphResizeCommitPayloadCopyWith<$Res> {
  _$GraphResizeCommitPayloadCopyWithImpl(this._self, this._then);

  final GraphResizeCommitPayload _self;
  final $Res Function(GraphResizeCommitPayload) _then;

/// Create a copy of GraphResizeCommitPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GraphResizeCommitPayload].
extension GraphResizeCommitPayloadPatterns on GraphResizeCommitPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GraphResizeCommitPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GraphResizeCommitPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GraphResizeCommitPayload value)  $default,){
final _that = this;
switch (_that) {
case _GraphResizeCommitPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GraphResizeCommitPayload value)?  $default,){
final _that = this;
switch (_that) {
case _GraphResizeCommitPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GraphIdentifier id,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GraphResizeCommitPayload() when $default != null:
return $default(_that.id,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GraphIdentifier id,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _GraphResizeCommitPayload():
return $default(_that.id,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GraphIdentifier id,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _GraphResizeCommitPayload() when $default != null:
return $default(_that.id,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _GraphResizeCommitPayload implements GraphResizeCommitPayload {
  const _GraphResizeCommitPayload({required this.id, required this.width, required this.height});
  

@override final  GraphIdentifier id;
@override final  int width;
@override final  int height;

/// Create a copy of GraphResizeCommitPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GraphResizeCommitPayloadCopyWith<_GraphResizeCommitPayload> get copyWith => __$GraphResizeCommitPayloadCopyWithImpl<_GraphResizeCommitPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GraphResizeCommitPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,id,width,height);

@override
String toString() {
  return 'GraphResizeCommitPayload(id: $id, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$GraphResizeCommitPayloadCopyWith<$Res> implements $GraphResizeCommitPayloadCopyWith<$Res> {
  factory _$GraphResizeCommitPayloadCopyWith(_GraphResizeCommitPayload value, $Res Function(_GraphResizeCommitPayload) _then) = __$GraphResizeCommitPayloadCopyWithImpl;
@override @useResult
$Res call({
 GraphIdentifier id, int width, int height
});




}
/// @nodoc
class __$GraphResizeCommitPayloadCopyWithImpl<$Res>
    implements _$GraphResizeCommitPayloadCopyWith<$Res> {
  __$GraphResizeCommitPayloadCopyWithImpl(this._self, this._then);

  final _GraphResizeCommitPayload _self;
  final $Res Function(_GraphResizeCommitPayload) _then;

/// Create a copy of GraphResizeCommitPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? width = null,Object? height = null,}) {
  return _then(_GraphResizeCommitPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
