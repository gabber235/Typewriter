// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_presence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresenceSessionKey {

 String get userId; String get sessionId;
/// Create a copy of PresenceSessionKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresenceSessionKeyCopyWith<PresenceSessionKey> get copyWith => _$PresenceSessionKeyCopyWithImpl<PresenceSessionKey>(this as PresenceSessionKey, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresenceSessionKey&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}


@override
int get hashCode => Object.hash(runtimeType,userId,sessionId);

@override
String toString() {
  return 'PresenceSessionKey(userId: $userId, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class $PresenceSessionKeyCopyWith<$Res>  {
  factory $PresenceSessionKeyCopyWith(PresenceSessionKey value, $Res Function(PresenceSessionKey) _then) = _$PresenceSessionKeyCopyWithImpl;
@useResult
$Res call({
 String userId, String sessionId
});




}
/// @nodoc
class _$PresenceSessionKeyCopyWithImpl<$Res>
    implements $PresenceSessionKeyCopyWith<$Res> {
  _$PresenceSessionKeyCopyWithImpl(this._self, this._then);

  final PresenceSessionKey _self;
  final $Res Function(PresenceSessionKey) _then;

/// Create a copy of PresenceSessionKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? sessionId = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PresenceSessionKey].
extension PresenceSessionKeyPatterns on PresenceSessionKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresenceSessionKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresenceSessionKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresenceSessionKey value)  $default,){
final _that = this;
switch (_that) {
case _PresenceSessionKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresenceSessionKey value)?  $default,){
final _that = this;
switch (_that) {
case _PresenceSessionKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String sessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresenceSessionKey() when $default != null:
return $default(_that.userId,_that.sessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String sessionId)  $default,) {final _that = this;
switch (_that) {
case _PresenceSessionKey():
return $default(_that.userId,_that.sessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String sessionId)?  $default,) {final _that = this;
switch (_that) {
case _PresenceSessionKey() when $default != null:
return $default(_that.userId,_that.sessionId);case _:
  return null;

}
}

}

/// @nodoc


class _PresenceSessionKey implements PresenceSessionKey {
  const _PresenceSessionKey(this.userId, this.sessionId);
  

@override final  String userId;
@override final  String sessionId;

/// Create a copy of PresenceSessionKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresenceSessionKeyCopyWith<_PresenceSessionKey> get copyWith => __$PresenceSessionKeyCopyWithImpl<_PresenceSessionKey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresenceSessionKey&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}


@override
int get hashCode => Object.hash(runtimeType,userId,sessionId);

@override
String toString() {
  return 'PresenceSessionKey(userId: $userId, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class _$PresenceSessionKeyCopyWith<$Res> implements $PresenceSessionKeyCopyWith<$Res> {
  factory _$PresenceSessionKeyCopyWith(_PresenceSessionKey value, $Res Function(_PresenceSessionKey) _then) = __$PresenceSessionKeyCopyWithImpl;
@override @useResult
$Res call({
 String userId, String sessionId
});




}
/// @nodoc
class __$PresenceSessionKeyCopyWithImpl<$Res>
    implements _$PresenceSessionKeyCopyWith<$Res> {
  __$PresenceSessionKeyCopyWithImpl(this._self, this._then);

  final _PresenceSessionKey _self;
  final $Res Function(_PresenceSessionKey) _then;

/// Create a copy of PresenceSessionKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? sessionId = null,}) {
  return _then(_PresenceSessionKey(
null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ActivePanelPresence {

 String get userId; wire.PanelPresence get presence; DateTime get observedAt;
/// Create a copy of ActivePanelPresence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivePanelPresenceCopyWith<ActivePanelPresence> get copyWith => _$ActivePanelPresenceCopyWithImpl<ActivePanelPresence>(this as ActivePanelPresence, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivePanelPresence&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.observedAt, observedAt) || other.observedAt == observedAt));
}


@override
int get hashCode => Object.hash(runtimeType,userId,presence,observedAt);

@override
String toString() {
  return 'ActivePanelPresence(userId: $userId, presence: $presence, observedAt: $observedAt)';
}


}

/// @nodoc
abstract mixin class $ActivePanelPresenceCopyWith<$Res>  {
  factory $ActivePanelPresenceCopyWith(ActivePanelPresence value, $Res Function(ActivePanelPresence) _then) = _$ActivePanelPresenceCopyWithImpl;
@useResult
$Res call({
 String userId, wire.PanelPresence presence, DateTime observedAt
});




}
/// @nodoc
class _$ActivePanelPresenceCopyWithImpl<$Res>
    implements $ActivePanelPresenceCopyWith<$Res> {
  _$ActivePanelPresenceCopyWithImpl(this._self, this._then);

  final ActivePanelPresence _self;
  final $Res Function(ActivePanelPresence) _then;

/// Create a copy of ActivePanelPresence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? presence = null,Object? observedAt = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as wire.PanelPresence,observedAt: null == observedAt ? _self.observedAt : observedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivePanelPresence].
extension ActivePanelPresencePatterns on ActivePanelPresence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivePanelPresence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivePanelPresence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivePanelPresence value)  $default,){
final _that = this;
switch (_that) {
case _ActivePanelPresence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivePanelPresence value)?  $default,){
final _that = this;
switch (_that) {
case _ActivePanelPresence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  wire.PanelPresence presence,  DateTime observedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivePanelPresence() when $default != null:
return $default(_that.userId,_that.presence,_that.observedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  wire.PanelPresence presence,  DateTime observedAt)  $default,) {final _that = this;
switch (_that) {
case _ActivePanelPresence():
return $default(_that.userId,_that.presence,_that.observedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  wire.PanelPresence presence,  DateTime observedAt)?  $default,) {final _that = this;
switch (_that) {
case _ActivePanelPresence() when $default != null:
return $default(_that.userId,_that.presence,_that.observedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ActivePanelPresence implements ActivePanelPresence {
  const _ActivePanelPresence({required this.userId, required this.presence, required this.observedAt});
  

@override final  String userId;
@override final  wire.PanelPresence presence;
@override final  DateTime observedAt;

/// Create a copy of ActivePanelPresence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivePanelPresenceCopyWith<_ActivePanelPresence> get copyWith => __$ActivePanelPresenceCopyWithImpl<_ActivePanelPresence>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivePanelPresence&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.observedAt, observedAt) || other.observedAt == observedAt));
}


@override
int get hashCode => Object.hash(runtimeType,userId,presence,observedAt);

@override
String toString() {
  return 'ActivePanelPresence(userId: $userId, presence: $presence, observedAt: $observedAt)';
}


}

/// @nodoc
abstract mixin class _$ActivePanelPresenceCopyWith<$Res> implements $ActivePanelPresenceCopyWith<$Res> {
  factory _$ActivePanelPresenceCopyWith(_ActivePanelPresence value, $Res Function(_ActivePanelPresence) _then) = __$ActivePanelPresenceCopyWithImpl;
@override @useResult
$Res call({
 String userId, wire.PanelPresence presence, DateTime observedAt
});




}
/// @nodoc
class __$ActivePanelPresenceCopyWithImpl<$Res>
    implements _$ActivePanelPresenceCopyWith<$Res> {
  __$ActivePanelPresenceCopyWithImpl(this._self, this._then);

  final _ActivePanelPresence _self;
  final $Res Function(_ActivePanelPresence) _then;

/// Create a copy of ActivePanelPresence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? presence = null,Object? observedAt = null,}) {
  return _then(_ActivePanelPresence(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as wire.PanelPresence,observedAt: null == observedAt ? _self.observedAt : observedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
