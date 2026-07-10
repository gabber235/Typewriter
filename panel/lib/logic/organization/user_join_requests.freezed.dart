// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_join_requests.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserJoinRequest implements DiagnosticableTreeMixin {

 skir.RecordId get requestId; skir.RecordId get organizationId; String get organizationName; String get organizationLogoUrl; DateTime get requestedAt; DateTime get expiresAt;
/// Create a copy of UserJoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserJoinRequestCopyWith<UserJoinRequest> get copyWith => _$UserJoinRequestCopyWithImpl<UserJoinRequest>(this as UserJoinRequest, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'UserJoinRequest'))
    ..add(DiagnosticsProperty('requestId', requestId))..add(DiagnosticsProperty('organizationId', organizationId))..add(DiagnosticsProperty('organizationName', organizationName))..add(DiagnosticsProperty('organizationLogoUrl', organizationLogoUrl))..add(DiagnosticsProperty('requestedAt', requestedAt))..add(DiagnosticsProperty('expiresAt', expiresAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.organizationLogoUrl, organizationLogoUrl) || other.organizationLogoUrl == organizationLogoUrl)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,organizationId,organizationName,organizationLogoUrl,requestedAt,expiresAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'UserJoinRequest(requestId: $requestId, organizationId: $organizationId, organizationName: $organizationName, organizationLogoUrl: $organizationLogoUrl, requestedAt: $requestedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $UserJoinRequestCopyWith<$Res>  {
  factory $UserJoinRequestCopyWith(UserJoinRequest value, $Res Function(UserJoinRequest) _then) = _$UserJoinRequestCopyWithImpl;
@useResult
$Res call({
 skir.RecordId requestId, skir.RecordId organizationId, String organizationName, String organizationLogoUrl, DateTime requestedAt, DateTime expiresAt
});




}
/// @nodoc
class _$UserJoinRequestCopyWithImpl<$Res>
    implements $UserJoinRequestCopyWith<$Res> {
  _$UserJoinRequestCopyWithImpl(this._self, this._then);

  final UserJoinRequest _self;
  final $Res Function(UserJoinRequest) _then;

/// Create a copy of UserJoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? organizationId = null,Object? organizationName = null,Object? organizationLogoUrl = null,Object? requestedAt = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,organizationLogoUrl: null == organizationLogoUrl ? _self.organizationLogoUrl : organizationLogoUrl // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserJoinRequest].
extension UserJoinRequestPatterns on UserJoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserJoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserJoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserJoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _UserJoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserJoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UserJoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId requestId,  skir.RecordId organizationId,  String organizationName,  String organizationLogoUrl,  DateTime requestedAt,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserJoinRequest() when $default != null:
return $default(_that.requestId,_that.organizationId,_that.organizationName,_that.organizationLogoUrl,_that.requestedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId requestId,  skir.RecordId organizationId,  String organizationName,  String organizationLogoUrl,  DateTime requestedAt,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _UserJoinRequest():
return $default(_that.requestId,_that.organizationId,_that.organizationName,_that.organizationLogoUrl,_that.requestedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId requestId,  skir.RecordId organizationId,  String organizationName,  String organizationLogoUrl,  DateTime requestedAt,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _UserJoinRequest() when $default != null:
return $default(_that.requestId,_that.organizationId,_that.organizationName,_that.organizationLogoUrl,_that.requestedAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _UserJoinRequest extends UserJoinRequest with DiagnosticableTreeMixin {
  const _UserJoinRequest({required this.requestId, required this.organizationId, required this.organizationName, required this.organizationLogoUrl, required this.requestedAt, required this.expiresAt}): super._();
  

@override final  skir.RecordId requestId;
@override final  skir.RecordId organizationId;
@override final  String organizationName;
@override final  String organizationLogoUrl;
@override final  DateTime requestedAt;
@override final  DateTime expiresAt;

/// Create a copy of UserJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserJoinRequestCopyWith<_UserJoinRequest> get copyWith => __$UserJoinRequestCopyWithImpl<_UserJoinRequest>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'UserJoinRequest'))
    ..add(DiagnosticsProperty('requestId', requestId))..add(DiagnosticsProperty('organizationId', organizationId))..add(DiagnosticsProperty('organizationName', organizationName))..add(DiagnosticsProperty('organizationLogoUrl', organizationLogoUrl))..add(DiagnosticsProperty('requestedAt', requestedAt))..add(DiagnosticsProperty('expiresAt', expiresAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserJoinRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.organizationLogoUrl, organizationLogoUrl) || other.organizationLogoUrl == organizationLogoUrl)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,organizationId,organizationName,organizationLogoUrl,requestedAt,expiresAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'UserJoinRequest(requestId: $requestId, organizationId: $organizationId, organizationName: $organizationName, organizationLogoUrl: $organizationLogoUrl, requestedAt: $requestedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$UserJoinRequestCopyWith<$Res> implements $UserJoinRequestCopyWith<$Res> {
  factory _$UserJoinRequestCopyWith(_UserJoinRequest value, $Res Function(_UserJoinRequest) _then) = __$UserJoinRequestCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId requestId, skir.RecordId organizationId, String organizationName, String organizationLogoUrl, DateTime requestedAt, DateTime expiresAt
});




}
/// @nodoc
class __$UserJoinRequestCopyWithImpl<$Res>
    implements _$UserJoinRequestCopyWith<$Res> {
  __$UserJoinRequestCopyWithImpl(this._self, this._then);

  final _UserJoinRequest _self;
  final $Res Function(_UserJoinRequest) _then;

/// Create a copy of UserJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? organizationId = null,Object? organizationName = null,Object? organizationLogoUrl = null,Object? requestedAt = null,Object? expiresAt = null,}) {
  return _then(_UserJoinRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,organizationLogoUrl: null == organizationLogoUrl ? _self.organizationLogoUrl : organizationLogoUrl // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
