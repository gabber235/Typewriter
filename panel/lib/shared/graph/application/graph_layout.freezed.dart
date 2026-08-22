// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'graph_layout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GraphInteractionPreview {

 Set<GraphIdentifier> get movingIds; (int, int) get moveDelta; GraphResizePreview? get resize;
/// Create a copy of GraphInteractionPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphInteractionPreviewCopyWith<GraphInteractionPreview> get copyWith => _$GraphInteractionPreviewCopyWithImpl<GraphInteractionPreview>(this as GraphInteractionPreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphInteractionPreview&&const DeepCollectionEquality().equals(other.movingIds, movingIds)&&(identical(other.moveDelta, moveDelta) || other.moveDelta == moveDelta)&&(identical(other.resize, resize) || other.resize == resize));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(movingIds),moveDelta,resize);

@override
String toString() {
  return 'GraphInteractionPreview(movingIds: $movingIds, moveDelta: $moveDelta, resize: $resize)';
}


}

/// @nodoc
abstract mixin class $GraphInteractionPreviewCopyWith<$Res>  {
  factory $GraphInteractionPreviewCopyWith(GraphInteractionPreview value, $Res Function(GraphInteractionPreview) _then) = _$GraphInteractionPreviewCopyWithImpl;
@useResult
$Res call({
 Set<GraphIdentifier> movingIds, (int, int) moveDelta, GraphResizePreview? resize
});


$GraphResizePreviewCopyWith<$Res>? get resize;

}
/// @nodoc
class _$GraphInteractionPreviewCopyWithImpl<$Res>
    implements $GraphInteractionPreviewCopyWith<$Res> {
  _$GraphInteractionPreviewCopyWithImpl(this._self, this._then);

  final GraphInteractionPreview _self;
  final $Res Function(GraphInteractionPreview) _then;

/// Create a copy of GraphInteractionPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? movingIds = null,Object? moveDelta = null,Object? resize = freezed,}) {
  return _then(_self.copyWith(
movingIds: null == movingIds ? _self.movingIds : movingIds // ignore: cast_nullable_to_non_nullable
as Set<GraphIdentifier>,moveDelta: null == moveDelta ? _self.moveDelta : moveDelta // ignore: cast_nullable_to_non_nullable
as (int, int),resize: freezed == resize ? _self.resize : resize // ignore: cast_nullable_to_non_nullable
as GraphResizePreview?,
  ));
}
/// Create a copy of GraphInteractionPreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphResizePreviewCopyWith<$Res>? get resize {
    if (_self.resize == null) {
    return null;
  }

  return $GraphResizePreviewCopyWith<$Res>(_self.resize!, (value) {
    return _then(_self.copyWith(resize: value));
  });
}
}


/// Adds pattern-matching-related methods to [GraphInteractionPreview].
extension GraphInteractionPreviewPatterns on GraphInteractionPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GraphInteractionPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GraphInteractionPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GraphInteractionPreview value)  $default,){
final _that = this;
switch (_that) {
case _GraphInteractionPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GraphInteractionPreview value)?  $default,){
final _that = this;
switch (_that) {
case _GraphInteractionPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<GraphIdentifier> movingIds,  (int, int) moveDelta,  GraphResizePreview? resize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GraphInteractionPreview() when $default != null:
return $default(_that.movingIds,_that.moveDelta,_that.resize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<GraphIdentifier> movingIds,  (int, int) moveDelta,  GraphResizePreview? resize)  $default,) {final _that = this;
switch (_that) {
case _GraphInteractionPreview():
return $default(_that.movingIds,_that.moveDelta,_that.resize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<GraphIdentifier> movingIds,  (int, int) moveDelta,  GraphResizePreview? resize)?  $default,) {final _that = this;
switch (_that) {
case _GraphInteractionPreview() when $default != null:
return $default(_that.movingIds,_that.moveDelta,_that.resize);case _:
  return null;

}
}

}

/// @nodoc


class _GraphInteractionPreview implements GraphInteractionPreview {
  const _GraphInteractionPreview({final  Set<GraphIdentifier> movingIds = const <GraphIdentifier>{}, this.moveDelta = const (0, 0), this.resize}): _movingIds = movingIds;
  

 final  Set<GraphIdentifier> _movingIds;
@override@JsonKey() Set<GraphIdentifier> get movingIds {
  if (_movingIds is EqualUnmodifiableSetView) return _movingIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_movingIds);
}

@override@JsonKey() final  (int, int) moveDelta;
@override final  GraphResizePreview? resize;

/// Create a copy of GraphInteractionPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GraphInteractionPreviewCopyWith<_GraphInteractionPreview> get copyWith => __$GraphInteractionPreviewCopyWithImpl<_GraphInteractionPreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GraphInteractionPreview&&const DeepCollectionEquality().equals(other._movingIds, _movingIds)&&(identical(other.moveDelta, moveDelta) || other.moveDelta == moveDelta)&&(identical(other.resize, resize) || other.resize == resize));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_movingIds),moveDelta,resize);

@override
String toString() {
  return 'GraphInteractionPreview(movingIds: $movingIds, moveDelta: $moveDelta, resize: $resize)';
}


}

/// @nodoc
abstract mixin class _$GraphInteractionPreviewCopyWith<$Res> implements $GraphInteractionPreviewCopyWith<$Res> {
  factory _$GraphInteractionPreviewCopyWith(_GraphInteractionPreview value, $Res Function(_GraphInteractionPreview) _then) = __$GraphInteractionPreviewCopyWithImpl;
@override @useResult
$Res call({
 Set<GraphIdentifier> movingIds, (int, int) moveDelta, GraphResizePreview? resize
});


@override $GraphResizePreviewCopyWith<$Res>? get resize;

}
/// @nodoc
class __$GraphInteractionPreviewCopyWithImpl<$Res>
    implements _$GraphInteractionPreviewCopyWith<$Res> {
  __$GraphInteractionPreviewCopyWithImpl(this._self, this._then);

  final _GraphInteractionPreview _self;
  final $Res Function(_GraphInteractionPreview) _then;

/// Create a copy of GraphInteractionPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? movingIds = null,Object? moveDelta = null,Object? resize = freezed,}) {
  return _then(_GraphInteractionPreview(
movingIds: null == movingIds ? _self._movingIds : movingIds // ignore: cast_nullable_to_non_nullable
as Set<GraphIdentifier>,moveDelta: null == moveDelta ? _self.moveDelta : moveDelta // ignore: cast_nullable_to_non_nullable
as (int, int),resize: freezed == resize ? _self.resize : resize // ignore: cast_nullable_to_non_nullable
as GraphResizePreview?,
  ));
}

/// Create a copy of GraphInteractionPreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphResizePreviewCopyWith<$Res>? get resize {
    if (_self.resize == null) {
    return null;
  }

  return $GraphResizePreviewCopyWith<$Res>(_self.resize!, (value) {
    return _then(_self.copyWith(resize: value));
  });
}
}

/// @nodoc
mixin _$GraphResizePreview {

 GraphIdentifier get id; int get width; int get height;
/// Create a copy of GraphResizePreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphResizePreviewCopyWith<GraphResizePreview> get copyWith => _$GraphResizePreviewCopyWithImpl<GraphResizePreview>(this as GraphResizePreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphResizePreview&&(identical(other.id, id) || other.id == id)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,id,width,height);

@override
String toString() {
  return 'GraphResizePreview(id: $id, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $GraphResizePreviewCopyWith<$Res>  {
  factory $GraphResizePreviewCopyWith(GraphResizePreview value, $Res Function(GraphResizePreview) _then) = _$GraphResizePreviewCopyWithImpl;
@useResult
$Res call({
 GraphIdentifier id, int width, int height
});




}
/// @nodoc
class _$GraphResizePreviewCopyWithImpl<$Res>
    implements $GraphResizePreviewCopyWith<$Res> {
  _$GraphResizePreviewCopyWithImpl(this._self, this._then);

  final GraphResizePreview _self;
  final $Res Function(GraphResizePreview) _then;

/// Create a copy of GraphResizePreview
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


/// Adds pattern-matching-related methods to [GraphResizePreview].
extension GraphResizePreviewPatterns on GraphResizePreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GraphResizePreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GraphResizePreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GraphResizePreview value)  $default,){
final _that = this;
switch (_that) {
case _GraphResizePreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GraphResizePreview value)?  $default,){
final _that = this;
switch (_that) {
case _GraphResizePreview() when $default != null:
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
case _GraphResizePreview() when $default != null:
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
case _GraphResizePreview():
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
case _GraphResizePreview() when $default != null:
return $default(_that.id,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _GraphResizePreview implements GraphResizePreview {
  const _GraphResizePreview({required this.id, required this.width, required this.height});
  

@override final  GraphIdentifier id;
@override final  int width;
@override final  int height;

/// Create a copy of GraphResizePreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GraphResizePreviewCopyWith<_GraphResizePreview> get copyWith => __$GraphResizePreviewCopyWithImpl<_GraphResizePreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GraphResizePreview&&(identical(other.id, id) || other.id == id)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,id,width,height);

@override
String toString() {
  return 'GraphResizePreview(id: $id, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$GraphResizePreviewCopyWith<$Res> implements $GraphResizePreviewCopyWith<$Res> {
  factory _$GraphResizePreviewCopyWith(_GraphResizePreview value, $Res Function(_GraphResizePreview) _then) = __$GraphResizePreviewCopyWithImpl;
@override @useResult
$Res call({
 GraphIdentifier id, int width, int height
});




}
/// @nodoc
class __$GraphResizePreviewCopyWithImpl<$Res>
    implements _$GraphResizePreviewCopyWith<$Res> {
  __$GraphResizePreviewCopyWithImpl(this._self, this._then);

  final _GraphResizePreview _self;
  final $Res Function(_GraphResizePreview) _then;

/// Create a copy of GraphResizePreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? width = null,Object? height = null,}) {
  return _then(_GraphResizePreview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GraphIdentifier,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$GraphPlacedElement {

 GraphElement get element; Rect get bounds;
/// Create a copy of GraphPlacedElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphPlacedElementCopyWith<GraphPlacedElement> get copyWith => _$GraphPlacedElementCopyWithImpl<GraphPlacedElement>(this as GraphPlacedElement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphPlacedElement&&(identical(other.element, element) || other.element == element)&&(identical(other.bounds, bounds) || other.bounds == bounds));
}


@override
int get hashCode => Object.hash(runtimeType,element,bounds);

@override
String toString() {
  return 'GraphPlacedElement(element: $element, bounds: $bounds)';
}


}

/// @nodoc
abstract mixin class $GraphPlacedElementCopyWith<$Res>  {
  factory $GraphPlacedElementCopyWith(GraphPlacedElement value, $Res Function(GraphPlacedElement) _then) = _$GraphPlacedElementCopyWithImpl;
@useResult
$Res call({
 GraphElement element, Rect bounds
});


$GraphElementCopyWith<$Res> get element;

}
/// @nodoc
class _$GraphPlacedElementCopyWithImpl<$Res>
    implements $GraphPlacedElementCopyWith<$Res> {
  _$GraphPlacedElementCopyWithImpl(this._self, this._then);

  final GraphPlacedElement _self;
  final $Res Function(GraphPlacedElement) _then;

/// Create a copy of GraphPlacedElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? element = null,Object? bounds = null,}) {
  return _then(_self.copyWith(
element: null == element ? _self.element : element // ignore: cast_nullable_to_non_nullable
as GraphElement,bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as Rect,
  ));
}
/// Create a copy of GraphPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphElementCopyWith<$Res> get element {
  
  return $GraphElementCopyWith<$Res>(_self.element, (value) {
    return _then(_self.copyWith(element: value));
  });
}
}


/// Adds pattern-matching-related methods to [GraphPlacedElement].
extension GraphPlacedElementPatterns on GraphPlacedElement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GraphPlacedElement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GraphPlacedElement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GraphPlacedElement value)  $default,){
final _that = this;
switch (_that) {
case _GraphPlacedElement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GraphPlacedElement value)?  $default,){
final _that = this;
switch (_that) {
case _GraphPlacedElement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GraphElement element,  Rect bounds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GraphPlacedElement() when $default != null:
return $default(_that.element,_that.bounds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GraphElement element,  Rect bounds)  $default,) {final _that = this;
switch (_that) {
case _GraphPlacedElement():
return $default(_that.element,_that.bounds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GraphElement element,  Rect bounds)?  $default,) {final _that = this;
switch (_that) {
case _GraphPlacedElement() when $default != null:
return $default(_that.element,_that.bounds);case _:
  return null;

}
}

}

/// @nodoc


class _GraphPlacedElement extends GraphPlacedElement {
  const _GraphPlacedElement({required this.element, required this.bounds}): super._();
  

@override final  GraphElement element;
@override final  Rect bounds;

/// Create a copy of GraphPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GraphPlacedElementCopyWith<_GraphPlacedElement> get copyWith => __$GraphPlacedElementCopyWithImpl<_GraphPlacedElement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GraphPlacedElement&&(identical(other.element, element) || other.element == element)&&(identical(other.bounds, bounds) || other.bounds == bounds));
}


@override
int get hashCode => Object.hash(runtimeType,element,bounds);

@override
String toString() {
  return 'GraphPlacedElement(element: $element, bounds: $bounds)';
}


}

/// @nodoc
abstract mixin class _$GraphPlacedElementCopyWith<$Res> implements $GraphPlacedElementCopyWith<$Res> {
  factory _$GraphPlacedElementCopyWith(_GraphPlacedElement value, $Res Function(_GraphPlacedElement) _then) = __$GraphPlacedElementCopyWithImpl;
@override @useResult
$Res call({
 GraphElement element, Rect bounds
});


@override $GraphElementCopyWith<$Res> get element;

}
/// @nodoc
class __$GraphPlacedElementCopyWithImpl<$Res>
    implements _$GraphPlacedElementCopyWith<$Res> {
  __$GraphPlacedElementCopyWithImpl(this._self, this._then);

  final _GraphPlacedElement _self;
  final $Res Function(_GraphPlacedElement) _then;

/// Create a copy of GraphPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? element = null,Object? bounds = null,}) {
  return _then(_GraphPlacedElement(
element: null == element ? _self.element : element // ignore: cast_nullable_to_non_nullable
as GraphElement,bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as Rect,
  ));
}

/// Create a copy of GraphPlacedElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphElementCopyWith<$Res> get element {
  
  return $GraphElementCopyWith<$Res>(_self.element, (value) {
    return _then(_self.copyWith(element: value));
  });
}
}

/// @nodoc
mixin _$GraphPlacedEdge {

 GraphEdge get edge; GraphPlacedElement get source; GraphPlacedElement get target; Offset get sourcePoint; Offset get targetPoint;
/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphPlacedEdgeCopyWith<GraphPlacedEdge> get copyWith => _$GraphPlacedEdgeCopyWithImpl<GraphPlacedEdge>(this as GraphPlacedEdge, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphPlacedEdge&&(identical(other.edge, edge) || other.edge == edge)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.sourcePoint, sourcePoint) || other.sourcePoint == sourcePoint)&&(identical(other.targetPoint, targetPoint) || other.targetPoint == targetPoint));
}


@override
int get hashCode => Object.hash(runtimeType,edge,source,target,sourcePoint,targetPoint);

@override
String toString() {
  return 'GraphPlacedEdge(edge: $edge, source: $source, target: $target, sourcePoint: $sourcePoint, targetPoint: $targetPoint)';
}


}

/// @nodoc
abstract mixin class $GraphPlacedEdgeCopyWith<$Res>  {
  factory $GraphPlacedEdgeCopyWith(GraphPlacedEdge value, $Res Function(GraphPlacedEdge) _then) = _$GraphPlacedEdgeCopyWithImpl;
@useResult
$Res call({
 GraphEdge edge, GraphPlacedElement source, GraphPlacedElement target, Offset sourcePoint, Offset targetPoint
});


$GraphEdgeCopyWith<$Res> get edge;$GraphPlacedElementCopyWith<$Res> get source;$GraphPlacedElementCopyWith<$Res> get target;

}
/// @nodoc
class _$GraphPlacedEdgeCopyWithImpl<$Res>
    implements $GraphPlacedEdgeCopyWith<$Res> {
  _$GraphPlacedEdgeCopyWithImpl(this._self, this._then);

  final GraphPlacedEdge _self;
  final $Res Function(GraphPlacedEdge) _then;

/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? edge = null,Object? source = null,Object? target = null,Object? sourcePoint = null,Object? targetPoint = null,}) {
  return _then(_self.copyWith(
edge: null == edge ? _self.edge : edge // ignore: cast_nullable_to_non_nullable
as GraphEdge,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as GraphPlacedElement,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as GraphPlacedElement,sourcePoint: null == sourcePoint ? _self.sourcePoint : sourcePoint // ignore: cast_nullable_to_non_nullable
as Offset,targetPoint: null == targetPoint ? _self.targetPoint : targetPoint // ignore: cast_nullable_to_non_nullable
as Offset,
  ));
}
/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphEdgeCopyWith<$Res> get edge {
  
  return $GraphEdgeCopyWith<$Res>(_self.edge, (value) {
    return _then(_self.copyWith(edge: value));
  });
}/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphPlacedElementCopyWith<$Res> get source {
  
  return $GraphPlacedElementCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphPlacedElementCopyWith<$Res> get target {
  
  return $GraphPlacedElementCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern-matching-related methods to [GraphPlacedEdge].
extension GraphPlacedEdgePatterns on GraphPlacedEdge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GraphPlacedEdge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GraphPlacedEdge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GraphPlacedEdge value)  $default,){
final _that = this;
switch (_that) {
case _GraphPlacedEdge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GraphPlacedEdge value)?  $default,){
final _that = this;
switch (_that) {
case _GraphPlacedEdge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GraphEdge edge,  GraphPlacedElement source,  GraphPlacedElement target,  Offset sourcePoint,  Offset targetPoint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GraphPlacedEdge() when $default != null:
return $default(_that.edge,_that.source,_that.target,_that.sourcePoint,_that.targetPoint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GraphEdge edge,  GraphPlacedElement source,  GraphPlacedElement target,  Offset sourcePoint,  Offset targetPoint)  $default,) {final _that = this;
switch (_that) {
case _GraphPlacedEdge():
return $default(_that.edge,_that.source,_that.target,_that.sourcePoint,_that.targetPoint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GraphEdge edge,  GraphPlacedElement source,  GraphPlacedElement target,  Offset sourcePoint,  Offset targetPoint)?  $default,) {final _that = this;
switch (_that) {
case _GraphPlacedEdge() when $default != null:
return $default(_that.edge,_that.source,_that.target,_that.sourcePoint,_that.targetPoint);case _:
  return null;

}
}

}

/// @nodoc


class _GraphPlacedEdge implements GraphPlacedEdge {
  const _GraphPlacedEdge({required this.edge, required this.source, required this.target, required this.sourcePoint, required this.targetPoint});
  

@override final  GraphEdge edge;
@override final  GraphPlacedElement source;
@override final  GraphPlacedElement target;
@override final  Offset sourcePoint;
@override final  Offset targetPoint;

/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GraphPlacedEdgeCopyWith<_GraphPlacedEdge> get copyWith => __$GraphPlacedEdgeCopyWithImpl<_GraphPlacedEdge>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GraphPlacedEdge&&(identical(other.edge, edge) || other.edge == edge)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.sourcePoint, sourcePoint) || other.sourcePoint == sourcePoint)&&(identical(other.targetPoint, targetPoint) || other.targetPoint == targetPoint));
}


@override
int get hashCode => Object.hash(runtimeType,edge,source,target,sourcePoint,targetPoint);

@override
String toString() {
  return 'GraphPlacedEdge(edge: $edge, source: $source, target: $target, sourcePoint: $sourcePoint, targetPoint: $targetPoint)';
}


}

/// @nodoc
abstract mixin class _$GraphPlacedEdgeCopyWith<$Res> implements $GraphPlacedEdgeCopyWith<$Res> {
  factory _$GraphPlacedEdgeCopyWith(_GraphPlacedEdge value, $Res Function(_GraphPlacedEdge) _then) = __$GraphPlacedEdgeCopyWithImpl;
@override @useResult
$Res call({
 GraphEdge edge, GraphPlacedElement source, GraphPlacedElement target, Offset sourcePoint, Offset targetPoint
});


@override $GraphEdgeCopyWith<$Res> get edge;@override $GraphPlacedElementCopyWith<$Res> get source;@override $GraphPlacedElementCopyWith<$Res> get target;

}
/// @nodoc
class __$GraphPlacedEdgeCopyWithImpl<$Res>
    implements _$GraphPlacedEdgeCopyWith<$Res> {
  __$GraphPlacedEdgeCopyWithImpl(this._self, this._then);

  final _GraphPlacedEdge _self;
  final $Res Function(_GraphPlacedEdge) _then;

/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? edge = null,Object? source = null,Object? target = null,Object? sourcePoint = null,Object? targetPoint = null,}) {
  return _then(_GraphPlacedEdge(
edge: null == edge ? _self.edge : edge // ignore: cast_nullable_to_non_nullable
as GraphEdge,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as GraphPlacedElement,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as GraphPlacedElement,sourcePoint: null == sourcePoint ? _self.sourcePoint : sourcePoint // ignore: cast_nullable_to_non_nullable
as Offset,targetPoint: null == targetPoint ? _self.targetPoint : targetPoint // ignore: cast_nullable_to_non_nullable
as Offset,
  ));
}

/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphEdgeCopyWith<$Res> get edge {
  
  return $GraphEdgeCopyWith<$Res>(_self.edge, (value) {
    return _then(_self.copyWith(edge: value));
  });
}/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphPlacedElementCopyWith<$Res> get source {
  
  return $GraphPlacedElementCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of GraphPlacedEdge
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GraphPlacedElementCopyWith<$Res> get target {
  
  return $GraphPlacedElementCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

// dart format on
