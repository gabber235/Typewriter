// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'icon_search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IconSearchResultPayload {

 String get identifier; String get name; String get collection;
/// Create a copy of IconSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IconSearchResultPayloadCopyWith<IconSearchResultPayload> get copyWith => _$IconSearchResultPayloadCopyWithImpl<IconSearchResultPayload>(this as IconSearchResultPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IconSearchResultPayload&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.name, name) || other.name == name)&&(identical(other.collection, collection) || other.collection == collection));
}


@override
int get hashCode => Object.hash(runtimeType,identifier,name,collection);

@override
String toString() {
  return 'IconSearchResultPayload(identifier: $identifier, name: $name, collection: $collection)';
}


}

/// @nodoc
abstract mixin class $IconSearchResultPayloadCopyWith<$Res>  {
  factory $IconSearchResultPayloadCopyWith(IconSearchResultPayload value, $Res Function(IconSearchResultPayload) _then) = _$IconSearchResultPayloadCopyWithImpl;
@useResult
$Res call({
 String identifier, String name, String collection
});




}
/// @nodoc
class _$IconSearchResultPayloadCopyWithImpl<$Res>
    implements $IconSearchResultPayloadCopyWith<$Res> {
  _$IconSearchResultPayloadCopyWithImpl(this._self, this._then);

  final IconSearchResultPayload _self;
  final $Res Function(IconSearchResultPayload) _then;

/// Create a copy of IconSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identifier = null,Object? name = null,Object? collection = null,}) {
  return _then(_self.copyWith(
identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,collection: null == collection ? _self.collection : collection // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IconSearchResultPayload].
extension IconSearchResultPayloadPatterns on IconSearchResultPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IconSearchResultPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IconSearchResultPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IconSearchResultPayload value)  $default,){
final _that = this;
switch (_that) {
case _IconSearchResultPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IconSearchResultPayload value)?  $default,){
final _that = this;
switch (_that) {
case _IconSearchResultPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String identifier,  String name,  String collection)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IconSearchResultPayload() when $default != null:
return $default(_that.identifier,_that.name,_that.collection);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String identifier,  String name,  String collection)  $default,) {final _that = this;
switch (_that) {
case _IconSearchResultPayload():
return $default(_that.identifier,_that.name,_that.collection);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String identifier,  String name,  String collection)?  $default,) {final _that = this;
switch (_that) {
case _IconSearchResultPayload() when $default != null:
return $default(_that.identifier,_that.name,_that.collection);case _:
  return null;

}
}

}

/// @nodoc


class _IconSearchResultPayload implements IconSearchResultPayload {
  const _IconSearchResultPayload({required this.identifier, required this.name, required this.collection});


@override final  String identifier;
@override final  String name;
@override final  String collection;

/// Create a copy of IconSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IconSearchResultPayloadCopyWith<_IconSearchResultPayload> get copyWith => __$IconSearchResultPayloadCopyWithImpl<_IconSearchResultPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IconSearchResultPayload&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.name, name) || other.name == name)&&(identical(other.collection, collection) || other.collection == collection));
}


@override
int get hashCode => Object.hash(runtimeType,identifier,name,collection);

@override
String toString() {
  return 'IconSearchResultPayload(identifier: $identifier, name: $name, collection: $collection)';
}


}

/// @nodoc
abstract mixin class _$IconSearchResultPayloadCopyWith<$Res> implements $IconSearchResultPayloadCopyWith<$Res> {
  factory _$IconSearchResultPayloadCopyWith(_IconSearchResultPayload value, $Res Function(_IconSearchResultPayload) _then) = __$IconSearchResultPayloadCopyWithImpl;
@override @useResult
$Res call({
 String identifier, String name, String collection
});




}
/// @nodoc
class __$IconSearchResultPayloadCopyWithImpl<$Res>
    implements _$IconSearchResultPayloadCopyWith<$Res> {
  __$IconSearchResultPayloadCopyWithImpl(this._self, this._then);

  final _IconSearchResultPayload _self;
  final $Res Function(_IconSearchResultPayload) _then;

/// Create a copy of IconSearchResultPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identifier = null,Object? name = null,Object? collection = null,}) {
  return _then(_IconSearchResultPayload(
identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,collection: null == collection ? _self.collection : collection // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
