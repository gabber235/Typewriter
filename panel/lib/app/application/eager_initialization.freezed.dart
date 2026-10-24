// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'eager_initialization.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StartupDependency<T> {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartupDependency<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return '_StartupDependency<$T>()';
}


}

/// @nodoc
class _$StartupDependencyCopyWith<T,$Res>  {
_$StartupDependencyCopyWith(_StartupDependency<T> _, $Res Function(_StartupDependency<T>) __);
}


/// Adds pattern-matching-related methods to [_StartupDependency].
extension _StartupDependencyPatterns<T> on _StartupDependency<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ReadyDependency<T> value)?  ready,TResult Function( _BlockedDependency<T> value)?  blocked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadyDependency() when ready != null:
return ready(_that);case _BlockedDependency() when blocked != null:
return blocked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ReadyDependency<T> value)  ready,required TResult Function( _BlockedDependency<T> value)  blocked,}){
final _that = this;
switch (_that) {
case _ReadyDependency():
return ready(_that);case _BlockedDependency():
return blocked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ReadyDependency<T> value)?  ready,TResult? Function( _BlockedDependency<T> value)?  blocked,}){
final _that = this;
switch (_that) {
case _ReadyDependency() when ready != null:
return ready(_that);case _BlockedDependency() when blocked != null:
return blocked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( T? value)?  ready,TResult Function( Widget boundary)?  blocked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadyDependency() when ready != null:
return ready(_that.value);case _BlockedDependency() when blocked != null:
return blocked(_that.boundary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( T? value)  ready,required TResult Function( Widget boundary)  blocked,}) {final _that = this;
switch (_that) {
case _ReadyDependency():
return ready(_that.value);case _BlockedDependency():
return blocked(_that.boundary);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( T? value)?  ready,TResult? Function( Widget boundary)?  blocked,}) {final _that = this;
switch (_that) {
case _ReadyDependency() when ready != null:
return ready(_that.value);case _BlockedDependency() when blocked != null:
return blocked(_that.boundary);case _:
  return null;

}
}

}

/// @nodoc


class _ReadyDependency<T> implements _StartupDependency<T> {
  const _ReadyDependency(this.value);
  

 final  T? value;

/// Create a copy of _StartupDependency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadyDependencyCopyWith<T, _ReadyDependency<T>> get copyWith => __$ReadyDependencyCopyWithImpl<T, _ReadyDependency<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadyDependency<T>&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(value));
}

@override
String toString() {
    return '_StartupDependency<$T>.ready(value: $value)';
}


}

/// @nodoc
abstract mixin class _$ReadyDependencyCopyWith<T,$Res> implements _$StartupDependencyCopyWith<T, $Res> {
  factory _$ReadyDependencyCopyWith(_ReadyDependency<T> value, $Res Function(_ReadyDependency<T>) _then) = __$ReadyDependencyCopyWithImpl;
@useResult
$Res call({
 T? value
});




}
/// @nodoc
class __$ReadyDependencyCopyWithImpl<T,$Res>
    implements _$ReadyDependencyCopyWith<T, $Res> {
  __$ReadyDependencyCopyWithImpl(this._self, this._then);

  final _ReadyDependency<T> _self;
  final $Res Function(_ReadyDependency<T>) _then;

/// Create a copy of _StartupDependency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(_ReadyDependency<T>(
freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T?,
  ));
}


}

/// @nodoc


class _BlockedDependency<T> implements _StartupDependency<T> {
  const _BlockedDependency(this.boundary);
  

 final  Widget boundary;

/// Create a copy of _StartupDependency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockedDependencyCopyWith<T, _BlockedDependency<T>> get copyWith => __$BlockedDependencyCopyWithImpl<T, _BlockedDependency<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockedDependency<T>&&(identical(other.boundary, boundary) || other.boundary == boundary));
}


@override
int get hashCode {
    return Object.hash(runtimeType,boundary);
}

@override
String toString() {
    return '_StartupDependency<$T>.blocked(boundary: $boundary)';
}


}

/// @nodoc
abstract mixin class _$BlockedDependencyCopyWith<T,$Res> implements _$StartupDependencyCopyWith<T, $Res> {
  factory _$BlockedDependencyCopyWith(_BlockedDependency<T> value, $Res Function(_BlockedDependency<T>) _then) = __$BlockedDependencyCopyWithImpl;
@useResult
$Res call({
 Widget boundary
});




}
/// @nodoc
class __$BlockedDependencyCopyWithImpl<T,$Res>
    implements _$BlockedDependencyCopyWith<T, $Res> {
  __$BlockedDependencyCopyWithImpl(this._self, this._then);

  final _BlockedDependency<T> _self;
  final $Res Function(_BlockedDependency<T>) _then;

/// Create a copy of _StartupDependency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? boundary = null,}) {
  return _then(_BlockedDependency<T>(
null == boundary ? _self.boundary : boundary // ignore: cast_nullable_to_non_nullable
as Widget,
  ));
}


}

// dart format on
