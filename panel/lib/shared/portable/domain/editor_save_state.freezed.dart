// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_save_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorPathConflict {

 skir.DataValue get base; skir.DataValue get local; skir.DataValue get remote;
/// Create a copy of EditorPathConflict
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorPathConflictCopyWith<EditorPathConflict> get copyWith => _$EditorPathConflictCopyWithImpl<EditorPathConflict>(this as EditorPathConflict, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorPathConflict;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorPathConflict&&(identical(other.base, _this.base) || other.base == _this.base)&&(identical(other.local, _this.local) || other.local == _this.local)&&(identical(other.remote, _this.remote) || other.remote == _this.remote));
}


@override
int get hashCode {
  final _this = this as EditorPathConflict;
  return Object.hash(runtimeType,_this.base,_this.local,_this.remote);
}

@override
String toString() {
  final _this = this as EditorPathConflict;
  return 'EditorPathConflict(base: ${_this.base}, local: ${_this.local}, remote: ${_this.remote})';
}


}

/// @nodoc
abstract mixin class $EditorPathConflictCopyWith<$Res>  {
  factory $EditorPathConflictCopyWith(EditorPathConflict value, $Res Function(EditorPathConflict) _then) = _$EditorPathConflictCopyWithImpl;
@useResult
$Res call({
 skir.DataValue base, skir.DataValue local, skir.DataValue remote
});




}
/// @nodoc
class _$EditorPathConflictCopyWithImpl<$Res>
    implements $EditorPathConflictCopyWith<$Res> {
  _$EditorPathConflictCopyWithImpl(this._self, this._then);

  final EditorPathConflict _self;
  final $Res Function(EditorPathConflict) _then;

/// Create a copy of EditorPathConflict
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? base = null,Object? local = null,Object? remote = null,}) {
  return _then(EditorPathConflict(
base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as skir.DataValue,local: null == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as skir.DataValue,remote: null == remote ? _self.remote : remote // ignore: cast_nullable_to_non_nullable
as skir.DataValue,
  ));
}

}


/// Adds pattern-matching-related methods to [EditorPathConflict].
extension EditorPathConflictPatterns on EditorPathConflict {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorPathConflict value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorPathConflict() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorPathConflict value)  $default,){
final _that = this;
switch (_that) {
case _EditorPathConflict():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorPathConflict value)?  $default,){
final _that = this;
switch (_that) {
case _EditorPathConflict() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.DataValue base,  skir.DataValue local,  skir.DataValue remote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorPathConflict() when $default != null:
return $default(_that.base,_that.local,_that.remote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.DataValue base,  skir.DataValue local,  skir.DataValue remote)  $default,) {final _that = this;
switch (_that) {
case _EditorPathConflict():
return $default(_that.base,_that.local,_that.remote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.DataValue base,  skir.DataValue local,  skir.DataValue remote)?  $default,) {final _that = this;
switch (_that) {
case _EditorPathConflict() when $default != null:
return $default(_that.base,_that.local,_that.remote);case _:
  return null;

}
}

}

/// @nodoc


class _EditorPathConflict implements EditorPathConflict {
  const _EditorPathConflict({required this.base, required this.local, required this.remote});
  

@override final  skir.DataValue base;
@override final  skir.DataValue local;
@override final  skir.DataValue remote;

/// Create a copy of EditorPathConflict
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorPathConflictCopyWith<_EditorPathConflict> get copyWith => __$EditorPathConflictCopyWithImpl<_EditorPathConflict>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorPathConflict&&(identical(other.base, base) || other.base == base)&&(identical(other.local, local) || other.local == local)&&(identical(other.remote, remote) || other.remote == remote));
}


@override
int get hashCode {
    return Object.hash(runtimeType,base,local,remote);
}

@override
String toString() {
    return 'EditorPathConflict(base: $base, local: $local, remote: $remote)';
}


}

/// @nodoc
abstract mixin class _$EditorPathConflictCopyWith<$Res> implements $EditorPathConflictCopyWith<$Res> {
  factory _$EditorPathConflictCopyWith(_EditorPathConflict value, $Res Function(_EditorPathConflict) _then) = __$EditorPathConflictCopyWithImpl;
@override @useResult
$Res call({
 skir.DataValue base, skir.DataValue local, skir.DataValue remote
});




}
/// @nodoc
class __$EditorPathConflictCopyWithImpl<$Res>
    implements _$EditorPathConflictCopyWith<$Res> {
  __$EditorPathConflictCopyWithImpl(this._self, this._then);

  final _EditorPathConflict _self;
  final $Res Function(_EditorPathConflict) _then;

/// Create a copy of EditorPathConflict
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? base = null,Object? local = null,Object? remote = null,}) {
  return _then(_EditorPathConflict(
base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as skir.DataValue,local: null == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as skir.DataValue,remote: null == remote ? _self.remote : remote // ignore: cast_nullable_to_non_nullable
as skir.DataValue,
  ));
}


}

/// @nodoc
mixin _$EditorSaveState {

 EditorSavePhase get phase; skir.ValuePath? get path; bool get replayAvailable; Object? get submissionId; EditorPathConflict? get conflict; EditorContentionDetails? get contention; List<EditorDiagnostic> get diagnostics;
/// Create a copy of EditorSaveState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorSaveStateCopyWith<EditorSaveState> get copyWith => _$EditorSaveStateCopyWithImpl<EditorSaveState>(this as EditorSaveState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorSaveState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorSaveState&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.replayAvailable, _this.replayAvailable) || other.replayAvailable == _this.replayAvailable)&&const DeepCollectionEquality().equals(other.submissionId, _this.submissionId)&&(identical(other.conflict, _this.conflict) || other.conflict == _this.conflict)&&(identical(other.contention, _this.contention) || other.contention == _this.contention)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as EditorSaveState;
  return Object.hash(runtimeType,_this.phase,_this.path,_this.replayAvailable,const DeepCollectionEquality().hash(_this.submissionId),_this.conflict,_this.contention,const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as EditorSaveState;
  return 'EditorSaveState(phase: ${_this.phase}, path: ${_this.path}, replayAvailable: ${_this.replayAvailable}, submissionId: ${_this.submissionId}, conflict: ${_this.conflict}, contention: ${_this.contention}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $EditorSaveStateCopyWith<$Res>  {
  factory $EditorSaveStateCopyWith(EditorSaveState value, $Res Function(EditorSaveState) _then) = _$EditorSaveStateCopyWithImpl;
@useResult
$Res call({
 EditorSavePhase phase, skir.ValuePath? path, bool replayAvailable, Object? submissionId, EditorPathConflict? conflict, EditorContentionDetails? contention, List<EditorDiagnostic> diagnostics
});


$EditorPathConflictCopyWith<$Res>? get conflict;

}
/// @nodoc
class _$EditorSaveStateCopyWithImpl<$Res>
    implements $EditorSaveStateCopyWith<$Res> {
  _$EditorSaveStateCopyWithImpl(this._self, this._then);

  final EditorSaveState _self;
  final $Res Function(EditorSaveState) _then;

/// Create a copy of EditorSaveState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? path = freezed,Object? replayAvailable = null,Object? submissionId = freezed,Object? conflict = freezed,Object? contention = freezed,Object? diagnostics = null,}) {
  return _then(EditorSaveState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as EditorSavePhase,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath?,replayAvailable: null == replayAvailable ? _self.replayAvailable : replayAvailable // ignore: cast_nullable_to_non_nullable
as bool,submissionId: freezed == submissionId ? _self.submissionId : submissionId ,conflict: freezed == conflict ? _self.conflict : conflict // ignore: cast_nullable_to_non_nullable
as EditorPathConflict?,contention: freezed == contention ? _self.contention : contention // ignore: cast_nullable_to_non_nullable
as EditorContentionDetails?,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}
/// Create a copy of EditorSaveState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPathConflictCopyWith<$Res>? get conflict {
    if (_self.conflict == null) {
    return null;
  }

  return $EditorPathConflictCopyWith<$Res>(_self.conflict!, (value) {
    return _then(_self.copyWith(conflict: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorSaveState].
extension EditorSaveStatePatterns on EditorSaveState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorSaveState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorSaveState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorSaveState value)  $default,){
final _that = this;
switch (_that) {
case _EditorSaveState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorSaveState value)?  $default,){
final _that = this;
switch (_that) {
case _EditorSaveState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorSavePhase phase,  skir.ValuePath? path,  bool replayAvailable,  Object? submissionId,  EditorPathConflict? conflict,  EditorContentionDetails? contention,  List<EditorDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorSaveState() when $default != null:
return $default(_that.phase,_that.path,_that.replayAvailable,_that.submissionId,_that.conflict,_that.contention,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorSavePhase phase,  skir.ValuePath? path,  bool replayAvailable,  Object? submissionId,  EditorPathConflict? conflict,  EditorContentionDetails? contention,  List<EditorDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _EditorSaveState():
return $default(_that.phase,_that.path,_that.replayAvailable,_that.submissionId,_that.conflict,_that.contention,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorSavePhase phase,  skir.ValuePath? path,  bool replayAvailable,  Object? submissionId,  EditorPathConflict? conflict,  EditorContentionDetails? contention,  List<EditorDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _EditorSaveState() when $default != null:
return $default(_that.phase,_that.path,_that.replayAvailable,_that.submissionId,_that.conflict,_that.contention,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _EditorSaveState extends EditorSaveState {
  const _EditorSaveState({required this.phase, this.path, this.replayAvailable = false, this.submissionId, this.conflict, this.contention,  List<EditorDiagnostic> diagnostics = const []}): _diagnostics = diagnostics,super._();
  

@override final  EditorSavePhase phase;
@override final  skir.ValuePath? path;
@override@JsonKey() final  bool replayAvailable;
@override final  Object? submissionId;
@override final  EditorPathConflict? conflict;
@override final  EditorContentionDetails? contention;
 final  List<EditorDiagnostic> _diagnostics;
@override@JsonKey() List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of EditorSaveState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorSaveStateCopyWith<_EditorSaveState> get copyWith => __$EditorSaveStateCopyWithImpl<_EditorSaveState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorSaveState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.path, path) || other.path == path)&&(identical(other.replayAvailable, replayAvailable) || other.replayAvailable == replayAvailable)&&const DeepCollectionEquality().equals(other.submissionId, submissionId)&&(identical(other.conflict, conflict) || other.conflict == conflict)&&(identical(other.contention, contention) || other.contention == contention)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,path,replayAvailable,const DeepCollectionEquality().hash(submissionId),conflict,contention,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'EditorSaveState(phase: $phase, path: $path, replayAvailable: $replayAvailable, submissionId: $submissionId, conflict: $conflict, contention: $contention, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$EditorSaveStateCopyWith<$Res> implements $EditorSaveStateCopyWith<$Res> {
  factory _$EditorSaveStateCopyWith(_EditorSaveState value, $Res Function(_EditorSaveState) _then) = __$EditorSaveStateCopyWithImpl;
@override @useResult
$Res call({
 EditorSavePhase phase, skir.ValuePath? path, bool replayAvailable, Object? submissionId, EditorPathConflict? conflict, EditorContentionDetails? contention, List<EditorDiagnostic> diagnostics
});


@override $EditorPathConflictCopyWith<$Res>? get conflict;

}
/// @nodoc
class __$EditorSaveStateCopyWithImpl<$Res>
    implements _$EditorSaveStateCopyWith<$Res> {
  __$EditorSaveStateCopyWithImpl(this._self, this._then);

  final _EditorSaveState _self;
  final $Res Function(_EditorSaveState) _then;

/// Create a copy of EditorSaveState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? path = freezed,Object? replayAvailable = null,Object? submissionId = freezed,Object? conflict = freezed,Object? contention = freezed,Object? diagnostics = null,}) {
  return _then(_EditorSaveState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as EditorSavePhase,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath?,replayAvailable: null == replayAvailable ? _self.replayAvailable : replayAvailable // ignore: cast_nullable_to_non_nullable
as bool,submissionId: freezed == submissionId ? _self.submissionId : submissionId ,conflict: freezed == conflict ? _self.conflict : conflict // ignore: cast_nullable_to_non_nullable
as EditorPathConflict?,contention: freezed == contention ? _self.contention : contention // ignore: cast_nullable_to_non_nullable
as EditorContentionDetails?,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}

/// Create a copy of EditorSaveState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPathConflictCopyWith<$Res>? get conflict {
    if (_self.conflict == null) {
    return null;
  }

  return $EditorPathConflictCopyWith<$Res>(_self.conflict!, (value) {
    return _then(_self.copyWith(conflict: value));
  });
}
}

// dart format on
