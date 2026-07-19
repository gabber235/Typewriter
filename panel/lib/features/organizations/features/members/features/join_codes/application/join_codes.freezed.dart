// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_codes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationJoinCode {

 skir.RecordId get code; DateTime get createdAt; DateTime? get expiresAt; bool get singleUse; JoinCodeAutoAccept get autoAccept;
/// Create a copy of OrganizationJoinCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationJoinCodeCopyWith<OrganizationJoinCode> get copyWith => _$OrganizationJoinCodeCopyWithImpl<OrganizationJoinCode>(this as OrganizationJoinCode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationJoinCode&&(identical(other.code, code) || other.code == code)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.singleUse, singleUse) || other.singleUse == singleUse)&&(identical(other.autoAccept, autoAccept) || other.autoAccept == autoAccept));
}


@override
int get hashCode => Object.hash(runtimeType,code,createdAt,expiresAt,singleUse,autoAccept);

@override
String toString() {
  return 'OrganizationJoinCode(code: $code, createdAt: $createdAt, expiresAt: $expiresAt, singleUse: $singleUse, autoAccept: $autoAccept)';
}


}

/// @nodoc
abstract mixin class $OrganizationJoinCodeCopyWith<$Res>  {
  factory $OrganizationJoinCodeCopyWith(OrganizationJoinCode value, $Res Function(OrganizationJoinCode) _then) = _$OrganizationJoinCodeCopyWithImpl;
@useResult
$Res call({
 skir.RecordId code, DateTime createdAt, DateTime? expiresAt, bool singleUse, JoinCodeAutoAccept autoAccept
});


$JoinCodeAutoAcceptCopyWith<$Res> get autoAccept;

}
/// @nodoc
class _$OrganizationJoinCodeCopyWithImpl<$Res>
    implements $OrganizationJoinCodeCopyWith<$Res> {
  _$OrganizationJoinCodeCopyWithImpl(this._self, this._then);

  final OrganizationJoinCode _self;
  final $Res Function(OrganizationJoinCode) _then;

/// Create a copy of OrganizationJoinCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? createdAt = null,Object? expiresAt = freezed,Object? singleUse = null,Object? autoAccept = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as skir.RecordId,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,singleUse: null == singleUse ? _self.singleUse : singleUse // ignore: cast_nullable_to_non_nullable
as bool,autoAccept: null == autoAccept ? _self.autoAccept : autoAccept // ignore: cast_nullable_to_non_nullable
as JoinCodeAutoAccept,
  ));
}
/// Create a copy of OrganizationJoinCode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JoinCodeAutoAcceptCopyWith<$Res> get autoAccept {
  
  return $JoinCodeAutoAcceptCopyWith<$Res>(_self.autoAccept, (value) {
    return _then(_self.copyWith(autoAccept: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrganizationJoinCode].
extension OrganizationJoinCodePatterns on OrganizationJoinCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationJoinCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationJoinCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationJoinCode value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationJoinCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationJoinCode value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationJoinCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId code,  DateTime createdAt,  DateTime? expiresAt,  bool singleUse,  JoinCodeAutoAccept autoAccept)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationJoinCode() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId code,  DateTime createdAt,  DateTime? expiresAt,  bool singleUse,  JoinCodeAutoAccept autoAccept)  $default,) {final _that = this;
switch (_that) {
case _OrganizationJoinCode():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId code,  DateTime createdAt,  DateTime? expiresAt,  bool singleUse,  JoinCodeAutoAccept autoAccept)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationJoinCode() when $default != null:
return $default(_that.code,_that.createdAt,_that.expiresAt,_that.singleUse,_that.autoAccept);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationJoinCode extends OrganizationJoinCode {
  const _OrganizationJoinCode({required this.code, required this.createdAt, this.expiresAt, this.singleUse = true, this.autoAccept = const JoinCodeAutoAccept()}): super._();
  

@override final  skir.RecordId code;
@override final  DateTime createdAt;
@override final  DateTime? expiresAt;
@override@JsonKey() final  bool singleUse;
@override@JsonKey() final  JoinCodeAutoAccept autoAccept;

/// Create a copy of OrganizationJoinCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationJoinCodeCopyWith<_OrganizationJoinCode> get copyWith => __$OrganizationJoinCodeCopyWithImpl<_OrganizationJoinCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationJoinCode&&(identical(other.code, code) || other.code == code)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.singleUse, singleUse) || other.singleUse == singleUse)&&(identical(other.autoAccept, autoAccept) || other.autoAccept == autoAccept));
}


@override
int get hashCode => Object.hash(runtimeType,code,createdAt,expiresAt,singleUse,autoAccept);

@override
String toString() {
  return 'OrganizationJoinCode(code: $code, createdAt: $createdAt, expiresAt: $expiresAt, singleUse: $singleUse, autoAccept: $autoAccept)';
}


}

/// @nodoc
abstract mixin class _$OrganizationJoinCodeCopyWith<$Res> implements $OrganizationJoinCodeCopyWith<$Res> {
  factory _$OrganizationJoinCodeCopyWith(_OrganizationJoinCode value, $Res Function(_OrganizationJoinCode) _then) = __$OrganizationJoinCodeCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId code, DateTime createdAt, DateTime? expiresAt, bool singleUse, JoinCodeAutoAccept autoAccept
});


@override $JoinCodeAutoAcceptCopyWith<$Res> get autoAccept;

}
/// @nodoc
class __$OrganizationJoinCodeCopyWithImpl<$Res>
    implements _$OrganizationJoinCodeCopyWith<$Res> {
  __$OrganizationJoinCodeCopyWithImpl(this._self, this._then);

  final _OrganizationJoinCode _self;
  final $Res Function(_OrganizationJoinCode) _then;

/// Create a copy of OrganizationJoinCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? createdAt = null,Object? expiresAt = freezed,Object? singleUse = null,Object? autoAccept = null,}) {
  return _then(_OrganizationJoinCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as skir.RecordId,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,singleUse: null == singleUse ? _self.singleUse : singleUse // ignore: cast_nullable_to_non_nullable
as bool,autoAccept: null == autoAccept ? _self.autoAccept : autoAccept // ignore: cast_nullable_to_non_nullable
as JoinCodeAutoAccept,
  ));
}

/// Create a copy of OrganizationJoinCode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JoinCodeAutoAcceptCopyWith<$Res> get autoAccept {
  
  return $JoinCodeAutoAcceptCopyWith<$Res>(_self.autoAccept, (value) {
    return _then(_self.copyWith(autoAccept: value));
  });
}
}

/// @nodoc
mixin _$JoinCodeAutoAccept {

 List<skir.RecordId> get roleIds;
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
 List<skir.RecordId> roleIds
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
as List<skir.RecordId>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<skir.RecordId> roleIds)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<skir.RecordId> roleIds)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<skir.RecordId> roleIds)?  $default,) {final _that = this;
switch (_that) {
case _JoinCodeAutoAccept() when $default != null:
return $default(_that.roleIds);case _:
  return null;

}
}

}

/// @nodoc


class _JoinCodeAutoAccept extends JoinCodeAutoAccept {
  const _JoinCodeAutoAccept({final  List<skir.RecordId> roleIds = const []}): _roleIds = roleIds,super._();
  

 final  List<skir.RecordId> _roleIds;
@override@JsonKey() List<skir.RecordId> get roleIds {
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
 List<skir.RecordId> roleIds
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
as List<skir.RecordId>,
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

 bool get singleUse; JoinCodeExpiration get expiration; List<skir.RecordId> get autoAcceptRoleIds;
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
 bool singleUse, JoinCodeExpiration expiration, List<skir.RecordId> autoAcceptRoleIds
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
@pragma('vm:prefer-inline') @override $Res call({Object? singleUse = null,Object? expiration = null,Object? autoAcceptRoleIds = null,}) {
  return _then(_self.copyWith(
singleUse: null == singleUse ? _self.singleUse : singleUse // ignore: cast_nullable_to_non_nullable
as bool,expiration: null == expiration ? _self.expiration : expiration // ignore: cast_nullable_to_non_nullable
as JoinCodeExpiration,autoAcceptRoleIds: null == autoAcceptRoleIds ? _self.autoAcceptRoleIds : autoAcceptRoleIds // ignore: cast_nullable_to_non_nullable
as List<skir.RecordId>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool singleUse,  JoinCodeExpiration expiration,  List<skir.RecordId> autoAcceptRoleIds)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool singleUse,  JoinCodeExpiration expiration,  List<skir.RecordId> autoAcceptRoleIds)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool singleUse,  JoinCodeExpiration expiration,  List<skir.RecordId> autoAcceptRoleIds)?  $default,) {final _that = this;
switch (_that) {
case _JoinCodeOptions() when $default != null:
return $default(_that.singleUse,_that.expiration,_that.autoAcceptRoleIds);case _:
  return null;

}
}

}

/// @nodoc


class _JoinCodeOptions implements JoinCodeOptions {
  const _JoinCodeOptions({this.singleUse = true, this.expiration = const JoinCodeExpiration.duration(Duration(days: 7)), final  List<skir.RecordId> autoAcceptRoleIds = const []}): _autoAcceptRoleIds = autoAcceptRoleIds;
  

@override@JsonKey() final  bool singleUse;
@override@JsonKey() final  JoinCodeExpiration expiration;
 final  List<skir.RecordId> _autoAcceptRoleIds;
@override@JsonKey() List<skir.RecordId> get autoAcceptRoleIds {
  if (_autoAcceptRoleIds is EqualUnmodifiableListView) return _autoAcceptRoleIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_autoAcceptRoleIds);
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
 bool singleUse, JoinCodeExpiration expiration, List<skir.RecordId> autoAcceptRoleIds
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
@override @pragma('vm:prefer-inline') $Res call({Object? singleUse = null,Object? expiration = null,Object? autoAcceptRoleIds = null,}) {
  return _then(_JoinCodeOptions(
singleUse: null == singleUse ? _self.singleUse : singleUse // ignore: cast_nullable_to_non_nullable
as bool,expiration: null == expiration ? _self.expiration : expiration // ignore: cast_nullable_to_non_nullable
as JoinCodeExpiration,autoAcceptRoleIds: null == autoAcceptRoleIds ? _self._autoAcceptRoleIds : autoAcceptRoleIds // ignore: cast_nullable_to_non_nullable
as List<skir.RecordId>,
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
