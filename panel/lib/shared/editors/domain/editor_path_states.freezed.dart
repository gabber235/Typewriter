// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_path_states.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorPathRecord {

 EditorPathProgress? get progress; EditorInteractionSession? get gate;
/// Create a copy of EditorPathRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorPathRecordCopyWith<EditorPathRecord> get copyWith => _$EditorPathRecordCopyWithImpl<EditorPathRecord>(this as EditorPathRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorPathRecord&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.gate, gate) || other.gate == gate));
}


@override
int get hashCode => Object.hash(runtimeType,progress,gate);

@override
String toString() {
  return 'EditorPathRecord(progress: $progress, gate: $gate)';
}


}

/// @nodoc
abstract mixin class $EditorPathRecordCopyWith<$Res>  {
  factory $EditorPathRecordCopyWith(EditorPathRecord value, $Res Function(EditorPathRecord) _then) = _$EditorPathRecordCopyWithImpl;
@useResult
$Res call({
 EditorPathProgress? progress, EditorInteractionSession? gate
});


$EditorPathProgressCopyWith<$Res>? get progress;

}
/// @nodoc
class _$EditorPathRecordCopyWithImpl<$Res>
    implements $EditorPathRecordCopyWith<$Res> {
  _$EditorPathRecordCopyWithImpl(this._self, this._then);

  final EditorPathRecord _self;
  final $Res Function(EditorPathRecord) _then;

/// Create a copy of EditorPathRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? progress = freezed,Object? gate = freezed,}) {
  return _then(_self.copyWith(
progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as EditorPathProgress?,gate: freezed == gate ? _self.gate : gate // ignore: cast_nullable_to_non_nullable
as EditorInteractionSession?,
  ));
}
/// Create a copy of EditorPathRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPathProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $EditorPathProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// Adds pattern-matching-related methods to [EditorPathRecord].
extension EditorPathRecordPatterns on EditorPathRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorPathRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorPathRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorPathRecord value)  $default,){
final _that = this;
switch (_that) {
case _EditorPathRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorPathRecord value)?  $default,){
final _that = this;
switch (_that) {
case _EditorPathRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorPathProgress? progress,  EditorInteractionSession? gate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorPathRecord() when $default != null:
return $default(_that.progress,_that.gate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorPathProgress? progress,  EditorInteractionSession? gate)  $default,) {final _that = this;
switch (_that) {
case _EditorPathRecord():
return $default(_that.progress,_that.gate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorPathProgress? progress,  EditorInteractionSession? gate)?  $default,) {final _that = this;
switch (_that) {
case _EditorPathRecord() when $default != null:
return $default(_that.progress,_that.gate);case _:
  return null;

}
}

}

/// @nodoc


class _EditorPathRecord extends EditorPathRecord {
  const _EditorPathRecord({this.progress, this.gate}): super._();
  

@override final  EditorPathProgress? progress;
@override final  EditorInteractionSession? gate;

/// Create a copy of EditorPathRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorPathRecordCopyWith<_EditorPathRecord> get copyWith => __$EditorPathRecordCopyWithImpl<_EditorPathRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorPathRecord&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.gate, gate) || other.gate == gate));
}


@override
int get hashCode => Object.hash(runtimeType,progress,gate);

@override
String toString() {
  return 'EditorPathRecord(progress: $progress, gate: $gate)';
}


}

/// @nodoc
abstract mixin class _$EditorPathRecordCopyWith<$Res> implements $EditorPathRecordCopyWith<$Res> {
  factory _$EditorPathRecordCopyWith(_EditorPathRecord value, $Res Function(_EditorPathRecord) _then) = __$EditorPathRecordCopyWithImpl;
@override @useResult
$Res call({
 EditorPathProgress? progress, EditorInteractionSession? gate
});


@override $EditorPathProgressCopyWith<$Res>? get progress;

}
/// @nodoc
class __$EditorPathRecordCopyWithImpl<$Res>
    implements _$EditorPathRecordCopyWith<$Res> {
  __$EditorPathRecordCopyWithImpl(this._self, this._then);

  final _EditorPathRecord _self;
  final $Res Function(_EditorPathRecord) _then;

/// Create a copy of EditorPathRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? progress = freezed,Object? gate = freezed,}) {
  return _then(_EditorPathRecord(
progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as EditorPathProgress?,gate: freezed == gate ? _self.gate : gate // ignore: cast_nullable_to_non_nullable
as EditorInteractionSession?,
  ));
}

/// Create a copy of EditorPathRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorPathProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $EditorPathProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}

/// @nodoc
mixin _$EditorPathProgress {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorPathProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorPathProgress()';
}


}

/// @nodoc
class $EditorPathProgressCopyWith<$Res>  {
$EditorPathProgressCopyWith(EditorPathProgress _, $Res Function(EditorPathProgress) __);
}


/// Adds pattern-matching-related methods to [EditorPathProgress].
extension EditorPathProgressPatterns on EditorPathProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PendingPathProgress value)?  pending,TResult Function( SavingPathProgress value)?  saving,TResult Function( FailedPathProgress value)?  failed,TResult Function( ContendedPathProgress value)?  contended,TResult Function( ConflictedPathProgress value)?  conflicted,TResult Function( SettledPathProgress value)?  settled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PendingPathProgress() when pending != null:
return pending(_that);case SavingPathProgress() when saving != null:
return saving(_that);case FailedPathProgress() when failed != null:
return failed(_that);case ContendedPathProgress() when contended != null:
return contended(_that);case ConflictedPathProgress() when conflicted != null:
return conflicted(_that);case SettledPathProgress() when settled != null:
return settled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PendingPathProgress value)  pending,required TResult Function( SavingPathProgress value)  saving,required TResult Function( FailedPathProgress value)  failed,required TResult Function( ContendedPathProgress value)  contended,required TResult Function( ConflictedPathProgress value)  conflicted,required TResult Function( SettledPathProgress value)  settled,}){
final _that = this;
switch (_that) {
case PendingPathProgress():
return pending(_that);case SavingPathProgress():
return saving(_that);case FailedPathProgress():
return failed(_that);case ContendedPathProgress():
return contended(_that);case ConflictedPathProgress():
return conflicted(_that);case SettledPathProgress():
return settled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PendingPathProgress value)?  pending,TResult? Function( SavingPathProgress value)?  saving,TResult? Function( FailedPathProgress value)?  failed,TResult? Function( ContendedPathProgress value)?  contended,TResult? Function( ConflictedPathProgress value)?  conflicted,TResult? Function( SettledPathProgress value)?  settled,}){
final _that = this;
switch (_that) {
case PendingPathProgress() when pending != null:
return pending(_that);case SavingPathProgress() when saving != null:
return saving(_that);case FailedPathProgress() when failed != null:
return failed(_that);case ContendedPathProgress() when contended != null:
return contended(_that);case ConflictedPathProgress() when conflicted != null:
return conflicted(_that);case SettledPathProgress() when settled != null:
return settled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  pending,TResult Function()?  saving,TResult Function( List<TypeDiagnostic> diagnostics)?  failed,TResult Function()?  contended,TResult Function( EditorPathConflict conflict)?  conflicted,TResult Function( EditorSavePhase phase)?  settled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PendingPathProgress() when pending != null:
return pending();case SavingPathProgress() when saving != null:
return saving();case FailedPathProgress() when failed != null:
return failed(_that.diagnostics);case ContendedPathProgress() when contended != null:
return contended();case ConflictedPathProgress() when conflicted != null:
return conflicted(_that.conflict);case SettledPathProgress() when settled != null:
return settled(_that.phase);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  pending,required TResult Function()  saving,required TResult Function( List<TypeDiagnostic> diagnostics)  failed,required TResult Function()  contended,required TResult Function( EditorPathConflict conflict)  conflicted,required TResult Function( EditorSavePhase phase)  settled,}) {final _that = this;
switch (_that) {
case PendingPathProgress():
return pending();case SavingPathProgress():
return saving();case FailedPathProgress():
return failed(_that.diagnostics);case ContendedPathProgress():
return contended();case ConflictedPathProgress():
return conflicted(_that.conflict);case SettledPathProgress():
return settled(_that.phase);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  pending,TResult? Function()?  saving,TResult? Function( List<TypeDiagnostic> diagnostics)?  failed,TResult? Function()?  contended,TResult? Function( EditorPathConflict conflict)?  conflicted,TResult? Function( EditorSavePhase phase)?  settled,}) {final _that = this;
switch (_that) {
case PendingPathProgress() when pending != null:
return pending();case SavingPathProgress() when saving != null:
return saving();case FailedPathProgress() when failed != null:
return failed(_that.diagnostics);case ContendedPathProgress() when contended != null:
return contended();case ConflictedPathProgress() when conflicted != null:
return conflicted(_that.conflict);case SettledPathProgress() when settled != null:
return settled(_that.phase);case _:
  return null;

}
}

}

/// @nodoc


class PendingPathProgress implements EditorPathProgress {
  const PendingPathProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingPathProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorPathProgress.pending()';
}


}




/// @nodoc


class SavingPathProgress implements EditorPathProgress {
  const SavingPathProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavingPathProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorPathProgress.saving()';
}


}




/// @nodoc


class FailedPathProgress implements EditorPathProgress {
  const FailedPathProgress(final  List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics;
  

 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of EditorPathProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailedPathProgressCopyWith<FailedPathProgress> get copyWith => _$FailedPathProgressCopyWithImpl<FailedPathProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FailedPathProgress&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

@override
String toString() {
  return 'EditorPathProgress.failed(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $FailedPathProgressCopyWith<$Res> implements $EditorPathProgressCopyWith<$Res> {
  factory $FailedPathProgressCopyWith(FailedPathProgress value, $Res Function(FailedPathProgress) _then) = _$FailedPathProgressCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$FailedPathProgressCopyWithImpl<$Res>
    implements $FailedPathProgressCopyWith<$Res> {
  _$FailedPathProgressCopyWithImpl(this._self, this._then);

  final FailedPathProgress _self;
  final $Res Function(FailedPathProgress) _then;

/// Create a copy of EditorPathProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(FailedPathProgress(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

/// @nodoc


class ContendedPathProgress implements EditorPathProgress {
  const ContendedPathProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContendedPathProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditorPathProgress.contended()';
}


}




/// @nodoc


class ConflictedPathProgress implements EditorPathProgress {
  const ConflictedPathProgress(this.conflict);
  

 final  EditorPathConflict conflict;

/// Create a copy of EditorPathProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConflictedPathProgressCopyWith<ConflictedPathProgress> get copyWith => _$ConflictedPathProgressCopyWithImpl<ConflictedPathProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictedPathProgress&&(identical(other.conflict, conflict) || other.conflict == conflict));
}


@override
int get hashCode => Object.hash(runtimeType,conflict);

@override
String toString() {
  return 'EditorPathProgress.conflicted(conflict: $conflict)';
}


}

/// @nodoc
abstract mixin class $ConflictedPathProgressCopyWith<$Res> implements $EditorPathProgressCopyWith<$Res> {
  factory $ConflictedPathProgressCopyWith(ConflictedPathProgress value, $Res Function(ConflictedPathProgress) _then) = _$ConflictedPathProgressCopyWithImpl;
@useResult
$Res call({
 EditorPathConflict conflict
});




}
/// @nodoc
class _$ConflictedPathProgressCopyWithImpl<$Res>
    implements $ConflictedPathProgressCopyWith<$Res> {
  _$ConflictedPathProgressCopyWithImpl(this._self, this._then);

  final ConflictedPathProgress _self;
  final $Res Function(ConflictedPathProgress) _then;

/// Create a copy of EditorPathProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conflict = null,}) {
  return _then(ConflictedPathProgress(
null == conflict ? _self.conflict : conflict // ignore: cast_nullable_to_non_nullable
as EditorPathConflict,
  ));
}


}

/// @nodoc


class SettledPathProgress implements EditorPathProgress {
  const SettledPathProgress(this.phase): assert(phase == EditorSavePhase.saved || phase == EditorSavePhase.sessionOnly, 'A settled path is either saved or session only.');
  

 final  EditorSavePhase phase;

/// Create a copy of EditorPathProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettledPathProgressCopyWith<SettledPathProgress> get copyWith => _$SettledPathProgressCopyWithImpl<SettledPathProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettledPathProgress&&(identical(other.phase, phase) || other.phase == phase));
}


@override
int get hashCode => Object.hash(runtimeType,phase);

@override
String toString() {
  return 'EditorPathProgress.settled(phase: $phase)';
}


}

/// @nodoc
abstract mixin class $SettledPathProgressCopyWith<$Res> implements $EditorPathProgressCopyWith<$Res> {
  factory $SettledPathProgressCopyWith(SettledPathProgress value, $Res Function(SettledPathProgress) _then) = _$SettledPathProgressCopyWithImpl;
@useResult
$Res call({
 EditorSavePhase phase
});




}
/// @nodoc
class _$SettledPathProgressCopyWithImpl<$Res>
    implements $SettledPathProgressCopyWith<$Res> {
  _$SettledPathProgressCopyWithImpl(this._self, this._then);

  final SettledPathProgress _self;
  final $Res Function(SettledPathProgress) _then;

/// Create a copy of EditorPathProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phase = null,}) {
  return _then(SettledPathProgress(
null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as EditorSavePhase,
  ));
}


}

// dart format on
