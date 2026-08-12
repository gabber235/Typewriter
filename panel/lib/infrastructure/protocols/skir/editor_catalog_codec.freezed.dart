// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_catalog_codec.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DecodedTypeCatalog {

 TypeCatalog get catalog; TypeRegistry get registry;
/// Create a copy of DecodedTypeCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DecodedTypeCatalogCopyWith<DecodedTypeCatalog> get copyWith => _$DecodedTypeCatalogCopyWithImpl<DecodedTypeCatalog>(this as DecodedTypeCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DecodedTypeCatalog&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.registry, registry) || other.registry == registry));
}


@override
int get hashCode => Object.hash(runtimeType,catalog,registry);

@override
String toString() {
  return 'DecodedTypeCatalog(catalog: $catalog, registry: $registry)';
}


}

/// @nodoc
abstract mixin class $DecodedTypeCatalogCopyWith<$Res>  {
  factory $DecodedTypeCatalogCopyWith(DecodedTypeCatalog value, $Res Function(DecodedTypeCatalog) _then) = _$DecodedTypeCatalogCopyWithImpl;
@useResult
$Res call({
 TypeCatalog catalog, TypeRegistry registry
});


$TypeCatalogCopyWith<$Res> get catalog;

}
/// @nodoc
class _$DecodedTypeCatalogCopyWithImpl<$Res>
    implements $DecodedTypeCatalogCopyWith<$Res> {
  _$DecodedTypeCatalogCopyWithImpl(this._self, this._then);

  final DecodedTypeCatalog _self;
  final $Res Function(DecodedTypeCatalog) _then;

/// Create a copy of DecodedTypeCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,Object? registry = null,}) {
  return _then(_self.copyWith(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as TypeCatalog,registry: null == registry ? _self.registry : registry // ignore: cast_nullable_to_non_nullable
as TypeRegistry,
  ));
}
/// Create a copy of DecodedTypeCatalog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeCatalogCopyWith<$Res> get catalog {
  
  return $TypeCatalogCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}
}


/// Adds pattern-matching-related methods to [DecodedTypeCatalog].
extension DecodedTypeCatalogPatterns on DecodedTypeCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DecodedTypeCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DecodedTypeCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DecodedTypeCatalog value)  $default,){
final _that = this;
switch (_that) {
case _DecodedTypeCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DecodedTypeCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _DecodedTypeCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeCatalog catalog,  TypeRegistry registry)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DecodedTypeCatalog() when $default != null:
return $default(_that.catalog,_that.registry);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeCatalog catalog,  TypeRegistry registry)  $default,) {final _that = this;
switch (_that) {
case _DecodedTypeCatalog():
return $default(_that.catalog,_that.registry);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeCatalog catalog,  TypeRegistry registry)?  $default,) {final _that = this;
switch (_that) {
case _DecodedTypeCatalog() when $default != null:
return $default(_that.catalog,_that.registry);case _:
  return null;

}
}

}

/// @nodoc


class _DecodedTypeCatalog implements DecodedTypeCatalog {
  const _DecodedTypeCatalog(this.catalog, this.registry);
  

@override final  TypeCatalog catalog;
@override final  TypeRegistry registry;

/// Create a copy of DecodedTypeCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DecodedTypeCatalogCopyWith<_DecodedTypeCatalog> get copyWith => __$DecodedTypeCatalogCopyWithImpl<_DecodedTypeCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DecodedTypeCatalog&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.registry, registry) || other.registry == registry));
}


@override
int get hashCode => Object.hash(runtimeType,catalog,registry);

@override
String toString() {
  return 'DecodedTypeCatalog(catalog: $catalog, registry: $registry)';
}


}

/// @nodoc
abstract mixin class _$DecodedTypeCatalogCopyWith<$Res> implements $DecodedTypeCatalogCopyWith<$Res> {
  factory _$DecodedTypeCatalogCopyWith(_DecodedTypeCatalog value, $Res Function(_DecodedTypeCatalog) _then) = __$DecodedTypeCatalogCopyWithImpl;
@override @useResult
$Res call({
 TypeCatalog catalog, TypeRegistry registry
});


@override $TypeCatalogCopyWith<$Res> get catalog;

}
/// @nodoc
class __$DecodedTypeCatalogCopyWithImpl<$Res>
    implements _$DecodedTypeCatalogCopyWith<$Res> {
  __$DecodedTypeCatalogCopyWithImpl(this._self, this._then);

  final _DecodedTypeCatalog _self;
  final $Res Function(_DecodedTypeCatalog) _then;

/// Create a copy of DecodedTypeCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,Object? registry = null,}) {
  return _then(_DecodedTypeCatalog(
null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as TypeCatalog,null == registry ? _self.registry : registry // ignore: cast_nullable_to_non_nullable
as TypeRegistry,
  ));
}

/// Create a copy of DecodedTypeCatalog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeCatalogCopyWith<$Res> get catalog {
  
  return $TypeCatalogCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}
}

// dart format on
