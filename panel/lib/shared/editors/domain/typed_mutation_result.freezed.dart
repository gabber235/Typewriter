// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'typed_mutation_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TypedMutationResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TypedMutationResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TypedMutationResult()';
}


}

/// @nodoc
class $TypedMutationResultCopyWith<$Res>  {
$TypedMutationResultCopyWith(TypedMutationResult _, $Res Function(TypedMutationResult) __);
}


/// Adds pattern matching related methods to [TypedMutationResult].
extension TypedMutationResultPatterns on TypedMutationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MutationSuccess value)?  success,TResult Function( MutationConflict value)?  conflict,TResult Function( MutationInvalid value)?  invalid,TResult Function( MutationPermissionDenied value)?  permissionDenied,TResult Function( MutationUncertain value)?  uncertain,TResult Function( MutationUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MutationSuccess() when success != null:
return success(_that);case MutationConflict() when conflict != null:
return conflict(_that);case MutationInvalid() when invalid != null:
return invalid(_that);case MutationPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case MutationUncertain() when uncertain != null:
return uncertain(_that);case MutationUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MutationSuccess value)  success,required TResult Function( MutationConflict value)  conflict,required TResult Function( MutationInvalid value)  invalid,required TResult Function( MutationPermissionDenied value)  permissionDenied,required TResult Function( MutationUncertain value)  uncertain,required TResult Function( MutationUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case MutationSuccess():
return success(_that);case MutationConflict():
return conflict(_that);case MutationInvalid():
return invalid(_that);case MutationPermissionDenied():
return permissionDenied(_that);case MutationUncertain():
return uncertain(_that);case MutationUnavailable():
return unavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MutationSuccess value)?  success,TResult? Function( MutationConflict value)?  conflict,TResult? Function( MutationInvalid value)?  invalid,TResult? Function( MutationPermissionDenied value)?  permissionDenied,TResult? Function( MutationUncertain value)?  uncertain,TResult? Function( MutationUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case MutationSuccess() when success != null:
return success(_that);case MutationConflict() when conflict != null:
return conflict(_that);case MutationInvalid() when invalid != null:
return invalid(_that);case MutationPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case MutationUncertain() when uncertain != null:
return uncertain(_that);case MutationUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int revision,  skir.DataValue value)?  success,TResult Function( int expectedRevision,  int actualRevision,  skir.DataValue actualValue)?  conflict,TResult Function( List<EditorDiagnostic> diagnostics)?  invalid,TResult Function( String message)?  permissionDenied,TResult Function( String message,  Object cause,  StackTrace stackTrace,  Future<TypedMutationResult> Function()? replay,  Object? submissionId)?  uncertain,TResult Function( List<EditorDiagnostic> diagnostics)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MutationSuccess() when success != null:
return success(_that.revision,_that.value);case MutationConflict() when conflict != null:
return conflict(_that.expectedRevision,_that.actualRevision,_that.actualValue);case MutationInvalid() when invalid != null:
return invalid(_that.diagnostics);case MutationPermissionDenied() when permissionDenied != null:
return permissionDenied(_that.message);case MutationUncertain() when uncertain != null:
return uncertain(_that.message,_that.cause,_that.stackTrace,_that.replay,_that.submissionId);case MutationUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int revision,  skir.DataValue value)  success,required TResult Function( int expectedRevision,  int actualRevision,  skir.DataValue actualValue)  conflict,required TResult Function( List<EditorDiagnostic> diagnostics)  invalid,required TResult Function( String message)  permissionDenied,required TResult Function( String message,  Object cause,  StackTrace stackTrace,  Future<TypedMutationResult> Function()? replay,  Object? submissionId)  uncertain,required TResult Function( List<EditorDiagnostic> diagnostics)  unavailable,}) {final _that = this;
switch (_that) {
case MutationSuccess():
return success(_that.revision,_that.value);case MutationConflict():
return conflict(_that.expectedRevision,_that.actualRevision,_that.actualValue);case MutationInvalid():
return invalid(_that.diagnostics);case MutationPermissionDenied():
return permissionDenied(_that.message);case MutationUncertain():
return uncertain(_that.message,_that.cause,_that.stackTrace,_that.replay,_that.submissionId);case MutationUnavailable():
return unavailable(_that.diagnostics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int revision,  skir.DataValue value)?  success,TResult? Function( int expectedRevision,  int actualRevision,  skir.DataValue actualValue)?  conflict,TResult? Function( List<EditorDiagnostic> diagnostics)?  invalid,TResult? Function( String message)?  permissionDenied,TResult? Function( String message,  Object cause,  StackTrace stackTrace,  Future<TypedMutationResult> Function()? replay,  Object? submissionId)?  uncertain,TResult? Function( List<EditorDiagnostic> diagnostics)?  unavailable,}) {final _that = this;
switch (_that) {
case MutationSuccess() when success != null:
return success(_that.revision,_that.value);case MutationConflict() when conflict != null:
return conflict(_that.expectedRevision,_that.actualRevision,_that.actualValue);case MutationInvalid() when invalid != null:
return invalid(_that.diagnostics);case MutationPermissionDenied() when permissionDenied != null:
return permissionDenied(_that.message);case MutationUncertain() when uncertain != null:
return uncertain(_that.message,_that.cause,_that.stackTrace,_that.replay,_that.submissionId);case MutationUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class MutationSuccess implements TypedMutationResult {
  const MutationSuccess({required this.revision, required this.value}): assert(revision >= 0, 'Revision must not be negative.');


 final  int revision;
 final  skir.DataValue value;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationSuccessCopyWith<MutationSuccess> get copyWith => _$MutationSuccessCopyWithImpl<MutationSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationSuccess&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,revision,value);
}

@override
String toString() {
    return 'TypedMutationResult.success(revision: $revision, value: $value)';
}


}

/// @nodoc
abstract mixin class $MutationSuccessCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationSuccessCopyWith(MutationSuccess value, $Res Function(MutationSuccess) _then) = _$MutationSuccessCopyWithImpl;
@useResult
$Res call({
 int revision, skir.DataValue value
});




}
/// @nodoc
class _$MutationSuccessCopyWithImpl<$Res>
    implements $MutationSuccessCopyWith<$Res> {
  _$MutationSuccessCopyWithImpl(this._self, this._then);

  final MutationSuccess _self;
  final $Res Function(MutationSuccess) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? revision = null,Object? value = null,}) {
  return _then(MutationSuccess(
revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,
  ));
}


}

/// @nodoc


class MutationConflict implements TypedMutationResult {
  const MutationConflict({required this.expectedRevision, required this.actualRevision, required this.actualValue});


 final  int expectedRevision;
 final  int actualRevision;
 final  skir.DataValue actualValue;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationConflictCopyWith<MutationConflict> get copyWith => _$MutationConflictCopyWithImpl<MutationConflict>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationConflict&&(identical(other.expectedRevision, expectedRevision) || other.expectedRevision == expectedRevision)&&(identical(other.actualRevision, actualRevision) || other.actualRevision == actualRevision)&&(identical(other.actualValue, actualValue) || other.actualValue == actualValue));
}


@override
int get hashCode {
    return Object.hash(runtimeType,expectedRevision,actualRevision,actualValue);
}

@override
String toString() {
    return 'TypedMutationResult.conflict(expectedRevision: $expectedRevision, actualRevision: $actualRevision, actualValue: $actualValue)';
}


}

/// @nodoc
abstract mixin class $MutationConflictCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationConflictCopyWith(MutationConflict value, $Res Function(MutationConflict) _then) = _$MutationConflictCopyWithImpl;
@useResult
$Res call({
 int expectedRevision, int actualRevision, skir.DataValue actualValue
});




}
/// @nodoc
class _$MutationConflictCopyWithImpl<$Res>
    implements $MutationConflictCopyWith<$Res> {
  _$MutationConflictCopyWithImpl(this._self, this._then);

  final MutationConflict _self;
  final $Res Function(MutationConflict) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expectedRevision = null,Object? actualRevision = null,Object? actualValue = null,}) {
  return _then(MutationConflict(
expectedRevision: null == expectedRevision ? _self.expectedRevision : expectedRevision // ignore: cast_nullable_to_non_nullable
as int,actualRevision: null == actualRevision ? _self.actualRevision : actualRevision // ignore: cast_nullable_to_non_nullable
as int,actualValue: null == actualValue ? _self.actualValue : actualValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,
  ));
}


}

/// @nodoc


class MutationInvalid implements TypedMutationResult {
   MutationInvalid( List<EditorDiagnostic> diagnostics): assert(diagnostics.isNotEmpty, 'Diagnostics must not be empty.'),_diagnostics = diagnostics;


 final  List<EditorDiagnostic> _diagnostics;
 List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationInvalidCopyWith<MutationInvalid> get copyWith => _$MutationInvalidCopyWithImpl<MutationInvalid>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationInvalid&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'TypedMutationResult.invalid(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $MutationInvalidCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationInvalidCopyWith(MutationInvalid value, $Res Function(MutationInvalid) _then) = _$MutationInvalidCopyWithImpl;
@useResult
$Res call({
 List<EditorDiagnostic> diagnostics
});




}
/// @nodoc
class _$MutationInvalidCopyWithImpl<$Res>
    implements $MutationInvalidCopyWith<$Res> {
  _$MutationInvalidCopyWithImpl(this._self, this._then);

  final MutationInvalid _self;
  final $Res Function(MutationInvalid) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(MutationInvalid(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}


}

/// @nodoc


class MutationPermissionDenied implements TypedMutationResult {
  const MutationPermissionDenied(this.message);


 final  String message;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationPermissionDeniedCopyWith<MutationPermissionDenied> get copyWith => _$MutationPermissionDeniedCopyWithImpl<MutationPermissionDenied>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationPermissionDenied&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'TypedMutationResult.permissionDenied(message: $message)';
}


}

/// @nodoc
abstract mixin class $MutationPermissionDeniedCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationPermissionDeniedCopyWith(MutationPermissionDenied value, $Res Function(MutationPermissionDenied) _then) = _$MutationPermissionDeniedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$MutationPermissionDeniedCopyWithImpl<$Res>
    implements $MutationPermissionDeniedCopyWith<$Res> {
  _$MutationPermissionDeniedCopyWithImpl(this._self, this._then);

  final MutationPermissionDenied _self;
  final $Res Function(MutationPermissionDenied) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(MutationPermissionDenied(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MutationUncertain implements TypedMutationResult {
  const MutationUncertain({required this.message, required this.cause, required this.stackTrace, this.replay, this.submissionId});


 final  String message;
 final  Object cause;
 final  StackTrace stackTrace;
 final  Future<TypedMutationResult> Function()? replay;
 final  Object? submissionId;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationUncertainCopyWith<MutationUncertain> get copyWith => _$MutationUncertainCopyWithImpl<MutationUncertain>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationUncertain&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace)&&(identical(other.replay, replay) || other.replay == replay)&&const DeepCollectionEquality().equals(other.submissionId, submissionId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause),stackTrace,replay,const DeepCollectionEquality().hash(submissionId));
}

@override
String toString() {
    return 'TypedMutationResult.uncertain(message: $message, cause: $cause, stackTrace: $stackTrace, replay: $replay, submissionId: $submissionId)';
}


}

/// @nodoc
abstract mixin class $MutationUncertainCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationUncertainCopyWith(MutationUncertain value, $Res Function(MutationUncertain) _then) = _$MutationUncertainCopyWithImpl;
@useResult
$Res call({
 String message, Object cause, StackTrace stackTrace, Future<TypedMutationResult> Function()? replay, Object? submissionId
});




}
/// @nodoc
class _$MutationUncertainCopyWithImpl<$Res>
    implements $MutationUncertainCopyWith<$Res> {
  _$MutationUncertainCopyWithImpl(this._self, this._then);

  final MutationUncertain _self;
  final $Res Function(MutationUncertain) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = null,Object? stackTrace = null,Object? replay = freezed,Object? submissionId = freezed,}) {
  return _then(MutationUncertain(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,cause: null == cause ? _self.cause : cause ,stackTrace: null == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace,replay: freezed == replay ? _self.replay : replay // ignore: cast_nullable_to_non_nullable
as Future<TypedMutationResult> Function()?,submissionId: freezed == submissionId ? _self.submissionId : submissionId ,
  ));
}


}

/// @nodoc


class MutationUnavailable implements TypedMutationResult {
   MutationUnavailable( List<EditorDiagnostic> diagnostics): assert(diagnostics.isNotEmpty, 'Diagnostics must not be empty.'),_diagnostics = diagnostics;


 final  List<EditorDiagnostic> _diagnostics;
 List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MutationUnavailableCopyWith<MutationUnavailable> get copyWith => _$MutationUnavailableCopyWithImpl<MutationUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MutationUnavailable&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'TypedMutationResult.unavailable(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $MutationUnavailableCopyWith<$Res> implements $TypedMutationResultCopyWith<$Res> {
  factory $MutationUnavailableCopyWith(MutationUnavailable value, $Res Function(MutationUnavailable) _then) = _$MutationUnavailableCopyWithImpl;
@useResult
$Res call({
 List<EditorDiagnostic> diagnostics
});




}
/// @nodoc
class _$MutationUnavailableCopyWithImpl<$Res>
    implements $MutationUnavailableCopyWith<$Res> {
  _$MutationUnavailableCopyWithImpl(this._self, this._then);

  final MutationUnavailable _self;
  final $Res Function(MutationUnavailable) _then;

/// Create a copy of TypedMutationResult
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(MutationUnavailable(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}


}

// dart format on
