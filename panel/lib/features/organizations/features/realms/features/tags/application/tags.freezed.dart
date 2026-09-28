// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Tag {

 skir.ResourceId get tagId; String get name; Color get color; List<skir.ResourceId> get parentIds; GraphPlacement get placement;
/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagCopyWith<Tag> get copyWith => _$TagCopyWithImpl<Tag>(this as Tag, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Tag;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tag&&(identical(other.tagId, _this.tagId) || other.tagId == _this.tagId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.color, _this.color) || other.color == _this.color)&&const DeepCollectionEquality().equals(other.parentIds, _this.parentIds)&&(identical(other.placement, _this.placement) || other.placement == _this.placement));
}


@override
int get hashCode {
  final _this = this as Tag;
  return Object.hash(runtimeType,_this.tagId,_this.name,_this.color,const DeepCollectionEquality().hash(_this.parentIds),_this.placement);
}

@override
String toString() {
  final _this = this as Tag;
  return 'Tag(tagId: ${_this.tagId}, name: ${_this.name}, color: ${_this.color}, parentIds: ${_this.parentIds}, placement: ${_this.placement})';
}


}

/// @nodoc
abstract mixin class $TagCopyWith<$Res>  {
  factory $TagCopyWith(Tag value, $Res Function(Tag) _then) = _$TagCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId tagId, String name, Color color, List<skir.ResourceId> parentIds, GraphPlacement placement
});




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
  return _then(Tag(
tagId: null == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,parentIds: null == parentIds ? _self.parentIds : parentIds // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as GraphPlacement,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId tagId,  String name,  Color color,  List<skir.ResourceId> parentIds,  GraphPlacement placement)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId tagId,  String name,  Color color,  List<skir.ResourceId> parentIds,  GraphPlacement placement)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId tagId,  String name,  Color color,  List<skir.ResourceId> parentIds,  GraphPlacement placement)?  $default,) {final _that = this;
switch (_that) {
case _Tag() when $default != null:
return $default(_that.tagId,_that.name,_that.color,_that.parentIds,_that.placement);case _:
  return null;

}
}

}

/// @nodoc


class _Tag extends Tag {
  const _Tag({required this.tagId, required this.name, required this.color, required  List<skir.ResourceId> parentIds, required this.placement}): assert(name != "", 'Name must not be empty.'),_parentIds = parentIds,super._();
  

@override final  skir.ResourceId tagId;
@override final  String name;
@override final  Color color;
 final  List<skir.ResourceId> _parentIds;
@override List<skir.ResourceId> get parentIds {
  if (_parentIds is EqualUnmodifiableListView) return _parentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parentIds);
}

@override final  GraphPlacement placement;

/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TagCopyWith<_Tag> get copyWith => __$TagCopyWithImpl<_Tag>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tag&&(identical(other.tagId, tagId) || other.tagId == tagId)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.parentIds, _parentIds)&&(identical(other.placement, placement) || other.placement == placement));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tagId,name,color,const DeepCollectionEquality().hash(_parentIds),placement);
}

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
 skir.ResourceId tagId, String name, Color color, List<skir.ResourceId> parentIds, GraphPlacement placement
});




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
as skir.ResourceId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,parentIds: null == parentIds ? _self._parentIds : parentIds // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as GraphPlacement,
  ));
}


}

// dart format on
