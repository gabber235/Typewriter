// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringSessionAccess implements DiagnosticableTreeMixin {

 AuthoringSession get notifier; AuthoringSessionState get state;
/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSessionAccessCopyWith<AuthoringSessionAccess> get copyWith => _$AuthoringSessionAccessCopyWithImpl<AuthoringSessionAccess>(this as AuthoringSessionAccess, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as AuthoringSessionAccess;
  properties
    ..add(DiagnosticsProperty('type', 'AuthoringSessionAccess'))
    ..add(DiagnosticsProperty('notifier', _this.notifier))..add(DiagnosticsProperty('state', _this.state));
}

@override
bool operator ==(Object other) {
  final _this = this as AuthoringSessionAccess;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSessionAccess&&(identical(other.notifier, _this.notifier) || other.notifier == _this.notifier)&&(identical(other.state, _this.state) || other.state == _this.state));
}


@override
int get hashCode {
  final _this = this as AuthoringSessionAccess;
  return Object.hash(runtimeType,_this.notifier,_this.state);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as AuthoringSessionAccess;
  return 'AuthoringSessionAccess(notifier: ${_this.notifier}, state: ${_this.state})';
}


}

/// @nodoc
abstract mixin class $AuthoringSessionAccessCopyWith<$Res>  {
  factory $AuthoringSessionAccessCopyWith(AuthoringSessionAccess value, $Res Function(AuthoringSessionAccess) _then) = _$AuthoringSessionAccessCopyWithImpl;
@useResult
$Res call({
 AuthoringSession notifier, AuthoringSessionState state
});


$AuthoringSessionStateCopyWith<$Res> get state;

}
/// @nodoc
class _$AuthoringSessionAccessCopyWithImpl<$Res>
    implements $AuthoringSessionAccessCopyWith<$Res> {
  _$AuthoringSessionAccessCopyWithImpl(this._self, this._then);

  final AuthoringSessionAccess _self;
  final $Res Function(AuthoringSessionAccess) _then;

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notifier = null,Object? state = null,}) {
  return _then(AuthoringSessionAccess(
notifier: null == notifier ? _self.notifier : notifier // ignore: cast_nullable_to_non_nullable
as AuthoringSession,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AuthoringSessionState,
  ));
}
/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<$Res> get state {
  
  return $AuthoringSessionStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoringSessionAccess].
extension AuthoringSessionAccessPatterns on AuthoringSessionAccess {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringSessionAccess value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringSessionAccess value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionAccess():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringSessionAccess value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringSession notifier,  AuthoringSessionState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
return $default(_that.notifier,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringSession notifier,  AuthoringSessionState state)  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionAccess():
return $default(_that.notifier,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringSession notifier,  AuthoringSessionState state)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
return $default(_that.notifier,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSessionAccess with DiagnosticableTreeMixin implements AuthoringSessionAccess {
  const _AuthoringSessionAccess({required this.notifier, required this.state});
  

@override final  AuthoringSession notifier;
@override final  AuthoringSessionState state;

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSessionAccessCopyWith<_AuthoringSessionAccess> get copyWith => __$AuthoringSessionAccessCopyWithImpl<_AuthoringSessionAccess>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'AuthoringSessionAccess'))
    ..add(DiagnosticsProperty('notifier', notifier))..add(DiagnosticsProperty('state', state));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSessionAccess&&(identical(other.notifier, notifier) || other.notifier == notifier)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode {
    return Object.hash(runtimeType,notifier,state);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'AuthoringSessionAccess(notifier: $notifier, state: $state)';
}


}

/// @nodoc
abstract mixin class _$AuthoringSessionAccessCopyWith<$Res> implements $AuthoringSessionAccessCopyWith<$Res> {
  factory _$AuthoringSessionAccessCopyWith(_AuthoringSessionAccess value, $Res Function(_AuthoringSessionAccess) _then) = __$AuthoringSessionAccessCopyWithImpl;
@override @useResult
$Res call({
 AuthoringSession notifier, AuthoringSessionState state
});


@override $AuthoringSessionStateCopyWith<$Res> get state;

}
/// @nodoc
class __$AuthoringSessionAccessCopyWithImpl<$Res>
    implements _$AuthoringSessionAccessCopyWith<$Res> {
  __$AuthoringSessionAccessCopyWithImpl(this._self, this._then);

  final _AuthoringSessionAccess _self;
  final $Res Function(_AuthoringSessionAccess) _then;

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notifier = null,Object? state = null,}) {
  return _then(_AuthoringSessionAccess(
notifier: null == notifier ? _self.notifier : notifier // ignore: cast_nullable_to_non_nullable
as AuthoringSession,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AuthoringSessionState,
  ));
}

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<$Res> get state {
  
  return $AuthoringSessionStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}

/// @nodoc
mixin _$AuthoringSessionState implements DiagnosticableTreeMixin {

 skir.AuthoringState? get snapshot; CheckedEditorCatalog? get catalog; bool get refreshing; Object? get failure;
/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<AuthoringSessionState> get copyWith => _$AuthoringSessionStateCopyWithImpl<AuthoringSessionState>(this as AuthoringSessionState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as AuthoringSessionState;
  properties
    ..add(DiagnosticsProperty('type', 'AuthoringSessionState'))
    ..add(DiagnosticsProperty('snapshot', _this.snapshot))..add(DiagnosticsProperty('catalog', _this.catalog))..add(DiagnosticsProperty('refreshing', _this.refreshing))..add(DiagnosticsProperty('failure', _this.failure));
}

@override
bool operator ==(Object other) {
  final _this = this as AuthoringSessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSessionState&&(identical(other.snapshot, _this.snapshot) || other.snapshot == _this.snapshot)&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.refreshing, _this.refreshing) || other.refreshing == _this.refreshing)&&const DeepCollectionEquality().equals(other.failure, _this.failure));
}


@override
int get hashCode {
  final _this = this as AuthoringSessionState;
  return Object.hash(runtimeType,_this.snapshot,_this.catalog,_this.refreshing,const DeepCollectionEquality().hash(_this.failure));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as AuthoringSessionState;
  return 'AuthoringSessionState(snapshot: ${_this.snapshot}, catalog: ${_this.catalog}, refreshing: ${_this.refreshing}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $AuthoringSessionStateCopyWith<$Res>  {
  factory $AuthoringSessionStateCopyWith(AuthoringSessionState value, $Res Function(AuthoringSessionState) _then) = _$AuthoringSessionStateCopyWithImpl;
@useResult
$Res call({
 skir.AuthoringState? snapshot, CheckedEditorCatalog? catalog, bool refreshing, Object? failure
});




}
/// @nodoc
class _$AuthoringSessionStateCopyWithImpl<$Res>
    implements $AuthoringSessionStateCopyWith<$Res> {
  _$AuthoringSessionStateCopyWithImpl(this._self, this._then);

  final AuthoringSessionState _self;
  final $Res Function(AuthoringSessionState) _then;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? snapshot = freezed,Object? catalog = freezed,Object? refreshing = null,Object? failure = freezed,}) {
  return _then(AuthoringSessionState(
snapshot: freezed == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as skir.AuthoringState?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure ,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringSessionState].
extension AuthoringSessionStatePatterns on AuthoringSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringSessionState value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.AuthoringState? snapshot,  CheckedEditorCatalog? catalog,  bool refreshing,  Object? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
return $default(_that.snapshot,_that.catalog,_that.refreshing,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.AuthoringState? snapshot,  CheckedEditorCatalog? catalog,  bool refreshing,  Object? failure)  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionState():
return $default(_that.snapshot,_that.catalog,_that.refreshing,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.AuthoringState? snapshot,  CheckedEditorCatalog? catalog,  bool refreshing,  Object? failure)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
return $default(_that.snapshot,_that.catalog,_that.refreshing,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSessionState with DiagnosticableTreeMixin implements AuthoringSessionState {
  const _AuthoringSessionState({this.snapshot, this.catalog, this.refreshing = false, this.failure});
  

@override final  skir.AuthoringState? snapshot;
@override final  CheckedEditorCatalog? catalog;
@override@JsonKey() final  bool refreshing;
@override final  Object? failure;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSessionStateCopyWith<_AuthoringSessionState> get copyWith => __$AuthoringSessionStateCopyWithImpl<_AuthoringSessionState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'AuthoringSessionState'))
    ..add(DiagnosticsProperty('snapshot', snapshot))..add(DiagnosticsProperty('catalog', catalog))..add(DiagnosticsProperty('refreshing', refreshing))..add(DiagnosticsProperty('failure', failure));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSessionState&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&const DeepCollectionEquality().equals(other.failure, failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,snapshot,catalog,refreshing,const DeepCollectionEquality().hash(failure));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'AuthoringSessionState(snapshot: $snapshot, catalog: $catalog, refreshing: $refreshing, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$AuthoringSessionStateCopyWith<$Res> implements $AuthoringSessionStateCopyWith<$Res> {
  factory _$AuthoringSessionStateCopyWith(_AuthoringSessionState value, $Res Function(_AuthoringSessionState) _then) = __$AuthoringSessionStateCopyWithImpl;
@override @useResult
$Res call({
 skir.AuthoringState? snapshot, CheckedEditorCatalog? catalog, bool refreshing, Object? failure
});




}
/// @nodoc
class __$AuthoringSessionStateCopyWithImpl<$Res>
    implements _$AuthoringSessionStateCopyWith<$Res> {
  __$AuthoringSessionStateCopyWithImpl(this._self, this._then);

  final _AuthoringSessionState _self;
  final $Res Function(_AuthoringSessionState) _then;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? snapshot = freezed,Object? catalog = freezed,Object? refreshing = null,Object? failure = freezed,}) {
  return _then(_AuthoringSessionState(
snapshot: freezed == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as skir.AuthoringState?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure ,
  ));
}


}

// dart format on
