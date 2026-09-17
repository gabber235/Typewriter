// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_route_access_binding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationAccessSnapshot {

 AsyncValue<String?> get principal; AsyncValue<List<OrganizationData>> get membership;
/// Create a copy of _OrganizationAccessSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationAccessSnapshotCopyWith<_OrganizationAccessSnapshot> get copyWith => __$OrganizationAccessSnapshotCopyWithImpl<_OrganizationAccessSnapshot>(this as _OrganizationAccessSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _OrganizationAccessSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationAccessSnapshot&&(identical(other.principal, _this.principal) || other.principal == _this.principal)&&(identical(other.membership, _this.membership) || other.membership == _this.membership));
}


@override
int get hashCode {
  final _this = this as _OrganizationAccessSnapshot;
  return Object.hash(runtimeType,_this.principal,_this.membership);
}

@override
String toString() {
  final _this = this as _OrganizationAccessSnapshot;
  return '_OrganizationAccessSnapshot(principal: ${_this.principal}, membership: ${_this.membership})';
}


}

/// @nodoc
abstract mixin class _$OrganizationAccessSnapshotCopyWith<$Res>  {
  factory _$OrganizationAccessSnapshotCopyWith(_OrganizationAccessSnapshot value, $Res Function(_OrganizationAccessSnapshot) _then) = __$OrganizationAccessSnapshotCopyWithImpl;
@useResult
$Res call({
 AsyncValue<String?> principal, AsyncValue<List<OrganizationData>> membership
});




}
/// @nodoc
class __$OrganizationAccessSnapshotCopyWithImpl<$Res>
    implements _$OrganizationAccessSnapshotCopyWith<$Res> {
  __$OrganizationAccessSnapshotCopyWithImpl(this._self, this._then);

  final _OrganizationAccessSnapshot _self;
  final $Res Function(_OrganizationAccessSnapshot) _then;

/// Create a copy of _OrganizationAccessSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? principal = null,Object? membership = null,}) {
  return _then(_OrganizationAccessSnapshot(
principal: null == principal ? _self.principal : principal // ignore: cast_nullable_to_non_nullable
as AsyncValue<String?>,membership: null == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<OrganizationData>>,
  ));
}

}


/// Adds pattern-matching-related methods to [_OrganizationAccessSnapshot].
extension _OrganizationAccessSnapshotPatterns on _OrganizationAccessSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __OrganizationAccessSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __OrganizationAccessSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __OrganizationAccessSnapshot value)  $default,){
final _that = this;
switch (_that) {
case __OrganizationAccessSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __OrganizationAccessSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case __OrganizationAccessSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AsyncValue<String?> principal,  AsyncValue<List<OrganizationData>> membership)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __OrganizationAccessSnapshot() when $default != null:
return $default(_that.principal,_that.membership);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AsyncValue<String?> principal,  AsyncValue<List<OrganizationData>> membership)  $default,) {final _that = this;
switch (_that) {
case __OrganizationAccessSnapshot():
return $default(_that.principal,_that.membership);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AsyncValue<String?> principal,  AsyncValue<List<OrganizationData>> membership)?  $default,) {final _that = this;
switch (_that) {
case __OrganizationAccessSnapshot() when $default != null:
return $default(_that.principal,_that.membership);case _:
  return null;

}
}

}

/// @nodoc


class __OrganizationAccessSnapshot implements _OrganizationAccessSnapshot {
  const __OrganizationAccessSnapshot({required this.principal, required this.membership});
  

@override final  AsyncValue<String?> principal;
@override final  AsyncValue<List<OrganizationData>> membership;

/// Create a copy of _OrganizationAccessSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_OrganizationAccessSnapshotCopyWith<__OrganizationAccessSnapshot> get copyWith => __$_OrganizationAccessSnapshotCopyWithImpl<__OrganizationAccessSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __OrganizationAccessSnapshot&&(identical(other.principal, principal) || other.principal == principal)&&(identical(other.membership, membership) || other.membership == membership));
}


@override
int get hashCode {
    return Object.hash(runtimeType,principal,membership);
}

@override
String toString() {
    return '_OrganizationAccessSnapshot(principal: $principal, membership: $membership)';
}


}

/// @nodoc
abstract mixin class _$_OrganizationAccessSnapshotCopyWith<$Res> implements _$OrganizationAccessSnapshotCopyWith<$Res> {
  factory _$_OrganizationAccessSnapshotCopyWith(__OrganizationAccessSnapshot value, $Res Function(__OrganizationAccessSnapshot) _then) = __$_OrganizationAccessSnapshotCopyWithImpl;
@override @useResult
$Res call({
 AsyncValue<String?> principal, AsyncValue<List<OrganizationData>> membership
});




}
/// @nodoc
class __$_OrganizationAccessSnapshotCopyWithImpl<$Res>
    implements _$_OrganizationAccessSnapshotCopyWith<$Res> {
  __$_OrganizationAccessSnapshotCopyWithImpl(this._self, this._then);

  final __OrganizationAccessSnapshot _self;
  final $Res Function(__OrganizationAccessSnapshot) _then;

/// Create a copy of _OrganizationAccessSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? principal = null,Object? membership = null,}) {
  return _then(__OrganizationAccessSnapshot(
principal: null == principal ? _self.principal : principal // ignore: cast_nullable_to_non_nullable
as AsyncValue<String?>,membership: null == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<OrganizationData>>,
  ));
}


}

// dart format on
