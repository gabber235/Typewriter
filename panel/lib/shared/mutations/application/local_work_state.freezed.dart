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

 Map<WorkEntryId, WorkEntryState> get entries; Map<EditorResourceKey, LocalEditorValue> get editorValues; List<LocalWorkSubmissionState> get submissions;
/// Create a copy of LocalWorkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalWorkStateCopyWith<LocalWorkState> get copyWith => _$LocalWorkStateCopyWithImpl<LocalWorkState>(this as LocalWorkState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LocalWorkState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalWorkState&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&const DeepCollectionEquality().equals(other.editorValues, _this.editorValues)&&const DeepCollectionEquality().equals(other.submissions, _this.submissions));
}


@override
int get hashCode {
  final _this = this as LocalWorkState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.entries),const DeepCollectionEquality().hash(_this.editorValues),const DeepCollectionEquality().hash(_this.submissions));
}

@override
String toString() {
  final _this = this as LocalWorkState;
  return 'LocalWorkState(entries: ${_this.entries}, editorValues: ${_this.editorValues}, submissions: ${_this.submissions})';
}


}

/// @nodoc
abstract mixin class $LocalWorkStateCopyWith<$Res>  {
  factory $LocalWorkStateCopyWith(LocalWorkState value, $Res Function(LocalWorkState) _then) = _$LocalWorkStateCopyWithImpl;
@useResult
$Res call({
 Map<WorkEntryId, WorkEntryState> entries, Map<EditorResourceKey, LocalEditorValue> editorValues, List<LocalWorkSubmissionState> submissions
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
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,Object? editorValues = null,Object? submissions = null,}) {
  return _then(LocalWorkState(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as Map<WorkEntryId, WorkEntryState>,editorValues: null == editorValues ? _self.editorValues : editorValues // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<WorkEntryId, WorkEntryState> entries,  Map<EditorResourceKey, LocalEditorValue> editorValues,  List<LocalWorkSubmissionState> submissions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalWorkState() when $default != null:
return $default(_that.entries,_that.editorValues,_that.submissions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<WorkEntryId, WorkEntryState> entries,  Map<EditorResourceKey, LocalEditorValue> editorValues,  List<LocalWorkSubmissionState> submissions)  $default,) {final _that = this;
switch (_that) {
case _LocalWorkState():
return $default(_that.entries,_that.editorValues,_that.submissions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<WorkEntryId, WorkEntryState> entries,  Map<EditorResourceKey, LocalEditorValue> editorValues,  List<LocalWorkSubmissionState> submissions)?  $default,) {final _that = this;
switch (_that) {
case _LocalWorkState() when $default != null:
return $default(_that.entries,_that.editorValues,_that.submissions);case _:
  return null;

}
}

}

/// @nodoc


class _LocalWorkState extends LocalWorkState {
  const _LocalWorkState({ Map<WorkEntryId, WorkEntryState> entries = const {},  Map<EditorResourceKey, LocalEditorValue> editorValues = const {},  List<LocalWorkSubmissionState> submissions = const []}): _entries = entries,_editorValues = editorValues,_submissions = submissions,super._();


 final  Map<WorkEntryId, WorkEntryState> _entries;
@override@JsonKey() Map<WorkEntryId, WorkEntryState> get entries {
  if (_entries is EqualUnmodifiableMapView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_entries);
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalWorkState&&const DeepCollectionEquality().equals(other.entries, _entries)&&const DeepCollectionEquality().equals(other.editorValues, _editorValues)&&const DeepCollectionEquality().equals(other.submissions, _submissions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_editorValues),const DeepCollectionEquality().hash(_submissions));
}

@override
String toString() {
    return 'LocalWorkState(entries: $entries, editorValues: $editorValues, submissions: $submissions)';
}


}

/// @nodoc
abstract mixin class _$LocalWorkStateCopyWith<$Res> implements $LocalWorkStateCopyWith<$Res> {
  factory _$LocalWorkStateCopyWith(_LocalWorkState value, $Res Function(_LocalWorkState) _then) = __$LocalWorkStateCopyWithImpl;
@override @useResult
$Res call({
 Map<WorkEntryId, WorkEntryState> entries, Map<EditorResourceKey, LocalEditorValue> editorValues, List<LocalWorkSubmissionState> submissions
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
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,Object? editorValues = null,Object? submissions = null,}) {
  return _then(_LocalWorkState(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as Map<WorkEntryId, WorkEntryState>,editorValues: null == editorValues ? _self._editorValues : editorValues // ignore: cast_nullable_to_non_nullable
as Map<EditorResourceKey, LocalEditorValue>,submissions: null == submissions ? _self._submissions : submissions // ignore: cast_nullable_to_non_nullable
as List<LocalWorkSubmissionState>,
  ));
}


}

/// @nodoc
mixin _$WorkDriverId {

 String get domain; Object get scope;
/// Create a copy of WorkDriverId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkDriverIdCopyWith<WorkDriverId> get copyWith => _$WorkDriverIdCopyWithImpl<WorkDriverId>(this as WorkDriverId, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkDriverId;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkDriverId&&(identical(other.domain, _this.domain) || other.domain == _this.domain)&&const DeepCollectionEquality().equals(other.scope, _this.scope));
}


@override
int get hashCode {
  final _this = this as WorkDriverId;
  return Object.hash(runtimeType,_this.domain,const DeepCollectionEquality().hash(_this.scope));
}

@override
String toString() {
  final _this = this as WorkDriverId;
  return 'WorkDriverId(domain: ${_this.domain}, scope: ${_this.scope})';
}


}

/// @nodoc
abstract mixin class $WorkDriverIdCopyWith<$Res>  {
  factory $WorkDriverIdCopyWith(WorkDriverId value, $Res Function(WorkDriverId) _then) = _$WorkDriverIdCopyWithImpl;
@useResult
$Res call({
 String domain, Object scope
});




}
/// @nodoc
class _$WorkDriverIdCopyWithImpl<$Res>
    implements $WorkDriverIdCopyWith<$Res> {
  _$WorkDriverIdCopyWithImpl(this._self, this._then);

  final WorkDriverId _self;
  final $Res Function(WorkDriverId) _then;

/// Create a copy of WorkDriverId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? domain = null,Object? scope = null,}) {
  return _then(WorkDriverId(
domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope ,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkDriverId].
extension WorkDriverIdPatterns on WorkDriverId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkDriverId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkDriverId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkDriverId value)  $default,){
final _that = this;
switch (_that) {
case _WorkDriverId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkDriverId value)?  $default,){
final _that = this;
switch (_that) {
case _WorkDriverId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String domain,  Object scope)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkDriverId() when $default != null:
return $default(_that.domain,_that.scope);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String domain,  Object scope)  $default,) {final _that = this;
switch (_that) {
case _WorkDriverId():
return $default(_that.domain,_that.scope);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String domain,  Object scope)?  $default,) {final _that = this;
switch (_that) {
case _WorkDriverId() when $default != null:
return $default(_that.domain,_that.scope);case _:
  return null;

}
}

}

/// @nodoc


class _WorkDriverId implements WorkDriverId {
  const _WorkDriverId({required this.domain, required this.scope});


@override final  String domain;
@override final  Object scope;

/// Create a copy of WorkDriverId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkDriverIdCopyWith<_WorkDriverId> get copyWith => __$WorkDriverIdCopyWithImpl<_WorkDriverId>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkDriverId&&(identical(other.domain, domain) || other.domain == domain)&&const DeepCollectionEquality().equals(other.scope, scope));
}


@override
int get hashCode {
    return Object.hash(runtimeType,domain,const DeepCollectionEquality().hash(scope));
}

@override
String toString() {
    return 'WorkDriverId(domain: $domain, scope: $scope)';
}


}

/// @nodoc
abstract mixin class _$WorkDriverIdCopyWith<$Res> implements $WorkDriverIdCopyWith<$Res> {
  factory _$WorkDriverIdCopyWith(_WorkDriverId value, $Res Function(_WorkDriverId) _then) = __$WorkDriverIdCopyWithImpl;
@override @useResult
$Res call({
 String domain, Object scope
});




}
/// @nodoc
class __$WorkDriverIdCopyWithImpl<$Res>
    implements _$WorkDriverIdCopyWith<$Res> {
  __$WorkDriverIdCopyWithImpl(this._self, this._then);

  final _WorkDriverId _self;
  final $Res Function(_WorkDriverId) _then;

/// Create a copy of WorkDriverId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? domain = null,Object? scope = null,}) {
  return _then(_WorkDriverId(
domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope ,
  ));
}


}

/// @nodoc
mixin _$WorkEntryId {

 WorkDriverId get driver; Object get identity;
/// Create a copy of WorkEntryId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkEntryIdCopyWith<WorkEntryId> get copyWith => _$WorkEntryIdCopyWithImpl<WorkEntryId>(this as WorkEntryId, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkEntryId;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkEntryId&&(identical(other.driver, _this.driver) || other.driver == _this.driver)&&const DeepCollectionEquality().equals(other.identity, _this.identity));
}


@override
int get hashCode {
  final _this = this as WorkEntryId;
  return Object.hash(runtimeType,_this.driver,const DeepCollectionEquality().hash(_this.identity));
}

@override
String toString() {
  final _this = this as WorkEntryId;
  return 'WorkEntryId(driver: ${_this.driver}, identity: ${_this.identity})';
}


}

/// @nodoc
abstract mixin class $WorkEntryIdCopyWith<$Res>  {
  factory $WorkEntryIdCopyWith(WorkEntryId value, $Res Function(WorkEntryId) _then) = _$WorkEntryIdCopyWithImpl;
@useResult
$Res call({
 WorkDriverId driver, Object identity
});


$WorkDriverIdCopyWith<$Res> get driver;

}
/// @nodoc
class _$WorkEntryIdCopyWithImpl<$Res>
    implements $WorkEntryIdCopyWith<$Res> {
  _$WorkEntryIdCopyWithImpl(this._self, this._then);

  final WorkEntryId _self;
  final $Res Function(WorkEntryId) _then;

/// Create a copy of WorkEntryId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driver = null,Object? identity = null,}) {
  return _then(WorkEntryId(
driver: null == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as WorkDriverId,identity: null == identity ? _self.identity : identity ,
  ));
}
/// Create a copy of WorkEntryId
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkDriverIdCopyWith<$Res> get driver {

  return $WorkDriverIdCopyWith<$Res>(_self.driver, (value) {
    return _then(_self.copyWith(driver: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkEntryId].
extension WorkEntryIdPatterns on WorkEntryId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkEntryId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkEntryId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkEntryId value)  $default,){
final _that = this;
switch (_that) {
case _WorkEntryId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkEntryId value)?  $default,){
final _that = this;
switch (_that) {
case _WorkEntryId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkDriverId driver,  Object identity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkEntryId() when $default != null:
return $default(_that.driver,_that.identity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkDriverId driver,  Object identity)  $default,) {final _that = this;
switch (_that) {
case _WorkEntryId():
return $default(_that.driver,_that.identity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkDriverId driver,  Object identity)?  $default,) {final _that = this;
switch (_that) {
case _WorkEntryId() when $default != null:
return $default(_that.driver,_that.identity);case _:
  return null;

}
}

}

/// @nodoc


class _WorkEntryId implements WorkEntryId {
  const _WorkEntryId({required this.driver, required this.identity});


@override final  WorkDriverId driver;
@override final  Object identity;

/// Create a copy of WorkEntryId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkEntryIdCopyWith<_WorkEntryId> get copyWith => __$WorkEntryIdCopyWithImpl<_WorkEntryId>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkEntryId&&(identical(other.driver, driver) || other.driver == driver)&&const DeepCollectionEquality().equals(other.identity, identity));
}


@override
int get hashCode {
    return Object.hash(runtimeType,driver,const DeepCollectionEquality().hash(identity));
}

@override
String toString() {
    return 'WorkEntryId(driver: $driver, identity: $identity)';
}


}

/// @nodoc
abstract mixin class _$WorkEntryIdCopyWith<$Res> implements $WorkEntryIdCopyWith<$Res> {
  factory _$WorkEntryIdCopyWith(_WorkEntryId value, $Res Function(_WorkEntryId) _then) = __$WorkEntryIdCopyWithImpl;
@override @useResult
$Res call({
 WorkDriverId driver, Object identity
});


@override $WorkDriverIdCopyWith<$Res> get driver;

}
/// @nodoc
class __$WorkEntryIdCopyWithImpl<$Res>
    implements _$WorkEntryIdCopyWith<$Res> {
  __$WorkEntryIdCopyWithImpl(this._self, this._then);

  final _WorkEntryId _self;
  final $Res Function(_WorkEntryId) _then;

/// Create a copy of WorkEntryId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driver = null,Object? identity = null,}) {
  return _then(_WorkEntryId(
driver: null == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as WorkDriverId,identity: null == identity ? _self.identity : identity ,
  ));
}

/// Create a copy of WorkEntryId
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkDriverIdCopyWith<$Res> get driver {

  return $WorkDriverIdCopyWith<$Res>(_self.driver, (value) {
    return _then(_self.copyWith(driver: value));
  });
}
}

/// @nodoc
mixin _$WorkFact {

 String get label; String get value;
/// Create a copy of WorkFact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkFactCopyWith<WorkFact> get copyWith => _$WorkFactCopyWithImpl<WorkFact>(this as WorkFact, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkFact;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkFact&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as WorkFact;
  return Object.hash(runtimeType,_this.label,_this.value);
}

@override
String toString() {
  final _this = this as WorkFact;
  return 'WorkFact(label: ${_this.label}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $WorkFactCopyWith<$Res>  {
  factory $WorkFactCopyWith(WorkFact value, $Res Function(WorkFact) _then) = _$WorkFactCopyWithImpl;
@useResult
$Res call({
 String label, String value
});




}
/// @nodoc
class _$WorkFactCopyWithImpl<$Res>
    implements $WorkFactCopyWith<$Res> {
  _$WorkFactCopyWithImpl(this._self, this._then);

  final WorkFact _self;
  final $Res Function(WorkFact) _then;

/// Create a copy of WorkFact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,}) {
  return _then(WorkFact(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkFact].
extension WorkFactPatterns on WorkFact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkFact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkFact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkFact value)  $default,){
final _that = this;
switch (_that) {
case _WorkFact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkFact value)?  $default,){
final _that = this;
switch (_that) {
case _WorkFact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkFact() when $default != null:
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String value)  $default,) {final _that = this;
switch (_that) {
case _WorkFact():
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String value)?  $default,) {final _that = this;
switch (_that) {
case _WorkFact() when $default != null:
return $default(_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _WorkFact implements WorkFact {
  const _WorkFact({required this.label, required this.value});


@override final  String label;
@override final  String value;

/// Create a copy of WorkFact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkFactCopyWith<_WorkFact> get copyWith => __$WorkFactCopyWithImpl<_WorkFact>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkFact&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,value);
}

@override
String toString() {
    return 'WorkFact(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$WorkFactCopyWith<$Res> implements $WorkFactCopyWith<$Res> {
  factory _$WorkFactCopyWith(_WorkFact value, $Res Function(_WorkFact) _then) = __$WorkFactCopyWithImpl;
@override @useResult
$Res call({
 String label, String value
});




}
/// @nodoc
class __$WorkFactCopyWithImpl<$Res>
    implements _$WorkFactCopyWith<$Res> {
  __$WorkFactCopyWithImpl(this._self, this._then);

  final _WorkFact _self;
  final $Res Function(_WorkFact) _then;

/// Create a copy of WorkFact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,}) {
  return _then(_WorkFact(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$WorkEntryState {

 WorkEntryId get id; String get label; String get phase; List<WorkFact> get details; bool get retained; bool get hasWork; bool get canSave; bool get canDiscard; bool get canRetry; bool get blocksNavigation; bool get saving; bool get needsAttention; bool get needsInput; LocalWorkDestinationState get destination;
/// Create a copy of WorkEntryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkEntryStateCopyWith<WorkEntryState> get copyWith => _$WorkEntryStateCopyWithImpl<WorkEntryState>(this as WorkEntryState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkEntryState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkEntryState&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&const DeepCollectionEquality().equals(other.details, _this.details)&&(identical(other.retained, _this.retained) || other.retained == _this.retained)&&(identical(other.hasWork, _this.hasWork) || other.hasWork == _this.hasWork)&&(identical(other.canSave, _this.canSave) || other.canSave == _this.canSave)&&(identical(other.canDiscard, _this.canDiscard) || other.canDiscard == _this.canDiscard)&&(identical(other.canRetry, _this.canRetry) || other.canRetry == _this.canRetry)&&(identical(other.blocksNavigation, _this.blocksNavigation) || other.blocksNavigation == _this.blocksNavigation)&&(identical(other.saving, _this.saving) || other.saving == _this.saving)&&(identical(other.needsAttention, _this.needsAttention) || other.needsAttention == _this.needsAttention)&&(identical(other.needsInput, _this.needsInput) || other.needsInput == _this.needsInput)&&(identical(other.destination, _this.destination) || other.destination == _this.destination));
}


@override
int get hashCode {
  final _this = this as WorkEntryState;
  return Object.hash(runtimeType,_this.id,_this.label,_this.phase,const DeepCollectionEquality().hash(_this.details),_this.retained,_this.hasWork,_this.canSave,_this.canDiscard,_this.canRetry,_this.blocksNavigation,_this.saving,_this.needsAttention,_this.needsInput,_this.destination);
}

@override
String toString() {
  final _this = this as WorkEntryState;
  return 'WorkEntryState(id: ${_this.id}, label: ${_this.label}, phase: ${_this.phase}, details: ${_this.details}, retained: ${_this.retained}, hasWork: ${_this.hasWork}, canSave: ${_this.canSave}, canDiscard: ${_this.canDiscard}, canRetry: ${_this.canRetry}, blocksNavigation: ${_this.blocksNavigation}, saving: ${_this.saving}, needsAttention: ${_this.needsAttention}, needsInput: ${_this.needsInput}, destination: ${_this.destination})';
}


}

/// @nodoc
abstract mixin class $WorkEntryStateCopyWith<$Res>  {
  factory $WorkEntryStateCopyWith(WorkEntryState value, $Res Function(WorkEntryState) _then) = _$WorkEntryStateCopyWithImpl;
@useResult
$Res call({
 WorkEntryId id, String label, String phase, List<WorkFact> details, bool retained, bool hasWork, bool canSave, bool canDiscard, bool canRetry, bool blocksNavigation, bool saving, bool needsAttention, bool needsInput, LocalWorkDestinationState destination
});


$WorkEntryIdCopyWith<$Res> get id;

}
/// @nodoc
class _$WorkEntryStateCopyWithImpl<$Res>
    implements $WorkEntryStateCopyWith<$Res> {
  _$WorkEntryStateCopyWithImpl(this._self, this._then);

  final WorkEntryState _self;
  final $Res Function(WorkEntryState) _then;

/// Create a copy of WorkEntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? phase = null,Object? details = null,Object? retained = null,Object? hasWork = null,Object? canSave = null,Object? canDiscard = null,Object? canRetry = null,Object? blocksNavigation = null,Object? saving = null,Object? needsAttention = null,Object? needsInput = null,Object? destination = null,}) {
  return _then(WorkEntryState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as WorkEntryId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as List<WorkFact>,retained: null == retained ? _self.retained : retained // ignore: cast_nullable_to_non_nullable
as bool,hasWork: null == hasWork ? _self.hasWork : hasWork // ignore: cast_nullable_to_non_nullable
as bool,canSave: null == canSave ? _self.canSave : canSave // ignore: cast_nullable_to_non_nullable
as bool,canDiscard: null == canDiscard ? _self.canDiscard : canDiscard // ignore: cast_nullable_to_non_nullable
as bool,canRetry: null == canRetry ? _self.canRetry : canRetry // ignore: cast_nullable_to_non_nullable
as bool,blocksNavigation: null == blocksNavigation ? _self.blocksNavigation : blocksNavigation // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,needsAttention: null == needsAttention ? _self.needsAttention : needsAttention // ignore: cast_nullable_to_non_nullable
as bool,needsInput: null == needsInput ? _self.needsInput : needsInput // ignore: cast_nullable_to_non_nullable
as bool,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as LocalWorkDestinationState,
  ));
}
/// Create a copy of WorkEntryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkEntryIdCopyWith<$Res> get id {

  return $WorkEntryIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkEntryState].
extension WorkEntryStatePatterns on WorkEntryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkEntryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkEntryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkEntryState value)  $default,){
final _that = this;
switch (_that) {
case _WorkEntryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkEntryState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkEntryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkEntryId id,  String label,  String phase,  List<WorkFact> details,  bool retained,  bool hasWork,  bool canSave,  bool canDiscard,  bool canRetry,  bool blocksNavigation,  bool saving,  bool needsAttention,  bool needsInput,  LocalWorkDestinationState destination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkEntryState() when $default != null:
return $default(_that.id,_that.label,_that.phase,_that.details,_that.retained,_that.hasWork,_that.canSave,_that.canDiscard,_that.canRetry,_that.blocksNavigation,_that.saving,_that.needsAttention,_that.needsInput,_that.destination);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkEntryId id,  String label,  String phase,  List<WorkFact> details,  bool retained,  bool hasWork,  bool canSave,  bool canDiscard,  bool canRetry,  bool blocksNavigation,  bool saving,  bool needsAttention,  bool needsInput,  LocalWorkDestinationState destination)  $default,) {final _that = this;
switch (_that) {
case _WorkEntryState():
return $default(_that.id,_that.label,_that.phase,_that.details,_that.retained,_that.hasWork,_that.canSave,_that.canDiscard,_that.canRetry,_that.blocksNavigation,_that.saving,_that.needsAttention,_that.needsInput,_that.destination);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkEntryId id,  String label,  String phase,  List<WorkFact> details,  bool retained,  bool hasWork,  bool canSave,  bool canDiscard,  bool canRetry,  bool blocksNavigation,  bool saving,  bool needsAttention,  bool needsInput,  LocalWorkDestinationState destination)?  $default,) {final _that = this;
switch (_that) {
case _WorkEntryState() when $default != null:
return $default(_that.id,_that.label,_that.phase,_that.details,_that.retained,_that.hasWork,_that.canSave,_that.canDiscard,_that.canRetry,_that.blocksNavigation,_that.saving,_that.needsAttention,_that.needsInput,_that.destination);case _:
  return null;

}
}

}

/// @nodoc


class _WorkEntryState implements WorkEntryState {
  const _WorkEntryState({required this.id, required this.label, required this.phase,  List<WorkFact> details = const [], this.retained = false, this.hasWork = false, this.canSave = false, this.canDiscard = false, this.canRetry = false, this.blocksNavigation = false, this.saving = false, this.needsAttention = false, this.needsInput = false, this.destination = LocalWorkDestinationState.unavailable}): _details = details;


@override final  WorkEntryId id;
@override final  String label;
@override final  String phase;
 final  List<WorkFact> _details;
@override@JsonKey() List<WorkFact> get details {
  if (_details is EqualUnmodifiableListView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_details);
}

@override@JsonKey() final  bool retained;
@override@JsonKey() final  bool hasWork;
@override@JsonKey() final  bool canSave;
@override@JsonKey() final  bool canDiscard;
@override@JsonKey() final  bool canRetry;
@override@JsonKey() final  bool blocksNavigation;
@override@JsonKey() final  bool saving;
@override@JsonKey() final  bool needsAttention;
@override@JsonKey() final  bool needsInput;
@override@JsonKey() final  LocalWorkDestinationState destination;

/// Create a copy of WorkEntryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkEntryStateCopyWith<_WorkEntryState> get copyWith => __$WorkEntryStateCopyWithImpl<_WorkEntryState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkEntryState&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.details, _details)&&(identical(other.retained, retained) || other.retained == retained)&&(identical(other.hasWork, hasWork) || other.hasWork == hasWork)&&(identical(other.canSave, canSave) || other.canSave == canSave)&&(identical(other.canDiscard, canDiscard) || other.canDiscard == canDiscard)&&(identical(other.canRetry, canRetry) || other.canRetry == canRetry)&&(identical(other.blocksNavigation, blocksNavigation) || other.blocksNavigation == blocksNavigation)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.needsAttention, needsAttention) || other.needsAttention == needsAttention)&&(identical(other.needsInput, needsInput) || other.needsInput == needsInput)&&(identical(other.destination, destination) || other.destination == destination));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,label,phase,const DeepCollectionEquality().hash(_details),retained,hasWork,canSave,canDiscard,canRetry,blocksNavigation,saving,needsAttention,needsInput,destination);
}

@override
String toString() {
    return 'WorkEntryState(id: $id, label: $label, phase: $phase, details: $details, retained: $retained, hasWork: $hasWork, canSave: $canSave, canDiscard: $canDiscard, canRetry: $canRetry, blocksNavigation: $blocksNavigation, saving: $saving, needsAttention: $needsAttention, needsInput: $needsInput, destination: $destination)';
}


}

/// @nodoc
abstract mixin class _$WorkEntryStateCopyWith<$Res> implements $WorkEntryStateCopyWith<$Res> {
  factory _$WorkEntryStateCopyWith(_WorkEntryState value, $Res Function(_WorkEntryState) _then) = __$WorkEntryStateCopyWithImpl;
@override @useResult
$Res call({
 WorkEntryId id, String label, String phase, List<WorkFact> details, bool retained, bool hasWork, bool canSave, bool canDiscard, bool canRetry, bool blocksNavigation, bool saving, bool needsAttention, bool needsInput, LocalWorkDestinationState destination
});


@override $WorkEntryIdCopyWith<$Res> get id;

}
/// @nodoc
class __$WorkEntryStateCopyWithImpl<$Res>
    implements _$WorkEntryStateCopyWith<$Res> {
  __$WorkEntryStateCopyWithImpl(this._self, this._then);

  final _WorkEntryState _self;
  final $Res Function(_WorkEntryState) _then;

/// Create a copy of WorkEntryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? phase = null,Object? details = null,Object? retained = null,Object? hasWork = null,Object? canSave = null,Object? canDiscard = null,Object? canRetry = null,Object? blocksNavigation = null,Object? saving = null,Object? needsAttention = null,Object? needsInput = null,Object? destination = null,}) {
  return _then(_WorkEntryState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as WorkEntryId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as List<WorkFact>,retained: null == retained ? _self.retained : retained // ignore: cast_nullable_to_non_nullable
as bool,hasWork: null == hasWork ? _self.hasWork : hasWork // ignore: cast_nullable_to_non_nullable
as bool,canSave: null == canSave ? _self.canSave : canSave // ignore: cast_nullable_to_non_nullable
as bool,canDiscard: null == canDiscard ? _self.canDiscard : canDiscard // ignore: cast_nullable_to_non_nullable
as bool,canRetry: null == canRetry ? _self.canRetry : canRetry // ignore: cast_nullable_to_non_nullable
as bool,blocksNavigation: null == blocksNavigation ? _self.blocksNavigation : blocksNavigation // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,needsAttention: null == needsAttention ? _self.needsAttention : needsAttention // ignore: cast_nullable_to_non_nullable
as bool,needsInput: null == needsInput ? _self.needsInput : needsInput // ignore: cast_nullable_to_non_nullable
as bool,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as LocalWorkDestinationState,
  ));
}

/// Create a copy of WorkEntryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkEntryIdCopyWith<$Res> get id {

  return $WorkEntryIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}
}

/// @nodoc
mixin _$WorkDriverSnapshot {

 List<WorkEntryState> get entries;
/// Create a copy of WorkDriverSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkDriverSnapshotCopyWith<WorkDriverSnapshot> get copyWith => _$WorkDriverSnapshotCopyWithImpl<WorkDriverSnapshot>(this as WorkDriverSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkDriverSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkDriverSnapshot&&const DeepCollectionEquality().equals(other.entries, _this.entries));
}


@override
int get hashCode {
  final _this = this as WorkDriverSnapshot;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.entries));
}

@override
String toString() {
  final _this = this as WorkDriverSnapshot;
  return 'WorkDriverSnapshot(entries: ${_this.entries})';
}


}

/// @nodoc
abstract mixin class $WorkDriverSnapshotCopyWith<$Res>  {
  factory $WorkDriverSnapshotCopyWith(WorkDriverSnapshot value, $Res Function(WorkDriverSnapshot) _then) = _$WorkDriverSnapshotCopyWithImpl;
@useResult
$Res call({
 List<WorkEntryState> entries
});




}
/// @nodoc
class _$WorkDriverSnapshotCopyWithImpl<$Res>
    implements $WorkDriverSnapshotCopyWith<$Res> {
  _$WorkDriverSnapshotCopyWithImpl(this._self, this._then);

  final WorkDriverSnapshot _self;
  final $Res Function(WorkDriverSnapshot) _then;

/// Create a copy of WorkDriverSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,}) {
  return _then(WorkDriverSnapshot(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<WorkEntryState>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkDriverSnapshot].
extension WorkDriverSnapshotPatterns on WorkDriverSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkDriverSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkDriverSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkDriverSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _WorkDriverSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkDriverSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _WorkDriverSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<WorkEntryState> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkDriverSnapshot() when $default != null:
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<WorkEntryState> entries)  $default,) {final _that = this;
switch (_that) {
case _WorkDriverSnapshot():
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<WorkEntryState> entries)?  $default,) {final _that = this;
switch (_that) {
case _WorkDriverSnapshot() when $default != null:
return $default(_that.entries);case _:
  return null;

}
}

}

/// @nodoc


class _WorkDriverSnapshot implements WorkDriverSnapshot {
  const _WorkDriverSnapshot({ List<WorkEntryState> entries = const []}): _entries = entries;


 final  List<WorkEntryState> _entries;
@override@JsonKey() List<WorkEntryState> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of WorkDriverSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkDriverSnapshotCopyWith<_WorkDriverSnapshot> get copyWith => __$WorkDriverSnapshotCopyWithImpl<_WorkDriverSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkDriverSnapshot&&const DeepCollectionEquality().equals(other.entries, _entries));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries));
}

@override
String toString() {
    return 'WorkDriverSnapshot(entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$WorkDriverSnapshotCopyWith<$Res> implements $WorkDriverSnapshotCopyWith<$Res> {
  factory _$WorkDriverSnapshotCopyWith(_WorkDriverSnapshot value, $Res Function(_WorkDriverSnapshot) _then) = __$WorkDriverSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<WorkEntryState> entries
});




}
/// @nodoc
class __$WorkDriverSnapshotCopyWithImpl<$Res>
    implements _$WorkDriverSnapshotCopyWith<$Res> {
  __$WorkDriverSnapshotCopyWithImpl(this._self, this._then);

  final _WorkDriverSnapshot _self;
  final $Res Function(_WorkDriverSnapshot) _then;

/// Create a copy of WorkDriverSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,}) {
  return _then(_WorkDriverSnapshot(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<WorkEntryState>,
  ));
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
