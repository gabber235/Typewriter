// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'members.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MemberRole {

 String get id; String get name; Color get color; bool get defaultRole; bool get assignable; bool get deletable;
/// Create a copy of MemberRole
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberRoleCopyWith<MemberRole> get copyWith => _$MemberRoleCopyWithImpl<MemberRole>(this as MemberRole, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberRole&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.defaultRole, defaultRole) || other.defaultRole == defaultRole)&&(identical(other.assignable, assignable) || other.assignable == assignable)&&(identical(other.deletable, deletable) || other.deletable == deletable));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,color,defaultRole,assignable,deletable);

@override
String toString() {
  return 'MemberRole(id: $id, name: $name, color: $color, defaultRole: $defaultRole, assignable: $assignable, deletable: $deletable)';
}


}

/// @nodoc
abstract mixin class $MemberRoleCopyWith<$Res>  {
  factory $MemberRoleCopyWith(MemberRole value, $Res Function(MemberRole) _then) = _$MemberRoleCopyWithImpl;
@useResult
$Res call({
 String id, String name, Color color, bool defaultRole, bool assignable, bool deletable
});




}
/// @nodoc
class _$MemberRoleCopyWithImpl<$Res>
    implements $MemberRoleCopyWith<$Res> {
  _$MemberRoleCopyWithImpl(this._self, this._then);

  final MemberRole _self;
  final $Res Function(MemberRole) _then;

/// Create a copy of MemberRole
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? color = null,Object? defaultRole = null,Object? assignable = null,Object? deletable = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,defaultRole: null == defaultRole ? _self.defaultRole : defaultRole // ignore: cast_nullable_to_non_nullable
as bool,assignable: null == assignable ? _self.assignable : assignable // ignore: cast_nullable_to_non_nullable
as bool,deletable: null == deletable ? _self.deletable : deletable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberRole].
extension MemberRolePatterns on MemberRole {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberRole value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberRole() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberRole value)  $default,){
final _that = this;
switch (_that) {
case _MemberRole():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberRole value)?  $default,){
final _that = this;
switch (_that) {
case _MemberRole() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Color color,  bool defaultRole,  bool assignable,  bool deletable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberRole() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.defaultRole,_that.assignable,_that.deletable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Color color,  bool defaultRole,  bool assignable,  bool deletable)  $default,) {final _that = this;
switch (_that) {
case _MemberRole():
return $default(_that.id,_that.name,_that.color,_that.defaultRole,_that.assignable,_that.deletable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Color color,  bool defaultRole,  bool assignable,  bool deletable)?  $default,) {final _that = this;
switch (_that) {
case _MemberRole() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.defaultRole,_that.assignable,_that.deletable);case _:
  return null;

}
}

}

/// @nodoc


class _MemberRole implements MemberRole {
  const _MemberRole({required this.id, required this.name, required this.color, this.defaultRole = false, this.assignable = false, this.deletable = false});
  

@override final  String id;
@override final  String name;
@override final  Color color;
@override@JsonKey() final  bool defaultRole;
@override@JsonKey() final  bool assignable;
@override@JsonKey() final  bool deletable;

/// Create a copy of MemberRole
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberRoleCopyWith<_MemberRole> get copyWith => __$MemberRoleCopyWithImpl<_MemberRole>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberRole&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.defaultRole, defaultRole) || other.defaultRole == defaultRole)&&(identical(other.assignable, assignable) || other.assignable == assignable)&&(identical(other.deletable, deletable) || other.deletable == deletable));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,color,defaultRole,assignable,deletable);

@override
String toString() {
  return 'MemberRole(id: $id, name: $name, color: $color, defaultRole: $defaultRole, assignable: $assignable, deletable: $deletable)';
}


}

/// @nodoc
abstract mixin class _$MemberRoleCopyWith<$Res> implements $MemberRoleCopyWith<$Res> {
  factory _$MemberRoleCopyWith(_MemberRole value, $Res Function(_MemberRole) _then) = __$MemberRoleCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Color color, bool defaultRole, bool assignable, bool deletable
});




}
/// @nodoc
class __$MemberRoleCopyWithImpl<$Res>
    implements _$MemberRoleCopyWith<$Res> {
  __$MemberRoleCopyWithImpl(this._self, this._then);

  final _MemberRole _self;
  final $Res Function(_MemberRole) _then;

/// Create a copy of MemberRole
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? color = null,Object? defaultRole = null,Object? assignable = null,Object? deletable = null,}) {
  return _then(_MemberRole(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,defaultRole: null == defaultRole ? _self.defaultRole : defaultRole // ignore: cast_nullable_to_non_nullable
as bool,assignable: null == assignable ? _self.assignable : assignable // ignore: cast_nullable_to_non_nullable
as bool,deletable: null == deletable ? _self.deletable : deletable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$OrganizationMember {

 String get id; String get name; String get email; String get avatarUrl; List<MemberRole> get roles; DateTime get joinedAt;
/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationMemberCopyWith<OrganizationMember> get copyWith => _$OrganizationMemberCopyWithImpl<OrganizationMember>(this as OrganizationMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationMember&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,email,avatarUrl,const DeepCollectionEquality().hash(roles),joinedAt);

@override
String toString() {
  return 'OrganizationMember(id: $id, name: $name, email: $email, avatarUrl: $avatarUrl, roles: $roles, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $OrganizationMemberCopyWith<$Res>  {
  factory $OrganizationMemberCopyWith(OrganizationMember value, $Res Function(OrganizationMember) _then) = _$OrganizationMemberCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, String avatarUrl, List<MemberRole> roles, DateTime joinedAt
});




}
/// @nodoc
class _$OrganizationMemberCopyWithImpl<$Res>
    implements $OrganizationMemberCopyWith<$Res> {
  _$OrganizationMemberCopyWithImpl(this._self, this._then);

  final OrganizationMember _self;
  final $Res Function(OrganizationMember) _then;

/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? avatarUrl = null,Object? roles = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<MemberRole>,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationMember].
extension OrganizationMemberPatterns on OrganizationMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationMember value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationMember value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String avatarUrl,  List<MemberRole> roles,  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationMember() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.avatarUrl,_that.roles,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String avatarUrl,  List<MemberRole> roles,  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _OrganizationMember():
return $default(_that.id,_that.name,_that.email,_that.avatarUrl,_that.roles,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String email,  String avatarUrl,  List<MemberRole> roles,  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationMember() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.avatarUrl,_that.roles,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationMember implements OrganizationMember {
  const _OrganizationMember({required this.id, required this.name, required this.email, required this.avatarUrl, required final  List<MemberRole> roles, required this.joinedAt}): _roles = roles;
  

@override final  String id;
@override final  String name;
@override final  String email;
@override final  String avatarUrl;
 final  List<MemberRole> _roles;
@override List<MemberRole> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override final  DateTime joinedAt;

/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationMemberCopyWith<_OrganizationMember> get copyWith => __$OrganizationMemberCopyWithImpl<_OrganizationMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationMember&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,email,avatarUrl,const DeepCollectionEquality().hash(_roles),joinedAt);

@override
String toString() {
  return 'OrganizationMember(id: $id, name: $name, email: $email, avatarUrl: $avatarUrl, roles: $roles, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$OrganizationMemberCopyWith<$Res> implements $OrganizationMemberCopyWith<$Res> {
  factory _$OrganizationMemberCopyWith(_OrganizationMember value, $Res Function(_OrganizationMember) _then) = __$OrganizationMemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, String avatarUrl, List<MemberRole> roles, DateTime joinedAt
});




}
/// @nodoc
class __$OrganizationMemberCopyWithImpl<$Res>
    implements _$OrganizationMemberCopyWith<$Res> {
  __$OrganizationMemberCopyWithImpl(this._self, this._then);

  final _OrganizationMember _self;
  final $Res Function(_OrganizationMember) _then;

/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? avatarUrl = null,Object? roles = null,Object? joinedAt = null,}) {
  return _then(_OrganizationMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<MemberRole>,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$JoinRequest {

 String get id; String get userId; String get userName; String get userEmail; String get userAvatarUrl; DateTime get requestedAt; DateTime get expiresAt;
/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinRequestCopyWith<JoinRequest> get copyWith => _$JoinRequestCopyWithImpl<JoinRequest>(this as JoinRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.userAvatarUrl, userAvatarUrl) || other.userAvatarUrl == userAvatarUrl)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,userName,userEmail,userAvatarUrl,requestedAt,expiresAt);

@override
String toString() {
  return 'JoinRequest(id: $id, userId: $userId, userName: $userName, userEmail: $userEmail, userAvatarUrl: $userAvatarUrl, requestedAt: $requestedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $JoinRequestCopyWith<$Res>  {
  factory $JoinRequestCopyWith(JoinRequest value, $Res Function(JoinRequest) _then) = _$JoinRequestCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String userName, String userEmail, String userAvatarUrl, DateTime requestedAt, DateTime expiresAt
});




}
/// @nodoc
class _$JoinRequestCopyWithImpl<$Res>
    implements $JoinRequestCopyWith<$Res> {
  _$JoinRequestCopyWithImpl(this._self, this._then);

  final JoinRequest _self;
  final $Res Function(JoinRequest) _then;

/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? userName = null,Object? userEmail = null,Object? userAvatarUrl = null,Object? requestedAt = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,userAvatarUrl: null == userAvatarUrl ? _self.userAvatarUrl : userAvatarUrl // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinRequest].
extension JoinRequestPatterns on JoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _JoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String userName,  String userEmail,  String userAvatarUrl,  DateTime requestedAt,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
return $default(_that.id,_that.userId,_that.userName,_that.userEmail,_that.userAvatarUrl,_that.requestedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String userName,  String userEmail,  String userAvatarUrl,  DateTime requestedAt,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _JoinRequest():
return $default(_that.id,_that.userId,_that.userName,_that.userEmail,_that.userAvatarUrl,_that.requestedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String userName,  String userEmail,  String userAvatarUrl,  DateTime requestedAt,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
return $default(_that.id,_that.userId,_that.userName,_that.userEmail,_that.userAvatarUrl,_that.requestedAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _JoinRequest extends JoinRequest {
  const _JoinRequest({required this.id, required this.userId, required this.userName, required this.userEmail, required this.userAvatarUrl, required this.requestedAt, required this.expiresAt}): super._();
  

@override final  String id;
@override final  String userId;
@override final  String userName;
@override final  String userEmail;
@override final  String userAvatarUrl;
@override final  DateTime requestedAt;
@override final  DateTime expiresAt;

/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinRequestCopyWith<_JoinRequest> get copyWith => __$JoinRequestCopyWithImpl<_JoinRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.userAvatarUrl, userAvatarUrl) || other.userAvatarUrl == userAvatarUrl)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,userName,userEmail,userAvatarUrl,requestedAt,expiresAt);

@override
String toString() {
  return 'JoinRequest(id: $id, userId: $userId, userName: $userName, userEmail: $userEmail, userAvatarUrl: $userAvatarUrl, requestedAt: $requestedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$JoinRequestCopyWith<$Res> implements $JoinRequestCopyWith<$Res> {
  factory _$JoinRequestCopyWith(_JoinRequest value, $Res Function(_JoinRequest) _then) = __$JoinRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String userName, String userEmail, String userAvatarUrl, DateTime requestedAt, DateTime expiresAt
});




}
/// @nodoc
class __$JoinRequestCopyWithImpl<$Res>
    implements _$JoinRequestCopyWith<$Res> {
  __$JoinRequestCopyWithImpl(this._self, this._then);

  final _JoinRequest _self;
  final $Res Function(_JoinRequest) _then;

/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? userName = null,Object? userEmail = null,Object? userAvatarUrl = null,Object? requestedAt = null,Object? expiresAt = null,}) {
  return _then(_JoinRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,userAvatarUrl: null == userAvatarUrl ? _self.userAvatarUrl : userAvatarUrl // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
