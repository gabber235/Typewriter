// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditReplay<S,E> {

 EditReplayKind get kind; S get observation; E get edit; List<EditorDiagnostic> get diagnostics; EditConflictEvidence? get conflict; Object? get missing; Object? get cause;
/// Create a copy of EditReplay
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditReplayCopyWith<S, E, EditReplay<S, E>> get copyWith => _$EditReplayCopyWithImpl<S, E, EditReplay<S, E>>(this as EditReplay<S, E>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditReplay<S, E>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditReplay<S, E>&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.observation, _this.observation)&&const DeepCollectionEquality().equals(other.edit, _this.edit)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics)&&(identical(other.conflict, _this.conflict) || other.conflict == _this.conflict)&&const DeepCollectionEquality().equals(other.missing, _this.missing)&&const DeepCollectionEquality().equals(other.cause, _this.cause));
}


@override
int get hashCode {
  final _this = this as EditReplay<S, E>;
  return Object.hash(runtimeType,_this.kind,const DeepCollectionEquality().hash(_this.observation),const DeepCollectionEquality().hash(_this.edit),const DeepCollectionEquality().hash(_this.diagnostics),_this.conflict,const DeepCollectionEquality().hash(_this.missing),const DeepCollectionEquality().hash(_this.cause));
}

@override
String toString() {
  final _this = this as EditReplay<S, E>;
  return 'EditReplay<$S, $E>(kind: ${_this.kind}, observation: ${_this.observation}, edit: ${_this.edit}, diagnostics: ${_this.diagnostics}, conflict: ${_this.conflict}, missing: ${_this.missing}, cause: ${_this.cause})';
}


}

/// @nodoc
abstract mixin class $EditReplayCopyWith<S,E,$Res>  {
  factory $EditReplayCopyWith(EditReplay<S, E> value, $Res Function(EditReplay<S, E>) _then) = _$EditReplayCopyWithImpl;
@useResult
$Res call({
 EditReplayKind kind, S observation, E edit, List<EditorDiagnostic> diagnostics, EditConflictEvidence? conflict, Object? missing, Object? cause
});




}
/// @nodoc
class _$EditReplayCopyWithImpl<S,E,$Res>
    implements $EditReplayCopyWith<S, E, $Res> {
  _$EditReplayCopyWithImpl(this._self, this._then);

  final EditReplay<S, E> _self;
  final $Res Function(EditReplay<S, E>) _then;

/// Create a copy of EditReplay
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? observation = freezed,Object? edit = freezed,Object? diagnostics = null,Object? conflict = freezed,Object? missing = freezed,Object? cause = freezed,}) {
  return _then(EditReplay(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EditReplayKind,observation: freezed == observation ? _self.observation : observation // ignore: cast_nullable_to_non_nullable
as S,edit: freezed == edit ? _self.edit : edit // ignore: cast_nullable_to_non_nullable
as E,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,conflict: freezed == conflict ? _self.conflict : conflict // ignore: cast_nullable_to_non_nullable
as EditConflictEvidence?,missing: freezed == missing ? _self.missing : missing ,cause: freezed == cause ? _self.cause : cause ,
  ));
}

}


/// Adds pattern matching related methods to [EditReplay].
extension EditReplayPatterns<S,E> on EditReplay<S, E> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditReplay<S, E> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditReplay() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditReplay<S, E> value)  $default,){
final _that = this;
switch (_that) {
case _EditReplay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditReplay<S, E> value)?  $default,){
final _that = this;
switch (_that) {
case _EditReplay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditReplayKind kind,  S observation,  E edit,  List<EditorDiagnostic> diagnostics,  EditConflictEvidence? conflict,  Object? missing,  Object? cause)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditReplay() when $default != null:
return $default(_that.kind,_that.observation,_that.edit,_that.diagnostics,_that.conflict,_that.missing,_that.cause);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditReplayKind kind,  S observation,  E edit,  List<EditorDiagnostic> diagnostics,  EditConflictEvidence? conflict,  Object? missing,  Object? cause)  $default,) {final _that = this;
switch (_that) {
case _EditReplay():
return $default(_that.kind,_that.observation,_that.edit,_that.diagnostics,_that.conflict,_that.missing,_that.cause);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditReplayKind kind,  S observation,  E edit,  List<EditorDiagnostic> diagnostics,  EditConflictEvidence? conflict,  Object? missing,  Object? cause)?  $default,) {final _that = this;
switch (_that) {
case _EditReplay() when $default != null:
return $default(_that.kind,_that.observation,_that.edit,_that.diagnostics,_that.conflict,_that.missing,_that.cause);case _:
  return null;

}
}

}

/// @nodoc


class _EditReplay<S,E> implements EditReplay<S, E> {
  const _EditReplay({required this.kind, required this.observation, required this.edit,  List<EditorDiagnostic> diagnostics = const [], this.conflict, this.missing, this.cause}): _diagnostics = diagnostics;


@override final  EditReplayKind kind;
@override final  S observation;
@override final  E edit;
 final  List<EditorDiagnostic> _diagnostics;
@override@JsonKey() List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

@override final  EditConflictEvidence? conflict;
@override final  Object? missing;
@override final  Object? cause;

/// Create a copy of EditReplay
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditReplayCopyWith<S, E, _EditReplay<S, E>> get copyWith => __$EditReplayCopyWithImpl<S, E, _EditReplay<S, E>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditReplay<S, E>&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.observation, observation)&&const DeepCollectionEquality().equals(other.edit, edit)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics)&&(identical(other.conflict, conflict) || other.conflict == conflict)&&const DeepCollectionEquality().equals(other.missing, missing)&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(observation),const DeepCollectionEquality().hash(edit),const DeepCollectionEquality().hash(_diagnostics),conflict,const DeepCollectionEquality().hash(missing),const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'EditReplay<$S, $E>(kind: $kind, observation: $observation, edit: $edit, diagnostics: $diagnostics, conflict: $conflict, missing: $missing, cause: $cause)';
}


}

/// @nodoc
abstract mixin class _$EditReplayCopyWith<S,E,$Res> implements $EditReplayCopyWith<S, E, $Res> {
  factory _$EditReplayCopyWith(_EditReplay<S, E> value, $Res Function(_EditReplay<S, E>) _then) = __$EditReplayCopyWithImpl;
@override @useResult
$Res call({
 EditReplayKind kind, S observation, E edit, List<EditorDiagnostic> diagnostics, EditConflictEvidence? conflict, Object? missing, Object? cause
});




}
/// @nodoc
class __$EditReplayCopyWithImpl<S,E,$Res>
    implements _$EditReplayCopyWith<S, E, $Res> {
  __$EditReplayCopyWithImpl(this._self, this._then);

  final _EditReplay<S, E> _self;
  final $Res Function(_EditReplay<S, E>) _then;

/// Create a copy of EditReplay
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? observation = freezed,Object? edit = freezed,Object? diagnostics = null,Object? conflict = freezed,Object? missing = freezed,Object? cause = freezed,}) {
  return _then(_EditReplay<S, E>(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EditReplayKind,observation: freezed == observation ? _self.observation : observation // ignore: cast_nullable_to_non_nullable
as S,edit: freezed == edit ? _self.edit : edit // ignore: cast_nullable_to_non_nullable
as E,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,conflict: freezed == conflict ? _self.conflict : conflict // ignore: cast_nullable_to_non_nullable
as EditConflictEvidence?,missing: freezed == missing ? _self.missing : missing ,cause: freezed == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc
mixin _$EditObservationResult<S> {

 EditObservationKind get kind; S get observation; String? get message; bool get changed;
/// Create a copy of EditObservationResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditObservationResultCopyWith<S, EditObservationResult<S>> get copyWith => _$EditObservationResultCopyWithImpl<S, EditObservationResult<S>>(this as EditObservationResult<S>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditObservationResult<S>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditObservationResult<S>&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.observation, _this.observation)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.changed, _this.changed) || other.changed == _this.changed));
}


@override
int get hashCode {
  final _this = this as EditObservationResult<S>;
  return Object.hash(runtimeType,_this.kind,const DeepCollectionEquality().hash(_this.observation),_this.message,_this.changed);
}

@override
String toString() {
  final _this = this as EditObservationResult<S>;
  return 'EditObservationResult<$S>(kind: ${_this.kind}, observation: ${_this.observation}, message: ${_this.message}, changed: ${_this.changed})';
}


}

/// @nodoc
abstract mixin class $EditObservationResultCopyWith<S,$Res>  {
  factory $EditObservationResultCopyWith(EditObservationResult<S> value, $Res Function(EditObservationResult<S>) _then) = _$EditObservationResultCopyWithImpl;
@useResult
$Res call({
 EditObservationKind kind, S observation, String? message, bool changed
});




}
/// @nodoc
class _$EditObservationResultCopyWithImpl<S,$Res>
    implements $EditObservationResultCopyWith<S, $Res> {
  _$EditObservationResultCopyWithImpl(this._self, this._then);

  final EditObservationResult<S> _self;
  final $Res Function(EditObservationResult<S>) _then;

/// Create a copy of EditObservationResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? observation = freezed,Object? message = freezed,Object? changed = null,}) {
  return _then(EditObservationResult(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EditObservationKind,observation: freezed == observation ? _self.observation : observation // ignore: cast_nullable_to_non_nullable
as S,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,changed: null == changed ? _self.changed : changed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern matching related methods to [EditObservationResult].
extension EditObservationResultPatterns<S> on EditObservationResult<S> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditObservationResult<S> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditObservationResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditObservationResult<S> value)  $default,){
final _that = this;
switch (_that) {
case _EditObservationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditObservationResult<S> value)?  $default,){
final _that = this;
switch (_that) {
case _EditObservationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditObservationKind kind,  S observation,  String? message,  bool changed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditObservationResult() when $default != null:
return $default(_that.kind,_that.observation,_that.message,_that.changed);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditObservationKind kind,  S observation,  String? message,  bool changed)  $default,) {final _that = this;
switch (_that) {
case _EditObservationResult():
return $default(_that.kind,_that.observation,_that.message,_that.changed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditObservationKind kind,  S observation,  String? message,  bool changed)?  $default,) {final _that = this;
switch (_that) {
case _EditObservationResult() when $default != null:
return $default(_that.kind,_that.observation,_that.message,_that.changed);case _:
  return null;

}
}

}

/// @nodoc


class _EditObservationResult<S> implements EditObservationResult<S> {
  const _EditObservationResult({required this.kind, required this.observation, this.message, this.changed = true});


@override final  EditObservationKind kind;
@override final  S observation;
@override final  String? message;
@override@JsonKey() final  bool changed;

/// Create a copy of EditObservationResult
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditObservationResultCopyWith<S, _EditObservationResult<S>> get copyWith => __$EditObservationResultCopyWithImpl<S, _EditObservationResult<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditObservationResult<S>&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.observation, observation)&&(identical(other.message, message) || other.message == message)&&(identical(other.changed, changed) || other.changed == changed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(observation),message,changed);
}

@override
String toString() {
    return 'EditObservationResult<$S>(kind: $kind, observation: $observation, message: $message, changed: $changed)';
}


}

/// @nodoc
abstract mixin class _$EditObservationResultCopyWith<S,$Res> implements $EditObservationResultCopyWith<S, $Res> {
  factory _$EditObservationResultCopyWith(_EditObservationResult<S> value, $Res Function(_EditObservationResult<S>) _then) = __$EditObservationResultCopyWithImpl;
@override @useResult
$Res call({
 EditObservationKind kind, S observation, String? message, bool changed
});




}
/// @nodoc
class __$EditObservationResultCopyWithImpl<S,$Res>
    implements _$EditObservationResultCopyWith<S, $Res> {
  __$EditObservationResultCopyWithImpl(this._self, this._then);

  final _EditObservationResult<S> _self;
  final $Res Function(_EditObservationResult<S>) _then;

/// Create a copy of EditObservationResult
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? observation = freezed,Object? message = freezed,Object? changed = null,}) {
  return _then(_EditObservationResult<S>(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EditObservationKind,observation: freezed == observation ? _self.observation : observation // ignore: cast_nullable_to_non_nullable
as S,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,changed: null == changed ? _self.changed : changed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$EditCapture<S,E> {

 EditGroupId get group; String get label; S get baseline; S get proposed; List<E> get edits; Set<int> get operations;
/// Create a copy of EditCapture
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditCaptureCopyWith<S, E, EditCapture<S, E>> get copyWith => _$EditCaptureCopyWithImpl<S, E, EditCapture<S, E>>(this as EditCapture<S, E>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditCapture<S, E>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditCapture<S, E>&&(identical(other.group, _this.group) || other.group == _this.group)&&(identical(other.label, _this.label) || other.label == _this.label)&&const DeepCollectionEquality().equals(other.baseline, _this.baseline)&&const DeepCollectionEquality().equals(other.proposed, _this.proposed)&&const DeepCollectionEquality().equals(other.edits, _this.edits)&&const DeepCollectionEquality().equals(other.operations, _this.operations));
}


@override
int get hashCode {
  final _this = this as EditCapture<S, E>;
  return Object.hash(runtimeType,_this.group,_this.label,const DeepCollectionEquality().hash(_this.baseline),const DeepCollectionEquality().hash(_this.proposed),const DeepCollectionEquality().hash(_this.edits),const DeepCollectionEquality().hash(_this.operations));
}

@override
String toString() {
  final _this = this as EditCapture<S, E>;
  return 'EditCapture<$S, $E>(group: ${_this.group}, label: ${_this.label}, baseline: ${_this.baseline}, proposed: ${_this.proposed}, edits: ${_this.edits}, operations: ${_this.operations})';
}


}

/// @nodoc
abstract mixin class $EditCaptureCopyWith<S,E,$Res>  {
  factory $EditCaptureCopyWith(EditCapture<S, E> value, $Res Function(EditCapture<S, E>) _then) = _$EditCaptureCopyWithImpl;
@useResult
$Res call({
 EditGroupId group, String label, S baseline, S proposed, List<E> edits, Set<int> operations
});


$EditGroupIdCopyWith<$Res> get group;

}
/// @nodoc
class _$EditCaptureCopyWithImpl<S,E,$Res>
    implements $EditCaptureCopyWith<S, E, $Res> {
  _$EditCaptureCopyWithImpl(this._self, this._then);

  final EditCapture<S, E> _self;
  final $Res Function(EditCapture<S, E>) _then;

/// Create a copy of EditCapture
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? group = null,Object? label = null,Object? baseline = freezed,Object? proposed = freezed,Object? edits = null,Object? operations = null,}) {
  return _then(EditCapture(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as EditGroupId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,baseline: freezed == baseline ? _self.baseline : baseline // ignore: cast_nullable_to_non_nullable
as S,proposed: freezed == proposed ? _self.proposed : proposed // ignore: cast_nullable_to_non_nullable
as S,edits: null == edits ? _self.edits : edits // ignore: cast_nullable_to_non_nullable
as List<E>,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}
/// Create a copy of EditCapture
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditGroupIdCopyWith<$Res> get group {

  return $EditGroupIdCopyWith<$Res>(_self.group, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}


/// Adds pattern matching related methods to [EditCapture].
extension EditCapturePatterns<S,E> on EditCapture<S, E> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditCapture<S, E> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditCapture() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditCapture<S, E> value)  $default,){
final _that = this;
switch (_that) {
case _EditCapture():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditCapture<S, E> value)?  $default,){
final _that = this;
switch (_that) {
case _EditCapture() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditGroupId group,  String label,  S baseline,  S proposed,  List<E> edits,  Set<int> operations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditCapture() when $default != null:
return $default(_that.group,_that.label,_that.baseline,_that.proposed,_that.edits,_that.operations);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditGroupId group,  String label,  S baseline,  S proposed,  List<E> edits,  Set<int> operations)  $default,) {final _that = this;
switch (_that) {
case _EditCapture():
return $default(_that.group,_that.label,_that.baseline,_that.proposed,_that.edits,_that.operations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditGroupId group,  String label,  S baseline,  S proposed,  List<E> edits,  Set<int> operations)?  $default,) {final _that = this;
switch (_that) {
case _EditCapture() when $default != null:
return $default(_that.group,_that.label,_that.baseline,_that.proposed,_that.edits,_that.operations);case _:
  return null;

}
}

}

/// @nodoc


class _EditCapture<S,E> implements EditCapture<S, E> {
  const _EditCapture({required this.group, required this.label, required this.baseline, required this.proposed, required  List<E> edits, required  Set<int> operations}): _edits = edits,_operations = operations;


@override final  EditGroupId group;
@override final  String label;
@override final  S baseline;
@override final  S proposed;
 final  List<E> _edits;
@override List<E> get edits {
  if (_edits is EqualUnmodifiableListView) return _edits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_edits);
}

 final  Set<int> _operations;
@override Set<int> get operations {
  if (_operations is EqualUnmodifiableSetView) return _operations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_operations);
}


/// Create a copy of EditCapture
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditCaptureCopyWith<S, E, _EditCapture<S, E>> get copyWith => __$EditCaptureCopyWithImpl<S, E, _EditCapture<S, E>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditCapture<S, E>&&(identical(other.group, group) || other.group == group)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.baseline, baseline)&&const DeepCollectionEquality().equals(other.proposed, proposed)&&const DeepCollectionEquality().equals(other.edits, _edits)&&const DeepCollectionEquality().equals(other.operations, _operations));
}


@override
int get hashCode {
    return Object.hash(runtimeType,group,label,const DeepCollectionEquality().hash(baseline),const DeepCollectionEquality().hash(proposed),const DeepCollectionEquality().hash(_edits),const DeepCollectionEquality().hash(_operations));
}

@override
String toString() {
    return 'EditCapture<$S, $E>(group: $group, label: $label, baseline: $baseline, proposed: $proposed, edits: $edits, operations: $operations)';
}


}

/// @nodoc
abstract mixin class _$EditCaptureCopyWith<S,E,$Res> implements $EditCaptureCopyWith<S, E, $Res> {
  factory _$EditCaptureCopyWith(_EditCapture<S, E> value, $Res Function(_EditCapture<S, E>) _then) = __$EditCaptureCopyWithImpl;
@override @useResult
$Res call({
 EditGroupId group, String label, S baseline, S proposed, List<E> edits, Set<int> operations
});


@override $EditGroupIdCopyWith<$Res> get group;

}
/// @nodoc
class __$EditCaptureCopyWithImpl<S,E,$Res>
    implements _$EditCaptureCopyWith<S, E, $Res> {
  __$EditCaptureCopyWithImpl(this._self, this._then);

  final _EditCapture<S, E> _self;
  final $Res Function(_EditCapture<S, E>) _then;

/// Create a copy of EditCapture
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? group = null,Object? label = null,Object? baseline = freezed,Object? proposed = freezed,Object? edits = null,Object? operations = null,}) {
  return _then(_EditCapture<S, E>(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as EditGroupId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,baseline: freezed == baseline ? _self.baseline : baseline // ignore: cast_nullable_to_non_nullable
as S,proposed: freezed == proposed ? _self.proposed : proposed // ignore: cast_nullable_to_non_nullable
as S,edits: null == edits ? _self._edits : edits // ignore: cast_nullable_to_non_nullable
as List<E>,operations: null == operations ? _self._operations : operations // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}

/// Create a copy of EditCapture
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditGroupIdCopyWith<$Res> get group {

  return $EditGroupIdCopyWith<$Res>(_self.group, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}

/// @nodoc
mixin _$EditSettlement<S> {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditSettlement<S>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditSettlement<$S>()';
}


}

/// @nodoc
class $EditSettlementCopyWith<S,$Res>  {
$EditSettlementCopyWith(EditSettlement<S> _, $Res Function(EditSettlement<S>) __);
}


/// Adds pattern matching related methods to [EditSettlement].
extension EditSettlementPatterns<S> on EditSettlement<S> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EditConfirmed<S> value)?  confirmed,TResult Function( EditAccepted<S> value)?  accepted,TResult Function( EditConflict<S> value)?  conflict,TResult Function( EditRejected<S> value)?  rejected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EditConfirmed() when confirmed != null:
return confirmed(_that);case EditAccepted() when accepted != null:
return accepted(_that);case EditConflict() when conflict != null:
return conflict(_that);case EditRejected() when rejected != null:
return rejected(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EditConfirmed<S> value)  confirmed,required TResult Function( EditAccepted<S> value)  accepted,required TResult Function( EditConflict<S> value)  conflict,required TResult Function( EditRejected<S> value)  rejected,}){
final _that = this;
switch (_that) {
case EditConfirmed():
return confirmed(_that);case EditAccepted():
return accepted(_that);case EditConflict():
return conflict(_that);case EditRejected():
return rejected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EditConfirmed<S> value)?  confirmed,TResult? Function( EditAccepted<S> value)?  accepted,TResult? Function( EditConflict<S> value)?  conflict,TResult? Function( EditRejected<S> value)?  rejected,}){
final _that = this;
switch (_that) {
case EditConfirmed() when confirmed != null:
return confirmed(_that);case EditAccepted() when accepted != null:
return accepted(_that);case EditConflict() when conflict != null:
return conflict(_that);case EditRejected() when rejected != null:
return rejected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( S observation)?  confirmed,TResult Function()?  accepted,TResult Function( EditConflictEvidence evidence,  S? observation)?  conflict,TResult Function( List<EditorDiagnostic> diagnostics,  Object? cause,  bool contractChanged)?  rejected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EditConfirmed() when confirmed != null:
return confirmed(_that.observation);case EditAccepted() when accepted != null:
return accepted();case EditConflict() when conflict != null:
return conflict(_that.evidence,_that.observation);case EditRejected() when rejected != null:
return rejected(_that.diagnostics,_that.cause,_that.contractChanged);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( S observation)  confirmed,required TResult Function()  accepted,required TResult Function( EditConflictEvidence evidence,  S? observation)  conflict,required TResult Function( List<EditorDiagnostic> diagnostics,  Object? cause,  bool contractChanged)  rejected,}) {final _that = this;
switch (_that) {
case EditConfirmed():
return confirmed(_that.observation);case EditAccepted():
return accepted();case EditConflict():
return conflict(_that.evidence,_that.observation);case EditRejected():
return rejected(_that.diagnostics,_that.cause,_that.contractChanged);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( S observation)?  confirmed,TResult? Function()?  accepted,TResult? Function( EditConflictEvidence evidence,  S? observation)?  conflict,TResult? Function( List<EditorDiagnostic> diagnostics,  Object? cause,  bool contractChanged)?  rejected,}) {final _that = this;
switch (_that) {
case EditConfirmed() when confirmed != null:
return confirmed(_that.observation);case EditAccepted() when accepted != null:
return accepted();case EditConflict() when conflict != null:
return conflict(_that.evidence,_that.observation);case EditRejected() when rejected != null:
return rejected(_that.diagnostics,_that.cause,_that.contractChanged);case _:
  return null;

}
}

}

/// @nodoc


class EditConfirmed<S> implements EditSettlement<S> {
  const EditConfirmed(this.observation);


 final  S observation;

/// Create a copy of EditSettlement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditConfirmedCopyWith<S, EditConfirmed<S>> get copyWith => _$EditConfirmedCopyWithImpl<S, EditConfirmed<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditConfirmed<S>&&const DeepCollectionEquality().equals(other.observation, observation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(observation));
}

@override
String toString() {
    return 'EditSettlement<$S>.confirmed(observation: $observation)';
}


}

/// @nodoc
abstract mixin class $EditConfirmedCopyWith<S,$Res> implements $EditSettlementCopyWith<S, $Res> {
  factory $EditConfirmedCopyWith(EditConfirmed<S> value, $Res Function(EditConfirmed<S>) _then) = _$EditConfirmedCopyWithImpl;
@useResult
$Res call({
 S observation
});




}
/// @nodoc
class _$EditConfirmedCopyWithImpl<S,$Res>
    implements $EditConfirmedCopyWith<S, $Res> {
  _$EditConfirmedCopyWithImpl(this._self, this._then);

  final EditConfirmed<S> _self;
  final $Res Function(EditConfirmed<S>) _then;

/// Create a copy of EditSettlement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? observation = freezed,}) {
  return _then(EditConfirmed<S>(
freezed == observation ? _self.observation : observation // ignore: cast_nullable_to_non_nullable
as S,
  ));
}


}

/// @nodoc


class EditAccepted<S> implements EditSettlement<S> {
  const EditAccepted();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditAccepted<S>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditSettlement<$S>.accepted()';
}


}




/// @nodoc


class EditConflict<S> implements EditSettlement<S> {
  const EditConflict({required this.evidence, this.observation});


 final  EditConflictEvidence evidence;
 final  S? observation;

/// Create a copy of EditSettlement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditConflictCopyWith<S, EditConflict<S>> get copyWith => _$EditConflictCopyWithImpl<S, EditConflict<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditConflict<S>&&(identical(other.evidence, evidence) || other.evidence == evidence)&&const DeepCollectionEquality().equals(other.observation, observation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,evidence,const DeepCollectionEquality().hash(observation));
}

@override
String toString() {
    return 'EditSettlement<$S>.conflict(evidence: $evidence, observation: $observation)';
}


}

/// @nodoc
abstract mixin class $EditConflictCopyWith<S,$Res> implements $EditSettlementCopyWith<S, $Res> {
  factory $EditConflictCopyWith(EditConflict<S> value, $Res Function(EditConflict<S>) _then) = _$EditConflictCopyWithImpl;
@useResult
$Res call({
 EditConflictEvidence evidence, S? observation
});




}
/// @nodoc
class _$EditConflictCopyWithImpl<S,$Res>
    implements $EditConflictCopyWith<S, $Res> {
  _$EditConflictCopyWithImpl(this._self, this._then);

  final EditConflict<S> _self;
  final $Res Function(EditConflict<S>) _then;

/// Create a copy of EditSettlement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? evidence = null,Object? observation = freezed,}) {
  return _then(EditConflict<S>(
evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as EditConflictEvidence,observation: freezed == observation ? _self.observation : observation // ignore: cast_nullable_to_non_nullable
as S?,
  ));
}


}

/// @nodoc


class EditRejected<S> implements EditSettlement<S> {
  const EditRejected({ List<EditorDiagnostic> diagnostics = const [], this.cause, this.contractChanged = false}): _diagnostics = diagnostics;


 final  List<EditorDiagnostic> _diagnostics;
@JsonKey() List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

 final  Object? cause;
@JsonKey() final  bool contractChanged;

/// Create a copy of EditSettlement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditRejectedCopyWith<S, EditRejected<S>> get copyWith => _$EditRejectedCopyWithImpl<S, EditRejected<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditRejected<S>&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics)&&const DeepCollectionEquality().equals(other.cause, cause)&&(identical(other.contractChanged, contractChanged) || other.contractChanged == contractChanged));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics),const DeepCollectionEquality().hash(cause),contractChanged);
}

@override
String toString() {
    return 'EditSettlement<$S>.rejected(diagnostics: $diagnostics, cause: $cause, contractChanged: $contractChanged)';
}


}

/// @nodoc
abstract mixin class $EditRejectedCopyWith<S,$Res> implements $EditSettlementCopyWith<S, $Res> {
  factory $EditRejectedCopyWith(EditRejected<S> value, $Res Function(EditRejected<S>) _then) = _$EditRejectedCopyWithImpl;
@useResult
$Res call({
 List<EditorDiagnostic> diagnostics, Object? cause, bool contractChanged
});




}
/// @nodoc
class _$EditRejectedCopyWithImpl<S,$Res>
    implements $EditRejectedCopyWith<S, $Res> {
  _$EditRejectedCopyWithImpl(this._self, this._then);

  final EditRejected<S> _self;
  final $Res Function(EditRejected<S>) _then;

/// Create a copy of EditSettlement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,Object? cause = freezed,Object? contractChanged = null,}) {
  return _then(EditRejected<S>(
diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,cause: freezed == cause ? _self.cause : cause ,contractChanged: null == contractChanged ? _self.contractChanged : contractChanged // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$EditGroupId {

 int get value;
/// Create a copy of EditGroupId
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupIdCopyWith<EditGroupId> get copyWith => _$EditGroupIdCopyWithImpl<EditGroupId>(this as EditGroupId, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditGroupId;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupId&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as EditGroupId;
  return Object.hash(runtimeType,_this.value);
}

@override
String toString() {
  final _this = this as EditGroupId;
  return 'EditGroupId(value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $EditGroupIdCopyWith<$Res>  {
  factory $EditGroupIdCopyWith(EditGroupId value, $Res Function(EditGroupId) _then) = _$EditGroupIdCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$EditGroupIdCopyWithImpl<$Res>
    implements $EditGroupIdCopyWith<$Res> {
  _$EditGroupIdCopyWithImpl(this._self, this._then);

  final EditGroupId _self;
  final $Res Function(EditGroupId) _then;

/// Create a copy of EditGroupId
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(EditGroupId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern matching related methods to [EditGroupId].
extension EditGroupIdPatterns on EditGroupId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditGroupId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditGroupId() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditGroupId value)  $default,){
final _that = this;
switch (_that) {
case _EditGroupId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditGroupId value)?  $default,){
final _that = this;
switch (_that) {
case _EditGroupId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditGroupId() when $default != null:
return $default(_that.value);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value)  $default,) {final _that = this;
switch (_that) {
case _EditGroupId():
return $default(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int value)?  $default,) {final _that = this;
switch (_that) {
case _EditGroupId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _EditGroupId implements EditGroupId {
  const _EditGroupId(this.value);


@override final  int value;

/// Create a copy of EditGroupId
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditGroupIdCopyWith<_EditGroupId> get copyWith => __$EditGroupIdCopyWithImpl<_EditGroupId>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditGroupId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString() {
    return 'EditGroupId(value: $value)';
}


}

/// @nodoc
abstract mixin class _$EditGroupIdCopyWith<$Res> implements $EditGroupIdCopyWith<$Res> {
  factory _$EditGroupIdCopyWith(_EditGroupId value, $Res Function(_EditGroupId) _then) = __$EditGroupIdCopyWithImpl;
@override @useResult
$Res call({
 int value
});




}
/// @nodoc
class __$EditGroupIdCopyWithImpl<$Res>
    implements _$EditGroupIdCopyWith<$Res> {
  __$EditGroupIdCopyWithImpl(this._self, this._then);

  final _EditGroupId _self;
  final $Res Function(_EditGroupId) _then;

/// Create a copy of EditGroupId
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_EditGroupId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$EditGroupPhase<S> {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupPhase<S>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditGroupPhase<$S>()';
}


}

/// @nodoc
class $EditGroupPhaseCopyWith<S,$Res>  {
$EditGroupPhaseCopyWith(EditGroupPhase<S> _, $Res Function(EditGroupPhase<S>) __);
}


/// Adds pattern matching related methods to [EditGroupPhase].
extension EditGroupPhasePatterns<S> on EditGroupPhase<S> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EditGroupDirty<S> value)?  dirty,TResult Function( EditGroupAwaitingDependency<S> value)?  awaitingDependency,TResult Function( EditGroupSaving<S> value)?  saving,TResult Function( EditGroupCommittedAwaitingRefresh<S> value)?  committedAwaitingRefresh,TResult Function( EditGroupConflict<S> value)?  conflict,TResult Function( EditGroupRejected<S> value)?  rejected,TResult Function( EditGroupContractChanged<S> value)?  contractChanged,TResult Function( EditGroupUncertain<S> value)?  uncertain,TResult Function( EditGroupRepeatedContention<S> value)?  repeatedContention,TResult Function( EditGroupResourceMissing<S> value)?  resourceMissing,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EditGroupDirty() when dirty != null:
return dirty(_that);case EditGroupAwaitingDependency() when awaitingDependency != null:
return awaitingDependency(_that);case EditGroupSaving() when saving != null:
return saving(_that);case EditGroupCommittedAwaitingRefresh() when committedAwaitingRefresh != null:
return committedAwaitingRefresh(_that);case EditGroupConflict() when conflict != null:
return conflict(_that);case EditGroupRejected() when rejected != null:
return rejected(_that);case EditGroupContractChanged() when contractChanged != null:
return contractChanged(_that);case EditGroupUncertain() when uncertain != null:
return uncertain(_that);case EditGroupRepeatedContention() when repeatedContention != null:
return repeatedContention(_that);case EditGroupResourceMissing() when resourceMissing != null:
return resourceMissing(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EditGroupDirty<S> value)  dirty,required TResult Function( EditGroupAwaitingDependency<S> value)  awaitingDependency,required TResult Function( EditGroupSaving<S> value)  saving,required TResult Function( EditGroupCommittedAwaitingRefresh<S> value)  committedAwaitingRefresh,required TResult Function( EditGroupConflict<S> value)  conflict,required TResult Function( EditGroupRejected<S> value)  rejected,required TResult Function( EditGroupContractChanged<S> value)  contractChanged,required TResult Function( EditGroupUncertain<S> value)  uncertain,required TResult Function( EditGroupRepeatedContention<S> value)  repeatedContention,required TResult Function( EditGroupResourceMissing<S> value)  resourceMissing,}){
final _that = this;
switch (_that) {
case EditGroupDirty():
return dirty(_that);case EditGroupAwaitingDependency():
return awaitingDependency(_that);case EditGroupSaving():
return saving(_that);case EditGroupCommittedAwaitingRefresh():
return committedAwaitingRefresh(_that);case EditGroupConflict():
return conflict(_that);case EditGroupRejected():
return rejected(_that);case EditGroupContractChanged():
return contractChanged(_that);case EditGroupUncertain():
return uncertain(_that);case EditGroupRepeatedContention():
return repeatedContention(_that);case EditGroupResourceMissing():
return resourceMissing(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EditGroupDirty<S> value)?  dirty,TResult? Function( EditGroupAwaitingDependency<S> value)?  awaitingDependency,TResult? Function( EditGroupSaving<S> value)?  saving,TResult? Function( EditGroupCommittedAwaitingRefresh<S> value)?  committedAwaitingRefresh,TResult? Function( EditGroupConflict<S> value)?  conflict,TResult? Function( EditGroupRejected<S> value)?  rejected,TResult? Function( EditGroupContractChanged<S> value)?  contractChanged,TResult? Function( EditGroupUncertain<S> value)?  uncertain,TResult? Function( EditGroupRepeatedContention<S> value)?  repeatedContention,TResult? Function( EditGroupResourceMissing<S> value)?  resourceMissing,}){
final _that = this;
switch (_that) {
case EditGroupDirty() when dirty != null:
return dirty(_that);case EditGroupAwaitingDependency() when awaitingDependency != null:
return awaitingDependency(_that);case EditGroupSaving() when saving != null:
return saving(_that);case EditGroupCommittedAwaitingRefresh() when committedAwaitingRefresh != null:
return committedAwaitingRefresh(_that);case EditGroupConflict() when conflict != null:
return conflict(_that);case EditGroupRejected() when rejected != null:
return rejected(_that);case EditGroupContractChanged() when contractChanged != null:
return contractChanged(_that);case EditGroupUncertain() when uncertain != null:
return uncertain(_that);case EditGroupRepeatedContention() when repeatedContention != null:
return repeatedContention(_that);case EditGroupResourceMissing() when resourceMissing != null:
return resourceMissing(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  dirty,TResult Function( Set<EditGroupId> groups)?  awaitingDependency,TResult Function()?  saving,TResult Function( Object? cause)?  committedAwaitingRefresh,TResult Function( String message,  EditConflictEvidence? evidence)?  conflict,TResult Function( String message,  Object? cause)?  rejected,TResult Function()?  contractChanged,TResult Function( Object cause)?  uncertain,TResult Function( int attempts,  EditConflictEvidence? evidence)?  repeatedContention,TResult Function( Object resource,  S proposal)?  resourceMissing,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EditGroupDirty() when dirty != null:
return dirty();case EditGroupAwaitingDependency() when awaitingDependency != null:
return awaitingDependency(_that.groups);case EditGroupSaving() when saving != null:
return saving();case EditGroupCommittedAwaitingRefresh() when committedAwaitingRefresh != null:
return committedAwaitingRefresh(_that.cause);case EditGroupConflict() when conflict != null:
return conflict(_that.message,_that.evidence);case EditGroupRejected() when rejected != null:
return rejected(_that.message,_that.cause);case EditGroupContractChanged() when contractChanged != null:
return contractChanged();case EditGroupUncertain() when uncertain != null:
return uncertain(_that.cause);case EditGroupRepeatedContention() when repeatedContention != null:
return repeatedContention(_that.attempts,_that.evidence);case EditGroupResourceMissing() when resourceMissing != null:
return resourceMissing(_that.resource,_that.proposal);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  dirty,required TResult Function( Set<EditGroupId> groups)  awaitingDependency,required TResult Function()  saving,required TResult Function( Object? cause)  committedAwaitingRefresh,required TResult Function( String message,  EditConflictEvidence? evidence)  conflict,required TResult Function( String message,  Object? cause)  rejected,required TResult Function()  contractChanged,required TResult Function( Object cause)  uncertain,required TResult Function( int attempts,  EditConflictEvidence? evidence)  repeatedContention,required TResult Function( Object resource,  S proposal)  resourceMissing,}) {final _that = this;
switch (_that) {
case EditGroupDirty():
return dirty();case EditGroupAwaitingDependency():
return awaitingDependency(_that.groups);case EditGroupSaving():
return saving();case EditGroupCommittedAwaitingRefresh():
return committedAwaitingRefresh(_that.cause);case EditGroupConflict():
return conflict(_that.message,_that.evidence);case EditGroupRejected():
return rejected(_that.message,_that.cause);case EditGroupContractChanged():
return contractChanged();case EditGroupUncertain():
return uncertain(_that.cause);case EditGroupRepeatedContention():
return repeatedContention(_that.attempts,_that.evidence);case EditGroupResourceMissing():
return resourceMissing(_that.resource,_that.proposal);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  dirty,TResult? Function( Set<EditGroupId> groups)?  awaitingDependency,TResult? Function()?  saving,TResult? Function( Object? cause)?  committedAwaitingRefresh,TResult? Function( String message,  EditConflictEvidence? evidence)?  conflict,TResult? Function( String message,  Object? cause)?  rejected,TResult? Function()?  contractChanged,TResult? Function( Object cause)?  uncertain,TResult? Function( int attempts,  EditConflictEvidence? evidence)?  repeatedContention,TResult? Function( Object resource,  S proposal)?  resourceMissing,}) {final _that = this;
switch (_that) {
case EditGroupDirty() when dirty != null:
return dirty();case EditGroupAwaitingDependency() when awaitingDependency != null:
return awaitingDependency(_that.groups);case EditGroupSaving() when saving != null:
return saving();case EditGroupCommittedAwaitingRefresh() when committedAwaitingRefresh != null:
return committedAwaitingRefresh(_that.cause);case EditGroupConflict() when conflict != null:
return conflict(_that.message,_that.evidence);case EditGroupRejected() when rejected != null:
return rejected(_that.message,_that.cause);case EditGroupContractChanged() when contractChanged != null:
return contractChanged();case EditGroupUncertain() when uncertain != null:
return uncertain(_that.cause);case EditGroupRepeatedContention() when repeatedContention != null:
return repeatedContention(_that.attempts,_that.evidence);case EditGroupResourceMissing() when resourceMissing != null:
return resourceMissing(_that.resource,_that.proposal);case _:
  return null;

}
}

}

/// @nodoc


class EditGroupDirty<S> extends EditGroupPhase<S> {
  const EditGroupDirty(): super._();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupDirty<S>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditGroupPhase<$S>.dirty()';
}


}




/// @nodoc


class EditGroupAwaitingDependency<S> extends EditGroupPhase<S> {
  const EditGroupAwaitingDependency( Set<EditGroupId> groups): _groups = groups,super._();


 final  Set<EditGroupId> _groups;
 Set<EditGroupId> get groups {
  if (_groups is EqualUnmodifiableSetView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_groups);
}


/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupAwaitingDependencyCopyWith<S, EditGroupAwaitingDependency<S>> get copyWith => _$EditGroupAwaitingDependencyCopyWithImpl<S, EditGroupAwaitingDependency<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupAwaitingDependency<S>&&const DeepCollectionEquality().equals(other.groups, _groups));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_groups));
}

@override
String toString() {
    return 'EditGroupPhase<$S>.awaitingDependency(groups: $groups)';
}


}

/// @nodoc
abstract mixin class $EditGroupAwaitingDependencyCopyWith<S,$Res> implements $EditGroupPhaseCopyWith<S, $Res> {
  factory $EditGroupAwaitingDependencyCopyWith(EditGroupAwaitingDependency<S> value, $Res Function(EditGroupAwaitingDependency<S>) _then) = _$EditGroupAwaitingDependencyCopyWithImpl;
@useResult
$Res call({
 Set<EditGroupId> groups
});




}
/// @nodoc
class _$EditGroupAwaitingDependencyCopyWithImpl<S,$Res>
    implements $EditGroupAwaitingDependencyCopyWith<S, $Res> {
  _$EditGroupAwaitingDependencyCopyWithImpl(this._self, this._then);

  final EditGroupAwaitingDependency<S> _self;
  final $Res Function(EditGroupAwaitingDependency<S>) _then;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? groups = null,}) {
  return _then(EditGroupAwaitingDependency<S>(
null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as Set<EditGroupId>,
  ));
}


}

/// @nodoc


class EditGroupSaving<S> extends EditGroupPhase<S> {
  const EditGroupSaving(): super._();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupSaving<S>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditGroupPhase<$S>.saving()';
}


}




/// @nodoc


class EditGroupCommittedAwaitingRefresh<S> extends EditGroupPhase<S> {
  const EditGroupCommittedAwaitingRefresh(this.cause): super._();


 final  Object? cause;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupCommittedAwaitingRefreshCopyWith<S, EditGroupCommittedAwaitingRefresh<S>> get copyWith => _$EditGroupCommittedAwaitingRefreshCopyWithImpl<S, EditGroupCommittedAwaitingRefresh<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupCommittedAwaitingRefresh<S>&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'EditGroupPhase<$S>.committedAwaitingRefresh(cause: $cause)';
}


}

/// @nodoc
abstract mixin class $EditGroupCommittedAwaitingRefreshCopyWith<S,$Res> implements $EditGroupPhaseCopyWith<S, $Res> {
  factory $EditGroupCommittedAwaitingRefreshCopyWith(EditGroupCommittedAwaitingRefresh<S> value, $Res Function(EditGroupCommittedAwaitingRefresh<S>) _then) = _$EditGroupCommittedAwaitingRefreshCopyWithImpl;
@useResult
$Res call({
 Object? cause
});




}
/// @nodoc
class _$EditGroupCommittedAwaitingRefreshCopyWithImpl<S,$Res>
    implements $EditGroupCommittedAwaitingRefreshCopyWith<S, $Res> {
  _$EditGroupCommittedAwaitingRefreshCopyWithImpl(this._self, this._then);

  final EditGroupCommittedAwaitingRefresh<S> _self;
  final $Res Function(EditGroupCommittedAwaitingRefresh<S>) _then;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cause = freezed,}) {
  return _then(EditGroupCommittedAwaitingRefresh<S>(
freezed == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc


class EditGroupConflict<S> extends EditGroupPhase<S> {
  const EditGroupConflict(this.message, this.evidence): super._();


 final  String message;
 final  EditConflictEvidence? evidence;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupConflictCopyWith<S, EditGroupConflict<S>> get copyWith => _$EditGroupConflictCopyWithImpl<S, EditGroupConflict<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupConflict<S>&&(identical(other.message, message) || other.message == message)&&(identical(other.evidence, evidence) || other.evidence == evidence));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,evidence);
}

@override
String toString() {
    return 'EditGroupPhase<$S>.conflict(message: $message, evidence: $evidence)';
}


}

/// @nodoc
abstract mixin class $EditGroupConflictCopyWith<S,$Res> implements $EditGroupPhaseCopyWith<S, $Res> {
  factory $EditGroupConflictCopyWith(EditGroupConflict<S> value, $Res Function(EditGroupConflict<S>) _then) = _$EditGroupConflictCopyWithImpl;
@useResult
$Res call({
 String message, EditConflictEvidence? evidence
});




}
/// @nodoc
class _$EditGroupConflictCopyWithImpl<S,$Res>
    implements $EditGroupConflictCopyWith<S, $Res> {
  _$EditGroupConflictCopyWithImpl(this._self, this._then);

  final EditGroupConflict<S> _self;
  final $Res Function(EditGroupConflict<S>) _then;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? evidence = freezed,}) {
  return _then(EditGroupConflict<S>(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,freezed == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as EditConflictEvidence?,
  ));
}


}

/// @nodoc


class EditGroupRejected<S> extends EditGroupPhase<S> {
  const EditGroupRejected(this.message, this.cause): super._();


 final  String message;
 final  Object? cause;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupRejectedCopyWith<S, EditGroupRejected<S>> get copyWith => _$EditGroupRejectedCopyWithImpl<S, EditGroupRejected<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupRejected<S>&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'EditGroupPhase<$S>.rejected(message: $message, cause: $cause)';
}


}

/// @nodoc
abstract mixin class $EditGroupRejectedCopyWith<S,$Res> implements $EditGroupPhaseCopyWith<S, $Res> {
  factory $EditGroupRejectedCopyWith(EditGroupRejected<S> value, $Res Function(EditGroupRejected<S>) _then) = _$EditGroupRejectedCopyWithImpl;
@useResult
$Res call({
 String message, Object? cause
});




}
/// @nodoc
class _$EditGroupRejectedCopyWithImpl<S,$Res>
    implements $EditGroupRejectedCopyWith<S, $Res> {
  _$EditGroupRejectedCopyWithImpl(this._self, this._then);

  final EditGroupRejected<S> _self;
  final $Res Function(EditGroupRejected<S>) _then;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = freezed,}) {
  return _then(EditGroupRejected<S>(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,freezed == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc


class EditGroupContractChanged<S> extends EditGroupPhase<S> {
  const EditGroupContractChanged(): super._();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupContractChanged<S>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditGroupPhase<$S>.contractChanged()';
}


}




/// @nodoc


class EditGroupUncertain<S> extends EditGroupPhase<S> {
  const EditGroupUncertain(this.cause): super._();


 final  Object cause;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupUncertainCopyWith<S, EditGroupUncertain<S>> get copyWith => _$EditGroupUncertainCopyWithImpl<S, EditGroupUncertain<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupUncertain<S>&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'EditGroupPhase<$S>.uncertain(cause: $cause)';
}


}

/// @nodoc
abstract mixin class $EditGroupUncertainCopyWith<S,$Res> implements $EditGroupPhaseCopyWith<S, $Res> {
  factory $EditGroupUncertainCopyWith(EditGroupUncertain<S> value, $Res Function(EditGroupUncertain<S>) _then) = _$EditGroupUncertainCopyWithImpl;
@useResult
$Res call({
 Object cause
});




}
/// @nodoc
class _$EditGroupUncertainCopyWithImpl<S,$Res>
    implements $EditGroupUncertainCopyWith<S, $Res> {
  _$EditGroupUncertainCopyWithImpl(this._self, this._then);

  final EditGroupUncertain<S> _self;
  final $Res Function(EditGroupUncertain<S>) _then;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cause = null,}) {
  return _then(EditGroupUncertain<S>(
null == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc


class EditGroupRepeatedContention<S> extends EditGroupPhase<S> {
  const EditGroupRepeatedContention(this.attempts, this.evidence): super._();


 final  int attempts;
 final  EditConflictEvidence? evidence;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupRepeatedContentionCopyWith<S, EditGroupRepeatedContention<S>> get copyWith => _$EditGroupRepeatedContentionCopyWithImpl<S, EditGroupRepeatedContention<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupRepeatedContention<S>&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.evidence, evidence) || other.evidence == evidence));
}


@override
int get hashCode {
    return Object.hash(runtimeType,attempts,evidence);
}

@override
String toString() {
    return 'EditGroupPhase<$S>.repeatedContention(attempts: $attempts, evidence: $evidence)';
}


}

/// @nodoc
abstract mixin class $EditGroupRepeatedContentionCopyWith<S,$Res> implements $EditGroupPhaseCopyWith<S, $Res> {
  factory $EditGroupRepeatedContentionCopyWith(EditGroupRepeatedContention<S> value, $Res Function(EditGroupRepeatedContention<S>) _then) = _$EditGroupRepeatedContentionCopyWithImpl;
@useResult
$Res call({
 int attempts, EditConflictEvidence? evidence
});




}
/// @nodoc
class _$EditGroupRepeatedContentionCopyWithImpl<S,$Res>
    implements $EditGroupRepeatedContentionCopyWith<S, $Res> {
  _$EditGroupRepeatedContentionCopyWithImpl(this._self, this._then);

  final EditGroupRepeatedContention<S> _self;
  final $Res Function(EditGroupRepeatedContention<S>) _then;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? attempts = null,Object? evidence = freezed,}) {
  return _then(EditGroupRepeatedContention<S>(
null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,freezed == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as EditConflictEvidence?,
  ));
}


}

/// @nodoc


class EditGroupResourceMissing<S> extends EditGroupPhase<S> {
  const EditGroupResourceMissing(this.resource, this.proposal): super._();


 final  Object resource;
 final  S proposal;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupResourceMissingCopyWith<S, EditGroupResourceMissing<S>> get copyWith => _$EditGroupResourceMissingCopyWithImpl<S, EditGroupResourceMissing<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupResourceMissing<S>&&const DeepCollectionEquality().equals(other.resource, resource)&&const DeepCollectionEquality().equals(other.proposal, proposal));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(resource),const DeepCollectionEquality().hash(proposal));
}

@override
String toString() {
    return 'EditGroupPhase<$S>.resourceMissing(resource: $resource, proposal: $proposal)';
}


}

/// @nodoc
abstract mixin class $EditGroupResourceMissingCopyWith<S,$Res> implements $EditGroupPhaseCopyWith<S, $Res> {
  factory $EditGroupResourceMissingCopyWith(EditGroupResourceMissing<S> value, $Res Function(EditGroupResourceMissing<S>) _then) = _$EditGroupResourceMissingCopyWithImpl;
@useResult
$Res call({
 Object resource, S proposal
});




}
/// @nodoc
class _$EditGroupResourceMissingCopyWithImpl<S,$Res>
    implements $EditGroupResourceMissingCopyWith<S, $Res> {
  _$EditGroupResourceMissingCopyWithImpl(this._self, this._then);

  final EditGroupResourceMissing<S> _self;
  final $Res Function(EditGroupResourceMissing<S>) _then;

/// Create a copy of EditGroupPhase
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? proposal = freezed,}) {
  return _then(EditGroupResourceMissing<S>(
null == resource ? _self.resource : resource ,freezed == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as S,
  ));
}


}

/// @nodoc
mixin _$EditGroup<S> {

 EditGroupId get id; String get label; EditorCommitPolicy get policy; EditGroupPhase<S> get phase; Set<Object> get resources; int get operationCount; S get original;
/// Create a copy of EditGroup
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupCopyWith<S, EditGroup<S>> get copyWith => _$EditGroupCopyWithImpl<S, EditGroup<S>>(this as EditGroup<S>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditGroup<S>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroup<S>&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.policy, _this.policy) || other.policy == _this.policy)&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&const DeepCollectionEquality().equals(other.resources, _this.resources)&&(identical(other.operationCount, _this.operationCount) || other.operationCount == _this.operationCount)&&const DeepCollectionEquality().equals(other.original, _this.original));
}


@override
int get hashCode {
  final _this = this as EditGroup<S>;
  return Object.hash(runtimeType,_this.id,_this.label,_this.policy,_this.phase,const DeepCollectionEquality().hash(_this.resources),_this.operationCount,const DeepCollectionEquality().hash(_this.original));
}

@override
String toString() {
  final _this = this as EditGroup<S>;
  return 'EditGroup<$S>(id: ${_this.id}, label: ${_this.label}, policy: ${_this.policy}, phase: ${_this.phase}, resources: ${_this.resources}, operationCount: ${_this.operationCount}, original: ${_this.original})';
}


}

/// @nodoc
abstract mixin class $EditGroupCopyWith<S,$Res>  {
  factory $EditGroupCopyWith(EditGroup<S> value, $Res Function(EditGroup<S>) _then) = _$EditGroupCopyWithImpl;
@useResult
$Res call({
 EditGroupId id, String label, EditorCommitPolicy policy, EditGroupPhase<S> phase, Set<Object> resources, int operationCount, S original
});


$EditGroupIdCopyWith<$Res> get id;$EditGroupPhaseCopyWith<S, $Res> get phase;

}
/// @nodoc
class _$EditGroupCopyWithImpl<S,$Res>
    implements $EditGroupCopyWith<S, $Res> {
  _$EditGroupCopyWithImpl(this._self, this._then);

  final EditGroup<S> _self;
  final $Res Function(EditGroup<S>) _then;

/// Create a copy of EditGroup
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? policy = null,Object? phase = null,Object? resources = null,Object? operationCount = null,Object? original = freezed,}) {
  return _then(EditGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as EditGroupId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as EditorCommitPolicy,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as EditGroupPhase<S>,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as Set<Object>,operationCount: null == operationCount ? _self.operationCount : operationCount // ignore: cast_nullable_to_non_nullable
as int,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as S,
  ));
}
/// Create a copy of EditGroup
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditGroupIdCopyWith<$Res> get id {

  return $EditGroupIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of EditGroup
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditGroupPhaseCopyWith<S, $Res> get phase {

  return $EditGroupPhaseCopyWith<S, $Res>(_self.phase, (value) {
    return _then(_self.copyWith(phase: value));
  });
}
}


/// Adds pattern matching related methods to [EditGroup].
extension EditGroupPatterns<S> on EditGroup<S> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditGroup<S> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditGroup() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditGroup<S> value)  $default,){
final _that = this;
switch (_that) {
case _EditGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditGroup<S> value)?  $default,){
final _that = this;
switch (_that) {
case _EditGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditGroupId id,  String label,  EditorCommitPolicy policy,  EditGroupPhase<S> phase,  Set<Object> resources,  int operationCount,  S original)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditGroup() when $default != null:
return $default(_that.id,_that.label,_that.policy,_that.phase,_that.resources,_that.operationCount,_that.original);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditGroupId id,  String label,  EditorCommitPolicy policy,  EditGroupPhase<S> phase,  Set<Object> resources,  int operationCount,  S original)  $default,) {final _that = this;
switch (_that) {
case _EditGroup():
return $default(_that.id,_that.label,_that.policy,_that.phase,_that.resources,_that.operationCount,_that.original);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditGroupId id,  String label,  EditorCommitPolicy policy,  EditGroupPhase<S> phase,  Set<Object> resources,  int operationCount,  S original)?  $default,) {final _that = this;
switch (_that) {
case _EditGroup() when $default != null:
return $default(_that.id,_that.label,_that.policy,_that.phase,_that.resources,_that.operationCount,_that.original);case _:
  return null;

}
}

}

/// @nodoc


class _EditGroup<S> implements EditGroup<S> {
  const _EditGroup({required this.id, required this.label, required this.policy, required this.phase, required  Set<Object> resources, required this.operationCount, required this.original}): _resources = resources;


@override final  EditGroupId id;
@override final  String label;
@override final  EditorCommitPolicy policy;
@override final  EditGroupPhase<S> phase;
 final  Set<Object> _resources;
@override Set<Object> get resources {
  if (_resources is EqualUnmodifiableSetView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resources);
}

@override final  int operationCount;
@override final  S original;

/// Create a copy of EditGroup
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditGroupCopyWith<S, _EditGroup<S>> get copyWith => __$EditGroupCopyWithImpl<S, _EditGroup<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditGroup<S>&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.resources, _resources)&&(identical(other.operationCount, operationCount) || other.operationCount == operationCount)&&const DeepCollectionEquality().equals(other.original, original));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,label,policy,phase,const DeepCollectionEquality().hash(_resources),operationCount,const DeepCollectionEquality().hash(original));
}

@override
String toString() {
    return 'EditGroup<$S>(id: $id, label: $label, policy: $policy, phase: $phase, resources: $resources, operationCount: $operationCount, original: $original)';
}


}

/// @nodoc
abstract mixin class _$EditGroupCopyWith<S,$Res> implements $EditGroupCopyWith<S, $Res> {
  factory _$EditGroupCopyWith(_EditGroup<S> value, $Res Function(_EditGroup<S>) _then) = __$EditGroupCopyWithImpl;
@override @useResult
$Res call({
 EditGroupId id, String label, EditorCommitPolicy policy, EditGroupPhase<S> phase, Set<Object> resources, int operationCount, S original
});


@override $EditGroupIdCopyWith<$Res> get id;@override $EditGroupPhaseCopyWith<S, $Res> get phase;

}
/// @nodoc
class __$EditGroupCopyWithImpl<S,$Res>
    implements _$EditGroupCopyWith<S, $Res> {
  __$EditGroupCopyWithImpl(this._self, this._then);

  final _EditGroup<S> _self;
  final $Res Function(_EditGroup<S>) _then;

/// Create a copy of EditGroup
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? policy = null,Object? phase = null,Object? resources = null,Object? operationCount = null,Object? original = freezed,}) {
  return _then(_EditGroup<S>(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as EditGroupId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as EditorCommitPolicy,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as EditGroupPhase<S>,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as Set<Object>,operationCount: null == operationCount ? _self.operationCount : operationCount // ignore: cast_nullable_to_non_nullable
as int,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as S,
  ));
}

/// Create a copy of EditGroup
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditGroupIdCopyWith<$Res> get id {

  return $EditGroupIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of EditGroup
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditGroupPhaseCopyWith<S, $Res> get phase {

  return $EditGroupPhaseCopyWith<S, $Res>(_self.phase, (value) {
    return _then(_self.copyWith(phase: value));
  });
}
}

/// @nodoc
mixin _$EditingState<S> {

 S? get confirmed; S? get working; Map<EditGroupId, EditGroup<S>> get groups; Object? get failure; bool get available;
/// Create a copy of EditingState
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditingStateCopyWith<S, EditingState<S>> get copyWith => _$EditingStateCopyWithImpl<S, EditingState<S>>(this as EditingState<S>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditingState<S>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditingState<S>&&const DeepCollectionEquality().equals(other.confirmed, _this.confirmed)&&const DeepCollectionEquality().equals(other.working, _this.working)&&const DeepCollectionEquality().equals(other.groups, _this.groups)&&const DeepCollectionEquality().equals(other.failure, _this.failure)&&(identical(other.available, _this.available) || other.available == _this.available));
}


@override
int get hashCode {
  final _this = this as EditingState<S>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.confirmed),const DeepCollectionEquality().hash(_this.working),const DeepCollectionEquality().hash(_this.groups),const DeepCollectionEquality().hash(_this.failure),_this.available);
}

@override
String toString() {
  final _this = this as EditingState<S>;
  return 'EditingState<$S>(confirmed: ${_this.confirmed}, working: ${_this.working}, groups: ${_this.groups}, failure: ${_this.failure}, available: ${_this.available})';
}


}

/// @nodoc
abstract mixin class $EditingStateCopyWith<S,$Res>  {
  factory $EditingStateCopyWith(EditingState<S> value, $Res Function(EditingState<S>) _then) = _$EditingStateCopyWithImpl;
@useResult
$Res call({
 S? confirmed, S? working, Map<EditGroupId, EditGroup<S>> groups, Object? failure, bool available
});




}
/// @nodoc
class _$EditingStateCopyWithImpl<S,$Res>
    implements $EditingStateCopyWith<S, $Res> {
  _$EditingStateCopyWithImpl(this._self, this._then);

  final EditingState<S> _self;
  final $Res Function(EditingState<S>) _then;

/// Create a copy of EditingState
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? confirmed = freezed,Object? working = freezed,Object? groups = null,Object? failure = freezed,Object? available = null,}) {
  return _then(EditingState(
confirmed: freezed == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as S?,working: freezed == working ? _self.working : working // ignore: cast_nullable_to_non_nullable
as S?,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as Map<EditGroupId, EditGroup<S>>,failure: freezed == failure ? _self.failure : failure ,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern matching related methods to [EditingState].
extension EditingStatePatterns<S> on EditingState<S> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditingState<S> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditingState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditingState<S> value)  $default,){
final _that = this;
switch (_that) {
case _EditingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditingState<S> value)?  $default,){
final _that = this;
switch (_that) {
case _EditingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( S? confirmed,  S? working,  Map<EditGroupId, EditGroup<S>> groups,  Object? failure,  bool available)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditingState() when $default != null:
return $default(_that.confirmed,_that.working,_that.groups,_that.failure,_that.available);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( S? confirmed,  S? working,  Map<EditGroupId, EditGroup<S>> groups,  Object? failure,  bool available)  $default,) {final _that = this;
switch (_that) {
case _EditingState():
return $default(_that.confirmed,_that.working,_that.groups,_that.failure,_that.available);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( S? confirmed,  S? working,  Map<EditGroupId, EditGroup<S>> groups,  Object? failure,  bool available)?  $default,) {final _that = this;
switch (_that) {
case _EditingState() when $default != null:
return $default(_that.confirmed,_that.working,_that.groups,_that.failure,_that.available);case _:
  return null;

}
}

}

/// @nodoc


class _EditingState<S> implements EditingState<S> {
  const _EditingState({this.confirmed, this.working,  Map<EditGroupId, EditGroup<S>> groups = const {}, this.failure, this.available = true}): _groups = groups;


@override final  S? confirmed;
@override final  S? working;
 final  Map<EditGroupId, EditGroup<S>> _groups;
@override@JsonKey() Map<EditGroupId, EditGroup<S>> get groups {
  if (_groups is EqualUnmodifiableMapView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_groups);
}

@override final  Object? failure;
@override@JsonKey() final  bool available;

/// Create a copy of EditingState
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditingStateCopyWith<S, _EditingState<S>> get copyWith => __$EditingStateCopyWithImpl<S, _EditingState<S>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditingState<S>&&const DeepCollectionEquality().equals(other.confirmed, confirmed)&&const DeepCollectionEquality().equals(other.working, working)&&const DeepCollectionEquality().equals(other.groups, _groups)&&const DeepCollectionEquality().equals(other.failure, failure)&&(identical(other.available, available) || other.available == available));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(confirmed),const DeepCollectionEquality().hash(working),const DeepCollectionEquality().hash(_groups),const DeepCollectionEquality().hash(failure),available);
}

@override
String toString() {
    return 'EditingState<$S>(confirmed: $confirmed, working: $working, groups: $groups, failure: $failure, available: $available)';
}


}

/// @nodoc
abstract mixin class _$EditingStateCopyWith<S,$Res> implements $EditingStateCopyWith<S, $Res> {
  factory _$EditingStateCopyWith(_EditingState<S> value, $Res Function(_EditingState<S>) _then) = __$EditingStateCopyWithImpl;
@override @useResult
$Res call({
 S? confirmed, S? working, Map<EditGroupId, EditGroup<S>> groups, Object? failure, bool available
});




}
/// @nodoc
class __$EditingStateCopyWithImpl<S,$Res>
    implements _$EditingStateCopyWith<S, $Res> {
  __$EditingStateCopyWithImpl(this._self, this._then);

  final _EditingState<S> _self;
  final $Res Function(_EditingState<S>) _then;

/// Create a copy of EditingState
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? confirmed = freezed,Object? working = freezed,Object? groups = null,Object? failure = freezed,Object? available = null,}) {
  return _then(_EditingState<S>(
confirmed: freezed == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as S?,working: freezed == working ? _self.working : working // ignore: cast_nullable_to_non_nullable
as S?,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as Map<EditGroupId, EditGroup<S>>,failure: freezed == failure ? _self.failure : failure ,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$EditStageResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditStageResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditStageResult()';
}


}

/// @nodoc
class $EditStageResultCopyWith<$Res>  {
$EditStageResultCopyWith(EditStageResult _, $Res Function(EditStageResult) __);
}


/// Adds pattern matching related methods to [EditStageResult].
extension EditStageResultPatterns on EditStageResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EditStaged value)?  staged,TResult Function( EditUnchanged value)?  unchanged,TResult Function( EditStageRejected value)?  rejected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EditStaged() when staged != null:
return staged(_that);case EditUnchanged() when unchanged != null:
return unchanged(_that);case EditStageRejected() when rejected != null:
return rejected(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EditStaged value)  staged,required TResult Function( EditUnchanged value)  unchanged,required TResult Function( EditStageRejected value)  rejected,}){
final _that = this;
switch (_that) {
case EditStaged():
return staged(_that);case EditUnchanged():
return unchanged(_that);case EditStageRejected():
return rejected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EditStaged value)?  staged,TResult? Function( EditUnchanged value)?  unchanged,TResult? Function( EditStageRejected value)?  rejected,}){
final _that = this;
switch (_that) {
case EditStaged() when staged != null:
return staged(_that);case EditUnchanged() when unchanged != null:
return unchanged(_that);case EditStageRejected() when rejected != null:
return rejected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( EditGroupId group)?  staged,TResult Function()?  unchanged,TResult Function( String message,  Object? cause)?  rejected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EditStaged() when staged != null:
return staged(_that.group);case EditUnchanged() when unchanged != null:
return unchanged();case EditStageRejected() when rejected != null:
return rejected(_that.message,_that.cause);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( EditGroupId group)  staged,required TResult Function()  unchanged,required TResult Function( String message,  Object? cause)  rejected,}) {final _that = this;
switch (_that) {
case EditStaged():
return staged(_that.group);case EditUnchanged():
return unchanged();case EditStageRejected():
return rejected(_that.message,_that.cause);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( EditGroupId group)?  staged,TResult? Function()?  unchanged,TResult? Function( String message,  Object? cause)?  rejected,}) {final _that = this;
switch (_that) {
case EditStaged() when staged != null:
return staged(_that.group);case EditUnchanged() when unchanged != null:
return unchanged();case EditStageRejected() when rejected != null:
return rejected(_that.message,_that.cause);case _:
  return null;

}
}

}

/// @nodoc


class EditStaged extends EditStageResult {
  const EditStaged(this.group): super._();


 final  EditGroupId group;

/// Create a copy of EditStageResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditStagedCopyWith<EditStaged> get copyWith => _$EditStagedCopyWithImpl<EditStaged>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditStaged&&(identical(other.group, group) || other.group == group));
}


@override
int get hashCode {
    return Object.hash(runtimeType,group);
}

@override
String toString() {
    return 'EditStageResult.staged(group: $group)';
}


}

/// @nodoc
abstract mixin class $EditStagedCopyWith<$Res> implements $EditStageResultCopyWith<$Res> {
  factory $EditStagedCopyWith(EditStaged value, $Res Function(EditStaged) _then) = _$EditStagedCopyWithImpl;
@useResult
$Res call({
 EditGroupId group
});


$EditGroupIdCopyWith<$Res> get group;

}
/// @nodoc
class _$EditStagedCopyWithImpl<$Res>
    implements $EditStagedCopyWith<$Res> {
  _$EditStagedCopyWithImpl(this._self, this._then);

  final EditStaged _self;
  final $Res Function(EditStaged) _then;

/// Create a copy of EditStageResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? group = null,}) {
  return _then(EditStaged(
null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as EditGroupId,
  ));
}

/// Create a copy of EditStageResult
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditGroupIdCopyWith<$Res> get group {

  return $EditGroupIdCopyWith<$Res>(_self.group, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}

/// @nodoc


class EditUnchanged extends EditStageResult {
  const EditUnchanged(): super._();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditUnchanged);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditStageResult.unchanged()';
}


}




/// @nodoc


class EditStageRejected extends EditStageResult {
  const EditStageRejected(this.message, this.cause): super._();


 final  String message;
 final  Object? cause;

/// Create a copy of EditStageResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditStageRejectedCopyWith<EditStageRejected> get copyWith => _$EditStageRejectedCopyWithImpl<EditStageRejected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditStageRejected&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'EditStageResult.rejected(message: $message, cause: $cause)';
}


}

/// @nodoc
abstract mixin class $EditStageRejectedCopyWith<$Res> implements $EditStageResultCopyWith<$Res> {
  factory $EditStageRejectedCopyWith(EditStageRejected value, $Res Function(EditStageRejected) _then) = _$EditStageRejectedCopyWithImpl;
@useResult
$Res call({
 String message, Object? cause
});




}
/// @nodoc
class _$EditStageRejectedCopyWithImpl<$Res>
    implements $EditStageRejectedCopyWith<$Res> {
  _$EditStageRejectedCopyWithImpl(this._self, this._then);

  final EditStageRejected _self;
  final $Res Function(EditStageRejected) _then;

/// Create a copy of EditStageResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = freezed,}) {
  return _then(EditStageRejected(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,freezed == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc
mixin _$EditGroupReview<S,E> {

 S get saved; S get original; S get beforeGroup; S get proposal; Set<int> get operations; List<E> get edits; List<EditConflictEvidence> get conflicts; List<EditorDiagnostic> get diagnostics;
/// Create a copy of EditGroupReview
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditGroupReviewCopyWith<S, E, EditGroupReview<S, E>> get copyWith => _$EditGroupReviewCopyWithImpl<S, E, EditGroupReview<S, E>>(this as EditGroupReview<S, E>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditGroupReview<S, E>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditGroupReview<S, E>&&const DeepCollectionEquality().equals(other.saved, _this.saved)&&const DeepCollectionEquality().equals(other.original, _this.original)&&const DeepCollectionEquality().equals(other.beforeGroup, _this.beforeGroup)&&const DeepCollectionEquality().equals(other.proposal, _this.proposal)&&const DeepCollectionEquality().equals(other.operations, _this.operations)&&const DeepCollectionEquality().equals(other.edits, _this.edits)&&const DeepCollectionEquality().equals(other.conflicts, _this.conflicts)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as EditGroupReview<S, E>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.saved),const DeepCollectionEquality().hash(_this.original),const DeepCollectionEquality().hash(_this.beforeGroup),const DeepCollectionEquality().hash(_this.proposal),const DeepCollectionEquality().hash(_this.operations),const DeepCollectionEquality().hash(_this.edits),const DeepCollectionEquality().hash(_this.conflicts),const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as EditGroupReview<S, E>;
  return 'EditGroupReview<$S, $E>(saved: ${_this.saved}, original: ${_this.original}, beforeGroup: ${_this.beforeGroup}, proposal: ${_this.proposal}, operations: ${_this.operations}, edits: ${_this.edits}, conflicts: ${_this.conflicts}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $EditGroupReviewCopyWith<S,E,$Res>  {
  factory $EditGroupReviewCopyWith(EditGroupReview<S, E> value, $Res Function(EditGroupReview<S, E>) _then) = _$EditGroupReviewCopyWithImpl;
@useResult
$Res call({
 S saved, S original, S beforeGroup, S proposal, Set<int> operations, List<E> edits, List<EditConflictEvidence> conflicts, List<EditorDiagnostic> diagnostics
});




}
/// @nodoc
class _$EditGroupReviewCopyWithImpl<S,E,$Res>
    implements $EditGroupReviewCopyWith<S, E, $Res> {
  _$EditGroupReviewCopyWithImpl(this._self, this._then);

  final EditGroupReview<S, E> _self;
  final $Res Function(EditGroupReview<S, E>) _then;

/// Create a copy of EditGroupReview
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? saved = freezed,Object? original = freezed,Object? beforeGroup = freezed,Object? proposal = freezed,Object? operations = null,Object? edits = null,Object? conflicts = null,Object? diagnostics = null,}) {
  return _then(EditGroupReview(
saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as S,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as S,beforeGroup: freezed == beforeGroup ? _self.beforeGroup : beforeGroup // ignore: cast_nullable_to_non_nullable
as S,proposal: freezed == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as S,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as Set<int>,edits: null == edits ? _self.edits : edits // ignore: cast_nullable_to_non_nullable
as List<E>,conflicts: null == conflicts ? _self.conflicts : conflicts // ignore: cast_nullable_to_non_nullable
as List<EditConflictEvidence>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}

}


/// Adds pattern matching related methods to [EditGroupReview].
extension EditGroupReviewPatterns<S,E> on EditGroupReview<S, E> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditGroupReview<S, E> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditGroupReview() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditGroupReview<S, E> value)  $default,){
final _that = this;
switch (_that) {
case _EditGroupReview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditGroupReview<S, E> value)?  $default,){
final _that = this;
switch (_that) {
case _EditGroupReview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( S saved,  S original,  S beforeGroup,  S proposal,  Set<int> operations,  List<E> edits,  List<EditConflictEvidence> conflicts,  List<EditorDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditGroupReview() when $default != null:
return $default(_that.saved,_that.original,_that.beforeGroup,_that.proposal,_that.operations,_that.edits,_that.conflicts,_that.diagnostics);case _:
  return orElse();

}
}
/// A method similar to a `switch` method, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( S saved,  S original,  S beforeGroup,  S proposal,  Set<int> operations,  List<E> edits,  List<EditConflictEvidence> conflicts,  List<EditorDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _EditGroupReview():
return $default(_that.saved,_that.original,_that.beforeGroup,_that.proposal,_that.operations,_that.edits,_that.conflicts,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( S saved,  S original,  S beforeGroup,  S proposal,  Set<int> operations,  List<E> edits,  List<EditConflictEvidence> conflicts,  List<EditorDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _EditGroupReview() when $default != null:
return $default(_that.saved,_that.original,_that.beforeGroup,_that.proposal,_that.operations,_that.edits,_that.conflicts,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _EditGroupReview<S,E> implements EditGroupReview<S, E> {
  const _EditGroupReview({required this.saved, required this.original, required this.beforeGroup, required this.proposal, required  Set<int> operations, required  List<E> edits,  List<EditConflictEvidence> conflicts = const [],  List<EditorDiagnostic> diagnostics = const []}): _operations = operations,_edits = edits,_conflicts = conflicts,_diagnostics = diagnostics;


@override final  S saved;
@override final  S original;
@override final  S beforeGroup;
@override final  S proposal;
 final  Set<int> _operations;
@override Set<int> get operations {
  if (_operations is EqualUnmodifiableSetView) return _operations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_operations);
}

 final  List<E> _edits;
@override List<E> get edits {
  if (_edits is EqualUnmodifiableListView) return _edits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_edits);
}

 final  List<EditConflictEvidence> _conflicts;
@override@JsonKey() List<EditConflictEvidence> get conflicts {
  if (_conflicts is EqualUnmodifiableListView) return _conflicts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conflicts);
}

 final  List<EditorDiagnostic> _diagnostics;
@override@JsonKey() List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of EditGroupReview
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditGroupReviewCopyWith<S, E, _EditGroupReview<S, E>> get copyWith => __$EditGroupReviewCopyWithImpl<S, E, _EditGroupReview<S, E>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditGroupReview<S, E>&&const DeepCollectionEquality().equals(other.saved, saved)&&const DeepCollectionEquality().equals(other.original, original)&&const DeepCollectionEquality().equals(other.beforeGroup, beforeGroup)&&const DeepCollectionEquality().equals(other.proposal, proposal)&&const DeepCollectionEquality().equals(other.operations, _operations)&&const DeepCollectionEquality().equals(other.edits, _edits)&&const DeepCollectionEquality().equals(other.conflicts, _conflicts)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(saved),const DeepCollectionEquality().hash(original),const DeepCollectionEquality().hash(beforeGroup),const DeepCollectionEquality().hash(proposal),const DeepCollectionEquality().hash(_operations),const DeepCollectionEquality().hash(_edits),const DeepCollectionEquality().hash(_conflicts),const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'EditGroupReview<$S, $E>(saved: $saved, original: $original, beforeGroup: $beforeGroup, proposal: $proposal, operations: $operations, edits: $edits, conflicts: $conflicts, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$EditGroupReviewCopyWith<S,E,$Res> implements $EditGroupReviewCopyWith<S, E, $Res> {
  factory _$EditGroupReviewCopyWith(_EditGroupReview<S, E> value, $Res Function(_EditGroupReview<S, E>) _then) = __$EditGroupReviewCopyWithImpl;
@override @useResult
$Res call({
 S saved, S original, S beforeGroup, S proposal, Set<int> operations, List<E> edits, List<EditConflictEvidence> conflicts, List<EditorDiagnostic> diagnostics
});




}
/// @nodoc
class __$EditGroupReviewCopyWithImpl<S,E,$Res>
    implements _$EditGroupReviewCopyWith<S, E, $Res> {
  __$EditGroupReviewCopyWithImpl(this._self, this._then);

  final _EditGroupReview<S, E> _self;
  final $Res Function(_EditGroupReview<S, E>) _then;

/// Create a copy of EditGroupReview
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? saved = freezed,Object? original = freezed,Object? beforeGroup = freezed,Object? proposal = freezed,Object? operations = null,Object? edits = null,Object? conflicts = null,Object? diagnostics = null,}) {
  return _then(_EditGroupReview<S, E>(
saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as S,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as S,beforeGroup: freezed == beforeGroup ? _self.beforeGroup : beforeGroup // ignore: cast_nullable_to_non_nullable
as S,proposal: freezed == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as S,operations: null == operations ? _self._operations : operations // ignore: cast_nullable_to_non_nullable
as Set<int>,edits: null == edits ? _self._edits : edits // ignore: cast_nullable_to_non_nullable
as List<E>,conflicts: null == conflicts ? _self._conflicts : conflicts // ignore: cast_nullable_to_non_nullable
as List<EditConflictEvidence>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}


}

// dart format on
