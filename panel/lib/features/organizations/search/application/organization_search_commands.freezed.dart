// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_search_commands.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpenOrganizationEffect {

 skir.RecordId get organizationId;
/// Create a copy of OpenOrganizationEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenOrganizationEffectCopyWith<OpenOrganizationEffect> get copyWith => _$OpenOrganizationEffectCopyWithImpl<OpenOrganizationEffect>(this as OpenOrganizationEffect, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OpenOrganizationEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenOrganizationEffect&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId));
}


@override
int get hashCode {
  final _this = this as OpenOrganizationEffect;
  return Object.hash(runtimeType,_this.organizationId);
}

@override
String toString() {
  final _this = this as OpenOrganizationEffect;
  return 'OpenOrganizationEffect(organizationId: ${_this.organizationId})';
}


}

/// @nodoc
abstract mixin class $OpenOrganizationEffectCopyWith<$Res>  {
  factory $OpenOrganizationEffectCopyWith(OpenOrganizationEffect value, $Res Function(OpenOrganizationEffect) _then) = _$OpenOrganizationEffectCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId
});




}
/// @nodoc
class _$OpenOrganizationEffectCopyWithImpl<$Res>
    implements $OpenOrganizationEffectCopyWith<$Res> {
  _$OpenOrganizationEffectCopyWithImpl(this._self, this._then);

  final OpenOrganizationEffect _self;
  final $Res Function(OpenOrganizationEffect) _then;

/// Create a copy of OpenOrganizationEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,}) {
  return _then(OpenOrganizationEffect(
null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenOrganizationEffect].
extension OpenOrganizationEffectPatterns on OpenOrganizationEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenOrganizationEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenOrganizationEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenOrganizationEffect value)  $default,){
final _that = this;
switch (_that) {
case _OpenOrganizationEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenOrganizationEffect value)?  $default,){
final _that = this;
switch (_that) {
case _OpenOrganizationEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenOrganizationEffect() when $default != null:
return $default(_that.organizationId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId)  $default,) {final _that = this;
switch (_that) {
case _OpenOrganizationEffect():
return $default(_that.organizationId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId)?  $default,) {final _that = this;
switch (_that) {
case _OpenOrganizationEffect() when $default != null:
return $default(_that.organizationId);case _:
  return null;

}
}

}

/// @nodoc


class _OpenOrganizationEffect implements OpenOrganizationEffect {
  const _OpenOrganizationEffect(this.organizationId);
  

@override final  skir.RecordId organizationId;

/// Create a copy of OpenOrganizationEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenOrganizationEffectCopyWith<_OpenOrganizationEffect> get copyWith => __$OpenOrganizationEffectCopyWithImpl<_OpenOrganizationEffect>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenOrganizationEffect&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId);
}

@override
String toString() {
    return 'OpenOrganizationEffect(organizationId: $organizationId)';
}


}

/// @nodoc
abstract mixin class _$OpenOrganizationEffectCopyWith<$Res> implements $OpenOrganizationEffectCopyWith<$Res> {
  factory _$OpenOrganizationEffectCopyWith(_OpenOrganizationEffect value, $Res Function(_OpenOrganizationEffect) _then) = __$OpenOrganizationEffectCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId
});




}
/// @nodoc
class __$OpenOrganizationEffectCopyWithImpl<$Res>
    implements _$OpenOrganizationEffectCopyWith<$Res> {
  __$OpenOrganizationEffectCopyWithImpl(this._self, this._then);

  final _OpenOrganizationEffect _self;
  final $Res Function(_OpenOrganizationEffect) _then;

/// Create a copy of OpenOrganizationEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,}) {
  return _then(_OpenOrganizationEffect(
null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}


}

/// @nodoc
mixin _$CreateOrganizationEffect {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateOrganizationEffect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CreateOrganizationEffect()';
}


}

/// @nodoc
class $CreateOrganizationEffectCopyWith<$Res>  {
$CreateOrganizationEffectCopyWith(CreateOrganizationEffect _, $Res Function(CreateOrganizationEffect) __);
}


/// Adds pattern-matching-related methods to [CreateOrganizationEffect].
extension CreateOrganizationEffectPatterns on CreateOrganizationEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateOrganizationEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateOrganizationEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateOrganizationEffect value)  $default,){
final _that = this;
switch (_that) {
case _CreateOrganizationEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateOrganizationEffect value)?  $default,){
final _that = this;
switch (_that) {
case _CreateOrganizationEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function()?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateOrganizationEffect() when $default != null:
return $default();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function()  $default,) {final _that = this;
switch (_that) {
case _CreateOrganizationEffect():
return $default();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function()?  $default,) {final _that = this;
switch (_that) {
case _CreateOrganizationEffect() when $default != null:
return $default();case _:
  return null;

}
}

}

/// @nodoc


class _CreateOrganizationEffect implements CreateOrganizationEffect {
  const _CreateOrganizationEffect();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateOrganizationEffect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CreateOrganizationEffect()';
}


}




// dart format on
