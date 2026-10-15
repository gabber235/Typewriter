// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'value_update_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CoalesceUpdates<T> {

 Duration get duration;
/// Create a copy of CoalesceUpdates
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoalesceUpdatesCopyWith<T, CoalesceUpdates<T>> get copyWith => _$CoalesceUpdatesCopyWithImpl<T, CoalesceUpdates<T>>(this as CoalesceUpdates<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoalesceUpdates<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoalesceUpdates<T>&&(identical(other.duration, _this.duration) || other.duration == _this.duration));
}


@override
int get hashCode {
  final _this = this as CoalesceUpdates<T>;
  return Object.hash(runtimeType,_this.duration);
}

@override
String toString() {
  final _this = this as CoalesceUpdates<T>;
  return 'CoalesceUpdates<$T>(duration: ${_this.duration})';
}


}

/// @nodoc
abstract mixin class $CoalesceUpdatesCopyWith<T,$Res>  {
  factory $CoalesceUpdatesCopyWith(CoalesceUpdates<T> value, $Res Function(CoalesceUpdates<T>) _then) = _$CoalesceUpdatesCopyWithImpl;
@useResult
$Res call({
 Duration duration
});




}
/// @nodoc
class _$CoalesceUpdatesCopyWithImpl<T,$Res>
    implements $CoalesceUpdatesCopyWith<T, $Res> {
  _$CoalesceUpdatesCopyWithImpl(this._self, this._then);

  final CoalesceUpdates<T> _self;
  final $Res Function(CoalesceUpdates<T>) _then;

/// Create a copy of CoalesceUpdates
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duration = null,}) {
  return _then(CoalesceUpdates(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [CoalesceUpdates].
extension CoalesceUpdatesPatterns<T> on CoalesceUpdates<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoalesceUpdates<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoalesceUpdates() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoalesceUpdates<T> value)  $default,){
final _that = this;
switch (_that) {
case _CoalesceUpdates():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoalesceUpdates<T> value)?  $default,){
final _that = this;
switch (_that) {
case _CoalesceUpdates() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoalesceUpdates() when $default != null:
return $default(_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration duration)  $default,) {final _that = this;
switch (_that) {
case _CoalesceUpdates():
return $default(_that.duration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration duration)?  $default,) {final _that = this;
switch (_that) {
case _CoalesceUpdates() when $default != null:
return $default(_that.duration);case _:
  return null;

}
}

}

/// @nodoc


class _CoalesceUpdates<T> extends CoalesceUpdates<T> {
  const _CoalesceUpdates({this.duration = const Duration(milliseconds: 100)}): super._();
  

@override@JsonKey() final  Duration duration;

/// Create a copy of CoalesceUpdates
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoalesceUpdatesCopyWith<T, _CoalesceUpdates<T>> get copyWith => __$CoalesceUpdatesCopyWithImpl<T, _CoalesceUpdates<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoalesceUpdates<T>&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode {
    return Object.hash(runtimeType,duration);
}

@override
String toString() {
    return 'CoalesceUpdates<$T>(duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$CoalesceUpdatesCopyWith<T,$Res> implements $CoalesceUpdatesCopyWith<T, $Res> {
  factory _$CoalesceUpdatesCopyWith(_CoalesceUpdates<T> value, $Res Function(_CoalesceUpdates<T>) _then) = __$CoalesceUpdatesCopyWithImpl;
@override @useResult
$Res call({
 Duration duration
});




}
/// @nodoc
class __$CoalesceUpdatesCopyWithImpl<T,$Res>
    implements _$CoalesceUpdatesCopyWith<T, $Res> {
  __$CoalesceUpdatesCopyWithImpl(this._self, this._then);

  final _CoalesceUpdates<T> _self;
  final $Res Function(_CoalesceUpdates<T>) _then;

/// Create a copy of CoalesceUpdates
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? duration = null,}) {
  return _then(_CoalesceUpdates<T>(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc
mixin _$DebounceUpdates<T> {

 Duration get duration;
/// Create a copy of DebounceUpdates
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebounceUpdatesCopyWith<T, DebounceUpdates<T>> get copyWith => _$DebounceUpdatesCopyWithImpl<T, DebounceUpdates<T>>(this as DebounceUpdates<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DebounceUpdates<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebounceUpdates<T>&&(identical(other.duration, _this.duration) || other.duration == _this.duration));
}


@override
int get hashCode {
  final _this = this as DebounceUpdates<T>;
  return Object.hash(runtimeType,_this.duration);
}

@override
String toString() {
  final _this = this as DebounceUpdates<T>;
  return 'DebounceUpdates<$T>(duration: ${_this.duration})';
}


}

/// @nodoc
abstract mixin class $DebounceUpdatesCopyWith<T,$Res>  {
  factory $DebounceUpdatesCopyWith(DebounceUpdates<T> value, $Res Function(DebounceUpdates<T>) _then) = _$DebounceUpdatesCopyWithImpl;
@useResult
$Res call({
 Duration duration
});




}
/// @nodoc
class _$DebounceUpdatesCopyWithImpl<T,$Res>
    implements $DebounceUpdatesCopyWith<T, $Res> {
  _$DebounceUpdatesCopyWithImpl(this._self, this._then);

  final DebounceUpdates<T> _self;
  final $Res Function(DebounceUpdates<T>) _then;

/// Create a copy of DebounceUpdates
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duration = null,}) {
  return _then(DebounceUpdates(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [DebounceUpdates].
extension DebounceUpdatesPatterns<T> on DebounceUpdates<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebounceUpdates<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebounceUpdates() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebounceUpdates<T> value)  $default,){
final _that = this;
switch (_that) {
case _DebounceUpdates():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebounceUpdates<T> value)?  $default,){
final _that = this;
switch (_that) {
case _DebounceUpdates() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebounceUpdates() when $default != null:
return $default(_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration duration)  $default,) {final _that = this;
switch (_that) {
case _DebounceUpdates():
return $default(_that.duration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration duration)?  $default,) {final _that = this;
switch (_that) {
case _DebounceUpdates() when $default != null:
return $default(_that.duration);case _:
  return null;

}
}

}

/// @nodoc


class _DebounceUpdates<T> extends DebounceUpdates<T> {
  const _DebounceUpdates({this.duration = const Duration(milliseconds: 100)}): super._();
  

@override@JsonKey() final  Duration duration;

/// Create a copy of DebounceUpdates
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebounceUpdatesCopyWith<T, _DebounceUpdates<T>> get copyWith => __$DebounceUpdatesCopyWithImpl<T, _DebounceUpdates<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebounceUpdates<T>&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode {
    return Object.hash(runtimeType,duration);
}

@override
String toString() {
    return 'DebounceUpdates<$T>(duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$DebounceUpdatesCopyWith<T,$Res> implements $DebounceUpdatesCopyWith<T, $Res> {
  factory _$DebounceUpdatesCopyWith(_DebounceUpdates<T> value, $Res Function(_DebounceUpdates<T>) _then) = __$DebounceUpdatesCopyWithImpl;
@override @useResult
$Res call({
 Duration duration
});




}
/// @nodoc
class __$DebounceUpdatesCopyWithImpl<T,$Res>
    implements _$DebounceUpdatesCopyWith<T, $Res> {
  __$DebounceUpdatesCopyWithImpl(this._self, this._then);

  final _DebounceUpdates<T> _self;
  final $Res Function(_DebounceUpdates<T>) _then;

/// Create a copy of DebounceUpdates
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? duration = null,}) {
  return _then(_DebounceUpdates<T>(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
