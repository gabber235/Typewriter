// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_selectable_resource.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringResourceIdentifier {

 skir.RecordId get organizationId; skir.RecordId get realmId; skir.ResourceId get resourceId;
/// Create a copy of AuthoringResourceIdentifier
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringResourceIdentifierCopyWith<AuthoringResourceIdentifier> get copyWith => _$AuthoringResourceIdentifierCopyWithImpl<AuthoringResourceIdentifier>(this as AuthoringResourceIdentifier, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringResourceIdentifier;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringResourceIdentifier&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId)&&(identical(other.resourceId, _this.resourceId) || other.resourceId == _this.resourceId));
}


@override
int get hashCode {
  final _this = this as AuthoringResourceIdentifier;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId,_this.resourceId);
}

@override
String toString() {
  final _this = this as AuthoringResourceIdentifier;
  return 'AuthoringResourceIdentifier(organizationId: ${_this.organizationId}, realmId: ${_this.realmId}, resourceId: ${_this.resourceId})';
}


}

/// @nodoc
abstract mixin class $AuthoringResourceIdentifierCopyWith<$Res>  {
  factory $AuthoringResourceIdentifierCopyWith(AuthoringResourceIdentifier value, $Res Function(AuthoringResourceIdentifier) _then) = _$AuthoringResourceIdentifierCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId resourceId
});




}
/// @nodoc
class _$AuthoringResourceIdentifierCopyWithImpl<$Res>
    implements $AuthoringResourceIdentifierCopyWith<$Res> {
  _$AuthoringResourceIdentifierCopyWithImpl(this._self, this._then);

  final AuthoringResourceIdentifier _self;
  final $Res Function(AuthoringResourceIdentifier) _then;

/// Create a copy of AuthoringResourceIdentifier
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,Object? resourceId = null,}) {
  return _then(AuthoringResourceIdentifier(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}

}


/// Adds pattern matching related methods to [AuthoringResourceIdentifier].
extension AuthoringResourceIdentifierPatterns on AuthoringResourceIdentifier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringResourceIdentifier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringResourceIdentifier() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringResourceIdentifier value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringResourceIdentifier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringResourceIdentifier value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringResourceIdentifier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId resourceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringResourceIdentifier() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.resourceId);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId resourceId)  $default,) {final _that = this;
switch (_that) {
case _AuthoringResourceIdentifier():
return $default(_that.organizationId,_that.realmId,_that.resourceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId,  skir.ResourceId resourceId)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringResourceIdentifier() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.resourceId);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringResourceIdentifier extends AuthoringResourceIdentifier {
  const _AuthoringResourceIdentifier({required this.organizationId, required this.realmId, required this.resourceId}): super._();


@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;
@override final  skir.ResourceId resourceId;

/// Create a copy of AuthoringResourceIdentifier
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringResourceIdentifierCopyWith<_AuthoringResourceIdentifier> get copyWith => __$AuthoringResourceIdentifierCopyWithImpl<_AuthoringResourceIdentifier>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringResourceIdentifier&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId,resourceId);
}

@override
String toString() {
    return 'AuthoringResourceIdentifier(organizationId: $organizationId, realmId: $realmId, resourceId: $resourceId)';
}


}

/// @nodoc
abstract mixin class _$AuthoringResourceIdentifierCopyWith<$Res> implements $AuthoringResourceIdentifierCopyWith<$Res> {
  factory _$AuthoringResourceIdentifierCopyWith(_AuthoringResourceIdentifier value, $Res Function(_AuthoringResourceIdentifier) _then) = __$AuthoringResourceIdentifierCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, skir.ResourceId resourceId
});




}
/// @nodoc
class __$AuthoringResourceIdentifierCopyWithImpl<$Res>
    implements _$AuthoringResourceIdentifierCopyWith<$Res> {
  __$AuthoringResourceIdentifierCopyWithImpl(this._self, this._then);

  final _AuthoringResourceIdentifier _self;
  final $Res Function(_AuthoringResourceIdentifier) _then;

/// Create a copy of AuthoringResourceIdentifier
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,Object? resourceId = null,}) {
  return _then(_AuthoringResourceIdentifier(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}


}

// dart format on
