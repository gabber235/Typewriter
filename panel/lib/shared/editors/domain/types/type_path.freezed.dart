// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'type_path.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TypeQuerySegment {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeQuerySegment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypeQuerySegment()';
}


}

/// @nodoc
class $TypeQuerySegmentCopyWith<$Res>  {
$TypeQuerySegmentCopyWith(TypeQuerySegment _, $Res Function(TypeQuerySegment) __);
}


/// Adds pattern-matching-related methods to [TypeQuerySegment].
extension TypeQuerySegmentPatterns on TypeQuerySegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TypeFieldQuerySegment value)?  field,TResult Function( TypeListElementQuerySegment value)?  listElement,TResult Function( TypeMapValueQuerySegment value)?  mapValue,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TypeFieldQuerySegment() when field != null:
return field(_that);case TypeListElementQuerySegment() when listElement != null:
return listElement(_that);case TypeMapValueQuerySegment() when mapValue != null:
return mapValue(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TypeFieldQuerySegment value)  field,required TResult Function( TypeListElementQuerySegment value)  listElement,required TResult Function( TypeMapValueQuerySegment value)  mapValue,}){
final _that = this;
switch (_that) {
case TypeFieldQuerySegment():
return field(_that);case TypeListElementQuerySegment():
return listElement(_that);case TypeMapValueQuerySegment():
return mapValue(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TypeFieldQuerySegment value)?  field,TResult? Function( TypeListElementQuerySegment value)?  listElement,TResult? Function( TypeMapValueQuerySegment value)?  mapValue,}){
final _that = this;
switch (_that) {
case TypeFieldQuerySegment() when field != null:
return field(_that);case TypeListElementQuerySegment() when listElement != null:
return listElement(_that);case TypeMapValueQuerySegment() when mapValue != null:
return mapValue(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name)?  field,TResult Function()?  listElement,TResult Function()?  mapValue,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TypeFieldQuerySegment() when field != null:
return field(_that.name);case TypeListElementQuerySegment() when listElement != null:
return listElement();case TypeMapValueQuerySegment() when mapValue != null:
return mapValue();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name)  field,required TResult Function()  listElement,required TResult Function()  mapValue,}) {final _that = this;
switch (_that) {
case TypeFieldQuerySegment():
return field(_that.name);case TypeListElementQuerySegment():
return listElement();case TypeMapValueQuerySegment():
return mapValue();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name)?  field,TResult? Function()?  listElement,TResult? Function()?  mapValue,}) {final _that = this;
switch (_that) {
case TypeFieldQuerySegment() when field != null:
return field(_that.name);case TypeListElementQuerySegment() when listElement != null:
return listElement();case TypeMapValueQuerySegment() when mapValue != null:
return mapValue();case _:
  return null;

}
}

}

/// @nodoc


class TypeFieldQuerySegment implements TypeQuerySegment {
  const TypeFieldQuerySegment(this.name);
  

 final  String name;

/// Create a copy of TypeQuerySegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeFieldQuerySegmentCopyWith<TypeFieldQuerySegment> get copyWith => _$TypeFieldQuerySegmentCopyWithImpl<TypeFieldQuerySegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeFieldQuerySegment&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'TypeQuerySegment.field(name: $name)';
}


}

/// @nodoc
abstract mixin class $TypeFieldQuerySegmentCopyWith<$Res> implements $TypeQuerySegmentCopyWith<$Res> {
  factory $TypeFieldQuerySegmentCopyWith(TypeFieldQuerySegment value, $Res Function(TypeFieldQuerySegment) _then) = _$TypeFieldQuerySegmentCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$TypeFieldQuerySegmentCopyWithImpl<$Res>
    implements $TypeFieldQuerySegmentCopyWith<$Res> {
  _$TypeFieldQuerySegmentCopyWithImpl(this._self, this._then);

  final TypeFieldQuerySegment _self;
  final $Res Function(TypeFieldQuerySegment) _then;

/// Create a copy of TypeQuerySegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(TypeFieldQuerySegment(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TypeListElementQuerySegment implements TypeQuerySegment {
  const TypeListElementQuerySegment();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeListElementQuerySegment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypeQuerySegment.listElement()';
}


}




/// @nodoc


class TypeMapValueQuerySegment implements TypeQuerySegment {
  const TypeMapValueQuerySegment();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeMapValueQuerySegment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypeQuerySegment.mapValue()';
}


}




/// @nodoc
mixin _$TypeReferenceLocation {

 List<TypeQuerySegment> get path; NamedType get type;
/// Create a copy of TypeReferenceLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeReferenceLocationCopyWith<TypeReferenceLocation> get copyWith => _$TypeReferenceLocationCopyWithImpl<TypeReferenceLocation>(this as TypeReferenceLocation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeReferenceLocation&&const DeepCollectionEquality().equals(other.path, path)&&const DeepCollectionEquality().equals(other.type, type));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(path),const DeepCollectionEquality().hash(type));

@override
String toString() {
  return 'TypeReferenceLocation(path: $path, type: $type)';
}


}

/// @nodoc
abstract mixin class $TypeReferenceLocationCopyWith<$Res>  {
  factory $TypeReferenceLocationCopyWith(TypeReferenceLocation value, $Res Function(TypeReferenceLocation) _then) = _$TypeReferenceLocationCopyWithImpl;
@useResult
$Res call({
 List<TypeQuerySegment> path, NamedType type
});




}
/// @nodoc
class _$TypeReferenceLocationCopyWithImpl<$Res>
    implements $TypeReferenceLocationCopyWith<$Res> {
  _$TypeReferenceLocationCopyWithImpl(this._self, this._then);

  final TypeReferenceLocation _self;
  final $Res Function(TypeReferenceLocation) _then;

/// Create a copy of TypeReferenceLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? type = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<TypeQuerySegment>,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NamedType,
  ));
}

}


/// Adds pattern-matching-related methods to [TypeReferenceLocation].
extension TypeReferenceLocationPatterns on TypeReferenceLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypeReferenceLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypeReferenceLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypeReferenceLocation value)  $default,){
final _that = this;
switch (_that) {
case _TypeReferenceLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypeReferenceLocation value)?  $default,){
final _that = this;
switch (_that) {
case _TypeReferenceLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TypeQuerySegment> path,  NamedType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypeReferenceLocation() when $default != null:
return $default(_that.path,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TypeQuerySegment> path,  NamedType type)  $default,) {final _that = this;
switch (_that) {
case _TypeReferenceLocation():
return $default(_that.path,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TypeQuerySegment> path,  NamedType type)?  $default,) {final _that = this;
switch (_that) {
case _TypeReferenceLocation() when $default != null:
return $default(_that.path,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _TypeReferenceLocation extends TypeReferenceLocation {
  const _TypeReferenceLocation({required final  List<TypeQuerySegment> path, required this.type}): _path = path,super._();
  

 final  List<TypeQuerySegment> _path;
@override List<TypeQuerySegment> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}

@override final  NamedType type;

/// Create a copy of TypeReferenceLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypeReferenceLocationCopyWith<_TypeReferenceLocation> get copyWith => __$TypeReferenceLocationCopyWithImpl<_TypeReferenceLocation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypeReferenceLocation&&const DeepCollectionEquality().equals(other._path, _path)&&const DeepCollectionEquality().equals(other.type, type));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_path),const DeepCollectionEquality().hash(type));

@override
String toString() {
  return 'TypeReferenceLocation(path: $path, type: $type)';
}


}

/// @nodoc
abstract mixin class _$TypeReferenceLocationCopyWith<$Res> implements $TypeReferenceLocationCopyWith<$Res> {
  factory _$TypeReferenceLocationCopyWith(_TypeReferenceLocation value, $Res Function(_TypeReferenceLocation) _then) = __$TypeReferenceLocationCopyWithImpl;
@override @useResult
$Res call({
 List<TypeQuerySegment> path, NamedType type
});




}
/// @nodoc
class __$TypeReferenceLocationCopyWithImpl<$Res>
    implements _$TypeReferenceLocationCopyWith<$Res> {
  __$TypeReferenceLocationCopyWithImpl(this._self, this._then);

  final _TypeReferenceLocation _self;
  final $Res Function(_TypeReferenceLocation) _then;

/// Create a copy of TypeReferenceLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? type = freezed,}) {
  return _then(_TypeReferenceLocation(
path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<TypeQuerySegment>,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NamedType,
  ));
}


}

// dart format on
