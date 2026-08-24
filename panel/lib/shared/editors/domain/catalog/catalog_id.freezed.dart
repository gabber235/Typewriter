// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_id.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationId {

 String get namespace; String get name;
/// Create a copy of PresentationId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationIdCopyWith<PresentationId> get copyWith => _$PresentationIdCopyWithImpl<PresentationId>(this as PresentationId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationId&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,namespace,name);

@override
String toString() {
  return 'PresentationId(namespace: $namespace, name: $name)';
}


}

/// @nodoc
abstract mixin class $PresentationIdCopyWith<$Res>  {
  factory $PresentationIdCopyWith(PresentationId value, $Res Function(PresentationId) _then) = _$PresentationIdCopyWithImpl;
@useResult
$Res call({
 String namespace, String name
});




}
/// @nodoc
class _$PresentationIdCopyWithImpl<$Res>
    implements $PresentationIdCopyWith<$Res> {
  _$PresentationIdCopyWithImpl(this._self, this._then);

  final PresentationId _self;
  final $Res Function(PresentationId) _then;

/// Create a copy of PresentationId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? namespace = null,Object? name = null,}) {
  return _then(_self.copyWith(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PresentationId].
extension PresentationIdPatterns on PresentationId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationId value)  $default,){
final _that = this;
switch (_that) {
case _PresentationId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationId value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String namespace,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationId() when $default != null:
return $default(_that.namespace,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String namespace,  String name)  $default,) {final _that = this;
switch (_that) {
case _PresentationId():
return $default(_that.namespace,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String namespace,  String name)?  $default,) {final _that = this;
switch (_that) {
case _PresentationId() when $default != null:
return $default(_that.namespace,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationId implements PresentationId {
  const _PresentationId({required this.namespace, required this.name}): assert(namespace != "", 'Namespace must not be empty.'),assert(name != "", 'Name must not be empty.');
  

@override final  String namespace;
@override final  String name;

/// Create a copy of PresentationId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationIdCopyWith<_PresentationId> get copyWith => __$PresentationIdCopyWithImpl<_PresentationId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationId&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,namespace,name);

@override
String toString() {
  return 'PresentationId(namespace: $namespace, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PresentationIdCopyWith<$Res> implements $PresentationIdCopyWith<$Res> {
  factory _$PresentationIdCopyWith(_PresentationId value, $Res Function(_PresentationId) _then) = __$PresentationIdCopyWithImpl;
@override @useResult
$Res call({
 String namespace, String name
});




}
/// @nodoc
class __$PresentationIdCopyWithImpl<$Res>
    implements _$PresentationIdCopyWith<$Res> {
  __$PresentationIdCopyWithImpl(this._self, this._then);

  final _PresentationId _self;
  final $Res Function(_PresentationId) _then;

/// Create a copy of PresentationId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? namespace = null,Object? name = null,}) {
  return _then(_PresentationId(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ConversionId {

 String get namespace; String get name;
/// Create a copy of ConversionId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<ConversionId> get copyWith => _$ConversionIdCopyWithImpl<ConversionId>(this as ConversionId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionId&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,namespace,name);

@override
String toString() {
  return 'ConversionId(namespace: $namespace, name: $name)';
}


}

/// @nodoc
abstract mixin class $ConversionIdCopyWith<$Res>  {
  factory $ConversionIdCopyWith(ConversionId value, $Res Function(ConversionId) _then) = _$ConversionIdCopyWithImpl;
@useResult
$Res call({
 String namespace, String name
});




}
/// @nodoc
class _$ConversionIdCopyWithImpl<$Res>
    implements $ConversionIdCopyWith<$Res> {
  _$ConversionIdCopyWithImpl(this._self, this._then);

  final ConversionId _self;
  final $Res Function(ConversionId) _then;

/// Create a copy of ConversionId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? namespace = null,Object? name = null,}) {
  return _then(_self.copyWith(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversionId].
extension ConversionIdPatterns on ConversionId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversionId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversionId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversionId value)  $default,){
final _that = this;
switch (_that) {
case _ConversionId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversionId value)?  $default,){
final _that = this;
switch (_that) {
case _ConversionId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String namespace,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversionId() when $default != null:
return $default(_that.namespace,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String namespace,  String name)  $default,) {final _that = this;
switch (_that) {
case _ConversionId():
return $default(_that.namespace,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String namespace,  String name)?  $default,) {final _that = this;
switch (_that) {
case _ConversionId() when $default != null:
return $default(_that.namespace,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _ConversionId implements ConversionId {
  const _ConversionId({required this.namespace, required this.name}): assert(namespace != "", 'Namespace must not be empty.'),assert(name != "", 'Name must not be empty.');
  

@override final  String namespace;
@override final  String name;

/// Create a copy of ConversionId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversionIdCopyWith<_ConversionId> get copyWith => __$ConversionIdCopyWithImpl<_ConversionId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversionId&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,namespace,name);

@override
String toString() {
  return 'ConversionId(namespace: $namespace, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ConversionIdCopyWith<$Res> implements $ConversionIdCopyWith<$Res> {
  factory _$ConversionIdCopyWith(_ConversionId value, $Res Function(_ConversionId) _then) = __$ConversionIdCopyWithImpl;
@override @useResult
$Res call({
 String namespace, String name
});




}
/// @nodoc
class __$ConversionIdCopyWithImpl<$Res>
    implements _$ConversionIdCopyWith<$Res> {
  __$ConversionIdCopyWithImpl(this._self, this._then);

  final _ConversionId _self;
  final $Res Function(_ConversionId) _then;

/// Create a copy of ConversionId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? namespace = null,Object? name = null,}) {
  return _then(_ConversionId(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CapabilityId {

 String get value;
/// Create a copy of CapabilityId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapabilityIdCopyWith<CapabilityId> get copyWith => _$CapabilityIdCopyWithImpl<CapabilityId>(this as CapabilityId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapabilityId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'CapabilityId(value: $value)';
}


}

/// @nodoc
abstract mixin class $CapabilityIdCopyWith<$Res>  {
  factory $CapabilityIdCopyWith(CapabilityId value, $Res Function(CapabilityId) _then) = _$CapabilityIdCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$CapabilityIdCopyWithImpl<$Res>
    implements $CapabilityIdCopyWith<$Res> {
  _$CapabilityIdCopyWithImpl(this._self, this._then);

  final CapabilityId _self;
  final $Res Function(CapabilityId) _then;

/// Create a copy of CapabilityId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CapabilityId].
extension CapabilityIdPatterns on CapabilityId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapabilityId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapabilityId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapabilityId value)  $default,){
final _that = this;
switch (_that) {
case _CapabilityId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapabilityId value)?  $default,){
final _that = this;
switch (_that) {
case _CapabilityId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapabilityId() when $default != null:
return $default(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value)  $default,) {final _that = this;
switch (_that) {
case _CapabilityId():
return $default(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value)?  $default,) {final _that = this;
switch (_that) {
case _CapabilityId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _CapabilityId implements CapabilityId {
  const _CapabilityId(this.value): assert(value != "", 'Capability ID must not be empty.');
  

@override final  String value;

/// Create a copy of CapabilityId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapabilityIdCopyWith<_CapabilityId> get copyWith => __$CapabilityIdCopyWithImpl<_CapabilityId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapabilityId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'CapabilityId(value: $value)';
}


}

/// @nodoc
abstract mixin class _$CapabilityIdCopyWith<$Res> implements $CapabilityIdCopyWith<$Res> {
  factory _$CapabilityIdCopyWith(_CapabilityId value, $Res Function(_CapabilityId) _then) = __$CapabilityIdCopyWithImpl;
@override @useResult
$Res call({
 String value
});




}
/// @nodoc
class __$CapabilityIdCopyWithImpl<$Res>
    implements _$CapabilityIdCopyWith<$Res> {
  __$CapabilityIdCopyWithImpl(this._self, this._then);

  final _CapabilityId _self;
  final $Res Function(_CapabilityId) _then;

/// Create a copy of CapabilityId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_CapabilityId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CatalogGeneration {

 String get value;
/// Create a copy of CatalogGeneration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogGenerationCopyWith<CatalogGeneration> get copyWith => _$CatalogGenerationCopyWithImpl<CatalogGeneration>(this as CatalogGeneration, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogGeneration&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'CatalogGeneration(value: $value)';
}


}

/// @nodoc
abstract mixin class $CatalogGenerationCopyWith<$Res>  {
  factory $CatalogGenerationCopyWith(CatalogGeneration value, $Res Function(CatalogGeneration) _then) = _$CatalogGenerationCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$CatalogGenerationCopyWithImpl<$Res>
    implements $CatalogGenerationCopyWith<$Res> {
  _$CatalogGenerationCopyWithImpl(this._self, this._then);

  final CatalogGeneration _self;
  final $Res Function(CatalogGeneration) _then;

/// Create a copy of CatalogGeneration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogGeneration].
extension CatalogGenerationPatterns on CatalogGeneration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogGeneration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogGeneration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogGeneration value)  $default,){
final _that = this;
switch (_that) {
case _CatalogGeneration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogGeneration value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogGeneration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogGeneration() when $default != null:
return $default(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value)  $default,) {final _that = this;
switch (_that) {
case _CatalogGeneration():
return $default(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value)?  $default,) {final _that = this;
switch (_that) {
case _CatalogGeneration() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogGeneration implements CatalogGeneration {
  const _CatalogGeneration(this.value): assert(value != "", 'Generation must not be empty.');
  

@override final  String value;

/// Create a copy of CatalogGeneration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogGenerationCopyWith<_CatalogGeneration> get copyWith => __$CatalogGenerationCopyWithImpl<_CatalogGeneration>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogGeneration&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'CatalogGeneration(value: $value)';
}


}

/// @nodoc
abstract mixin class _$CatalogGenerationCopyWith<$Res> implements $CatalogGenerationCopyWith<$Res> {
  factory _$CatalogGenerationCopyWith(_CatalogGeneration value, $Res Function(_CatalogGeneration) _then) = __$CatalogGenerationCopyWithImpl;
@override @useResult
$Res call({
 String value
});




}
/// @nodoc
class __$CatalogGenerationCopyWithImpl<$Res>
    implements _$CatalogGenerationCopyWith<$Res> {
  __$CatalogGenerationCopyWithImpl(this._self, this._then);

  final _CatalogGeneration _self;
  final $Res Function(_CatalogGeneration) _then;

/// Create a copy of CatalogGeneration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_CatalogGeneration(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
