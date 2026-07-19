// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'roles.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationRole {

 skir.RecordId get roleId; String get name; Color get color; bool get defaultRole; bool get assignable; bool get deletable;
/// Create a copy of OrganizationRole
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationRoleCopyWith<OrganizationRole> get copyWith => _$OrganizationRoleCopyWithImpl<OrganizationRole>(this as OrganizationRole, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationRole&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.defaultRole, defaultRole) || other.defaultRole == defaultRole)&&(identical(other.assignable, assignable) || other.assignable == assignable)&&(identical(other.deletable, deletable) || other.deletable == deletable));
}


@override
int get hashCode => Object.hash(runtimeType,roleId,name,color,defaultRole,assignable,deletable);

@override
String toString() {
  return 'OrganizationRole(roleId: $roleId, name: $name, color: $color, defaultRole: $defaultRole, assignable: $assignable, deletable: $deletable)';
}


}

/// @nodoc
abstract mixin class $OrganizationRoleCopyWith<$Res>  {
  factory $OrganizationRoleCopyWith(OrganizationRole value, $Res Function(OrganizationRole) _then) = _$OrganizationRoleCopyWithImpl;
@useResult
$Res call({
 skir.RecordId roleId, String name, Color color, bool defaultRole, bool assignable, bool deletable
});




}
/// @nodoc
class _$OrganizationRoleCopyWithImpl<$Res>
    implements $OrganizationRoleCopyWith<$Res> {
  _$OrganizationRoleCopyWithImpl(this._self, this._then);

  final OrganizationRole _self;
  final $Res Function(OrganizationRole) _then;

/// Create a copy of OrganizationRole
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roleId = null,Object? name = null,Object? color = null,Object? defaultRole = null,Object? assignable = null,Object? deletable = null,}) {
  return _then(_self.copyWith(
roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,defaultRole: null == defaultRole ? _self.defaultRole : defaultRole // ignore: cast_nullable_to_non_nullable
as bool,assignable: null == assignable ? _self.assignable : assignable // ignore: cast_nullable_to_non_nullable
as bool,deletable: null == deletable ? _self.deletable : deletable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationRole].
extension OrganizationRolePatterns on OrganizationRole {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationRole value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationRole() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationRole value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationRole():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationRole value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationRole() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId roleId,  String name,  Color color,  bool defaultRole,  bool assignable,  bool deletable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationRole() when $default != null:
return $default(_that.roleId,_that.name,_that.color,_that.defaultRole,_that.assignable,_that.deletable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId roleId,  String name,  Color color,  bool defaultRole,  bool assignable,  bool deletable)  $default,) {final _that = this;
switch (_that) {
case _OrganizationRole():
return $default(_that.roleId,_that.name,_that.color,_that.defaultRole,_that.assignable,_that.deletable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId roleId,  String name,  Color color,  bool defaultRole,  bool assignable,  bool deletable)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationRole() when $default != null:
return $default(_that.roleId,_that.name,_that.color,_that.defaultRole,_that.assignable,_that.deletable);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationRole extends OrganizationRole {
  const _OrganizationRole({required this.roleId, required this.name, required this.color, this.defaultRole = false, this.assignable = false, this.deletable = false}): assert(name != "", 'Name must not be empty.'),super._();
  

@override final  skir.RecordId roleId;
@override final  String name;
@override final  Color color;
@override@JsonKey() final  bool defaultRole;
@override@JsonKey() final  bool assignable;
@override@JsonKey() final  bool deletable;

/// Create a copy of OrganizationRole
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationRoleCopyWith<_OrganizationRole> get copyWith => __$OrganizationRoleCopyWithImpl<_OrganizationRole>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationRole&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.defaultRole, defaultRole) || other.defaultRole == defaultRole)&&(identical(other.assignable, assignable) || other.assignable == assignable)&&(identical(other.deletable, deletable) || other.deletable == deletable));
}


@override
int get hashCode => Object.hash(runtimeType,roleId,name,color,defaultRole,assignable,deletable);

@override
String toString() {
  return 'OrganizationRole(roleId: $roleId, name: $name, color: $color, defaultRole: $defaultRole, assignable: $assignable, deletable: $deletable)';
}


}

/// @nodoc
abstract mixin class _$OrganizationRoleCopyWith<$Res> implements $OrganizationRoleCopyWith<$Res> {
  factory _$OrganizationRoleCopyWith(_OrganizationRole value, $Res Function(_OrganizationRole) _then) = __$OrganizationRoleCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId roleId, String name, Color color, bool defaultRole, bool assignable, bool deletable
});




}
/// @nodoc
class __$OrganizationRoleCopyWithImpl<$Res>
    implements _$OrganizationRoleCopyWith<$Res> {
  __$OrganizationRoleCopyWithImpl(this._self, this._then);

  final _OrganizationRole _self;
  final $Res Function(_OrganizationRole) _then;

/// Create a copy of OrganizationRole
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roleId = null,Object? name = null,Object? color = null,Object? defaultRole = null,Object? assignable = null,Object? deletable = null,}) {
  return _then(_OrganizationRole(
roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,defaultRole: null == defaultRole ? _self.defaultRole : defaultRole // ignore: cast_nullable_to_non_nullable
as bool,assignable: null == assignable ? _self.assignable : assignable // ignore: cast_nullable_to_non_nullable
as bool,deletable: null == deletable ? _self.deletable : deletable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
