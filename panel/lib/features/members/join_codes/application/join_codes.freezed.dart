// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_codes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
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
int get hashCode {
    return Object.hash(runtimeType,duration);
}

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
  final _this = this as JoinCodeOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinCodeOptions&&(identical(other.singleUse, _this.singleUse) || other.singleUse == _this.singleUse)&&(identical(other.expiration, _this.expiration) || other.expiration == _this.expiration)&&const DeepCollectionEquality().equals(other.autoAcceptRoleIds, _this.autoAcceptRoleIds));
}


@override
int get hashCode {
  final _this = this as JoinCodeOptions;
  return Object.hash(runtimeType,_this.singleUse,_this.expiration,const DeepCollectionEquality().hash(_this.autoAcceptRoleIds));
}

@override
String toString() {
  final _this = this as JoinCodeOptions;
  return 'JoinCodeOptions(singleUse: ${_this.singleUse}, expiration: ${_this.expiration}, autoAcceptRoleIds: ${_this.autoAcceptRoleIds})';
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
  return _then(JoinCodeOptions(
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
  const _JoinCodeOptions({this.singleUse = true, this.expiration = const JoinCodeExpiration.duration(Duration(days: 7)),  List<skir.RecordId> autoAcceptRoleIds = const []}): _autoAcceptRoleIds = autoAcceptRoleIds;
  

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinCodeOptions&&(identical(other.singleUse, singleUse) || other.singleUse == singleUse)&&(identical(other.expiration, expiration) || other.expiration == expiration)&&const DeepCollectionEquality().equals(other.autoAcceptRoleIds, _autoAcceptRoleIds));
}


@override
int get hashCode {
    return Object.hash(runtimeType,singleUse,expiration,const DeepCollectionEquality().hash(_autoAcceptRoleIds));
}

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
