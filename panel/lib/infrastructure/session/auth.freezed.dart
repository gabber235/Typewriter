// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserInfo {

 String get sub; String? get name; String? get username; String? get email; String? get avatarUrl; bool? get emailVerified; List<String>? get entitlements; List<String>? get groups; DiscordInfo? get discord;
/// Create a copy of UserInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserInfoCopyWith<UserInfo> get copyWith => _$UserInfoCopyWithImpl<UserInfo>(this as UserInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserInfo&&(identical(other.sub, _this.sub) || other.sub == _this.sub)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.emailVerified, _this.emailVerified) || other.emailVerified == _this.emailVerified)&&const DeepCollectionEquality().equals(other.entitlements, _this.entitlements)&&const DeepCollectionEquality().equals(other.groups, _this.groups)&&(identical(other.discord, _this.discord) || other.discord == _this.discord));
}


@override
int get hashCode {
  final _this = this as UserInfo;
  return Object.hash(runtimeType,_this.sub,_this.name,_this.username,_this.email,_this.avatarUrl,_this.emailVerified,const DeepCollectionEquality().hash(_this.entitlements),const DeepCollectionEquality().hash(_this.groups),_this.discord);
}

@override
String toString() {
  final _this = this as UserInfo;
  return 'UserInfo(sub: ${_this.sub}, name: ${_this.name}, username: ${_this.username}, email: ${_this.email}, avatarUrl: ${_this.avatarUrl}, emailVerified: ${_this.emailVerified}, entitlements: ${_this.entitlements}, groups: ${_this.groups}, discord: ${_this.discord})';
}


}

/// @nodoc
abstract mixin class $UserInfoCopyWith<$Res>  {
  factory $UserInfoCopyWith(UserInfo value, $Res Function(UserInfo) _then) = _$UserInfoCopyWithImpl;
@useResult
$Res call({
 String sub, String? name, String? username, String? email, String? avatarUrl, bool? emailVerified, List<String>? entitlements, List<String>? groups, DiscordInfo? discord
});


$DiscordInfoCopyWith<$Res>? get discord;

}
/// @nodoc
class _$UserInfoCopyWithImpl<$Res>
    implements $UserInfoCopyWith<$Res> {
  _$UserInfoCopyWithImpl(this._self, this._then);

  final UserInfo _self;
  final $Res Function(UserInfo) _then;

/// Create a copy of UserInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sub = null,Object? name = freezed,Object? username = freezed,Object? email = freezed,Object? avatarUrl = freezed,Object? emailVerified = freezed,Object? entitlements = freezed,Object? groups = freezed,Object? discord = freezed,}) {
  return _then(UserInfo(
sub: null == sub ? _self.sub : sub // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,emailVerified: freezed == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool?,entitlements: freezed == entitlements ? _self.entitlements : entitlements // ignore: cast_nullable_to_non_nullable
as List<String>?,groups: freezed == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<String>?,discord: freezed == discord ? _self.discord : discord // ignore: cast_nullable_to_non_nullable
as DiscordInfo?,
  ));
}
/// Create a copy of UserInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiscordInfoCopyWith<$Res>? get discord {
    if (_self.discord == null) {
    return null;
  }

  return $DiscordInfoCopyWith<$Res>(_self.discord!, (value) {
    return _then(_self.copyWith(discord: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserInfo].
extension UserInfoPatterns on UserInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserInfo value)  $default,){
final _that = this;
switch (_that) {
case _UserInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserInfo value)?  $default,){
final _that = this;
switch (_that) {
case _UserInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sub,  String? name,  String? username,  String? email,  String? avatarUrl,  bool? emailVerified,  List<String>? entitlements,  List<String>? groups,  DiscordInfo? discord)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserInfo() when $default != null:
return $default(_that.sub,_that.name,_that.username,_that.email,_that.avatarUrl,_that.emailVerified,_that.entitlements,_that.groups,_that.discord);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sub,  String? name,  String? username,  String? email,  String? avatarUrl,  bool? emailVerified,  List<String>? entitlements,  List<String>? groups,  DiscordInfo? discord)  $default,) {final _that = this;
switch (_that) {
case _UserInfo():
return $default(_that.sub,_that.name,_that.username,_that.email,_that.avatarUrl,_that.emailVerified,_that.entitlements,_that.groups,_that.discord);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sub,  String? name,  String? username,  String? email,  String? avatarUrl,  bool? emailVerified,  List<String>? entitlements,  List<String>? groups,  DiscordInfo? discord)?  $default,) {final _that = this;
switch (_that) {
case _UserInfo() when $default != null:
return $default(_that.sub,_that.name,_that.username,_that.email,_that.avatarUrl,_that.emailVerified,_that.entitlements,_that.groups,_that.discord);case _:
  return null;

}
}

}

/// @nodoc


class _UserInfo implements UserInfo {
  const _UserInfo({required this.sub, this.name, this.username, this.email, this.avatarUrl, this.emailVerified,  List<String>? entitlements,  List<String>? groups, this.discord}): _entitlements = entitlements,_groups = groups;
  

@override final  String sub;
@override final  String? name;
@override final  String? username;
@override final  String? email;
@override final  String? avatarUrl;
@override final  bool? emailVerified;
 final  List<String>? _entitlements;
@override List<String>? get entitlements {
  final value = _entitlements;
  if (value == null) return null;
  if (_entitlements is EqualUnmodifiableListView) return _entitlements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _groups;
@override List<String>? get groups {
  final value = _groups;
  if (value == null) return null;
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  DiscordInfo? discord;

/// Create a copy of UserInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserInfoCopyWith<_UserInfo> get copyWith => __$UserInfoCopyWithImpl<_UserInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserInfo&&(identical(other.sub, sub) || other.sub == sub)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.emailVerified, emailVerified) || other.emailVerified == emailVerified)&&const DeepCollectionEquality().equals(other.entitlements, _entitlements)&&const DeepCollectionEquality().equals(other.groups, _groups)&&(identical(other.discord, discord) || other.discord == discord));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sub,name,username,email,avatarUrl,emailVerified,const DeepCollectionEquality().hash(_entitlements),const DeepCollectionEquality().hash(_groups),discord);
}

@override
String toString() {
    return 'UserInfo(sub: $sub, name: $name, username: $username, email: $email, avatarUrl: $avatarUrl, emailVerified: $emailVerified, entitlements: $entitlements, groups: $groups, discord: $discord)';
}


}

/// @nodoc
abstract mixin class _$UserInfoCopyWith<$Res> implements $UserInfoCopyWith<$Res> {
  factory _$UserInfoCopyWith(_UserInfo value, $Res Function(_UserInfo) _then) = __$UserInfoCopyWithImpl;
@override @useResult
$Res call({
 String sub, String? name, String? username, String? email, String? avatarUrl, bool? emailVerified, List<String>? entitlements, List<String>? groups, DiscordInfo? discord
});


@override $DiscordInfoCopyWith<$Res>? get discord;

}
/// @nodoc
class __$UserInfoCopyWithImpl<$Res>
    implements _$UserInfoCopyWith<$Res> {
  __$UserInfoCopyWithImpl(this._self, this._then);

  final _UserInfo _self;
  final $Res Function(_UserInfo) _then;

/// Create a copy of UserInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sub = null,Object? name = freezed,Object? username = freezed,Object? email = freezed,Object? avatarUrl = freezed,Object? emailVerified = freezed,Object? entitlements = freezed,Object? groups = freezed,Object? discord = freezed,}) {
  return _then(_UserInfo(
sub: null == sub ? _self.sub : sub // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,emailVerified: freezed == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool?,entitlements: freezed == entitlements ? _self._entitlements : entitlements // ignore: cast_nullable_to_non_nullable
as List<String>?,groups: freezed == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<String>?,discord: freezed == discord ? _self.discord : discord // ignore: cast_nullable_to_non_nullable
as DiscordInfo?,
  ));
}

/// Create a copy of UserInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiscordInfoCopyWith<$Res>? get discord {
    if (_self.discord == null) {
    return null;
  }

  return $DiscordInfoCopyWith<$Res>(_self.discord!, (value) {
    return _then(_self.copyWith(discord: value));
  });
}
}

/// @nodoc
mixin _$DiscordInfo {

 String get id; String? get username; String? get avatarUrl; String? get email; List<String>? get roles;
/// Create a copy of DiscordInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscordInfoCopyWith<DiscordInfo> get copyWith => _$DiscordInfoCopyWithImpl<DiscordInfo>(this as DiscordInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiscordInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscordInfo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.email, _this.email) || other.email == _this.email)&&const DeepCollectionEquality().equals(other.roles, _this.roles));
}


@override
int get hashCode {
  final _this = this as DiscordInfo;
  return Object.hash(runtimeType,_this.id,_this.username,_this.avatarUrl,_this.email,const DeepCollectionEquality().hash(_this.roles));
}

@override
String toString() {
  final _this = this as DiscordInfo;
  return 'DiscordInfo(id: ${_this.id}, username: ${_this.username}, avatarUrl: ${_this.avatarUrl}, email: ${_this.email}, roles: ${_this.roles})';
}


}

/// @nodoc
abstract mixin class $DiscordInfoCopyWith<$Res>  {
  factory $DiscordInfoCopyWith(DiscordInfo value, $Res Function(DiscordInfo) _then) = _$DiscordInfoCopyWithImpl;
@useResult
$Res call({
 String id, String? username, String? avatarUrl, String? email, List<String>? roles
});




}
/// @nodoc
class _$DiscordInfoCopyWithImpl<$Res>
    implements $DiscordInfoCopyWith<$Res> {
  _$DiscordInfoCopyWithImpl(this._self, this._then);

  final DiscordInfo _self;
  final $Res Function(DiscordInfo) _then;

/// Create a copy of DiscordInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = freezed,Object? avatarUrl = freezed,Object? email = freezed,Object? roles = freezed,}) {
  return _then(DiscordInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,roles: freezed == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscordInfo].
extension DiscordInfoPatterns on DiscordInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscordInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscordInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscordInfo value)  $default,){
final _that = this;
switch (_that) {
case _DiscordInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscordInfo value)?  $default,){
final _that = this;
switch (_that) {
case _DiscordInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? username,  String? avatarUrl,  String? email,  List<String>? roles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscordInfo() when $default != null:
return $default(_that.id,_that.username,_that.avatarUrl,_that.email,_that.roles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? username,  String? avatarUrl,  String? email,  List<String>? roles)  $default,) {final _that = this;
switch (_that) {
case _DiscordInfo():
return $default(_that.id,_that.username,_that.avatarUrl,_that.email,_that.roles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? username,  String? avatarUrl,  String? email,  List<String>? roles)?  $default,) {final _that = this;
switch (_that) {
case _DiscordInfo() when $default != null:
return $default(_that.id,_that.username,_that.avatarUrl,_that.email,_that.roles);case _:
  return null;

}
}

}

/// @nodoc


class _DiscordInfo implements DiscordInfo {
  const _DiscordInfo({required this.id, this.username, this.avatarUrl, this.email,  List<String>? roles}): _roles = roles;
  

@override final  String id;
@override final  String? username;
@override final  String? avatarUrl;
@override final  String? email;
 final  List<String>? _roles;
@override List<String>? get roles {
  final value = _roles;
  if (value == null) return null;
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of DiscordInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscordInfoCopyWith<_DiscordInfo> get copyWith => __$DiscordInfoCopyWithImpl<_DiscordInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscordInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.roles, _roles));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,username,avatarUrl,email,const DeepCollectionEquality().hash(_roles));
}

@override
String toString() {
    return 'DiscordInfo(id: $id, username: $username, avatarUrl: $avatarUrl, email: $email, roles: $roles)';
}


}

/// @nodoc
abstract mixin class _$DiscordInfoCopyWith<$Res> implements $DiscordInfoCopyWith<$Res> {
  factory _$DiscordInfoCopyWith(_DiscordInfo value, $Res Function(_DiscordInfo) _then) = __$DiscordInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? username, String? avatarUrl, String? email, List<String>? roles
});




}
/// @nodoc
class __$DiscordInfoCopyWithImpl<$Res>
    implements _$DiscordInfoCopyWith<$Res> {
  __$DiscordInfoCopyWithImpl(this._self, this._then);

  final _DiscordInfo _self;
  final $Res Function(_DiscordInfo) _then;

/// Create a copy of DiscordInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = freezed,Object? avatarUrl = freezed,Object? email = freezed,Object? roles = freezed,}) {
  return _then(_DiscordInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,roles: freezed == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

/// @nodoc
mixin _$AccessToken {

 String get token; DateTime? get expiresAt;
/// Create a copy of AccessToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessTokenCopyWith<AccessToken> get copyWith => _$AccessTokenCopyWithImpl<AccessToken>(this as AccessToken, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AccessToken;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessToken&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}


@override
int get hashCode {
  final _this = this as AccessToken;
  return Object.hash(runtimeType,_this.token,_this.expiresAt);
}

@override
String toString() {
  final _this = this as AccessToken;
  return 'AccessToken(token: ${_this.token}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $AccessTokenCopyWith<$Res>  {
  factory $AccessTokenCopyWith(AccessToken value, $Res Function(AccessToken) _then) = _$AccessTokenCopyWithImpl;
@useResult
$Res call({
 String token, DateTime? expiresAt
});




}
/// @nodoc
class _$AccessTokenCopyWithImpl<$Res>
    implements $AccessTokenCopyWith<$Res> {
  _$AccessTokenCopyWithImpl(this._self, this._then);

  final AccessToken _self;
  final $Res Function(AccessToken) _then;

/// Create a copy of AccessToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? expiresAt = freezed,}) {
  return _then(AccessToken(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccessToken].
extension AccessTokenPatterns on AccessToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccessToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccessToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccessToken value)  $default,){
final _that = this;
switch (_that) {
case _AccessToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccessToken value)?  $default,){
final _that = this;
switch (_that) {
case _AccessToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccessToken() when $default != null:
return $default(_that.token,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _AccessToken():
return $default(_that.token,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _AccessToken() when $default != null:
return $default(_that.token,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _AccessToken implements AccessToken {
  const _AccessToken({required this.token, this.expiresAt});
  

@override final  String token;
@override final  DateTime? expiresAt;

/// Create a copy of AccessToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccessTokenCopyWith<_AccessToken> get copyWith => __$AccessTokenCopyWithImpl<_AccessToken>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccessToken&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,token,expiresAt);
}

@override
String toString() {
    return 'AccessToken(token: $token, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$AccessTokenCopyWith<$Res> implements $AccessTokenCopyWith<$Res> {
  factory _$AccessTokenCopyWith(_AccessToken value, $Res Function(_AccessToken) _then) = __$AccessTokenCopyWithImpl;
@override @useResult
$Res call({
 String token, DateTime? expiresAt
});




}
/// @nodoc
class __$AccessTokenCopyWithImpl<$Res>
    implements _$AccessTokenCopyWith<$Res> {
  __$AccessTokenCopyWithImpl(this._self, this._then);

  final _AccessToken _self;
  final $Res Function(_AccessToken) _then;

/// Create a copy of AccessToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? expiresAt = freezed,}) {
  return _then(_AccessToken(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
