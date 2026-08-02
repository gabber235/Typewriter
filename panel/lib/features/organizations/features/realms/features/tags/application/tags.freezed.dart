// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Placement {

 int get x; int get y; int get width; int get height;
/// Create a copy of Placement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlacementCopyWith<Placement> get copyWith => _$PlacementCopyWithImpl<Placement>(this as Placement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Placement&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'Placement(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $PlacementCopyWith<$Res>  {
  factory $PlacementCopyWith(Placement value, $Res Function(Placement) _then) = _$PlacementCopyWithImpl;
@useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class _$PlacementCopyWithImpl<$Res>
    implements $PlacementCopyWith<$Res> {
  _$PlacementCopyWithImpl(this._self, this._then);

  final Placement _self;
  final $Res Function(Placement) _then;

/// Create a copy of Placement
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


/// Adds pattern-matching-related methods to [Placement].
extension PlacementPatterns on Placement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Placement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Placement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Placement value)  $default,){
final _that = this;
switch (_that) {
case _Placement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Placement value)?  $default,){
final _that = this;
switch (_that) {
case _Placement() when $default != null:
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
case _Placement() when $default != null:
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
case _Placement():
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
case _Placement() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _Placement extends Placement {
  const _Placement({required this.x, required this.y, required this.width, required this.height}): super._();
  

@override final  int x;
@override final  int y;
@override final  int width;
@override final  int height;

/// Create a copy of Placement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlacementCopyWith<_Placement> get copyWith => __$PlacementCopyWithImpl<_Placement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Placement&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'Placement(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$PlacementCopyWith<$Res> implements $PlacementCopyWith<$Res> {
  factory _$PlacementCopyWith(_Placement value, $Res Function(_Placement) _then) = __$PlacementCopyWithImpl;
@override @useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class __$PlacementCopyWithImpl<$Res>
    implements _$PlacementCopyWith<$Res> {
  __$PlacementCopyWithImpl(this._self, this._then);

  final _Placement _self;
  final $Res Function(_Placement) _then;

/// Create a copy of Placement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_Placement(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Tag {

 skir.RecordId get tagId; String get name; Color get color; List<skir.RecordId> get parentIds; Placement get placement;
/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagCopyWith<Tag> get copyWith => _$TagCopyWithImpl<Tag>(this as Tag, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tag&&(identical(other.tagId, tagId) || other.tagId == tagId)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.parentIds, parentIds)&&(identical(other.placement, placement) || other.placement == placement));
}


@override
int get hashCode => Object.hash(runtimeType,tagId,name,color,const DeepCollectionEquality().hash(parentIds),placement);

@override
String toString() {
  return 'Tag(tagId: $tagId, name: $name, color: $color, parentIds: $parentIds, placement: $placement)';
}


}

/// @nodoc
abstract mixin class $TagCopyWith<$Res>  {
  factory $TagCopyWith(Tag value, $Res Function(Tag) _then) = _$TagCopyWithImpl;
@useResult
$Res call({
 skir.RecordId tagId, String name, Color color, List<skir.RecordId> parentIds, Placement placement
});


$PlacementCopyWith<$Res> get placement;

}
/// @nodoc
class _$TagCopyWithImpl<$Res>
    implements $TagCopyWith<$Res> {
  _$TagCopyWithImpl(this._self, this._then);

  final Tag _self;
  final $Res Function(Tag) _then;

/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tagId = null,Object? name = null,Object? color = null,Object? parentIds = null,Object? placement = null,}) {
  return _then(_self.copyWith(
tagId: null == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,parentIds: null == parentIds ? _self.parentIds : parentIds // ignore: cast_nullable_to_non_nullable
as List<skir.RecordId>,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as Placement,
  ));
}
/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlacementCopyWith<$Res> get placement {
  
  return $PlacementCopyWith<$Res>(_self.placement, (value) {
    return _then(_self.copyWith(placement: value));
  });
}
}


/// Adds pattern-matching-related methods to [Tag].
extension TagPatterns on Tag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tag value)  $default,){
final _that = this;
switch (_that) {
case _Tag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tag value)?  $default,){
final _that = this;
switch (_that) {
case _Tag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId tagId,  String name,  Color color,  List<skir.RecordId> parentIds,  Placement placement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tag() when $default != null:
return $default(_that.tagId,_that.name,_that.color,_that.parentIds,_that.placement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId tagId,  String name,  Color color,  List<skir.RecordId> parentIds,  Placement placement)  $default,) {final _that = this;
switch (_that) {
case _Tag():
return $default(_that.tagId,_that.name,_that.color,_that.parentIds,_that.placement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId tagId,  String name,  Color color,  List<skir.RecordId> parentIds,  Placement placement)?  $default,) {final _that = this;
switch (_that) {
case _Tag() when $default != null:
return $default(_that.tagId,_that.name,_that.color,_that.parentIds,_that.placement);case _:
  return null;

}
}

}

/// @nodoc


class _Tag extends Tag {
  const _Tag({required this.tagId, required this.name, required this.color, required final  List<skir.RecordId> parentIds, required this.placement}): assert(name != "", 'Name must not be empty.'),_parentIds = parentIds,super._();
  

@override final  skir.RecordId tagId;
@override final  String name;
@override final  Color color;
 final  List<skir.RecordId> _parentIds;
@override List<skir.RecordId> get parentIds {
  if (_parentIds is EqualUnmodifiableListView) return _parentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parentIds);
}

@override final  Placement placement;

/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TagCopyWith<_Tag> get copyWith => __$TagCopyWithImpl<_Tag>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tag&&(identical(other.tagId, tagId) || other.tagId == tagId)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other._parentIds, _parentIds)&&(identical(other.placement, placement) || other.placement == placement));
}


@override
int get hashCode => Object.hash(runtimeType,tagId,name,color,const DeepCollectionEquality().hash(_parentIds),placement);

@override
String toString() {
  return 'Tag(tagId: $tagId, name: $name, color: $color, parentIds: $parentIds, placement: $placement)';
}


}

/// @nodoc
abstract mixin class _$TagCopyWith<$Res> implements $TagCopyWith<$Res> {
  factory _$TagCopyWith(_Tag value, $Res Function(_Tag) _then) = __$TagCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId tagId, String name, Color color, List<skir.RecordId> parentIds, Placement placement
});


@override $PlacementCopyWith<$Res> get placement;

}
/// @nodoc
class __$TagCopyWithImpl<$Res>
    implements _$TagCopyWith<$Res> {
  __$TagCopyWithImpl(this._self, this._then);

  final _Tag _self;
  final $Res Function(_Tag) _then;

/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tagId = null,Object? name = null,Object? color = null,Object? parentIds = null,Object? placement = null,}) {
  return _then(_Tag(
tagId: null == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,parentIds: null == parentIds ? _self._parentIds : parentIds // ignore: cast_nullable_to_non_nullable
as List<skir.RecordId>,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as Placement,
  ));
}

/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlacementCopyWith<$Res> get placement {
  
  return $PlacementCopyWith<$Res>(_self.placement, (value) {
    return _then(_self.copyWith(placement: value));
  });
}
}

// dart format on
