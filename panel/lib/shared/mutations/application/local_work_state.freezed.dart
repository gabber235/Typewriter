// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_work_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocalWorkState {

 Map<EditorResourceKey, LocalWorkResourceState> get resources; Map<EditorResourceKey, LocalEditorValue> get editorValues; List<LocalWorkSubmissionState> get submissions;
/// Create a copy of LocalWorkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalWorkStateCopyWith<LocalWorkState> get copyWith => _$LocalWorkStateCopyWithImpl<LocalWorkState>(this as LocalWorkState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LocalWorkState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalWorkState&&const DeepCollectionEquality().equals(other.resources, _this.resources)&&const DeepCollectionEquality().equals(other.editorValues, _this.editorValues)&&const DeepCollectionEquality().equals(other.submissions, _this.submissions));
}


@override
int get hashCode {
  final _this = this as LocalWorkState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.resources),const DeepCollectionEquality().hash(_this.editorValues),const DeepCollectionEquality().hash(_this.submissions));
}

@override
String toString() {
  final _this = this as LocalWorkState;
  return 'LocalWorkState(resources: ${_this.resources}, editorValues: ${_this.editorValues}, submissions: ${_this.submissions})';
}


}

/// @nodoc
abstract mixin class $LocalWorkStateCopyWith<$Res>  {
  factory $LocalWorkStateCopyWith(LocalWorkState value, $Res Function(LocalWorkState) _then) = _$LocalWorkStateCopyWithImpl;
@useResult
$Res call({
 Map<EditorResourceKey, LocalWorkResourceState> resources, Map<EditorResourceKey, LocalEditorValue> editorValues, List<LocalWorkSubmissionState> submissions
});




}
/// @nodoc
class _$LocalWorkStateCopyWithImpl<$Res>
    implements $LocalWorkStateCopyWith<$Res> {
  _$LocalWorkStateCopyWithImpl(this._self, this._then);

  final LocalWorkState _self;
  final $Res Function(LocalWorkState) _then;

/// Create a copy of LocalWorkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resources = null,Object? editorValues = null,Object? submissions = null,}) {
  return _then(LocalWorkState(
resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as Map<EditorResourceKey, LocalWorkResourceState>,editorValues: null == editorValues ? _self.editorValues : editorValues // ignore: cast_nullable_to_non_nullable
as Map<EditorResourceKey, LocalEditorValue>,submissions: null == submissions ? _self.submissions : submissions // ignore: cast_nullable_to_non_nullable
as List<LocalWorkSubmissionState>,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalWorkState].
extension LocalWorkStatePatterns on LocalWorkState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalWorkState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalWorkState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalWorkState value)  $default,){
final _that = this;
switch (_that) {
case _LocalWorkState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalWorkState value)?  $default,){
final _that = this;
switch (_that) {
case _LocalWorkState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<EditorResourceKey, LocalWorkResourceState> resources,  Map<EditorResourceKey, LocalEditorValue> editorValues,  List<LocalWorkSubmissionState> submissions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalWorkState() when $default != null:
return $default(_that.resources,_that.editorValues,_that.submissions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<EditorResourceKey, LocalWorkResourceState> resources,  Map<EditorResourceKey, LocalEditorValue> editorValues,  List<LocalWorkSubmissionState> submissions)  $default,) {final _that = this;
switch (_that) {
case _LocalWorkState():
return $default(_that.resources,_that.editorValues,_that.submissions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<EditorResourceKey, LocalWorkResourceState> resources,  Map<EditorResourceKey, LocalEditorValue> editorValues,  List<LocalWorkSubmissionState> submissions)?  $default,) {final _that = this;
switch (_that) {
case _LocalWorkState() when $default != null:
return $default(_that.resources,_that.editorValues,_that.submissions);case _:
  return null;

}
}

}

/// @nodoc


class _LocalWorkState implements LocalWorkState {
  const _LocalWorkState({ Map<EditorResourceKey, LocalWorkResourceState> resources = const {},  Map<EditorResourceKey, LocalEditorValue> editorValues = const {},  List<LocalWorkSubmissionState> submissions = const []}): _resources = resources,_editorValues = editorValues,_submissions = submissions;
  

 final  Map<EditorResourceKey, LocalWorkResourceState> _resources;
@override@JsonKey() Map<EditorResourceKey, LocalWorkResourceState> get resources {
  if (_resources is EqualUnmodifiableMapView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_resources);
}

 final  Map<EditorResourceKey, LocalEditorValue> _editorValues;
@override@JsonKey() Map<EditorResourceKey, LocalEditorValue> get editorValues {
  if (_editorValues is EqualUnmodifiableMapView) return _editorValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_editorValues);
}

 final  List<LocalWorkSubmissionState> _submissions;
@override@JsonKey() List<LocalWorkSubmissionState> get submissions {
  if (_submissions is EqualUnmodifiableListView) return _submissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_submissions);
}


/// Create a copy of LocalWorkState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalWorkStateCopyWith<_LocalWorkState> get copyWith => __$LocalWorkStateCopyWithImpl<_LocalWorkState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalWorkState&&const DeepCollectionEquality().equals(other.resources, _resources)&&const DeepCollectionEquality().equals(other.editorValues, _editorValues)&&const DeepCollectionEquality().equals(other.submissions, _submissions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_resources),const DeepCollectionEquality().hash(_editorValues),const DeepCollectionEquality().hash(_submissions));
}

@override
String toString() {
    return 'LocalWorkState(resources: $resources, editorValues: $editorValues, submissions: $submissions)';
}


}

/// @nodoc
abstract mixin class _$LocalWorkStateCopyWith<$Res> implements $LocalWorkStateCopyWith<$Res> {
  factory _$LocalWorkStateCopyWith(_LocalWorkState value, $Res Function(_LocalWorkState) _then) = __$LocalWorkStateCopyWithImpl;
@override @useResult
$Res call({
 Map<EditorResourceKey, LocalWorkResourceState> resources, Map<EditorResourceKey, LocalEditorValue> editorValues, List<LocalWorkSubmissionState> submissions
});




}
/// @nodoc
class __$LocalWorkStateCopyWithImpl<$Res>
    implements _$LocalWorkStateCopyWith<$Res> {
  __$LocalWorkStateCopyWithImpl(this._self, this._then);

  final _LocalWorkState _self;
  final $Res Function(_LocalWorkState) _then;

/// Create a copy of LocalWorkState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resources = null,Object? editorValues = null,Object? submissions = null,}) {
  return _then(_LocalWorkState(
resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as Map<EditorResourceKey, LocalWorkResourceState>,editorValues: null == editorValues ? _self._editorValues : editorValues // ignore: cast_nullable_to_non_nullable
as Map<EditorResourceKey, LocalEditorValue>,submissions: null == submissions ? _self._submissions : submissions // ignore: cast_nullable_to_non_nullable
as List<LocalWorkSubmissionState>,
  ));
}


}

/// @nodoc
mixin _$LocalWorkResourceState {

 EditorResourceKey get key; String get label; EditorCommitPolicy get commitPolicy; EditorSavePhase get savePhase; bool get readOnly; bool get hasDiagnostics; LocalWorkDestinationState get destination;
/// Create a copy of LocalWorkResourceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalWorkResourceStateCopyWith<LocalWorkResourceState> get copyWith => _$LocalWorkResourceStateCopyWithImpl<LocalWorkResourceState>(this as LocalWorkResourceState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LocalWorkResourceState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalWorkResourceState&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.commitPolicy, _this.commitPolicy) || other.commitPolicy == _this.commitPolicy)&&(identical(other.savePhase, _this.savePhase) || other.savePhase == _this.savePhase)&&(identical(other.readOnly, _this.readOnly) || other.readOnly == _this.readOnly)&&(identical(other.hasDiagnostics, _this.hasDiagnostics) || other.hasDiagnostics == _this.hasDiagnostics)&&(identical(other.destination, _this.destination) || other.destination == _this.destination));
}


@override
int get hashCode {
  final _this = this as LocalWorkResourceState;
  return Object.hash(runtimeType,_this.key,_this.label,_this.commitPolicy,_this.savePhase,_this.readOnly,_this.hasDiagnostics,_this.destination);
}

@override
String toString() {
  final _this = this as LocalWorkResourceState;
  return 'LocalWorkResourceState(key: ${_this.key}, label: ${_this.label}, commitPolicy: ${_this.commitPolicy}, savePhase: ${_this.savePhase}, readOnly: ${_this.readOnly}, hasDiagnostics: ${_this.hasDiagnostics}, destination: ${_this.destination})';
}


}

/// @nodoc
abstract mixin class $LocalWorkResourceStateCopyWith<$Res>  {
  factory $LocalWorkResourceStateCopyWith(LocalWorkResourceState value, $Res Function(LocalWorkResourceState) _then) = _$LocalWorkResourceStateCopyWithImpl;
@useResult
$Res call({
 EditorResourceKey key, String label, EditorCommitPolicy commitPolicy, EditorSavePhase savePhase, bool readOnly, bool hasDiagnostics, LocalWorkDestinationState destination
});


$EditorResourceKeyCopyWith<$Res> get key;

}
/// @nodoc
class _$LocalWorkResourceStateCopyWithImpl<$Res>
    implements $LocalWorkResourceStateCopyWith<$Res> {
  _$LocalWorkResourceStateCopyWithImpl(this._self, this._then);

  final LocalWorkResourceState _self;
  final $Res Function(LocalWorkResourceState) _then;

/// Create a copy of LocalWorkResourceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? commitPolicy = null,Object? savePhase = null,Object? readOnly = null,Object? hasDiagnostics = null,Object? destination = null,}) {
  return _then(LocalWorkResourceState(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as EditorResourceKey,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,commitPolicy: null == commitPolicy ? _self.commitPolicy : commitPolicy // ignore: cast_nullable_to_non_nullable
as EditorCommitPolicy,savePhase: null == savePhase ? _self.savePhase : savePhase // ignore: cast_nullable_to_non_nullable
as EditorSavePhase,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,hasDiagnostics: null == hasDiagnostics ? _self.hasDiagnostics : hasDiagnostics // ignore: cast_nullable_to_non_nullable
as bool,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as LocalWorkDestinationState,
  ));
}
/// Create a copy of LocalWorkResourceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorResourceKeyCopyWith<$Res> get key {
  
  return $EditorResourceKeyCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}
}


/// Adds pattern-matching-related methods to [LocalWorkResourceState].
extension LocalWorkResourceStatePatterns on LocalWorkResourceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalWorkResourceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalWorkResourceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalWorkResourceState value)  $default,){
final _that = this;
switch (_that) {
case _LocalWorkResourceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalWorkResourceState value)?  $default,){
final _that = this;
switch (_that) {
case _LocalWorkResourceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorResourceKey key,  String label,  EditorCommitPolicy commitPolicy,  EditorSavePhase savePhase,  bool readOnly,  bool hasDiagnostics,  LocalWorkDestinationState destination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalWorkResourceState() when $default != null:
return $default(_that.key,_that.label,_that.commitPolicy,_that.savePhase,_that.readOnly,_that.hasDiagnostics,_that.destination);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorResourceKey key,  String label,  EditorCommitPolicy commitPolicy,  EditorSavePhase savePhase,  bool readOnly,  bool hasDiagnostics,  LocalWorkDestinationState destination)  $default,) {final _that = this;
switch (_that) {
case _LocalWorkResourceState():
return $default(_that.key,_that.label,_that.commitPolicy,_that.savePhase,_that.readOnly,_that.hasDiagnostics,_that.destination);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorResourceKey key,  String label,  EditorCommitPolicy commitPolicy,  EditorSavePhase savePhase,  bool readOnly,  bool hasDiagnostics,  LocalWorkDestinationState destination)?  $default,) {final _that = this;
switch (_that) {
case _LocalWorkResourceState() when $default != null:
return $default(_that.key,_that.label,_that.commitPolicy,_that.savePhase,_that.readOnly,_that.hasDiagnostics,_that.destination);case _:
  return null;

}
}

}

/// @nodoc


class _LocalWorkResourceState implements LocalWorkResourceState {
  const _LocalWorkResourceState({required this.key, required this.label, required this.commitPolicy, required this.savePhase, required this.readOnly, required this.hasDiagnostics, required this.destination});
  

@override final  EditorResourceKey key;
@override final  String label;
@override final  EditorCommitPolicy commitPolicy;
@override final  EditorSavePhase savePhase;
@override final  bool readOnly;
@override final  bool hasDiagnostics;
@override final  LocalWorkDestinationState destination;

/// Create a copy of LocalWorkResourceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalWorkResourceStateCopyWith<_LocalWorkResourceState> get copyWith => __$LocalWorkResourceStateCopyWithImpl<_LocalWorkResourceState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalWorkResourceState&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.commitPolicy, commitPolicy) || other.commitPolicy == commitPolicy)&&(identical(other.savePhase, savePhase) || other.savePhase == savePhase)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.hasDiagnostics, hasDiagnostics) || other.hasDiagnostics == hasDiagnostics)&&(identical(other.destination, destination) || other.destination == destination));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,label,commitPolicy,savePhase,readOnly,hasDiagnostics,destination);
}

@override
String toString() {
    return 'LocalWorkResourceState(key: $key, label: $label, commitPolicy: $commitPolicy, savePhase: $savePhase, readOnly: $readOnly, hasDiagnostics: $hasDiagnostics, destination: $destination)';
}


}

/// @nodoc
abstract mixin class _$LocalWorkResourceStateCopyWith<$Res> implements $LocalWorkResourceStateCopyWith<$Res> {
  factory _$LocalWorkResourceStateCopyWith(_LocalWorkResourceState value, $Res Function(_LocalWorkResourceState) _then) = __$LocalWorkResourceStateCopyWithImpl;
@override @useResult
$Res call({
 EditorResourceKey key, String label, EditorCommitPolicy commitPolicy, EditorSavePhase savePhase, bool readOnly, bool hasDiagnostics, LocalWorkDestinationState destination
});


@override $EditorResourceKeyCopyWith<$Res> get key;

}
/// @nodoc
class __$LocalWorkResourceStateCopyWithImpl<$Res>
    implements _$LocalWorkResourceStateCopyWith<$Res> {
  __$LocalWorkResourceStateCopyWithImpl(this._self, this._then);

  final _LocalWorkResourceState _self;
  final $Res Function(_LocalWorkResourceState) _then;

/// Create a copy of LocalWorkResourceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? commitPolicy = null,Object? savePhase = null,Object? readOnly = null,Object? hasDiagnostics = null,Object? destination = null,}) {
  return _then(_LocalWorkResourceState(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as EditorResourceKey,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,commitPolicy: null == commitPolicy ? _self.commitPolicy : commitPolicy // ignore: cast_nullable_to_non_nullable
as EditorCommitPolicy,savePhase: null == savePhase ? _self.savePhase : savePhase // ignore: cast_nullable_to_non_nullable
as EditorSavePhase,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,hasDiagnostics: null == hasDiagnostics ? _self.hasDiagnostics : hasDiagnostics // ignore: cast_nullable_to_non_nullable
as bool,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as LocalWorkDestinationState,
  ));
}

/// Create a copy of LocalWorkResourceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorResourceKeyCopyWith<$Res> get key {
  
  return $EditorResourceKeyCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}
}

/// @nodoc
mixin _$LocalWorkSubmissionState {

 Object get id; String get label; bool get sending; bool get canReplay; bool get integrationFailed; LocalWorkSubmissionResult get result; String? get message;
/// Create a copy of LocalWorkSubmissionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalWorkSubmissionStateCopyWith<LocalWorkSubmissionState> get copyWith => _$LocalWorkSubmissionStateCopyWithImpl<LocalWorkSubmissionState>(this as LocalWorkSubmissionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LocalWorkSubmissionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalWorkSubmissionState&&const DeepCollectionEquality().equals(other.id, _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.sending, _this.sending) || other.sending == _this.sending)&&(identical(other.canReplay, _this.canReplay) || other.canReplay == _this.canReplay)&&(identical(other.integrationFailed, _this.integrationFailed) || other.integrationFailed == _this.integrationFailed)&&(identical(other.result, _this.result) || other.result == _this.result)&&(identical(other.message, _this.message) || other.message == _this.message));
}


@override
int get hashCode {
  final _this = this as LocalWorkSubmissionState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.id),_this.label,_this.sending,_this.canReplay,_this.integrationFailed,_this.result,_this.message);
}

@override
String toString() {
  final _this = this as LocalWorkSubmissionState;
  return 'LocalWorkSubmissionState(id: ${_this.id}, label: ${_this.label}, sending: ${_this.sending}, canReplay: ${_this.canReplay}, integrationFailed: ${_this.integrationFailed}, result: ${_this.result}, message: ${_this.message})';
}


}

/// @nodoc
abstract mixin class $LocalWorkSubmissionStateCopyWith<$Res>  {
  factory $LocalWorkSubmissionStateCopyWith(LocalWorkSubmissionState value, $Res Function(LocalWorkSubmissionState) _then) = _$LocalWorkSubmissionStateCopyWithImpl;
@useResult
$Res call({
 Object id, String label, bool sending, bool canReplay, bool integrationFailed, LocalWorkSubmissionResult result, String? message
});




}
/// @nodoc
class _$LocalWorkSubmissionStateCopyWithImpl<$Res>
    implements $LocalWorkSubmissionStateCopyWith<$Res> {
  _$LocalWorkSubmissionStateCopyWithImpl(this._self, this._then);

  final LocalWorkSubmissionState _self;
  final $Res Function(LocalWorkSubmissionState) _then;

/// Create a copy of LocalWorkSubmissionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? sending = null,Object? canReplay = null,Object? integrationFailed = null,Object? result = null,Object? message = freezed,}) {
  return _then(LocalWorkSubmissionState(
id: null == id ? _self.id : id ,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,sending: null == sending ? _self.sending : sending // ignore: cast_nullable_to_non_nullable
as bool,canReplay: null == canReplay ? _self.canReplay : canReplay // ignore: cast_nullable_to_non_nullable
as bool,integrationFailed: null == integrationFailed ? _self.integrationFailed : integrationFailed // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as LocalWorkSubmissionResult,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalWorkSubmissionState].
extension LocalWorkSubmissionStatePatterns on LocalWorkSubmissionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalWorkSubmissionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalWorkSubmissionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalWorkSubmissionState value)  $default,){
final _that = this;
switch (_that) {
case _LocalWorkSubmissionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalWorkSubmissionState value)?  $default,){
final _that = this;
switch (_that) {
case _LocalWorkSubmissionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object id,  String label,  bool sending,  bool canReplay,  bool integrationFailed,  LocalWorkSubmissionResult result,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalWorkSubmissionState() when $default != null:
return $default(_that.id,_that.label,_that.sending,_that.canReplay,_that.integrationFailed,_that.result,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object id,  String label,  bool sending,  bool canReplay,  bool integrationFailed,  LocalWorkSubmissionResult result,  String? message)  $default,) {final _that = this;
switch (_that) {
case _LocalWorkSubmissionState():
return $default(_that.id,_that.label,_that.sending,_that.canReplay,_that.integrationFailed,_that.result,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object id,  String label,  bool sending,  bool canReplay,  bool integrationFailed,  LocalWorkSubmissionResult result,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _LocalWorkSubmissionState() when $default != null:
return $default(_that.id,_that.label,_that.sending,_that.canReplay,_that.integrationFailed,_that.result,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _LocalWorkSubmissionState implements LocalWorkSubmissionState {
  const _LocalWorkSubmissionState({required this.id, required this.label, required this.sending, required this.canReplay, required this.integrationFailed, required this.result, this.message});
  

@override final  Object id;
@override final  String label;
@override final  bool sending;
@override final  bool canReplay;
@override final  bool integrationFailed;
@override final  LocalWorkSubmissionResult result;
@override final  String? message;

/// Create a copy of LocalWorkSubmissionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalWorkSubmissionStateCopyWith<_LocalWorkSubmissionState> get copyWith => __$LocalWorkSubmissionStateCopyWithImpl<_LocalWorkSubmissionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalWorkSubmissionState&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.label, label) || other.label == label)&&(identical(other.sending, sending) || other.sending == sending)&&(identical(other.canReplay, canReplay) || other.canReplay == canReplay)&&(identical(other.integrationFailed, integrationFailed) || other.integrationFailed == integrationFailed)&&(identical(other.result, result) || other.result == result)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(id),label,sending,canReplay,integrationFailed,result,message);
}

@override
String toString() {
    return 'LocalWorkSubmissionState(id: $id, label: $label, sending: $sending, canReplay: $canReplay, integrationFailed: $integrationFailed, result: $result, message: $message)';
}


}

/// @nodoc
abstract mixin class _$LocalWorkSubmissionStateCopyWith<$Res> implements $LocalWorkSubmissionStateCopyWith<$Res> {
  factory _$LocalWorkSubmissionStateCopyWith(_LocalWorkSubmissionState value, $Res Function(_LocalWorkSubmissionState) _then) = __$LocalWorkSubmissionStateCopyWithImpl;
@override @useResult
$Res call({
 Object id, String label, bool sending, bool canReplay, bool integrationFailed, LocalWorkSubmissionResult result, String? message
});




}
/// @nodoc
class __$LocalWorkSubmissionStateCopyWithImpl<$Res>
    implements _$LocalWorkSubmissionStateCopyWith<$Res> {
  __$LocalWorkSubmissionStateCopyWithImpl(this._self, this._then);

  final _LocalWorkSubmissionState _self;
  final $Res Function(_LocalWorkSubmissionState) _then;

/// Create a copy of LocalWorkSubmissionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? sending = null,Object? canReplay = null,Object? integrationFailed = null,Object? result = null,Object? message = freezed,}) {
  return _then(_LocalWorkSubmissionState(
id: null == id ? _self.id : id ,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,sending: null == sending ? _self.sending : sending // ignore: cast_nullable_to_non_nullable
as bool,canReplay: null == canReplay ? _self.canReplay : canReplay // ignore: cast_nullable_to_non_nullable
as bool,integrationFailed: null == integrationFailed ? _self.integrationFailed : integrationFailed // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as LocalWorkSubmissionResult,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
