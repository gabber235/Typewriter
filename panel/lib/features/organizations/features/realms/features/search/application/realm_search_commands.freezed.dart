// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_search_commands.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpenRealmEffect implements DiagnosticableTreeMixin {

 skir.RecordId get organizationId; skir.RecordId get realmId;
/// Create a copy of OpenRealmEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenRealmEffectCopyWith<OpenRealmEffect> get copyWith => _$OpenRealmEffectCopyWithImpl<OpenRealmEffect>(this as OpenRealmEffect, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as OpenRealmEffect;
  properties
    ..add(DiagnosticsProperty('type', 'OpenRealmEffect'))
    ..add(DiagnosticsProperty('organizationId', _this.organizationId))..add(DiagnosticsProperty('realmId', _this.realmId));
}

@override
bool operator ==(Object other) {
  final _this = this as OpenRealmEffect;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenRealmEffect&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId));
}


@override
int get hashCode {
  final _this = this as OpenRealmEffect;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as OpenRealmEffect;
  return 'OpenRealmEffect(organizationId: ${_this.organizationId}, realmId: ${_this.realmId})';
}


}

/// @nodoc
abstract mixin class $OpenRealmEffectCopyWith<$Res>  {
  factory $OpenRealmEffectCopyWith(OpenRealmEffect value, $Res Function(OpenRealmEffect) _then) = _$OpenRealmEffectCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId
});




}
/// @nodoc
class _$OpenRealmEffectCopyWithImpl<$Res>
    implements $OpenRealmEffectCopyWith<$Res> {
  _$OpenRealmEffectCopyWithImpl(this._self, this._then);

  final OpenRealmEffect _self;
  final $Res Function(OpenRealmEffect) _then;

/// Create a copy of OpenRealmEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(OpenRealmEffect(
null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenRealmEffect].
extension OpenRealmEffectPatterns on OpenRealmEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenRealmEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenRealmEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenRealmEffect value)  $default,){
final _that = this;
switch (_that) {
case _OpenRealmEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenRealmEffect value)?  $default,){
final _that = this;
switch (_that) {
case _OpenRealmEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenRealmEffect() when $default != null:
return $default(_that.organizationId,_that.realmId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId)  $default,) {final _that = this;
switch (_that) {
case _OpenRealmEffect():
return $default(_that.organizationId,_that.realmId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId)?  $default,) {final _that = this;
switch (_that) {
case _OpenRealmEffect() when $default != null:
return $default(_that.organizationId,_that.realmId);case _:
  return null;

}
}

}

/// @nodoc


class _OpenRealmEffect with DiagnosticableTreeMixin implements OpenRealmEffect {
  const _OpenRealmEffect(this.organizationId, this.realmId);
  

@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;

/// Create a copy of OpenRealmEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenRealmEffectCopyWith<_OpenRealmEffect> get copyWith => __$OpenRealmEffectCopyWithImpl<_OpenRealmEffect>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'OpenRealmEffect'))
    ..add(DiagnosticsProperty('organizationId', organizationId))..add(DiagnosticsProperty('realmId', realmId));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenRealmEffect&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'OpenRealmEffect(organizationId: $organizationId, realmId: $realmId)';
}


}

/// @nodoc
abstract mixin class _$OpenRealmEffectCopyWith<$Res> implements $OpenRealmEffectCopyWith<$Res> {
  factory _$OpenRealmEffectCopyWith(_OpenRealmEffect value, $Res Function(_OpenRealmEffect) _then) = __$OpenRealmEffectCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId
});




}
/// @nodoc
class __$OpenRealmEffectCopyWithImpl<$Res>
    implements _$OpenRealmEffectCopyWith<$Res> {
  __$OpenRealmEffectCopyWithImpl(this._self, this._then);

  final _OpenRealmEffect _self;
  final $Res Function(_OpenRealmEffect) _then;

/// Create a copy of OpenRealmEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(_OpenRealmEffect(
null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}


}

// dart format on
