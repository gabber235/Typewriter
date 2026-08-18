// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secret_field_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SecretFieldState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretFieldState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SecretFieldState()';
}


}

/// @nodoc
class $SecretFieldStateCopyWith<$Res>  {
$SecretFieldStateCopyWith(SecretFieldState _, $Res Function(SecretFieldState) __);
}


/// Adds pattern-matching-related methods to [SecretFieldState].
extension SecretFieldStatePatterns on SecretFieldState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SecretFieldIdle value)?  idle,TResult Function( SecretFieldLoading value)?  loading,TResult Function( SecretFieldRevealed value)?  revealed,TResult Function( SecretFieldExpired value)?  expired,TResult Function( SecretFieldError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SecretFieldIdle() when idle != null:
return idle(_that);case SecretFieldLoading() when loading != null:
return loading(_that);case SecretFieldRevealed() when revealed != null:
return revealed(_that);case SecretFieldExpired() when expired != null:
return expired(_that);case SecretFieldError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SecretFieldIdle value)  idle,required TResult Function( SecretFieldLoading value)  loading,required TResult Function( SecretFieldRevealed value)  revealed,required TResult Function( SecretFieldExpired value)  expired,required TResult Function( SecretFieldError value)  error,}){
final _that = this;
switch (_that) {
case SecretFieldIdle():
return idle(_that);case SecretFieldLoading():
return loading(_that);case SecretFieldRevealed():
return revealed(_that);case SecretFieldExpired():
return expired(_that);case SecretFieldError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SecretFieldIdle value)?  idle,TResult? Function( SecretFieldLoading value)?  loading,TResult? Function( SecretFieldRevealed value)?  revealed,TResult? Function( SecretFieldExpired value)?  expired,TResult? Function( SecretFieldError value)?  error,}){
final _that = this;
switch (_that) {
case SecretFieldIdle() when idle != null:
return idle(_that);case SecretFieldLoading() when loading != null:
return loading(_that);case SecretFieldRevealed() when revealed != null:
return revealed(_that);case SecretFieldExpired() when expired != null:
return expired(_that);case SecretFieldError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  loading,TResult Function( String value,  DateTime? expiresAt)?  revealed,TResult Function( String value)?  expired,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SecretFieldIdle() when idle != null:
return idle();case SecretFieldLoading() when loading != null:
return loading();case SecretFieldRevealed() when revealed != null:
return revealed(_that.value,_that.expiresAt);case SecretFieldExpired() when expired != null:
return expired(_that.value);case SecretFieldError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  loading,required TResult Function( String value,  DateTime? expiresAt)  revealed,required TResult Function( String value)  expired,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case SecretFieldIdle():
return idle();case SecretFieldLoading():
return loading();case SecretFieldRevealed():
return revealed(_that.value,_that.expiresAt);case SecretFieldExpired():
return expired(_that.value);case SecretFieldError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  loading,TResult? Function( String value,  DateTime? expiresAt)?  revealed,TResult? Function( String value)?  expired,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case SecretFieldIdle() when idle != null:
return idle();case SecretFieldLoading() when loading != null:
return loading();case SecretFieldRevealed() when revealed != null:
return revealed(_that.value,_that.expiresAt);case SecretFieldExpired() when expired != null:
return expired(_that.value);case SecretFieldError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SecretFieldIdle implements SecretFieldState {
  const SecretFieldIdle();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretFieldIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SecretFieldState.idle()';
}


}




/// @nodoc


class SecretFieldLoading implements SecretFieldState {
  const SecretFieldLoading();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretFieldLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SecretFieldState.loading()';
}


}




/// @nodoc


class SecretFieldRevealed implements SecretFieldState {
  const SecretFieldRevealed({required this.value, this.expiresAt});


 final  String value;
 final  DateTime? expiresAt;

/// Create a copy of SecretFieldState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretFieldRevealedCopyWith<SecretFieldRevealed> get copyWith => _$SecretFieldRevealedCopyWithImpl<SecretFieldRevealed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretFieldRevealed&&(identical(other.value, value) || other.value == value)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,value,expiresAt);

@override
String toString() {
  return 'SecretFieldState.revealed(value: $value, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $SecretFieldRevealedCopyWith<$Res> implements $SecretFieldStateCopyWith<$Res> {
  factory $SecretFieldRevealedCopyWith(SecretFieldRevealed value, $Res Function(SecretFieldRevealed) _then) = _$SecretFieldRevealedCopyWithImpl;
@useResult
$Res call({
 String value, DateTime? expiresAt
});




}
/// @nodoc
class _$SecretFieldRevealedCopyWithImpl<$Res>
    implements $SecretFieldRevealedCopyWith<$Res> {
  _$SecretFieldRevealedCopyWithImpl(this._self, this._then);

  final SecretFieldRevealed _self;
  final $Res Function(SecretFieldRevealed) _then;

/// Create a copy of SecretFieldState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,Object? expiresAt = freezed,}) {
  return _then(SecretFieldRevealed(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class SecretFieldExpired implements SecretFieldState {
  const SecretFieldExpired({required this.value});


 final  String value;

/// Create a copy of SecretFieldState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretFieldExpiredCopyWith<SecretFieldExpired> get copyWith => _$SecretFieldExpiredCopyWithImpl<SecretFieldExpired>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretFieldExpired&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'SecretFieldState.expired(value: $value)';
}


}

/// @nodoc
abstract mixin class $SecretFieldExpiredCopyWith<$Res> implements $SecretFieldStateCopyWith<$Res> {
  factory $SecretFieldExpiredCopyWith(SecretFieldExpired value, $Res Function(SecretFieldExpired) _then) = _$SecretFieldExpiredCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$SecretFieldExpiredCopyWithImpl<$Res>
    implements $SecretFieldExpiredCopyWith<$Res> {
  _$SecretFieldExpiredCopyWithImpl(this._self, this._then);

  final SecretFieldExpired _self;
  final $Res Function(SecretFieldExpired) _then;

/// Create a copy of SecretFieldState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(SecretFieldExpired(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SecretFieldError implements SecretFieldState {
  const SecretFieldError({required this.message});


 final  String message;

/// Create a copy of SecretFieldState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretFieldErrorCopyWith<SecretFieldError> get copyWith => _$SecretFieldErrorCopyWithImpl<SecretFieldError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretFieldError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SecretFieldState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SecretFieldErrorCopyWith<$Res> implements $SecretFieldStateCopyWith<$Res> {
  factory $SecretFieldErrorCopyWith(SecretFieldError value, $Res Function(SecretFieldError) _then) = _$SecretFieldErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SecretFieldErrorCopyWithImpl<$Res>
    implements $SecretFieldErrorCopyWith<$Res> {
  _$SecretFieldErrorCopyWithImpl(this._self, this._then);

  final SecretFieldError _self;
  final $Res Function(SecretFieldError) _then;

/// Create a copy of SecretFieldState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SecretFieldError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
