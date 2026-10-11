// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nats_client.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NatsConnectionState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NatsConnectionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'NatsConnectionState()';
}


}

/// @nodoc
class $NatsConnectionStateCopyWith<$Res>  {
$NatsConnectionStateCopyWith(NatsConnectionState _, $Res Function(NatsConnectionState) __);
}


/// Adds pattern matching related methods to [NatsConnectionState].
extension NatsConnectionStatePatterns on NatsConnectionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NatsConnecting value)?  connecting,TResult Function( NatsConnected value)?  connected,TResult Function( NatsReconnecting value)?  reconnecting,TResult Function( NatsFailed value)?  failed,TResult Function( NatsClosed value)?  closed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NatsConnecting() when connecting != null:
return connecting(_that);case NatsConnected() when connected != null:
return connected(_that);case NatsReconnecting() when reconnecting != null:
return reconnecting(_that);case NatsFailed() when failed != null:
return failed(_that);case NatsClosed() when closed != null:
return closed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NatsConnecting value)  connecting,required TResult Function( NatsConnected value)  connected,required TResult Function( NatsReconnecting value)  reconnecting,required TResult Function( NatsFailed value)  failed,required TResult Function( NatsClosed value)  closed,}){
final _that = this;
switch (_that) {
case NatsConnecting():
return connecting(_that);case NatsConnected():
return connected(_that);case NatsReconnecting():
return reconnecting(_that);case NatsFailed():
return failed(_that);case NatsClosed():
return closed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NatsConnecting value)?  connecting,TResult? Function( NatsConnected value)?  connected,TResult? Function( NatsReconnecting value)?  reconnecting,TResult? Function( NatsFailed value)?  failed,TResult? Function( NatsClosed value)?  closed,}){
final _that = this;
switch (_that) {
case NatsConnecting() when connecting != null:
return connecting(_that);case NatsConnected() when connected != null:
return connected(_that);case NatsReconnecting() when reconnecting != null:
return reconnecting(_that);case NatsFailed() when failed != null:
return failed(_that);case NatsClosed() when closed != null:
return closed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  connecting,TResult Function()?  connected,TResult Function( NatsClientException failure)?  reconnecting,TResult Function( NatsClientException failure)?  failed,TResult Function()?  closed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NatsConnecting() when connecting != null:
return connecting();case NatsConnected() when connected != null:
return connected();case NatsReconnecting() when reconnecting != null:
return reconnecting(_that.failure);case NatsFailed() when failed != null:
return failed(_that.failure);case NatsClosed() when closed != null:
return closed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  connecting,required TResult Function()  connected,required TResult Function( NatsClientException failure)  reconnecting,required TResult Function( NatsClientException failure)  failed,required TResult Function()  closed,}) {final _that = this;
switch (_that) {
case NatsConnecting():
return connecting();case NatsConnected():
return connected();case NatsReconnecting():
return reconnecting(_that.failure);case NatsFailed():
return failed(_that.failure);case NatsClosed():
return closed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  connecting,TResult? Function()?  connected,TResult? Function( NatsClientException failure)?  reconnecting,TResult? Function( NatsClientException failure)?  failed,TResult? Function()?  closed,}) {final _that = this;
switch (_that) {
case NatsConnecting() when connecting != null:
return connecting();case NatsConnected() when connected != null:
return connected();case NatsReconnecting() when reconnecting != null:
return reconnecting(_that.failure);case NatsFailed() when failed != null:
return failed(_that.failure);case NatsClosed() when closed != null:
return closed();case _:
  return null;

}
}

}

/// @nodoc


class NatsConnecting implements NatsConnectionState {
  const NatsConnecting();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NatsConnecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'NatsConnectionState.connecting()';
}


}




/// @nodoc


class NatsConnected implements NatsConnectionState {
  const NatsConnected();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NatsConnected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'NatsConnectionState.connected()';
}


}




/// @nodoc


class NatsReconnecting implements NatsConnectionState {
  const NatsReconnecting(this.failure);


 final  NatsClientException failure;

/// Create a copy of NatsConnectionState
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NatsReconnectingCopyWith<NatsReconnecting> get copyWith => _$NatsReconnectingCopyWithImpl<NatsReconnecting>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NatsReconnecting&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure);
}

@override
String toString() {
    return 'NatsConnectionState.reconnecting(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NatsReconnectingCopyWith<$Res> implements $NatsConnectionStateCopyWith<$Res> {
  factory $NatsReconnectingCopyWith(NatsReconnecting value, $Res Function(NatsReconnecting) _then) = _$NatsReconnectingCopyWithImpl;
@useResult
$Res call({
 NatsClientException failure
});




}
/// @nodoc
class _$NatsReconnectingCopyWithImpl<$Res>
    implements $NatsReconnectingCopyWith<$Res> {
  _$NatsReconnectingCopyWithImpl(this._self, this._then);

  final NatsReconnecting _self;
  final $Res Function(NatsReconnecting) _then;

/// Create a copy of NatsConnectionState
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NatsReconnecting(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NatsClientException,
  ));
}


}

/// @nodoc


class NatsFailed implements NatsConnectionState {
  const NatsFailed(this.failure);


 final  NatsClientException failure;

/// Create a copy of NatsConnectionState
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NatsFailedCopyWith<NatsFailed> get copyWith => _$NatsFailedCopyWithImpl<NatsFailed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NatsFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure);
}

@override
String toString() {
    return 'NatsConnectionState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NatsFailedCopyWith<$Res> implements $NatsConnectionStateCopyWith<$Res> {
  factory $NatsFailedCopyWith(NatsFailed value, $Res Function(NatsFailed) _then) = _$NatsFailedCopyWithImpl;
@useResult
$Res call({
 NatsClientException failure
});




}
/// @nodoc
class _$NatsFailedCopyWithImpl<$Res>
    implements $NatsFailedCopyWith<$Res> {
  _$NatsFailedCopyWithImpl(this._self, this._then);

  final NatsFailed _self;
  final $Res Function(NatsFailed) _then;

/// Create a copy of NatsConnectionState
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NatsFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as NatsClientException,
  ));
}


}

/// @nodoc


class NatsClosed implements NatsConnectionState {
  const NatsClosed();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NatsClosed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'NatsConnectionState.closed()';
}


}




// dart format on
