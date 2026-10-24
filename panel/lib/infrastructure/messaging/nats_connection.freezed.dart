// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nats_connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NatsConnectionSettings {

 String get url; String get token; UserInfo get user; skir.GetSentinelCredentialsResponse_Success get sentinel; skir.RecordId? get organization;
/// Create a copy of NatsConnectionSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NatsConnectionSettingsCopyWith<NatsConnectionSettings> get copyWith => _$NatsConnectionSettingsCopyWithImpl<NatsConnectionSettings>(this as NatsConnectionSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NatsConnectionSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NatsConnectionSettings&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.user, _this.user) || other.user == _this.user)&&(identical(other.sentinel, _this.sentinel) || other.sentinel == _this.sentinel)&&(identical(other.organization, _this.organization) || other.organization == _this.organization));
}


@override
int get hashCode {
  final _this = this as NatsConnectionSettings;
  return Object.hash(runtimeType,_this.url,_this.token,_this.user,_this.sentinel,_this.organization);
}



}

/// @nodoc
abstract mixin class $NatsConnectionSettingsCopyWith<$Res>  {
  factory $NatsConnectionSettingsCopyWith(NatsConnectionSettings value, $Res Function(NatsConnectionSettings) _then) = _$NatsConnectionSettingsCopyWithImpl;
@useResult
$Res call({
 String url, String token, UserInfo user, skir.GetSentinelCredentialsResponse_Success sentinel, skir.RecordId? organization
});


$UserInfoCopyWith<$Res> get user;

}
/// @nodoc
class _$NatsConnectionSettingsCopyWithImpl<$Res>
    implements $NatsConnectionSettingsCopyWith<$Res> {
  _$NatsConnectionSettingsCopyWithImpl(this._self, this._then);

  final NatsConnectionSettings _self;
  final $Res Function(NatsConnectionSettings) _then;

/// Create a copy of NatsConnectionSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? token = null,Object? user = null,Object? sentinel = null,Object? organization = freezed,}) {
  return _then(NatsConnectionSettings(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserInfo,sentinel: null == sentinel ? _self.sentinel : sentinel // ignore: cast_nullable_to_non_nullable
as skir.GetSentinelCredentialsResponse_Success,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,
  ));
}
/// Create a copy of NatsConnectionSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserInfoCopyWith<$Res> get user {
  
  return $UserInfoCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [NatsConnectionSettings].
extension NatsConnectionSettingsPatterns on NatsConnectionSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NatsConnectionSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NatsConnectionSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NatsConnectionSettings value)  $default,){
final _that = this;
switch (_that) {
case _NatsConnectionSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NatsConnectionSettings value)?  $default,){
final _that = this;
switch (_that) {
case _NatsConnectionSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String token,  UserInfo user,  skir.GetSentinelCredentialsResponse_Success sentinel,  skir.RecordId? organization)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NatsConnectionSettings() when $default != null:
return $default(_that.url,_that.token,_that.user,_that.sentinel,_that.organization);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String token,  UserInfo user,  skir.GetSentinelCredentialsResponse_Success sentinel,  skir.RecordId? organization)  $default,) {final _that = this;
switch (_that) {
case _NatsConnectionSettings():
return $default(_that.url,_that.token,_that.user,_that.sentinel,_that.organization);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String token,  UserInfo user,  skir.GetSentinelCredentialsResponse_Success sentinel,  skir.RecordId? organization)?  $default,) {final _that = this;
switch (_that) {
case _NatsConnectionSettings() when $default != null:
return $default(_that.url,_that.token,_that.user,_that.sentinel,_that.organization);case _:
  return null;

}
}

}

/// @nodoc


class _NatsConnectionSettings extends NatsConnectionSettings {
  const _NatsConnectionSettings({required this.url, required this.token, required this.user, required this.sentinel, required this.organization}): super._();
  

@override final  String url;
@override final  String token;
@override final  UserInfo user;
@override final  skir.GetSentinelCredentialsResponse_Success sentinel;
@override final  skir.RecordId? organization;

/// Create a copy of NatsConnectionSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NatsConnectionSettingsCopyWith<_NatsConnectionSettings> get copyWith => __$NatsConnectionSettingsCopyWithImpl<_NatsConnectionSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NatsConnectionSettings&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.user, user) || other.user == user)&&(identical(other.sentinel, sentinel) || other.sentinel == sentinel)&&(identical(other.organization, organization) || other.organization == organization));
}


@override
int get hashCode {
    return Object.hash(runtimeType,url,token,user,sentinel,organization);
}



}

/// @nodoc
abstract mixin class _$NatsConnectionSettingsCopyWith<$Res> implements $NatsConnectionSettingsCopyWith<$Res> {
  factory _$NatsConnectionSettingsCopyWith(_NatsConnectionSettings value, $Res Function(_NatsConnectionSettings) _then) = __$NatsConnectionSettingsCopyWithImpl;
@override @useResult
$Res call({
 String url, String token, UserInfo user, skir.GetSentinelCredentialsResponse_Success sentinel, skir.RecordId? organization
});


@override $UserInfoCopyWith<$Res> get user;

}
/// @nodoc
class __$NatsConnectionSettingsCopyWithImpl<$Res>
    implements _$NatsConnectionSettingsCopyWith<$Res> {
  __$NatsConnectionSettingsCopyWithImpl(this._self, this._then);

  final _NatsConnectionSettings _self;
  final $Res Function(_NatsConnectionSettings) _then;

/// Create a copy of NatsConnectionSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? token = null,Object? user = null,Object? sentinel = null,Object? organization = freezed,}) {
  return _then(_NatsConnectionSettings(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserInfo,sentinel: null == sentinel ? _self.sentinel : sentinel // ignore: cast_nullable_to_non_nullable
as skir.GetSentinelCredentialsResponse_Success,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,
  ));
}

/// Create a copy of NatsConnectionSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserInfoCopyWith<$Res> get user {
  
  return $UserInfoCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
