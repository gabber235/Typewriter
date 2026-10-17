// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bounded_transfer_assembler.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BoundedTransferState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BoundedTransferState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BoundedTransferState()';
}


}

/// @nodoc
class $BoundedTransferStateCopyWith<$Res>  {
$BoundedTransferStateCopyWith(BoundedTransferState _, $Res Function(BoundedTransferState) __);
}


/// Adds pattern matching related methods to [BoundedTransferState].
extension BoundedTransferStatePatterns on BoundedTransferState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BoundedTransferPending value)?  pending,TResult Function( BoundedTransferComplete value)?  complete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BoundedTransferPending() when pending != null:
return pending(_that);case BoundedTransferComplete() when complete != null:
return complete(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BoundedTransferPending value)  pending,required TResult Function( BoundedTransferComplete value)  complete,}){
final _that = this;
switch (_that) {
case BoundedTransferPending():
return pending(_that);case BoundedTransferComplete():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BoundedTransferPending value)?  pending,TResult? Function( BoundedTransferComplete value)?  complete,}){
final _that = this;
switch (_that) {
case BoundedTransferPending() when pending != null:
return pending(_that);case BoundedTransferComplete() when complete != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  pending,TResult Function( Uint8List bytes)?  complete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BoundedTransferPending() when pending != null:
return pending();case BoundedTransferComplete() when complete != null:
return complete(_that.bytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  pending,required TResult Function( Uint8List bytes)  complete,}) {final _that = this;
switch (_that) {
case BoundedTransferPending():
return pending();case BoundedTransferComplete():
return complete(_that.bytes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  pending,TResult? Function( Uint8List bytes)?  complete,}) {final _that = this;
switch (_that) {
case BoundedTransferPending() when pending != null:
return pending();case BoundedTransferComplete() when complete != null:
return complete(_that.bytes);case _:
  return null;

}
}

}

/// @nodoc


class BoundedTransferPending implements BoundedTransferState {
  const BoundedTransferPending();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BoundedTransferPending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BoundedTransferState.pending()';
}


}




/// @nodoc


class BoundedTransferComplete implements BoundedTransferState {
  const BoundedTransferComplete(this.bytes);


 final  Uint8List bytes;

/// Create a copy of BoundedTransferState
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoundedTransferCompleteCopyWith<BoundedTransferComplete> get copyWith => _$BoundedTransferCompleteCopyWithImpl<BoundedTransferComplete>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BoundedTransferComplete&&const DeepCollectionEquality().equals(other.bytes, bytes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(bytes));
}

@override
String toString() {
    return 'BoundedTransferState.complete(bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $BoundedTransferCompleteCopyWith<$Res> implements $BoundedTransferStateCopyWith<$Res> {
  factory $BoundedTransferCompleteCopyWith(BoundedTransferComplete value, $Res Function(BoundedTransferComplete) _then) = _$BoundedTransferCompleteCopyWithImpl;
@useResult
$Res call({
 Uint8List bytes
});




}
/// @nodoc
class _$BoundedTransferCompleteCopyWithImpl<$Res>
    implements $BoundedTransferCompleteCopyWith<$Res> {
  _$BoundedTransferCompleteCopyWithImpl(this._self, this._then);

  final BoundedTransferComplete _self;
  final $Res Function(BoundedTransferComplete) _then;

/// Create a copy of BoundedTransferState
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bytes = null,}) {
  return _then(BoundedTransferComplete(
null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

// dart format on
