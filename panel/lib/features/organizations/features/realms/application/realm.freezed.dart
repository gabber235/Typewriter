// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmInteractionState {

 RealmConnectionState get connectionState;
/// Create a copy of RealmInteractionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmInteractionStateCopyWith<RealmInteractionState> get copyWith => _$RealmInteractionStateCopyWithImpl<RealmInteractionState>(this as RealmInteractionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmInteractionState&&(identical(other.connectionState, connectionState) || other.connectionState == connectionState));
}


@override
int get hashCode => Object.hash(runtimeType,connectionState);

@override
String toString() {
  return 'RealmInteractionState(connectionState: $connectionState)';
}


}

/// @nodoc
abstract mixin class $RealmInteractionStateCopyWith<$Res>  {
  factory $RealmInteractionStateCopyWith(RealmInteractionState value, $Res Function(RealmInteractionState) _then) = _$RealmInteractionStateCopyWithImpl;
@useResult
$Res call({
 RealmConnectionState connectionState
});




}
/// @nodoc
class _$RealmInteractionStateCopyWithImpl<$Res>
    implements $RealmInteractionStateCopyWith<$Res> {
  _$RealmInteractionStateCopyWithImpl(this._self, this._then);

  final RealmInteractionState _self;
  final $Res Function(RealmInteractionState) _then;

/// Create a copy of RealmInteractionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectionState = null,}) {
  return _then(_self.copyWith(
connectionState: null == connectionState ? _self.connectionState : connectionState // ignore: cast_nullable_to_non_nullable
as RealmConnectionState,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmInteractionState].
extension RealmInteractionStatePatterns on RealmInteractionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmInteractionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmInteractionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmInteractionState value)  $default,){
final _that = this;
switch (_that) {
case _RealmInteractionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmInteractionState value)?  $default,){
final _that = this;
switch (_that) {
case _RealmInteractionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RealmConnectionState connectionState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmInteractionState() when $default != null:
return $default(_that.connectionState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RealmConnectionState connectionState)  $default,) {final _that = this;
switch (_that) {
case _RealmInteractionState():
return $default(_that.connectionState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RealmConnectionState connectionState)?  $default,) {final _that = this;
switch (_that) {
case _RealmInteractionState() when $default != null:
return $default(_that.connectionState);case _:
  return null;

}
}

}

/// @nodoc


class _RealmInteractionState extends RealmInteractionState {
  const _RealmInteractionState({required this.connectionState}): super._();
  

@override final  RealmConnectionState connectionState;

/// Create a copy of RealmInteractionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmInteractionStateCopyWith<_RealmInteractionState> get copyWith => __$RealmInteractionStateCopyWithImpl<_RealmInteractionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmInteractionState&&(identical(other.connectionState, connectionState) || other.connectionState == connectionState));
}


@override
int get hashCode => Object.hash(runtimeType,connectionState);

@override
String toString() {
  return 'RealmInteractionState(connectionState: $connectionState)';
}


}

/// @nodoc
abstract mixin class _$RealmInteractionStateCopyWith<$Res> implements $RealmInteractionStateCopyWith<$Res> {
  factory _$RealmInteractionStateCopyWith(_RealmInteractionState value, $Res Function(_RealmInteractionState) _then) = __$RealmInteractionStateCopyWithImpl;
@override @useResult
$Res call({
 RealmConnectionState connectionState
});




}
/// @nodoc
class __$RealmInteractionStateCopyWithImpl<$Res>
    implements _$RealmInteractionStateCopyWith<$Res> {
  __$RealmInteractionStateCopyWithImpl(this._self, this._then);

  final _RealmInteractionState _self;
  final $Res Function(_RealmInteractionState) _then;

/// Create a copy of RealmInteractionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectionState = null,}) {
  return _then(_RealmInteractionState(
connectionState: null == connectionState ? _self.connectionState : connectionState // ignore: cast_nullable_to_non_nullable
as RealmConnectionState,
  ));
}


}

// dart format on
