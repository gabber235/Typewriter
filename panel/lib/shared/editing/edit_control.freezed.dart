// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_control.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditControlState {

 bool get hasWork; bool get showControls; bool get canApply; bool get canDiscard; bool get canRetry; bool get hasSubmittedWork; bool get hasLaterEdits; String? get status; List<EditorDiagnostic> get diagnostics;
/// Create a copy of EditControlState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditControlStateCopyWith<EditControlState> get copyWith => _$EditControlStateCopyWithImpl<EditControlState>(this as EditControlState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditControlState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditControlState&&(identical(other.hasWork, _this.hasWork) || other.hasWork == _this.hasWork)&&(identical(other.showControls, _this.showControls) || other.showControls == _this.showControls)&&(identical(other.canApply, _this.canApply) || other.canApply == _this.canApply)&&(identical(other.canDiscard, _this.canDiscard) || other.canDiscard == _this.canDiscard)&&(identical(other.canRetry, _this.canRetry) || other.canRetry == _this.canRetry)&&(identical(other.hasSubmittedWork, _this.hasSubmittedWork) || other.hasSubmittedWork == _this.hasSubmittedWork)&&(identical(other.hasLaterEdits, _this.hasLaterEdits) || other.hasLaterEdits == _this.hasLaterEdits)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as EditControlState;
  return Object.hash(runtimeType,_this.hasWork,_this.showControls,_this.canApply,_this.canDiscard,_this.canRetry,_this.hasSubmittedWork,_this.hasLaterEdits,_this.status,const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as EditControlState;
  return 'EditControlState(hasWork: ${_this.hasWork}, showControls: ${_this.showControls}, canApply: ${_this.canApply}, canDiscard: ${_this.canDiscard}, canRetry: ${_this.canRetry}, hasSubmittedWork: ${_this.hasSubmittedWork}, hasLaterEdits: ${_this.hasLaterEdits}, status: ${_this.status}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $EditControlStateCopyWith<$Res>  {
  factory $EditControlStateCopyWith(EditControlState value, $Res Function(EditControlState) _then) = _$EditControlStateCopyWithImpl;
@useResult
$Res call({
 bool hasWork, bool showControls, bool canApply, bool canDiscard, bool canRetry, bool hasSubmittedWork, bool hasLaterEdits, String? status, List<EditorDiagnostic> diagnostics
});




}
/// @nodoc
class _$EditControlStateCopyWithImpl<$Res>
    implements $EditControlStateCopyWith<$Res> {
  _$EditControlStateCopyWithImpl(this._self, this._then);

  final EditControlState _self;
  final $Res Function(EditControlState) _then;

/// Create a copy of EditControlState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasWork = null,Object? showControls = null,Object? canApply = null,Object? canDiscard = null,Object? canRetry = null,Object? hasSubmittedWork = null,Object? hasLaterEdits = null,Object? status = freezed,Object? diagnostics = null,}) {
  return _then(EditControlState(
hasWork: null == hasWork ? _self.hasWork : hasWork // ignore: cast_nullable_to_non_nullable
as bool,showControls: null == showControls ? _self.showControls : showControls // ignore: cast_nullable_to_non_nullable
as bool,canApply: null == canApply ? _self.canApply : canApply // ignore: cast_nullable_to_non_nullable
as bool,canDiscard: null == canDiscard ? _self.canDiscard : canDiscard // ignore: cast_nullable_to_non_nullable
as bool,canRetry: null == canRetry ? _self.canRetry : canRetry // ignore: cast_nullable_to_non_nullable
as bool,hasSubmittedWork: null == hasSubmittedWork ? _self.hasSubmittedWork : hasSubmittedWork // ignore: cast_nullable_to_non_nullable
as bool,hasLaterEdits: null == hasLaterEdits ? _self.hasLaterEdits : hasLaterEdits // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [EditControlState].
extension EditControlStatePatterns on EditControlState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditControlState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditControlState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditControlState value)  $default,){
final _that = this;
switch (_that) {
case _EditControlState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditControlState value)?  $default,){
final _that = this;
switch (_that) {
case _EditControlState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasWork,  bool showControls,  bool canApply,  bool canDiscard,  bool canRetry,  bool hasSubmittedWork,  bool hasLaterEdits,  String? status,  List<EditorDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditControlState() when $default != null:
return $default(_that.hasWork,_that.showControls,_that.canApply,_that.canDiscard,_that.canRetry,_that.hasSubmittedWork,_that.hasLaterEdits,_that.status,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasWork,  bool showControls,  bool canApply,  bool canDiscard,  bool canRetry,  bool hasSubmittedWork,  bool hasLaterEdits,  String? status,  List<EditorDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _EditControlState():
return $default(_that.hasWork,_that.showControls,_that.canApply,_that.canDiscard,_that.canRetry,_that.hasSubmittedWork,_that.hasLaterEdits,_that.status,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasWork,  bool showControls,  bool canApply,  bool canDiscard,  bool canRetry,  bool hasSubmittedWork,  bool hasLaterEdits,  String? status,  List<EditorDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _EditControlState() when $default != null:
return $default(_that.hasWork,_that.showControls,_that.canApply,_that.canDiscard,_that.canRetry,_that.hasSubmittedWork,_that.hasLaterEdits,_that.status,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _EditControlState implements EditControlState {
  const _EditControlState({this.hasWork = false, this.showControls = false, this.canApply = false, this.canDiscard = false, this.canRetry = false, this.hasSubmittedWork = false, this.hasLaterEdits = false, this.status,  List<EditorDiagnostic> diagnostics = const []}): _diagnostics = diagnostics;
  

@override@JsonKey() final  bool hasWork;
@override@JsonKey() final  bool showControls;
@override@JsonKey() final  bool canApply;
@override@JsonKey() final  bool canDiscard;
@override@JsonKey() final  bool canRetry;
@override@JsonKey() final  bool hasSubmittedWork;
@override@JsonKey() final  bool hasLaterEdits;
@override final  String? status;
 final  List<EditorDiagnostic> _diagnostics;
@override@JsonKey() List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of EditControlState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditControlStateCopyWith<_EditControlState> get copyWith => __$EditControlStateCopyWithImpl<_EditControlState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditControlState&&(identical(other.hasWork, hasWork) || other.hasWork == hasWork)&&(identical(other.showControls, showControls) || other.showControls == showControls)&&(identical(other.canApply, canApply) || other.canApply == canApply)&&(identical(other.canDiscard, canDiscard) || other.canDiscard == canDiscard)&&(identical(other.canRetry, canRetry) || other.canRetry == canRetry)&&(identical(other.hasSubmittedWork, hasSubmittedWork) || other.hasSubmittedWork == hasSubmittedWork)&&(identical(other.hasLaterEdits, hasLaterEdits) || other.hasLaterEdits == hasLaterEdits)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,hasWork,showControls,canApply,canDiscard,canRetry,hasSubmittedWork,hasLaterEdits,status,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'EditControlState(hasWork: $hasWork, showControls: $showControls, canApply: $canApply, canDiscard: $canDiscard, canRetry: $canRetry, hasSubmittedWork: $hasSubmittedWork, hasLaterEdits: $hasLaterEdits, status: $status, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$EditControlStateCopyWith<$Res> implements $EditControlStateCopyWith<$Res> {
  factory _$EditControlStateCopyWith(_EditControlState value, $Res Function(_EditControlState) _then) = __$EditControlStateCopyWithImpl;
@override @useResult
$Res call({
 bool hasWork, bool showControls, bool canApply, bool canDiscard, bool canRetry, bool hasSubmittedWork, bool hasLaterEdits, String? status, List<EditorDiagnostic> diagnostics
});




}
/// @nodoc
class __$EditControlStateCopyWithImpl<$Res>
    implements _$EditControlStateCopyWith<$Res> {
  __$EditControlStateCopyWithImpl(this._self, this._then);

  final _EditControlState _self;
  final $Res Function(_EditControlState) _then;

/// Create a copy of EditControlState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasWork = null,Object? showControls = null,Object? canApply = null,Object? canDiscard = null,Object? canRetry = null,Object? hasSubmittedWork = null,Object? hasLaterEdits = null,Object? status = freezed,Object? diagnostics = null,}) {
  return _then(_EditControlState(
hasWork: null == hasWork ? _self.hasWork : hasWork // ignore: cast_nullable_to_non_nullable
as bool,showControls: null == showControls ? _self.showControls : showControls // ignore: cast_nullable_to_non_nullable
as bool,canApply: null == canApply ? _self.canApply : canApply // ignore: cast_nullable_to_non_nullable
as bool,canDiscard: null == canDiscard ? _self.canDiscard : canDiscard // ignore: cast_nullable_to_non_nullable
as bool,canRetry: null == canRetry ? _self.canRetry : canRetry // ignore: cast_nullable_to_non_nullable
as bool,hasSubmittedWork: null == hasSubmittedWork ? _self.hasSubmittedWork : hasSubmittedWork // ignore: cast_nullable_to_non_nullable
as bool,hasLaterEdits: null == hasLaterEdits ? _self.hasLaterEdits : hasLaterEdits // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}


}

// dart format on
