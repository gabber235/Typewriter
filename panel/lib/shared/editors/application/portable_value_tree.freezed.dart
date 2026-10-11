// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_value_tree.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortablePathResult<T> {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePathResult<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortablePathResult<$T>()';
}


}

/// @nodoc
class $PortablePathResultCopyWith<T,$Res>  {
$PortablePathResultCopyWith(PortablePathResult<T> _, $Res Function(PortablePathResult<T>) __);
}


/// Adds pattern matching related methods to [PortablePathResult].
extension PortablePathResultPatterns<T> on PortablePathResult<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortablePathValue<T> value)?  value,TResult Function( PortablePathUnavailable<T> value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortablePathValue() when value != null:
return value(_that);case PortablePathUnavailable() when unavailable != null:
return unavailable(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortablePathValue<T> value)  value,required TResult Function( PortablePathUnavailable<T> value)  unavailable,}){
final _that = this;
switch (_that) {
case PortablePathValue():
return value(_that);case PortablePathUnavailable():
return unavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortablePathValue<T> value)?  value,TResult? Function( PortablePathUnavailable<T> value)?  unavailable,}){
final _that = this;
switch (_that) {
case PortablePathValue() when value != null:
return value(_that);case PortablePathUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( T value)?  value,TResult Function( String message)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortablePathValue() when value != null:
return value(_that.value);case PortablePathUnavailable() when unavailable != null:
return unavailable(_that.message);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( T value)  value,required TResult Function( String message)  unavailable,}) {final _that = this;
switch (_that) {
case PortablePathValue():
return value(_that.value);case PortablePathUnavailable():
return unavailable(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( T value)?  value,TResult? Function( String message)?  unavailable,}) {final _that = this;
switch (_that) {
case PortablePathValue() when value != null:
return value(_that.value);case PortablePathUnavailable() when unavailable != null:
return unavailable(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class PortablePathValue<T> implements PortablePathResult<T> {
  const PortablePathValue(this.value);


 final  T value;

/// Create a copy of PortablePathResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePathValueCopyWith<T, PortablePathValue<T>> get copyWith => _$PortablePathValueCopyWithImpl<T, PortablePathValue<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePathValue<T>&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(value));
}

@override
String toString() {
    return 'PortablePathResult<$T>.value(value: $value)';
}


}

/// @nodoc
abstract mixin class $PortablePathValueCopyWith<T,$Res> implements $PortablePathResultCopyWith<T, $Res> {
  factory $PortablePathValueCopyWith(PortablePathValue<T> value, $Res Function(PortablePathValue<T>) _then) = _$PortablePathValueCopyWithImpl;
@useResult
$Res call({
 T value
});




}
/// @nodoc
class _$PortablePathValueCopyWithImpl<T,$Res>
    implements $PortablePathValueCopyWith<T, $Res> {
  _$PortablePathValueCopyWithImpl(this._self, this._then);

  final PortablePathValue<T> _self;
  final $Res Function(PortablePathValue<T>) _then;

/// Create a copy of PortablePathResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(PortablePathValue<T>(
freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class PortablePathUnavailable<T> implements PortablePathResult<T> {
  const PortablePathUnavailable(this.message);


 final  String message;

/// Create a copy of PortablePathResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePathUnavailableCopyWith<T, PortablePathUnavailable<T>> get copyWith => _$PortablePathUnavailableCopyWithImpl<T, PortablePathUnavailable<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePathUnavailable<T>&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'PortablePathResult<$T>.unavailable(message: $message)';
}


}

/// @nodoc
abstract mixin class $PortablePathUnavailableCopyWith<T,$Res> implements $PortablePathResultCopyWith<T, $Res> {
  factory $PortablePathUnavailableCopyWith(PortablePathUnavailable<T> value, $Res Function(PortablePathUnavailable<T>) _then) = _$PortablePathUnavailableCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PortablePathUnavailableCopyWithImpl<T,$Res>
    implements $PortablePathUnavailableCopyWith<T, $Res> {
  _$PortablePathUnavailableCopyWithImpl(this._self, this._then);

  final PortablePathUnavailable<T> _self;
  final $Res Function(PortablePathUnavailable<T>) _then;

/// Create a copy of PortablePathResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PortablePathUnavailable<T>(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
