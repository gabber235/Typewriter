// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_requests.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationJoinRequest {

 skir.RecordId get requestId; skir.RecordId get userId; DateTime get requestedAt; DateTime get expiresAt; String? get userName; String? get userEmail; String? get userAvatarUrl;
/// Create a copy of OrganizationJoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationJoinRequestCopyWith<OrganizationJoinRequest> get copyWith => _$OrganizationJoinRequestCopyWithImpl<OrganizationJoinRequest>(this as OrganizationJoinRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.userAvatarUrl, userAvatarUrl) || other.userAvatarUrl == userAvatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,userId,requestedAt,expiresAt,userName,userEmail,userAvatarUrl);

@override
String toString() {
  return 'OrganizationJoinRequest(requestId: $requestId, userId: $userId, requestedAt: $requestedAt, expiresAt: $expiresAt, userName: $userName, userEmail: $userEmail, userAvatarUrl: $userAvatarUrl)';
}


}

/// @nodoc
abstract mixin class $OrganizationJoinRequestCopyWith<$Res>  {
  factory $OrganizationJoinRequestCopyWith(OrganizationJoinRequest value, $Res Function(OrganizationJoinRequest) _then) = _$OrganizationJoinRequestCopyWithImpl;
@useResult
$Res call({
 skir.RecordId requestId, skir.RecordId userId, DateTime requestedAt, DateTime expiresAt, String? userName, String? userEmail, String? userAvatarUrl
});




}
/// @nodoc
class _$OrganizationJoinRequestCopyWithImpl<$Res>
    implements $OrganizationJoinRequestCopyWith<$Res> {
  _$OrganizationJoinRequestCopyWithImpl(this._self, this._then);

  final OrganizationJoinRequest _self;
  final $Res Function(OrganizationJoinRequest) _then;

/// Create a copy of OrganizationJoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? userId = null,Object? requestedAt = null,Object? expiresAt = null,Object? userName = freezed,Object? userEmail = freezed,Object? userAvatarUrl = freezed,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,userEmail: freezed == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String?,userAvatarUrl: freezed == userAvatarUrl ? _self.userAvatarUrl : userAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationJoinRequest].
extension OrganizationJoinRequestPatterns on OrganizationJoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationJoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationJoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationJoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationJoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationJoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationJoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId requestId,  skir.RecordId userId,  DateTime requestedAt,  DateTime expiresAt,  String? userName,  String? userEmail,  String? userAvatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationJoinRequest() when $default != null:
return $default(_that.requestId,_that.userId,_that.requestedAt,_that.expiresAt,_that.userName,_that.userEmail,_that.userAvatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId requestId,  skir.RecordId userId,  DateTime requestedAt,  DateTime expiresAt,  String? userName,  String? userEmail,  String? userAvatarUrl)  $default,) {final _that = this;
switch (_that) {
case _OrganizationJoinRequest():
return $default(_that.requestId,_that.userId,_that.requestedAt,_that.expiresAt,_that.userName,_that.userEmail,_that.userAvatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId requestId,  skir.RecordId userId,  DateTime requestedAt,  DateTime expiresAt,  String? userName,  String? userEmail,  String? userAvatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationJoinRequest() when $default != null:
return $default(_that.requestId,_that.userId,_that.requestedAt,_that.expiresAt,_that.userName,_that.userEmail,_that.userAvatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationJoinRequest extends OrganizationJoinRequest {
  const _OrganizationJoinRequest({required this.requestId, required this.userId, required this.requestedAt, required this.expiresAt, this.userName, this.userEmail, this.userAvatarUrl}): super._();
  

@override final  skir.RecordId requestId;
@override final  skir.RecordId userId;
@override final  DateTime requestedAt;
@override final  DateTime expiresAt;
@override final  String? userName;
@override final  String? userEmail;
@override final  String? userAvatarUrl;

/// Create a copy of OrganizationJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationJoinRequestCopyWith<_OrganizationJoinRequest> get copyWith => __$OrganizationJoinRequestCopyWithImpl<_OrganizationJoinRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.userAvatarUrl, userAvatarUrl) || other.userAvatarUrl == userAvatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,userId,requestedAt,expiresAt,userName,userEmail,userAvatarUrl);

@override
String toString() {
  return 'OrganizationJoinRequest(requestId: $requestId, userId: $userId, requestedAt: $requestedAt, expiresAt: $expiresAt, userName: $userName, userEmail: $userEmail, userAvatarUrl: $userAvatarUrl)';
}


}

/// @nodoc
abstract mixin class _$OrganizationJoinRequestCopyWith<$Res> implements $OrganizationJoinRequestCopyWith<$Res> {
  factory _$OrganizationJoinRequestCopyWith(_OrganizationJoinRequest value, $Res Function(_OrganizationJoinRequest) _then) = __$OrganizationJoinRequestCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId requestId, skir.RecordId userId, DateTime requestedAt, DateTime expiresAt, String? userName, String? userEmail, String? userAvatarUrl
});




}
/// @nodoc
class __$OrganizationJoinRequestCopyWithImpl<$Res>
    implements _$OrganizationJoinRequestCopyWith<$Res> {
  __$OrganizationJoinRequestCopyWithImpl(this._self, this._then);

  final _OrganizationJoinRequest _self;
  final $Res Function(_OrganizationJoinRequest) _then;

/// Create a copy of OrganizationJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? userId = null,Object? requestedAt = null,Object? expiresAt = null,Object? userName = freezed,Object? userEmail = freezed,Object? userAvatarUrl = freezed,}) {
  return _then(_OrganizationJoinRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,userEmail: freezed == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String?,userAvatarUrl: freezed == userAvatarUrl ? _self.userAvatarUrl : userAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
