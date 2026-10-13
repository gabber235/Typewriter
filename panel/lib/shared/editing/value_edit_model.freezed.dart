// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'value_edit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ValueEditDocument {

 EditorSnapshot get metadata; skir.DataValue get value; Object? get identity; bool get exists;
/// Create a copy of ValueEditDocument
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueEditDocumentCopyWith<ValueEditDocument> get copyWith => _$ValueEditDocumentCopyWithImpl<ValueEditDocument>(this as ValueEditDocument, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ValueEditDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueEditDocument&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&(identical(other.value, _this.value) || other.value == _this.value)&&const DeepCollectionEquality().equals(other.identity, _this.identity)&&(identical(other.exists, _this.exists) || other.exists == _this.exists));
}


@override
int get hashCode {
  final _this = this as ValueEditDocument;
  return Object.hash(runtimeType,_this.metadata,_this.value,const DeepCollectionEquality().hash(_this.identity),_this.exists);
}

@override
String toString() {
  final _this = this as ValueEditDocument;
  return 'ValueEditDocument(metadata: ${_this.metadata}, value: ${_this.value}, identity: ${_this.identity}, exists: ${_this.exists})';
}


}

/// @nodoc
abstract mixin class $ValueEditDocumentCopyWith<$Res>  {
  factory $ValueEditDocumentCopyWith(ValueEditDocument value, $Res Function(ValueEditDocument) _then) = _$ValueEditDocumentCopyWithImpl;
@useResult
$Res call({
 EditorSnapshot metadata, skir.DataValue value, Object? identity, bool exists
});




}
/// @nodoc
class _$ValueEditDocumentCopyWithImpl<$Res>
    implements $ValueEditDocumentCopyWith<$Res> {
  _$ValueEditDocumentCopyWithImpl(this._self, this._then);

  final ValueEditDocument _self;
  final $Res Function(ValueEditDocument) _then;

/// Create a copy of ValueEditDocument
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadata = null,Object? value = null,Object? identity = freezed,Object? exists = null,}) {
  return _then(ValueEditDocument(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as EditorSnapshot,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,identity: freezed == identity ? _self.identity : identity ,exists: null == exists ? _self.exists : exists // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern matching related methods to [ValueEditDocument].
extension ValueEditDocumentPatterns on ValueEditDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ValueEditDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValueEditDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ValueEditDocument value)  $default,){
final _that = this;
switch (_that) {
case _ValueEditDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ValueEditDocument value)?  $default,){
final _that = this;
switch (_that) {
case _ValueEditDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorSnapshot metadata,  skir.DataValue value,  Object? identity,  bool exists)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValueEditDocument() when $default != null:
return $default(_that.metadata,_that.value,_that.identity,_that.exists);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorSnapshot metadata,  skir.DataValue value,  Object? identity,  bool exists)  $default,) {final _that = this;
switch (_that) {
case _ValueEditDocument():
return $default(_that.metadata,_that.value,_that.identity,_that.exists);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorSnapshot metadata,  skir.DataValue value,  Object? identity,  bool exists)?  $default,) {final _that = this;
switch (_that) {
case _ValueEditDocument() when $default != null:
return $default(_that.metadata,_that.value,_that.identity,_that.exists);case _:
  return null;

}
}

}

/// @nodoc


class _ValueEditDocument extends ValueEditDocument {
  const _ValueEditDocument({required this.metadata, required this.value, this.identity, this.exists = true}): super._();


@override final  EditorSnapshot metadata;
@override final  skir.DataValue value;
@override final  Object? identity;
@override@JsonKey() final  bool exists;

/// Create a copy of ValueEditDocument
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValueEditDocumentCopyWith<_ValueEditDocument> get copyWith => __$ValueEditDocumentCopyWithImpl<_ValueEditDocument>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValueEditDocument&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other.identity, identity)&&(identical(other.exists, exists) || other.exists == exists));
}


@override
int get hashCode {
    return Object.hash(runtimeType,metadata,value,const DeepCollectionEquality().hash(identity),exists);
}

@override
String toString() {
    return 'ValueEditDocument(metadata: $metadata, value: $value, identity: $identity, exists: $exists)';
}


}

/// @nodoc
abstract mixin class _$ValueEditDocumentCopyWith<$Res> implements $ValueEditDocumentCopyWith<$Res> {
  factory _$ValueEditDocumentCopyWith(_ValueEditDocument value, $Res Function(_ValueEditDocument) _then) = __$ValueEditDocumentCopyWithImpl;
@override @useResult
$Res call({
 EditorSnapshot metadata, skir.DataValue value, Object? identity, bool exists
});




}
/// @nodoc
class __$ValueEditDocumentCopyWithImpl<$Res>
    implements _$ValueEditDocumentCopyWith<$Res> {
  __$ValueEditDocumentCopyWithImpl(this._self, this._then);

  final _ValueEditDocument _self;
  final $Res Function(_ValueEditDocument) _then;

/// Create a copy of ValueEditDocument
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metadata = null,Object? value = null,Object? identity = freezed,Object? exists = null,}) {
  return _then(_ValueEditDocument(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as EditorSnapshot,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,identity: freezed == identity ? _self.identity : identity ,exists: null == exists ? _self.exists : exists // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$ValueEdit {

 ValueEditDocument get baseline; skir.DataValue get proposed; Set<skir.ValuePath> get paths; List<EditorStructuralMutation> get mutations;
/// Create a copy of ValueEdit
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueEditCopyWith<ValueEdit> get copyWith => _$ValueEditCopyWithImpl<ValueEdit>(this as ValueEdit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ValueEdit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueEdit&&(identical(other.baseline, _this.baseline) || other.baseline == _this.baseline)&&(identical(other.proposed, _this.proposed) || other.proposed == _this.proposed)&&const DeepCollectionEquality().equals(other.paths, _this.paths)&&const DeepCollectionEquality().equals(other.mutations, _this.mutations));
}


@override
int get hashCode {
  final _this = this as ValueEdit;
  return Object.hash(runtimeType,_this.baseline,_this.proposed,const DeepCollectionEquality().hash(_this.paths),const DeepCollectionEquality().hash(_this.mutations));
}

@override
String toString() {
  final _this = this as ValueEdit;
  return 'ValueEdit(baseline: ${_this.baseline}, proposed: ${_this.proposed}, paths: ${_this.paths}, mutations: ${_this.mutations})';
}


}

/// @nodoc
abstract mixin class $ValueEditCopyWith<$Res>  {
  factory $ValueEditCopyWith(ValueEdit value, $Res Function(ValueEdit) _then) = _$ValueEditCopyWithImpl;
@useResult
$Res call({
 ValueEditDocument baseline, skir.DataValue proposed, Set<skir.ValuePath> paths, List<EditorStructuralMutation> mutations
});


$ValueEditDocumentCopyWith<$Res> get baseline;

}
/// @nodoc
class _$ValueEditCopyWithImpl<$Res>
    implements $ValueEditCopyWith<$Res> {
  _$ValueEditCopyWithImpl(this._self, this._then);

  final ValueEdit _self;
  final $Res Function(ValueEdit) _then;

/// Create a copy of ValueEdit
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseline = null,Object? proposed = null,Object? paths = null,Object? mutations = null,}) {
  return _then(ValueEdit(
baseline: null == baseline ? _self.baseline : baseline // ignore: cast_nullable_to_non_nullable
as ValueEditDocument,proposed: null == proposed ? _self.proposed : proposed // ignore: cast_nullable_to_non_nullable
as skir.DataValue,paths: null == paths ? _self.paths : paths // ignore: cast_nullable_to_non_nullable
as Set<skir.ValuePath>,mutations: null == mutations ? _self.mutations : mutations // ignore: cast_nullable_to_non_nullable
as List<EditorStructuralMutation>,
  ));
}
/// Create a copy of ValueEdit
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$ValueEditDocumentCopyWith<$Res> get baseline {

  return $ValueEditDocumentCopyWith<$Res>(_self.baseline, (value) {
    return _then(_self.copyWith(baseline: value));
  });
}
}


/// Adds pattern matching related methods to [ValueEdit].
extension ValueEditPatterns on ValueEdit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ValueEdit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValueEdit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ValueEdit value)  $default,){
final _that = this;
switch (_that) {
case _ValueEdit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ValueEdit value)?  $default,){
final _that = this;
switch (_that) {
case _ValueEdit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ValueEditDocument baseline,  skir.DataValue proposed,  Set<skir.ValuePath> paths,  List<EditorStructuralMutation> mutations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValueEdit() when $default != null:
return $default(_that.baseline,_that.proposed,_that.paths,_that.mutations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ValueEditDocument baseline,  skir.DataValue proposed,  Set<skir.ValuePath> paths,  List<EditorStructuralMutation> mutations)  $default,) {final _that = this;
switch (_that) {
case _ValueEdit():
return $default(_that.baseline,_that.proposed,_that.paths,_that.mutations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ValueEditDocument baseline,  skir.DataValue proposed,  Set<skir.ValuePath> paths,  List<EditorStructuralMutation> mutations)?  $default,) {final _that = this;
switch (_that) {
case _ValueEdit() when $default != null:
return $default(_that.baseline,_that.proposed,_that.paths,_that.mutations);case _:
  return null;

}
}

}

/// @nodoc


class _ValueEdit implements ValueEdit {
  const _ValueEdit({required this.baseline, required this.proposed, required  Set<skir.ValuePath> paths,  List<EditorStructuralMutation> mutations = const []}): _paths = paths,_mutations = mutations;


@override final  ValueEditDocument baseline;
@override final  skir.DataValue proposed;
 final  Set<skir.ValuePath> _paths;
@override Set<skir.ValuePath> get paths {
  if (_paths is EqualUnmodifiableSetView) return _paths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_paths);
}

 final  List<EditorStructuralMutation> _mutations;
@override@JsonKey() List<EditorStructuralMutation> get mutations {
  if (_mutations is EqualUnmodifiableListView) return _mutations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mutations);
}


/// Create a copy of ValueEdit
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValueEditCopyWith<_ValueEdit> get copyWith => __$ValueEditCopyWithImpl<_ValueEdit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValueEdit&&(identical(other.baseline, baseline) || other.baseline == baseline)&&(identical(other.proposed, proposed) || other.proposed == proposed)&&const DeepCollectionEquality().equals(other.paths, _paths)&&const DeepCollectionEquality().equals(other.mutations, _mutations));
}


@override
int get hashCode {
    return Object.hash(runtimeType,baseline,proposed,const DeepCollectionEquality().hash(_paths),const DeepCollectionEquality().hash(_mutations));
}

@override
String toString() {
    return 'ValueEdit(baseline: $baseline, proposed: $proposed, paths: $paths, mutations: $mutations)';
}


}

/// @nodoc
abstract mixin class _$ValueEditCopyWith<$Res> implements $ValueEditCopyWith<$Res> {
  factory _$ValueEditCopyWith(_ValueEdit value, $Res Function(_ValueEdit) _then) = __$ValueEditCopyWithImpl;
@override @useResult
$Res call({
 ValueEditDocument baseline, skir.DataValue proposed, Set<skir.ValuePath> paths, List<EditorStructuralMutation> mutations
});


@override $ValueEditDocumentCopyWith<$Res> get baseline;

}
/// @nodoc
class __$ValueEditCopyWithImpl<$Res>
    implements _$ValueEditCopyWith<$Res> {
  __$ValueEditCopyWithImpl(this._self, this._then);

  final _ValueEdit _self;
  final $Res Function(_ValueEdit) _then;

/// Create a copy of ValueEdit
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseline = null,Object? proposed = null,Object? paths = null,Object? mutations = null,}) {
  return _then(_ValueEdit(
baseline: null == baseline ? _self.baseline : baseline // ignore: cast_nullable_to_non_nullable
as ValueEditDocument,proposed: null == proposed ? _self.proposed : proposed // ignore: cast_nullable_to_non_nullable
as skir.DataValue,paths: null == paths ? _self._paths : paths // ignore: cast_nullable_to_non_nullable
as Set<skir.ValuePath>,mutations: null == mutations ? _self._mutations : mutations // ignore: cast_nullable_to_non_nullable
as List<EditorStructuralMutation>,
  ));
}

/// Create a copy of ValueEdit
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$ValueEditDocumentCopyWith<$Res> get baseline {

  return $ValueEditDocumentCopyWith<$Res>(_self.baseline, (value) {
    return _then(_self.copyWith(baseline: value));
  });
}
}

/// @nodoc
mixin _$ValueConflictEvidence {

 Map<skir.ValuePath, EditorPathConflict> get paths; TypedMutationResult? get response; List<EditorDiagnostic> get diagnostics;
/// Create a copy of ValueConflictEvidence
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueConflictEvidenceCopyWith<ValueConflictEvidence> get copyWith => _$ValueConflictEvidenceCopyWithImpl<ValueConflictEvidence>(this as ValueConflictEvidence, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ValueConflictEvidence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueConflictEvidence&&const DeepCollectionEquality().equals(other.paths, _this.paths)&&(identical(other.response, _this.response) || other.response == _this.response)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as ValueConflictEvidence;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.paths),_this.response,const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as ValueConflictEvidence;
  return 'ValueConflictEvidence(paths: ${_this.paths}, response: ${_this.response}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $ValueConflictEvidenceCopyWith<$Res>  {
  factory $ValueConflictEvidenceCopyWith(ValueConflictEvidence value, $Res Function(ValueConflictEvidence) _then) = _$ValueConflictEvidenceCopyWithImpl;
@useResult
$Res call({
 Map<skir.ValuePath, EditorPathConflict> paths, TypedMutationResult? response, List<EditorDiagnostic> diagnostics
});


$TypedMutationResultCopyWith<$Res>? get response;

}
/// @nodoc
class _$ValueConflictEvidenceCopyWithImpl<$Res>
    implements $ValueConflictEvidenceCopyWith<$Res> {
  _$ValueConflictEvidenceCopyWithImpl(this._self, this._then);

  final ValueConflictEvidence _self;
  final $Res Function(ValueConflictEvidence) _then;

/// Create a copy of ValueConflictEvidence
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paths = null,Object? response = freezed,Object? diagnostics = null,}) {
  return _then(ValueConflictEvidence(
paths: null == paths ? _self.paths : paths // ignore: cast_nullable_to_non_nullable
as Map<skir.ValuePath, EditorPathConflict>,response: freezed == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as TypedMutationResult?,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}
/// Create a copy of ValueConflictEvidence
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedMutationResultCopyWith<$Res>? get response {
    if (_self.response == null) {
    return null;
  }

  return $TypedMutationResultCopyWith<$Res>(_self.response!, (value) {
    return _then(_self.copyWith(response: value));
  });
}
}


/// Adds pattern matching related methods to [ValueConflictEvidence].
extension ValueConflictEvidencePatterns on ValueConflictEvidence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ValueConflictEvidence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValueConflictEvidence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ValueConflictEvidence value)  $default,){
final _that = this;
switch (_that) {
case _ValueConflictEvidence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ValueConflictEvidence value)?  $default,){
final _that = this;
switch (_that) {
case _ValueConflictEvidence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<skir.ValuePath, EditorPathConflict> paths,  TypedMutationResult? response,  List<EditorDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValueConflictEvidence() when $default != null:
return $default(_that.paths,_that.response,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<skir.ValuePath, EditorPathConflict> paths,  TypedMutationResult? response,  List<EditorDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _ValueConflictEvidence():
return $default(_that.paths,_that.response,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<skir.ValuePath, EditorPathConflict> paths,  TypedMutationResult? response,  List<EditorDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _ValueConflictEvidence() when $default != null:
return $default(_that.paths,_that.response,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _ValueConflictEvidence extends ValueConflictEvidence {
  const _ValueConflictEvidence({ Map<skir.ValuePath, EditorPathConflict> paths = const {}, this.response,  List<EditorDiagnostic> diagnostics = const []}): _paths = paths,_diagnostics = diagnostics,super._();


 final  Map<skir.ValuePath, EditorPathConflict> _paths;
@override@JsonKey() Map<skir.ValuePath, EditorPathConflict> get paths {
  if (_paths is EqualUnmodifiableMapView) return _paths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_paths);
}

@override final  TypedMutationResult? response;
 final  List<EditorDiagnostic> _diagnostics;
@override@JsonKey() List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of ValueConflictEvidence
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValueConflictEvidenceCopyWith<_ValueConflictEvidence> get copyWith => __$ValueConflictEvidenceCopyWithImpl<_ValueConflictEvidence>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValueConflictEvidence&&const DeepCollectionEquality().equals(other.paths, _paths)&&(identical(other.response, response) || other.response == response)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_paths),response,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'ValueConflictEvidence(paths: $paths, response: $response, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$ValueConflictEvidenceCopyWith<$Res> implements $ValueConflictEvidenceCopyWith<$Res> {
  factory _$ValueConflictEvidenceCopyWith(_ValueConflictEvidence value, $Res Function(_ValueConflictEvidence) _then) = __$ValueConflictEvidenceCopyWithImpl;
@override @useResult
$Res call({
 Map<skir.ValuePath, EditorPathConflict> paths, TypedMutationResult? response, List<EditorDiagnostic> diagnostics
});


@override $TypedMutationResultCopyWith<$Res>? get response;

}
/// @nodoc
class __$ValueConflictEvidenceCopyWithImpl<$Res>
    implements _$ValueConflictEvidenceCopyWith<$Res> {
  __$ValueConflictEvidenceCopyWithImpl(this._self, this._then);

  final _ValueConflictEvidence _self;
  final $Res Function(_ValueConflictEvidence) _then;

/// Create a copy of ValueConflictEvidence
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paths = null,Object? response = freezed,Object? diagnostics = null,}) {
  return _then(_ValueConflictEvidence(
paths: null == paths ? _self._paths : paths // ignore: cast_nullable_to_non_nullable
as Map<skir.ValuePath, EditorPathConflict>,response: freezed == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as TypedMutationResult?,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,
  ));
}

/// Create a copy of ValueConflictEvidence
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedMutationResultCopyWith<$Res>? get response {
    if (_self.response == null) {
    return null;
  }

  return $TypedMutationResultCopyWith<$Res>(_self.response!, (value) {
    return _then(_self.copyWith(response: value));
  });
}
}

// dart format on
