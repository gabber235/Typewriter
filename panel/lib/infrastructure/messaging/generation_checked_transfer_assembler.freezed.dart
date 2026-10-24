// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'generation_checked_transfer_assembler.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GenerationCheckedTransferState<T> {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GenerationCheckedTransferState<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'GenerationCheckedTransferState<$T>()';
}


}

/// @nodoc
class $GenerationCheckedTransferStateCopyWith<T,$Res>  {
$GenerationCheckedTransferStateCopyWith(GenerationCheckedTransferState<T> _, $Res Function(GenerationCheckedTransferState<T>) __);
}


/// Adds pattern-matching-related methods to [GenerationCheckedTransferState].
extension GenerationCheckedTransferStatePatterns<T> on GenerationCheckedTransferState<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GenerationCheckedTransferPending<T> value)?  pending,TResult Function( GenerationCheckedTransferComplete<T> value)?  complete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GenerationCheckedTransferPending() when pending != null:
return pending(_that);case GenerationCheckedTransferComplete() when complete != null:
return complete(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GenerationCheckedTransferPending<T> value)  pending,required TResult Function( GenerationCheckedTransferComplete<T> value)  complete,}){
final _that = this;
switch (_that) {
case GenerationCheckedTransferPending():
return pending(_that);case GenerationCheckedTransferComplete():
return complete(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GenerationCheckedTransferPending<T> value)?  pending,TResult? Function( GenerationCheckedTransferComplete<T> value)?  complete,}){
final _that = this;
switch (_that) {
case GenerationCheckedTransferPending() when pending != null:
return pending(_that);case GenerationCheckedTransferComplete() when complete != null:
return complete(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  pending,TResult Function( T value)?  complete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GenerationCheckedTransferPending() when pending != null:
return pending();case GenerationCheckedTransferComplete() when complete != null:
return complete(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  pending,required TResult Function( T value)  complete,}) {final _that = this;
switch (_that) {
case GenerationCheckedTransferPending():
return pending();case GenerationCheckedTransferComplete():
return complete(_that.value);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  pending,TResult? Function( T value)?  complete,}) {final _that = this;
switch (_that) {
case GenerationCheckedTransferPending() when pending != null:
return pending();case GenerationCheckedTransferComplete() when complete != null:
return complete(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class GenerationCheckedTransferPending<T> implements GenerationCheckedTransferState<T> {
  const GenerationCheckedTransferPending();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GenerationCheckedTransferPending<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'GenerationCheckedTransferState<$T>.pending()';
}


}




/// @nodoc


class GenerationCheckedTransferComplete<T> implements GenerationCheckedTransferState<T> {
  const GenerationCheckedTransferComplete(this.value);
  

 final  T value;

/// Create a copy of GenerationCheckedTransferState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenerationCheckedTransferCompleteCopyWith<T, GenerationCheckedTransferComplete<T>> get copyWith => _$GenerationCheckedTransferCompleteCopyWithImpl<T, GenerationCheckedTransferComplete<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GenerationCheckedTransferComplete<T>&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(value));
}

@override
String toString() {
    return 'GenerationCheckedTransferState<$T>.complete(value: $value)';
}


}

/// @nodoc
abstract mixin class $GenerationCheckedTransferCompleteCopyWith<T,$Res> implements $GenerationCheckedTransferStateCopyWith<T, $Res> {
  factory $GenerationCheckedTransferCompleteCopyWith(GenerationCheckedTransferComplete<T> value, $Res Function(GenerationCheckedTransferComplete<T>) _then) = _$GenerationCheckedTransferCompleteCopyWithImpl;
@useResult
$Res call({
 T value
});




}
/// @nodoc
class _$GenerationCheckedTransferCompleteCopyWithImpl<T,$Res>
    implements $GenerationCheckedTransferCompleteCopyWith<T, $Res> {
  _$GenerationCheckedTransferCompleteCopyWithImpl(this._self, this._then);

  final GenerationCheckedTransferComplete<T> _self;
  final $Res Function(GenerationCheckedTransferComplete<T>) _then;

/// Create a copy of GenerationCheckedTransferState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(GenerationCheckedTransferComplete<T>(
freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

// dart format on
