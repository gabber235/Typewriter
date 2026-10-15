// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_authoring_search_commands.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpenAuthoringResourceEffect {

 AuthoringResourceIdentifier get resource;
/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAuthoringResourceEffectCopyWith<OpenAuthoringResourceEffect> get copyWith => _$OpenAuthoringResourceEffectCopyWithImpl<OpenAuthoringResourceEffect>(this as OpenAuthoringResourceEffect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OpenAuthoringResourceEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAuthoringResourceEffect&&(identical(other.resource, _this.resource) || other.resource == _this.resource));
}


@override
int get hashCode {
  final _this = this as OpenAuthoringResourceEffect;
  return Object.hash(runtimeType,_this.resource);
}

@override
String toString() {
  final _this = this as OpenAuthoringResourceEffect;
  return 'OpenAuthoringResourceEffect(resource: ${_this.resource})';
}


}

/// @nodoc
abstract mixin class $OpenAuthoringResourceEffectCopyWith<$Res>  {
  factory $OpenAuthoringResourceEffectCopyWith(OpenAuthoringResourceEffect value, $Res Function(OpenAuthoringResourceEffect) _then) = _$OpenAuthoringResourceEffectCopyWithImpl;
@useResult
$Res call({
 AuthoringResourceIdentifier resource
});


$AuthoringResourceIdentifierCopyWith<$Res> get resource;

}
/// @nodoc
class _$OpenAuthoringResourceEffectCopyWithImpl<$Res>
    implements $OpenAuthoringResourceEffectCopyWith<$Res> {
  _$OpenAuthoringResourceEffectCopyWithImpl(this._self, this._then);

  final OpenAuthoringResourceEffect _self;
  final $Res Function(OpenAuthoringResourceEffect) _then;

/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,}) {
  return _then(OpenAuthoringResourceEffect(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as AuthoringResourceIdentifier,
  ));
}
/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringResourceIdentifierCopyWith<$Res> get resource {

  return $AuthoringResourceIdentifierCopyWith<$Res>(_self.resource, (value) {
    return _then(_self.copyWith(resource: value));
  });
}
}


/// Adds pattern-matching-related methods to [OpenAuthoringResourceEffect].
extension OpenAuthoringResourceEffectPatterns on OpenAuthoringResourceEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAuthoringResourceEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAuthoringResourceEffect value)  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAuthoringResourceEffect value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringResourceIdentifier resource)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect() when $default != null:
return $default(_that.resource);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringResourceIdentifier resource)  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect():
return $default(_that.resource);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringResourceIdentifier resource)?  $default,) {final _that = this;
switch (_that) {
case _OpenAuthoringResourceEffect() when $default != null:
return $default(_that.resource);case _:
  return null;

}
}

}

/// @nodoc


class _OpenAuthoringResourceEffect implements OpenAuthoringResourceEffect {
  const _OpenAuthoringResourceEffect({required this.resource});


@override final  AuthoringResourceIdentifier resource;

/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAuthoringResourceEffectCopyWith<_OpenAuthoringResourceEffect> get copyWith => __$OpenAuthoringResourceEffectCopyWithImpl<_OpenAuthoringResourceEffect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAuthoringResourceEffect&&(identical(other.resource, resource) || other.resource == resource));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource);
}

@override
String toString() {
    return 'OpenAuthoringResourceEffect(resource: $resource)';
}


}

/// @nodoc
abstract mixin class _$OpenAuthoringResourceEffectCopyWith<$Res> implements $OpenAuthoringResourceEffectCopyWith<$Res> {
  factory _$OpenAuthoringResourceEffectCopyWith(_OpenAuthoringResourceEffect value, $Res Function(_OpenAuthoringResourceEffect) _then) = __$OpenAuthoringResourceEffectCopyWithImpl;
@override @useResult
$Res call({
 AuthoringResourceIdentifier resource
});


@override $AuthoringResourceIdentifierCopyWith<$Res> get resource;

}
/// @nodoc
class __$OpenAuthoringResourceEffectCopyWithImpl<$Res>
    implements _$OpenAuthoringResourceEffectCopyWith<$Res> {
  __$OpenAuthoringResourceEffectCopyWithImpl(this._self, this._then);

  final _OpenAuthoringResourceEffect _self;
  final $Res Function(_OpenAuthoringResourceEffect) _then;

/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,}) {
  return _then(_OpenAuthoringResourceEffect(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as AuthoringResourceIdentifier,
  ));
}

/// Create a copy of OpenAuthoringResourceEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringResourceIdentifierCopyWith<$Res> get resource {

  return $AuthoringResourceIdentifierCopyWith<$Res>(_self.resource, (value) {
    return _then(_self.copyWith(resource: value));
  });
}
}

// dart format on
