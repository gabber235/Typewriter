// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'services_packed_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServicesPackedNode {

 GraphIdentifier get id; int get width; int get height; WidgetBuilder get builder; int get priority;
/// Create a copy of ServicesPackedNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServicesPackedNodeCopyWith<ServicesPackedNode> get copyWith => _$ServicesPackedNodeCopyWithImpl<ServicesPackedNode>(this as ServicesPackedNode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServicesPackedNode&&(identical(other.id, id) || other.id == id)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.builder, builder) || other.builder == builder)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,id,width,height,builder,priority);

@override
String toString() {
  return 'ServicesPackedNode(id: $id, width: $width, height: $height, builder: $builder, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $ServicesPackedNodeCopyWith<$Res>  {
  factory $ServicesPackedNodeCopyWith(ServicesPackedNode value, $Res Function(ServicesPackedNode) _then) = _$ServicesPackedNodeCopyWithImpl;
@useResult
$Res call({
 GraphIdentifier id, int width, int height, WidgetBuilder builder, int priority
});




}
/// @nodoc
class _$ServicesPackedNodeCopyWithImpl<$Res>
    implements $ServicesPackedNodeCopyWith<$Res> {
  _$ServicesPackedNodeCopyWithImpl(this._self, this._then);

  final ServicesPackedNode _self;
  final $Res Function(ServicesPackedNode) _then;

/// Create a copy of ServicesPackedNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? width = null,Object? height = null,Object? builder = null,Object? priority = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,builder: null == builder ? _self.builder : builder // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ServicesPackedNode].
extension ServicesPackedNodePatterns on ServicesPackedNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServicesPackedNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServicesPackedNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServicesPackedNode value)  $default,){
final _that = this;
switch (_that) {
case _ServicesPackedNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServicesPackedNode value)?  $default,){
final _that = this;
switch (_that) {
case _ServicesPackedNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GraphIdentifier id,  int width,  int height,  WidgetBuilder builder,  int priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServicesPackedNode() when $default != null:
return $default(_that.id,_that.width,_that.height,_that.builder,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GraphIdentifier id,  int width,  int height,  WidgetBuilder builder,  int priority)  $default,) {final _that = this;
switch (_that) {
case _ServicesPackedNode():
return $default(_that.id,_that.width,_that.height,_that.builder,_that.priority);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GraphIdentifier id,  int width,  int height,  WidgetBuilder builder,  int priority)?  $default,) {final _that = this;
switch (_that) {
case _ServicesPackedNode() when $default != null:
return $default(_that.id,_that.width,_that.height,_that.builder,_that.priority);case _:
  return null;

}
}

}

/// @nodoc


class _ServicesPackedNode implements ServicesPackedNode {
  const _ServicesPackedNode({required this.id, required this.width, required this.height, required this.builder, this.priority = 0});
  

@override final  GraphIdentifier id;
@override final  int width;
@override final  int height;
@override final  WidgetBuilder builder;
@override@JsonKey() final  int priority;

/// Create a copy of ServicesPackedNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServicesPackedNodeCopyWith<_ServicesPackedNode> get copyWith => __$ServicesPackedNodeCopyWithImpl<_ServicesPackedNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServicesPackedNode&&(identical(other.id, id) || other.id == id)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.builder, builder) || other.builder == builder)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,id,width,height,builder,priority);

@override
String toString() {
  return 'ServicesPackedNode(id: $id, width: $width, height: $height, builder: $builder, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$ServicesPackedNodeCopyWith<$Res> implements $ServicesPackedNodeCopyWith<$Res> {
  factory _$ServicesPackedNodeCopyWith(_ServicesPackedNode value, $Res Function(_ServicesPackedNode) _then) = __$ServicesPackedNodeCopyWithImpl;
@override @useResult
$Res call({
 GraphIdentifier id, int width, int height, WidgetBuilder builder, int priority
});




}
/// @nodoc
class __$ServicesPackedNodeCopyWithImpl<$Res>
    implements _$ServicesPackedNodeCopyWith<$Res> {
  __$ServicesPackedNodeCopyWithImpl(this._self, this._then);

  final _ServicesPackedNode _self;
  final $Res Function(_ServicesPackedNode) _then;

/// Create a copy of ServicesPackedNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? width = null,Object? height = null,Object? builder = null,Object? priority = null,}) {
  return _then(_ServicesPackedNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,builder: null == builder ? _self.builder : builder // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ServicesPackedConnection {

 String get id; GraphIdentifier get source; GraphIdentifier get target; Color get color;
/// Create a copy of ServicesPackedConnection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServicesPackedConnectionCopyWith<ServicesPackedConnection> get copyWith => _$ServicesPackedConnectionCopyWithImpl<ServicesPackedConnection>(this as ServicesPackedConnection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServicesPackedConnection&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,source,target,color);

@override
String toString() {
  return 'ServicesPackedConnection(id: $id, source: $source, target: $target, color: $color)';
}


}

/// @nodoc
abstract mixin class $ServicesPackedConnectionCopyWith<$Res>  {
  factory $ServicesPackedConnectionCopyWith(ServicesPackedConnection value, $Res Function(ServicesPackedConnection) _then) = _$ServicesPackedConnectionCopyWithImpl;
@useResult
$Res call({
 String id, GraphIdentifier source, GraphIdentifier target, Color color
});




}
/// @nodoc
class _$ServicesPackedConnectionCopyWithImpl<$Res>
    implements $ServicesPackedConnectionCopyWith<$Res> {
  _$ServicesPackedConnectionCopyWithImpl(this._self, this._then);

  final ServicesPackedConnection _self;
  final $Res Function(ServicesPackedConnection) _then;

/// Create a copy of ServicesPackedConnection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? target = null,Object? color = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}

}


/// Adds pattern-matching-related methods to [ServicesPackedConnection].
extension ServicesPackedConnectionPatterns on ServicesPackedConnection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServicesPackedConnection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServicesPackedConnection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServicesPackedConnection value)  $default,){
final _that = this;
switch (_that) {
case _ServicesPackedConnection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServicesPackedConnection value)?  $default,){
final _that = this;
switch (_that) {
case _ServicesPackedConnection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GraphIdentifier source,  GraphIdentifier target,  Color color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServicesPackedConnection() when $default != null:
return $default(_that.id,_that.source,_that.target,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GraphIdentifier source,  GraphIdentifier target,  Color color)  $default,) {final _that = this;
switch (_that) {
case _ServicesPackedConnection():
return $default(_that.id,_that.source,_that.target,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GraphIdentifier source,  GraphIdentifier target,  Color color)?  $default,) {final _that = this;
switch (_that) {
case _ServicesPackedConnection() when $default != null:
return $default(_that.id,_that.source,_that.target,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class _ServicesPackedConnection implements ServicesPackedConnection {
  const _ServicesPackedConnection({required this.id, required this.source, required this.target, required this.color});
  

@override final  String id;
@override final  GraphIdentifier source;
@override final  GraphIdentifier target;
@override final  Color color;

/// Create a copy of ServicesPackedConnection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServicesPackedConnectionCopyWith<_ServicesPackedConnection> get copyWith => __$ServicesPackedConnectionCopyWithImpl<_ServicesPackedConnection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServicesPackedConnection&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,source,target,color);

@override
String toString() {
  return 'ServicesPackedConnection(id: $id, source: $source, target: $target, color: $color)';
}


}

/// @nodoc
abstract mixin class _$ServicesPackedConnectionCopyWith<$Res> implements $ServicesPackedConnectionCopyWith<$Res> {
  factory _$ServicesPackedConnectionCopyWith(_ServicesPackedConnection value, $Res Function(_ServicesPackedConnection) _then) = __$ServicesPackedConnectionCopyWithImpl;
@override @useResult
$Res call({
 String id, GraphIdentifier source, GraphIdentifier target, Color color
});




}
/// @nodoc
class __$ServicesPackedConnectionCopyWithImpl<$Res>
    implements _$ServicesPackedConnectionCopyWith<$Res> {
  __$ServicesPackedConnectionCopyWithImpl(this._self, this._then);

  final _ServicesPackedConnection _self;
  final $Res Function(_ServicesPackedConnection) _then;

/// Create a copy of ServicesPackedConnection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? target = null,Object? color = null,}) {
  return _then(_ServicesPackedConnection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

/// @nodoc
mixin _$ServicesPackedComponentPlacement {

 String get id; int get width; int get height; Map<GraphIdentifier, ServicesPackedGridPlacement> get placements;
/// Create a copy of ServicesPackedComponentPlacement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServicesPackedComponentPlacementCopyWith<ServicesPackedComponentPlacement> get copyWith => _$ServicesPackedComponentPlacementCopyWithImpl<ServicesPackedComponentPlacement>(this as ServicesPackedComponentPlacement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServicesPackedComponentPlacement&&(identical(other.id, id) || other.id == id)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&const DeepCollectionEquality().equals(other.placements, placements));
}


@override
int get hashCode => Object.hash(runtimeType,id,width,height,const DeepCollectionEquality().hash(placements));

@override
String toString() {
  return 'ServicesPackedComponentPlacement(id: $id, width: $width, height: $height, placements: $placements)';
}


}

/// @nodoc
abstract mixin class $ServicesPackedComponentPlacementCopyWith<$Res>  {
  factory $ServicesPackedComponentPlacementCopyWith(ServicesPackedComponentPlacement value, $Res Function(ServicesPackedComponentPlacement) _then) = _$ServicesPackedComponentPlacementCopyWithImpl;
@useResult
$Res call({
 String id, int width, int height, Map<GraphIdentifier, ServicesPackedGridPlacement> placements
});




}
/// @nodoc
class _$ServicesPackedComponentPlacementCopyWithImpl<$Res>
    implements $ServicesPackedComponentPlacementCopyWith<$Res> {
  _$ServicesPackedComponentPlacementCopyWithImpl(this._self, this._then);

  final ServicesPackedComponentPlacement _self;
  final $Res Function(ServicesPackedComponentPlacement) _then;

/// Create a copy of ServicesPackedComponentPlacement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? width = null,Object? height = null,Object? placements = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,placements: null == placements ? _self.placements : placements // ignore: cast_nullable_to_non_nullable
as Map<GraphIdentifier, ServicesPackedGridPlacement>,
  ));
}

}


/// Adds pattern-matching-related methods to [ServicesPackedComponentPlacement].
extension ServicesPackedComponentPlacementPatterns on ServicesPackedComponentPlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServicesPackedComponentPlacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServicesPackedComponentPlacement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServicesPackedComponentPlacement value)  $default,){
final _that = this;
switch (_that) {
case _ServicesPackedComponentPlacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServicesPackedComponentPlacement value)?  $default,){
final _that = this;
switch (_that) {
case _ServicesPackedComponentPlacement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int width,  int height,  Map<GraphIdentifier, ServicesPackedGridPlacement> placements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServicesPackedComponentPlacement() when $default != null:
return $default(_that.id,_that.width,_that.height,_that.placements);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int width,  int height,  Map<GraphIdentifier, ServicesPackedGridPlacement> placements)  $default,) {final _that = this;
switch (_that) {
case _ServicesPackedComponentPlacement():
return $default(_that.id,_that.width,_that.height,_that.placements);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int width,  int height,  Map<GraphIdentifier, ServicesPackedGridPlacement> placements)?  $default,) {final _that = this;
switch (_that) {
case _ServicesPackedComponentPlacement() when $default != null:
return $default(_that.id,_that.width,_that.height,_that.placements);case _:
  return null;

}
}

}

/// @nodoc


class _ServicesPackedComponentPlacement implements ServicesPackedComponentPlacement {
  const _ServicesPackedComponentPlacement({required this.id, required this.width, required this.height, required final  Map<GraphIdentifier, ServicesPackedGridPlacement> placements}): _placements = placements;
  

@override final  String id;
@override final  int width;
@override final  int height;
 final  Map<GraphIdentifier, ServicesPackedGridPlacement> _placements;
@override Map<GraphIdentifier, ServicesPackedGridPlacement> get placements {
  if (_placements is EqualUnmodifiableMapView) return _placements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_placements);
}


/// Create a copy of ServicesPackedComponentPlacement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServicesPackedComponentPlacementCopyWith<_ServicesPackedComponentPlacement> get copyWith => __$ServicesPackedComponentPlacementCopyWithImpl<_ServicesPackedComponentPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServicesPackedComponentPlacement&&(identical(other.id, id) || other.id == id)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&const DeepCollectionEquality().equals(other._placements, _placements));
}


@override
int get hashCode => Object.hash(runtimeType,id,width,height,const DeepCollectionEquality().hash(_placements));

@override
String toString() {
  return 'ServicesPackedComponentPlacement(id: $id, width: $width, height: $height, placements: $placements)';
}


}

/// @nodoc
abstract mixin class _$ServicesPackedComponentPlacementCopyWith<$Res> implements $ServicesPackedComponentPlacementCopyWith<$Res> {
  factory _$ServicesPackedComponentPlacementCopyWith(_ServicesPackedComponentPlacement value, $Res Function(_ServicesPackedComponentPlacement) _then) = __$ServicesPackedComponentPlacementCopyWithImpl;
@override @useResult
$Res call({
 String id, int width, int height, Map<GraphIdentifier, ServicesPackedGridPlacement> placements
});




}
/// @nodoc
class __$ServicesPackedComponentPlacementCopyWithImpl<$Res>
    implements _$ServicesPackedComponentPlacementCopyWith<$Res> {
  __$ServicesPackedComponentPlacementCopyWithImpl(this._self, this._then);

  final _ServicesPackedComponentPlacement _self;
  final $Res Function(_ServicesPackedComponentPlacement) _then;

/// Create a copy of ServicesPackedComponentPlacement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? width = null,Object? height = null,Object? placements = null,}) {
  return _then(_ServicesPackedComponentPlacement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,placements: null == placements ? _self._placements : placements // ignore: cast_nullable_to_non_nullable
as Map<GraphIdentifier, ServicesPackedGridPlacement>,
  ));
}


}

/// @nodoc
mixin _$ServicesPackedGridPlacement {

 int get x; int get y; int get width; int get height;
/// Create a copy of ServicesPackedGridPlacement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServicesPackedGridPlacementCopyWith<ServicesPackedGridPlacement> get copyWith => _$ServicesPackedGridPlacementCopyWithImpl<ServicesPackedGridPlacement>(this as ServicesPackedGridPlacement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServicesPackedGridPlacement&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'ServicesPackedGridPlacement(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $ServicesPackedGridPlacementCopyWith<$Res>  {
  factory $ServicesPackedGridPlacementCopyWith(ServicesPackedGridPlacement value, $Res Function(ServicesPackedGridPlacement) _then) = _$ServicesPackedGridPlacementCopyWithImpl;
@useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class _$ServicesPackedGridPlacementCopyWithImpl<$Res>
    implements $ServicesPackedGridPlacementCopyWith<$Res> {
  _$ServicesPackedGridPlacementCopyWithImpl(this._self, this._then);

  final ServicesPackedGridPlacement _self;
  final $Res Function(ServicesPackedGridPlacement) _then;

/// Create a copy of ServicesPackedGridPlacement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ServicesPackedGridPlacement].
extension ServicesPackedGridPlacementPatterns on ServicesPackedGridPlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServicesPackedGridPlacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServicesPackedGridPlacement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServicesPackedGridPlacement value)  $default,){
final _that = this;
switch (_that) {
case _ServicesPackedGridPlacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServicesPackedGridPlacement value)?  $default,){
final _that = this;
switch (_that) {
case _ServicesPackedGridPlacement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServicesPackedGridPlacement() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _ServicesPackedGridPlacement():
return $default(_that.x,_that.y,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int x,  int y,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _ServicesPackedGridPlacement() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _ServicesPackedGridPlacement extends ServicesPackedGridPlacement {
  const _ServicesPackedGridPlacement({required this.x, required this.y, required this.width, required this.height}): super._();
  

@override final  int x;
@override final  int y;
@override final  int width;
@override final  int height;

/// Create a copy of ServicesPackedGridPlacement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServicesPackedGridPlacementCopyWith<_ServicesPackedGridPlacement> get copyWith => __$ServicesPackedGridPlacementCopyWithImpl<_ServicesPackedGridPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServicesPackedGridPlacement&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'ServicesPackedGridPlacement(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$ServicesPackedGridPlacementCopyWith<$Res> implements $ServicesPackedGridPlacementCopyWith<$Res> {
  factory _$ServicesPackedGridPlacementCopyWith(_ServicesPackedGridPlacement value, $Res Function(_ServicesPackedGridPlacement) _then) = __$ServicesPackedGridPlacementCopyWithImpl;
@override @useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class __$ServicesPackedGridPlacementCopyWithImpl<$Res>
    implements _$ServicesPackedGridPlacementCopyWith<$Res> {
  __$ServicesPackedGridPlacementCopyWithImpl(this._self, this._then);

  final _ServicesPackedGridPlacement _self;
  final $Res Function(_ServicesPackedGridPlacement) _then;

/// Create a copy of ServicesPackedGridPlacement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_ServicesPackedGridPlacement(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
