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

/// @nodoc
mixin _$JoinCode {

 String get code; DateTime get createdAt; DateTime? get expiresAt; bool get singleUse; JoinCodeAutoAccept? get autoAccept;
/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinCodeCopyWith<JoinCode> get copyWith => _$JoinCodeCopyWithImpl<JoinCode>(this as JoinCode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinCode&&(identical(other.code, code) || other.code == code)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.singleUse, singleUse) || other.singleUse == singleUse)&&(identical(other.autoAccept, autoAccept) || other.autoAccept == autoAccept));
}


@override
int get hashCode => Object.hash(runtimeType,code,createdAt,expiresAt,singleUse,autoAccept);

@override
String toString() {
  return 'JoinCode(code: $code, createdAt: $createdAt, expiresAt: $expiresAt, singleUse: $singleUse, autoAccept: $autoAccept)';
}


}

/// @nodoc
abstract mixin class $JoinCodeCopyWith<$Res>  {
  factory $JoinCodeCopyWith(JoinCode value, $Res Function(JoinCode) _then) = _$JoinCodeCopyWithImpl;
@useResult
$Res call({
 String code, DateTime createdAt, DateTime? expiresAt, bool singleUse, JoinCodeAutoAccept? autoAccept
});


$JoinCodeAutoAcceptCopyWith<$Res>? get autoAccept;

}
/// @nodoc
class _$JoinCodeCopyWithImpl<$Res>
    implements $JoinCodeCopyWith<$Res> {
  _$JoinCodeCopyWithImpl(this._self, this._then);

  final JoinCode _self;
  final $Res Function(JoinCode) _then;

/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? createdAt = null,Object? expiresAt = freezed,Object? singleUse = null,Object? autoAccept = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,singleUse: null == singleUse ? _self.singleUse : singleUse // ignore: cast_nullable_to_non_nullable
as bool,autoAccept: freezed == autoAccept ? _self.autoAccept : autoAccept // ignore: cast_nullable_to_non_nullable
as JoinCodeAutoAccept?,
  ));
}
/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JoinCodeAutoAcceptCopyWith<$Res>? get autoAccept {
    if (_self.autoAccept == null) {
    return null;
  }

  return $JoinCodeAutoAcceptCopyWith<$Res>(_self.autoAccept!, (value) {
    return _then(_self.copyWith(autoAccept: value));
  });
}
}


/// Adds pattern-matching-related methods to [JoinCode].
extension JoinCodePatterns on JoinCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinCode value)  $default,){
final _that = this;
switch (_that) {
case _JoinCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinCode value)?  $default,){
final _that = this;
switch (_that) {
case _JoinCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  DateTime createdAt,  DateTime? expiresAt,  bool singleUse,  JoinCodeAutoAccept? autoAccept)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinCode() when $default != null:
return $default(_that.code,_that.createdAt,_that.expiresAt,_that.singleUse,_that.autoAccept);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  DateTime createdAt,  DateTime? expiresAt,  bool singleUse,  JoinCodeAutoAccept? autoAccept)  $default,) {final _that = this;
switch (_that) {
case _JoinCode():
return $default(_that.code,_that.createdAt,_that.expiresAt,_that.singleUse,_that.autoAccept);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  DateTime createdAt,  DateTime? expiresAt,  bool singleUse,  JoinCodeAutoAccept? autoAccept)?  $default,) {final _that = this;
switch (_that) {
case _JoinCode() when $default != null:
return $default(_that.code,_that.createdAt,_that.expiresAt,_that.singleUse,_that.autoAccept);case _:
  return null;

}
}

}

/// @nodoc


class _JoinCode extends JoinCode {
  const _JoinCode({required this.code, required this.createdAt, this.expiresAt, this.singleUse = true, this.autoAccept}): super._();
  

@override final  String code;
@override final  DateTime createdAt;
@override final  DateTime? expiresAt;
@override@JsonKey() final  bool singleUse;
@override final  JoinCodeAutoAccept? autoAccept;

/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinCodeCopyWith<_JoinCode> get copyWith => __$JoinCodeCopyWithImpl<_JoinCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinCode&&(identical(other.code, code) || other.code == code)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.singleUse, singleUse) || other.singleUse == singleUse)&&(identical(other.autoAccept, autoAccept) || other.autoAccept == autoAccept));
}


@override
int get hashCode => Object.hash(runtimeType,code,createdAt,expiresAt,singleUse,autoAccept);

@override
String toString() {
  return 'JoinCode(code: $code, createdAt: $createdAt, expiresAt: $expiresAt, singleUse: $singleUse, autoAccept: $autoAccept)';
}


}

/// @nodoc
abstract mixin class _$JoinCodeCopyWith<$Res> implements $JoinCodeCopyWith<$Res> {
  factory _$JoinCodeCopyWith(_JoinCode value, $Res Function(_JoinCode) _then) = __$JoinCodeCopyWithImpl;
@override @useResult
$Res call({
 String code, DateTime createdAt, DateTime? expiresAt, bool singleUse, JoinCodeAutoAccept? autoAccept
});


@override $JoinCodeAutoAcceptCopyWith<$Res>? get autoAccept;

}
/// @nodoc
class __$JoinCodeCopyWithImpl<$Res>
    implements _$JoinCodeCopyWith<$Res> {
  __$JoinCodeCopyWithImpl(this._self, this._then);

  final _JoinCode _self;
  final $Res Function(_JoinCode) _then;

/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? createdAt = null,Object? expiresAt = freezed,Object? singleUse = null,Object? autoAccept = freezed,}) {
  return _then(_JoinCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,singleUse: null == singleUse ? _self.singleUse : singleUse // ignore: cast_nullable_to_non_nullable
as bool,autoAccept: freezed == autoAccept ? _self.autoAccept : autoAccept // ignore: cast_nullable_to_non_nullable
as JoinCodeAutoAccept?,
  ));
}

/// Create a copy of JoinCode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JoinCodeAutoAcceptCopyWith<$Res>? get autoAccept {
    if (_self.autoAccept == null) {
    return null;
  }

  return $JoinCodeAutoAcceptCopyWith<$Res>(_self.autoAccept!, (value) {
    return _then(_self.copyWith(autoAccept: value));
  });
}
}

/// @nodoc
mixin _$JoinCodeAutoAccept {

 List<String> get roleIds;
/// Create a copy of JoinCodeAutoAccept
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinCodeAutoAcceptCopyWith<JoinCodeAutoAccept> get copyWith => _$JoinCodeAutoAcceptCopyWithImpl<JoinCodeAutoAccept>(this as JoinCodeAutoAccept, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinCodeAutoAccept&&const DeepCollectionEquality().equals(other.roleIds, roleIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(roleIds));

@override
String toString() {
  return 'JoinCodeAutoAccept(roleIds: $roleIds)';
}


}

/// @nodoc
abstract mixin class $JoinCodeAutoAcceptCopyWith<$Res>  {
  factory $JoinCodeAutoAcceptCopyWith(JoinCodeAutoAccept value, $Res Function(JoinCodeAutoAccept) _then) = _$JoinCodeAutoAcceptCopyWithImpl;
@useResult
$Res call({
 List<String> roleIds
});




}
/// @nodoc
class _$JoinCodeAutoAcceptCopyWithImpl<$Res>
    implements $JoinCodeAutoAcceptCopyWith<$Res> {
  _$JoinCodeAutoAcceptCopyWithImpl(this._self, this._then);

  final JoinCodeAutoAccept _self;
  final $Res Function(JoinCodeAutoAccept) _then;

/// Create a copy of JoinCodeAutoAccept
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roleIds = null,}) {
  return _then(_self.copyWith(
roleIds: null == roleIds ? _self.roleIds : roleIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinCodeAutoAccept].
extension JoinCodeAutoAcceptPatterns on JoinCodeAutoAccept {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinCodeAutoAccept value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinCodeAutoAccept() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinCodeAutoAccept value)  $default,){
final _that = this;
switch (_that) {
case _JoinCodeAutoAccept():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinCodeAutoAccept value)?  $default,){
final _that = this;
switch (_that) {
case _JoinCodeAutoAccept() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> roleIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinCodeAutoAccept() when $default != null:
return $default(_that.roleIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> roleIds)  $default,) {final _that = this;
switch (_that) {
case _JoinCodeAutoAccept():
return $default(_that.roleIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> roleIds)?  $default,) {final _that = this;
switch (_that) {
case _JoinCodeAutoAccept() when $default != null:
return $default(_that.roleIds);case _:
  return null;

}
}

}

/// @nodoc


class _JoinCodeAutoAccept implements JoinCodeAutoAccept {
  const _JoinCodeAutoAccept({required final  List<String> roleIds}): _roleIds = roleIds;
  

 final  List<String> _roleIds;
@override List<String> get roleIds {
  if (_roleIds is EqualUnmodifiableListView) return _roleIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roleIds);
}


/// Create a copy of JoinCodeAutoAccept
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinCodeAutoAcceptCopyWith<_JoinCodeAutoAccept> get copyWith => __$JoinCodeAutoAcceptCopyWithImpl<_JoinCodeAutoAccept>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinCodeAutoAccept&&const DeepCollectionEquality().equals(other._roleIds, _roleIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_roleIds));

@override
String toString() {
  return 'JoinCodeAutoAccept(roleIds: $roleIds)';
}


}

/// @nodoc
abstract mixin class _$JoinCodeAutoAcceptCopyWith<$Res> implements $JoinCodeAutoAcceptCopyWith<$Res> {
  factory _$JoinCodeAutoAcceptCopyWith(_JoinCodeAutoAccept value, $Res Function(_JoinCodeAutoAccept) _then) = __$JoinCodeAutoAcceptCopyWithImpl;
@override @useResult
$Res call({
 List<String> roleIds
});




}
/// @nodoc
class __$JoinCodeAutoAcceptCopyWithImpl<$Res>
    implements _$JoinCodeAutoAcceptCopyWith<$Res> {
  __$JoinCodeAutoAcceptCopyWithImpl(this._self, this._then);

  final _JoinCodeAutoAccept _self;
  final $Res Function(_JoinCodeAutoAccept) _then;

/// Create a copy of JoinCodeAutoAccept
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roleIds = null,}) {
  return _then(_JoinCodeAutoAccept(
roleIds: null == roleIds ? _self._roleIds : roleIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$JoinCodeExpiration {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinCodeExpiration);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JoinCodeExpiration()';
}


}

/// @nodoc
class $JoinCodeExpirationCopyWith<$Res>  {
$JoinCodeExpirationCopyWith(JoinCodeExpiration _, $Res Function(JoinCodeExpiration) __);
}


/// Adds pattern-matching-related methods to [JoinCodeExpiration].
extension JoinCodeExpirationPatterns on JoinCodeExpiration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( JoinCodeExpirationNever value)?  never,TResult Function( JoinCodeExpirationDuration value)?  duration,required TResult orElse(),}){
final _that = this;
switch (_that) {
case JoinCodeExpirationNever() when never != null:
return never(_that);case JoinCodeExpirationDuration() when duration != null:
return duration(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( JoinCodeExpirationNever value)  never,required TResult Function( JoinCodeExpirationDuration value)  duration,}){
final _that = this;
switch (_that) {
case JoinCodeExpirationNever():
return never(_that);case JoinCodeExpirationDuration():
return duration(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( JoinCodeExpirationNever value)?  never,TResult? Function( JoinCodeExpirationDuration value)?  duration,}){
final _that = this;
switch (_that) {
case JoinCodeExpirationNever() when never != null:
return never(_that);case JoinCodeExpirationDuration() when duration != null:
return duration(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  never,TResult Function( Duration duration)?  duration,required TResult orElse(),}) {final _that = this;
switch (_that) {
case JoinCodeExpirationNever() when never != null:
return never();case JoinCodeExpirationDuration() when duration != null:
return duration(_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  never,required TResult Function( Duration duration)  duration,}) {final _that = this;
switch (_that) {
case JoinCodeExpirationNever():
return never();case JoinCodeExpirationDuration():
return duration(_that.duration);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  never,TResult? Function( Duration duration)?  duration,}) {final _that = this;
switch (_that) {
case JoinCodeExpirationNever() when never != null:
return never();case JoinCodeExpirationDuration() when duration != null:
return duration(_that.duration);case _:
  return null;

}
}

}

/// @nodoc


class JoinCodeExpirationNever implements JoinCodeExpiration {
  const JoinCodeExpirationNever();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinCodeExpirationNever);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JoinCodeExpiration.never()';
}


}




/// @nodoc


class JoinCodeExpirationDuration implements JoinCodeExpiration {
  const JoinCodeExpirationDuration(this.duration);
  

 final  Duration duration;

/// Create a copy of JoinCodeExpiration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinCodeExpirationDurationCopyWith<JoinCodeExpirationDuration> get copyWith => _$JoinCodeExpirationDurationCopyWithImpl<JoinCodeExpirationDuration>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinCodeExpirationDuration&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode => Object.hash(runtimeType,duration);

@override
String toString() {
  return 'JoinCodeExpiration.duration(duration: $duration)';
}


}

/// @nodoc
abstract mixin class $JoinCodeExpirationDurationCopyWith<$Res> implements $JoinCodeExpirationCopyWith<$Res> {
  factory $JoinCodeExpirationDurationCopyWith(JoinCodeExpirationDuration value, $Res Function(JoinCodeExpirationDuration) _then) = _$JoinCodeExpirationDurationCopyWithImpl;
@useResult
$Res call({
 Duration duration
});




}
/// @nodoc
class _$JoinCodeExpirationDurationCopyWithImpl<$Res>
    implements $JoinCodeExpirationDurationCopyWith<$Res> {
  _$JoinCodeExpirationDurationCopyWithImpl(this._self, this._then);

  final JoinCodeExpirationDuration _self;
  final $Res Function(JoinCodeExpirationDuration) _then;

/// Create a copy of JoinCodeExpiration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? duration = null,}) {
  return _then(JoinCodeExpirationDuration(
null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc
mixin _$JoinCodeOptions {

 bool get singleUse; JoinCodeExpiration get expiration; List<String>? get autoAcceptRoleIds;
/// Create a copy of JoinCodeOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinCodeOptionsCopyWith<JoinCodeOptions> get copyWith => _$JoinCodeOptionsCopyWithImpl<JoinCodeOptions>(this as JoinCodeOptions, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinCodeOptions&&(identical(other.singleUse, singleUse) || other.singleUse == singleUse)&&(identical(other.expiration, expiration) || other.expiration == expiration)&&const DeepCollectionEquality().equals(other.autoAcceptRoleIds, autoAcceptRoleIds));
}


@override
int get hashCode => Object.hash(runtimeType,singleUse,expiration,const DeepCollectionEquality().hash(autoAcceptRoleIds));

@override
String toString() {
  return 'JoinCodeOptions(singleUse: $singleUse, expiration: $expiration, autoAcceptRoleIds: $autoAcceptRoleIds)';
}


}

/// @nodoc
abstract mixin class $JoinCodeOptionsCopyWith<$Res>  {
  factory $JoinCodeOptionsCopyWith(JoinCodeOptions value, $Res Function(JoinCodeOptions) _then) = _$JoinCodeOptionsCopyWithImpl;
@useResult
$Res call({
 bool singleUse, JoinCodeExpiration expiration, List<String>? autoAcceptRoleIds
});


$JoinCodeExpirationCopyWith<$Res> get expiration;

}
/// @nodoc
class _$JoinCodeOptionsCopyWithImpl<$Res>
    implements $JoinCodeOptionsCopyWith<$Res> {
  _$JoinCodeOptionsCopyWithImpl(this._self, this._then);

  final JoinCodeOptions _self;
  final $Res Function(JoinCodeOptions) _then;

/// Create a copy of JoinCodeOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? singleUse = null,Object? expiration = null,Object? autoAcceptRoleIds = freezed,}) {
  return _then(_self.copyWith(
singleUse: null == singleUse ? _self.singleUse : singleUse // ignore: cast_nullable_to_non_nullable
as bool,expiration: null == expiration ? _self.expiration : expiration // ignore: cast_nullable_to_non_nullable
as JoinCodeExpiration,autoAcceptRoleIds: freezed == autoAcceptRoleIds ? _self.autoAcceptRoleIds : autoAcceptRoleIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}
/// Create a copy of JoinCodeOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JoinCodeExpirationCopyWith<$Res> get expiration {
  
  return $JoinCodeExpirationCopyWith<$Res>(_self.expiration, (value) {
    return _then(_self.copyWith(expiration: value));
  });
}
}


/// Adds pattern-matching-related methods to [JoinCodeOptions].
extension JoinCodeOptionsPatterns on JoinCodeOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinCodeOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinCodeOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinCodeOptions value)  $default,){
final _that = this;
switch (_that) {
case _JoinCodeOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinCodeOptions value)?  $default,){
final _that = this;
switch (_that) {
case _JoinCodeOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool singleUse,  JoinCodeExpiration expiration,  List<String>? autoAcceptRoleIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinCodeOptions() when $default != null:
return $default(_that.singleUse,_that.expiration,_that.autoAcceptRoleIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool singleUse,  JoinCodeExpiration expiration,  List<String>? autoAcceptRoleIds)  $default,) {final _that = this;
switch (_that) {
case _JoinCodeOptions():
return $default(_that.singleUse,_that.expiration,_that.autoAcceptRoleIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool singleUse,  JoinCodeExpiration expiration,  List<String>? autoAcceptRoleIds)?  $default,) {final _that = this;
switch (_that) {
case _JoinCodeOptions() when $default != null:
return $default(_that.singleUse,_that.expiration,_that.autoAcceptRoleIds);case _:
  return null;

}
}

}

/// @nodoc


class _JoinCodeOptions implements JoinCodeOptions {
  const _JoinCodeOptions({this.singleUse = true, this.expiration = const JoinCodeExpiration.duration(Duration(days: 7)), final  List<String>? autoAcceptRoleIds}): _autoAcceptRoleIds = autoAcceptRoleIds;
  

@override@JsonKey() final  bool singleUse;
@override@JsonKey() final  JoinCodeExpiration expiration;
 final  List<String>? _autoAcceptRoleIds;
@override List<String>? get autoAcceptRoleIds {
  final value = _autoAcceptRoleIds;
  if (value == null) return null;
  if (_autoAcceptRoleIds is EqualUnmodifiableListView) return _autoAcceptRoleIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of JoinCodeOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinCodeOptionsCopyWith<_JoinCodeOptions> get copyWith => __$JoinCodeOptionsCopyWithImpl<_JoinCodeOptions>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinCodeOptions&&(identical(other.singleUse, singleUse) || other.singleUse == singleUse)&&(identical(other.expiration, expiration) || other.expiration == expiration)&&const DeepCollectionEquality().equals(other._autoAcceptRoleIds, _autoAcceptRoleIds));
}


@override
int get hashCode => Object.hash(runtimeType,singleUse,expiration,const DeepCollectionEquality().hash(_autoAcceptRoleIds));

@override
String toString() {
  return 'JoinCodeOptions(singleUse: $singleUse, expiration: $expiration, autoAcceptRoleIds: $autoAcceptRoleIds)';
}


}

/// @nodoc
abstract mixin class _$JoinCodeOptionsCopyWith<$Res> implements $JoinCodeOptionsCopyWith<$Res> {
  factory _$JoinCodeOptionsCopyWith(_JoinCodeOptions value, $Res Function(_JoinCodeOptions) _then) = __$JoinCodeOptionsCopyWithImpl;
@override @useResult
$Res call({
 bool singleUse, JoinCodeExpiration expiration, List<String>? autoAcceptRoleIds
});


@override $JoinCodeExpirationCopyWith<$Res> get expiration;

}
/// @nodoc
class __$JoinCodeOptionsCopyWithImpl<$Res>
    implements _$JoinCodeOptionsCopyWith<$Res> {
  __$JoinCodeOptionsCopyWithImpl(this._self, this._then);

  final _JoinCodeOptions _self;
  final $Res Function(_JoinCodeOptions) _then;

/// Create a copy of JoinCodeOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? singleUse = null,Object? expiration = null,Object? autoAcceptRoleIds = freezed,}) {
  return _then(_JoinCodeOptions(
singleUse: null == singleUse ? _self.singleUse : singleUse // ignore: cast_nullable_to_non_nullable
as bool,expiration: null == expiration ? _self.expiration : expiration // ignore: cast_nullable_to_non_nullable
as JoinCodeExpiration,autoAcceptRoleIds: freezed == autoAcceptRoleIds ? _self._autoAcceptRoleIds : autoAcceptRoleIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

/// Create a copy of JoinCodeOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JoinCodeExpirationCopyWith<$Res> get expiration {
  
  return $JoinCodeExpirationCopyWith<$Res>(_self.expiration, (value) {
    return _then(_self.copyWith(expiration: value));
  });
}
}

// dart format on
