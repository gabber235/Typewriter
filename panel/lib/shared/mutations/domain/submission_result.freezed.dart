// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'submission_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubmissionResult<T> {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmissionResult<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SubmissionResult<$T>()';
}


}

/// @nodoc
class $SubmissionResultCopyWith<T,$Res>  {
$SubmissionResultCopyWith(SubmissionResult<T> _, $Res Function(SubmissionResult<T>) __);
}


/// Adds pattern-matching-related methods to [SubmissionResult].
extension SubmissionResultPatterns<T> on SubmissionResult<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SubmissionConfirmed<T> value)?  confirmed,TResult Function( SubmissionRejected<T> value)?  rejected,TResult Function( SubmissionNotSubmitted<T> value)?  notSubmitted,TResult Function( SubmissionUncertain<T> value)?  uncertain,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SubmissionConfirmed() when confirmed != null:
return confirmed(_that);case SubmissionRejected() when rejected != null:
return rejected(_that);case SubmissionNotSubmitted() when notSubmitted != null:
return notSubmitted(_that);case SubmissionUncertain() when uncertain != null:
return uncertain(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SubmissionConfirmed<T> value)  confirmed,required TResult Function( SubmissionRejected<T> value)  rejected,required TResult Function( SubmissionNotSubmitted<T> value)  notSubmitted,required TResult Function( SubmissionUncertain<T> value)  uncertain,}){
final _that = this;
switch (_that) {
case SubmissionConfirmed():
return confirmed(_that);case SubmissionRejected():
return rejected(_that);case SubmissionNotSubmitted():
return notSubmitted(_that);case SubmissionUncertain():
return uncertain(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SubmissionConfirmed<T> value)?  confirmed,TResult? Function( SubmissionRejected<T> value)?  rejected,TResult? Function( SubmissionNotSubmitted<T> value)?  notSubmitted,TResult? Function( SubmissionUncertain<T> value)?  uncertain,}){
final _that = this;
switch (_that) {
case SubmissionConfirmed() when confirmed != null:
return confirmed(_that);case SubmissionRejected() when rejected != null:
return rejected(_that);case SubmissionNotSubmitted() when notSubmitted != null:
return notSubmitted(_that);case SubmissionUncertain() when uncertain != null:
return uncertain(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( T value)?  confirmed,TResult Function( String message,  Object? cause,  T? response)?  rejected,TResult Function( String message,  Object? cause)?  notSubmitted,TResult Function( String message,  Object cause,  StackTrace stackTrace)?  uncertain,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SubmissionConfirmed() when confirmed != null:
return confirmed(_that.value);case SubmissionRejected() when rejected != null:
return rejected(_that.message,_that.cause,_that.response);case SubmissionNotSubmitted() when notSubmitted != null:
return notSubmitted(_that.message,_that.cause);case SubmissionUncertain() when uncertain != null:
return uncertain(_that.message,_that.cause,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( T value)  confirmed,required TResult Function( String message,  Object? cause,  T? response)  rejected,required TResult Function( String message,  Object? cause)  notSubmitted,required TResult Function( String message,  Object cause,  StackTrace stackTrace)  uncertain,}) {final _that = this;
switch (_that) {
case SubmissionConfirmed():
return confirmed(_that.value);case SubmissionRejected():
return rejected(_that.message,_that.cause,_that.response);case SubmissionNotSubmitted():
return notSubmitted(_that.message,_that.cause);case SubmissionUncertain():
return uncertain(_that.message,_that.cause,_that.stackTrace);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( T value)?  confirmed,TResult? Function( String message,  Object? cause,  T? response)?  rejected,TResult? Function( String message,  Object? cause)?  notSubmitted,TResult? Function( String message,  Object cause,  StackTrace stackTrace)?  uncertain,}) {final _that = this;
switch (_that) {
case SubmissionConfirmed() when confirmed != null:
return confirmed(_that.value);case SubmissionRejected() when rejected != null:
return rejected(_that.message,_that.cause,_that.response);case SubmissionNotSubmitted() when notSubmitted != null:
return notSubmitted(_that.message,_that.cause);case SubmissionUncertain() when uncertain != null:
return uncertain(_that.message,_that.cause,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class SubmissionConfirmed<T> implements SubmissionResult<T> {
  const SubmissionConfirmed(this.value);
  

 final  T value;

/// Create a copy of SubmissionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmissionConfirmedCopyWith<T, SubmissionConfirmed<T>> get copyWith => _$SubmissionConfirmedCopyWithImpl<T, SubmissionConfirmed<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmissionConfirmed<T>&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(value));
}

@override
String toString() {
    return 'SubmissionResult<$T>.confirmed(value: $value)';
}


}

/// @nodoc
abstract mixin class $SubmissionConfirmedCopyWith<T,$Res> implements $SubmissionResultCopyWith<T, $Res> {
  factory $SubmissionConfirmedCopyWith(SubmissionConfirmed<T> value, $Res Function(SubmissionConfirmed<T>) _then) = _$SubmissionConfirmedCopyWithImpl;
@useResult
$Res call({
 T value
});




}
/// @nodoc
class _$SubmissionConfirmedCopyWithImpl<T,$Res>
    implements $SubmissionConfirmedCopyWith<T, $Res> {
  _$SubmissionConfirmedCopyWithImpl(this._self, this._then);

  final SubmissionConfirmed<T> _self;
  final $Res Function(SubmissionConfirmed<T>) _then;

/// Create a copy of SubmissionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(SubmissionConfirmed<T>(
freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class SubmissionRejected<T> implements SubmissionResult<T> {
  const SubmissionRejected({required this.message, this.cause, this.response});
  

 final  String message;
 final  Object? cause;
 final  T? response;

/// Create a copy of SubmissionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmissionRejectedCopyWith<T, SubmissionRejected<T>> get copyWith => _$SubmissionRejectedCopyWithImpl<T, SubmissionRejected<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmissionRejected<T>&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause)&&const DeepCollectionEquality().equals(other.response, response));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause),const DeepCollectionEquality().hash(response));
}

@override
String toString() {
    return 'SubmissionResult<$T>.rejected(message: $message, cause: $cause, response: $response)';
}


}

/// @nodoc
abstract mixin class $SubmissionRejectedCopyWith<T,$Res> implements $SubmissionResultCopyWith<T, $Res> {
  factory $SubmissionRejectedCopyWith(SubmissionRejected<T> value, $Res Function(SubmissionRejected<T>) _then) = _$SubmissionRejectedCopyWithImpl;
@useResult
$Res call({
 String message, Object? cause, T? response
});




}
/// @nodoc
class _$SubmissionRejectedCopyWithImpl<T,$Res>
    implements $SubmissionRejectedCopyWith<T, $Res> {
  _$SubmissionRejectedCopyWithImpl(this._self, this._then);

  final SubmissionRejected<T> _self;
  final $Res Function(SubmissionRejected<T>) _then;

/// Create a copy of SubmissionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = freezed,Object? response = freezed,}) {
  return _then(SubmissionRejected<T>(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,cause: freezed == cause ? _self.cause : cause ,response: freezed == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as T?,
  ));
}


}

/// @nodoc


class SubmissionNotSubmitted<T> implements SubmissionResult<T> {
  const SubmissionNotSubmitted({required this.message, this.cause});
  

 final  String message;
 final  Object? cause;

/// Create a copy of SubmissionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmissionNotSubmittedCopyWith<T, SubmissionNotSubmitted<T>> get copyWith => _$SubmissionNotSubmittedCopyWithImpl<T, SubmissionNotSubmitted<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmissionNotSubmitted<T>&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'SubmissionResult<$T>.notSubmitted(message: $message, cause: $cause)';
}


}

/// @nodoc
abstract mixin class $SubmissionNotSubmittedCopyWith<T,$Res> implements $SubmissionResultCopyWith<T, $Res> {
  factory $SubmissionNotSubmittedCopyWith(SubmissionNotSubmitted<T> value, $Res Function(SubmissionNotSubmitted<T>) _then) = _$SubmissionNotSubmittedCopyWithImpl;
@useResult
$Res call({
 String message, Object? cause
});




}
/// @nodoc
class _$SubmissionNotSubmittedCopyWithImpl<T,$Res>
    implements $SubmissionNotSubmittedCopyWith<T, $Res> {
  _$SubmissionNotSubmittedCopyWithImpl(this._self, this._then);

  final SubmissionNotSubmitted<T> _self;
  final $Res Function(SubmissionNotSubmitted<T>) _then;

/// Create a copy of SubmissionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = freezed,}) {
  return _then(SubmissionNotSubmitted<T>(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,cause: freezed == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc


class SubmissionUncertain<T> implements SubmissionResult<T> {
  const SubmissionUncertain({required this.message, required this.cause, required this.stackTrace});
  

 final  String message;
 final  Object cause;
 final  StackTrace stackTrace;

/// Create a copy of SubmissionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmissionUncertainCopyWith<T, SubmissionUncertain<T>> get copyWith => _$SubmissionUncertainCopyWithImpl<T, SubmissionUncertain<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmissionUncertain<T>&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause),stackTrace);
}

@override
String toString() {
    return 'SubmissionResult<$T>.uncertain(message: $message, cause: $cause, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $SubmissionUncertainCopyWith<T,$Res> implements $SubmissionResultCopyWith<T, $Res> {
  factory $SubmissionUncertainCopyWith(SubmissionUncertain<T> value, $Res Function(SubmissionUncertain<T>) _then) = _$SubmissionUncertainCopyWithImpl;
@useResult
$Res call({
 String message, Object cause, StackTrace stackTrace
});




}
/// @nodoc
class _$SubmissionUncertainCopyWithImpl<T,$Res>
    implements $SubmissionUncertainCopyWith<T, $Res> {
  _$SubmissionUncertainCopyWithImpl(this._self, this._then);

  final SubmissionUncertain<T> _self;
  final $Res Function(SubmissionUncertain<T>) _then;

/// Create a copy of SubmissionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = null,Object? stackTrace = null,}) {
  return _then(SubmissionUncertain<T>(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,cause: null == cause ? _self.cause : cause ,stackTrace: null == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
