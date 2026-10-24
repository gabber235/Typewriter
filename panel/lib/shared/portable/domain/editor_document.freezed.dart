// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditorDocument {

 skir.TypeUse get rootType; CheckedEditorCatalog get catalog; skir.DataValue get confirmedValue; int get revision; Map<skir.ValuePath, EditorMergePolicy> get mergePolicies; List<EditorDiagnostic> get diagnostics; bool get readOnly;
/// Create a copy of EditorDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorDocumentCopyWith<EditorDocument> get copyWith => _$EditorDocumentCopyWithImpl<EditorDocument>(this as EditorDocument, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorDocument&&(identical(other.rootType, _this.rootType) || other.rootType == _this.rootType)&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.confirmedValue, _this.confirmedValue) || other.confirmedValue == _this.confirmedValue)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&const DeepCollectionEquality().equals(other.mergePolicies, _this.mergePolicies)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics)&&(identical(other.readOnly, _this.readOnly) || other.readOnly == _this.readOnly));
}


@override
int get hashCode {
  final _this = this as EditorDocument;
  return Object.hash(runtimeType,_this.rootType,_this.catalog,_this.confirmedValue,_this.revision,const DeepCollectionEquality().hash(_this.mergePolicies),const DeepCollectionEquality().hash(_this.diagnostics),_this.readOnly);
}

@override
String toString() {
  final _this = this as EditorDocument;
  return 'EditorDocument(rootType: ${_this.rootType}, catalog: ${_this.catalog}, confirmedValue: ${_this.confirmedValue}, revision: ${_this.revision}, mergePolicies: ${_this.mergePolicies}, diagnostics: ${_this.diagnostics}, readOnly: ${_this.readOnly})';
}


}

/// @nodoc
abstract mixin class $EditorDocumentCopyWith<$Res>  {
  factory $EditorDocumentCopyWith(EditorDocument value, $Res Function(EditorDocument) _then) = _$EditorDocumentCopyWithImpl;
@useResult
$Res call({
 skir.TypeUse rootType, CheckedEditorCatalog catalog, skir.DataValue confirmedValue, int revision, Map<skir.ValuePath, EditorMergePolicy> mergePolicies, List<EditorDiagnostic> diagnostics, bool readOnly
});




}
/// @nodoc
class _$EditorDocumentCopyWithImpl<$Res>
    implements $EditorDocumentCopyWith<$Res> {
  _$EditorDocumentCopyWithImpl(this._self, this._then);

  final EditorDocument _self;
  final $Res Function(EditorDocument) _then;

/// Create a copy of EditorDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rootType = null,Object? catalog = null,Object? confirmedValue = null,Object? revision = null,Object? mergePolicies = null,Object? diagnostics = null,Object? readOnly = null,}) {
  return _then(EditorDocument(
rootType: null == rootType ? _self.rootType : rootType // ignore: cast_nullable_to_non_nullable
as skir.TypeUse,catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog,confirmedValue: null == confirmedValue ? _self.confirmedValue : confirmedValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,mergePolicies: null == mergePolicies ? _self.mergePolicies : mergePolicies // ignore: cast_nullable_to_non_nullable
as Map<skir.ValuePath, EditorMergePolicy>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EditorDocument].
extension EditorDocumentPatterns on EditorDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorDocument value)  $default,){
final _that = this;
switch (_that) {
case _EditorDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorDocument value)?  $default,){
final _that = this;
switch (_that) {
case _EditorDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.TypeUse rootType,  CheckedEditorCatalog catalog,  skir.DataValue confirmedValue,  int revision,  Map<skir.ValuePath, EditorMergePolicy> mergePolicies,  List<EditorDiagnostic> diagnostics,  bool readOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorDocument() when $default != null:
return $default(_that.rootType,_that.catalog,_that.confirmedValue,_that.revision,_that.mergePolicies,_that.diagnostics,_that.readOnly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.TypeUse rootType,  CheckedEditorCatalog catalog,  skir.DataValue confirmedValue,  int revision,  Map<skir.ValuePath, EditorMergePolicy> mergePolicies,  List<EditorDiagnostic> diagnostics,  bool readOnly)  $default,) {final _that = this;
switch (_that) {
case _EditorDocument():
return $default(_that.rootType,_that.catalog,_that.confirmedValue,_that.revision,_that.mergePolicies,_that.diagnostics,_that.readOnly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.TypeUse rootType,  CheckedEditorCatalog catalog,  skir.DataValue confirmedValue,  int revision,  Map<skir.ValuePath, EditorMergePolicy> mergePolicies,  List<EditorDiagnostic> diagnostics,  bool readOnly)?  $default,) {final _that = this;
switch (_that) {
case _EditorDocument() when $default != null:
return $default(_that.rootType,_that.catalog,_that.confirmedValue,_that.revision,_that.mergePolicies,_that.diagnostics,_that.readOnly);case _:
  return null;

}
}

}

/// @nodoc


class _EditorDocument extends EditorDocument {
  const _EditorDocument({required this.rootType, required this.catalog, required this.confirmedValue, required this.revision,  Map<skir.ValuePath, EditorMergePolicy> mergePolicies = const {},  List<EditorDiagnostic> diagnostics = const [], this.readOnly = false}): assert(revision >= 0, 'Revision must not be negative.'),_mergePolicies = mergePolicies,_diagnostics = diagnostics,super._();
  

@override final  skir.TypeUse rootType;
@override final  CheckedEditorCatalog catalog;
@override final  skir.DataValue confirmedValue;
@override final  int revision;
 final  Map<skir.ValuePath, EditorMergePolicy> _mergePolicies;
@override@JsonKey() Map<skir.ValuePath, EditorMergePolicy> get mergePolicies {
  if (_mergePolicies is EqualUnmodifiableMapView) return _mergePolicies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_mergePolicies);
}

 final  List<EditorDiagnostic> _diagnostics;
@override@JsonKey() List<EditorDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

@override@JsonKey() final  bool readOnly;

/// Create a copy of EditorDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorDocumentCopyWith<_EditorDocument> get copyWith => __$EditorDocumentCopyWithImpl<_EditorDocument>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorDocument&&(identical(other.rootType, rootType) || other.rootType == rootType)&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.confirmedValue, confirmedValue) || other.confirmedValue == confirmedValue)&&(identical(other.revision, revision) || other.revision == revision)&&const DeepCollectionEquality().equals(other.mergePolicies, _mergePolicies)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly));
}


@override
int get hashCode {
    return Object.hash(runtimeType,rootType,catalog,confirmedValue,revision,const DeepCollectionEquality().hash(_mergePolicies),const DeepCollectionEquality().hash(_diagnostics),readOnly);
}

@override
String toString() {
    return 'EditorDocument(rootType: $rootType, catalog: $catalog, confirmedValue: $confirmedValue, revision: $revision, mergePolicies: $mergePolicies, diagnostics: $diagnostics, readOnly: $readOnly)';
}


}

/// @nodoc
abstract mixin class _$EditorDocumentCopyWith<$Res> implements $EditorDocumentCopyWith<$Res> {
  factory _$EditorDocumentCopyWith(_EditorDocument value, $Res Function(_EditorDocument) _then) = __$EditorDocumentCopyWithImpl;
@override @useResult
$Res call({
 skir.TypeUse rootType, CheckedEditorCatalog catalog, skir.DataValue confirmedValue, int revision, Map<skir.ValuePath, EditorMergePolicy> mergePolicies, List<EditorDiagnostic> diagnostics, bool readOnly
});




}
/// @nodoc
class __$EditorDocumentCopyWithImpl<$Res>
    implements _$EditorDocumentCopyWith<$Res> {
  __$EditorDocumentCopyWithImpl(this._self, this._then);

  final _EditorDocument _self;
  final $Res Function(_EditorDocument) _then;

/// Create a copy of EditorDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rootType = null,Object? catalog = null,Object? confirmedValue = null,Object? revision = null,Object? mergePolicies = null,Object? diagnostics = null,Object? readOnly = null,}) {
  return _then(_EditorDocument(
rootType: null == rootType ? _self.rootType : rootType // ignore: cast_nullable_to_non_nullable
as skir.TypeUse,catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog,confirmedValue: null == confirmedValue ? _self.confirmedValue : confirmedValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,mergePolicies: null == mergePolicies ? _self._mergePolicies : mergePolicies // ignore: cast_nullable_to_non_nullable
as Map<skir.ValuePath, EditorMergePolicy>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<EditorDiagnostic>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$EditorCommit {

 int get expectedRevision; int get localRevision; skir.DataValue get rootValue; skir.DataValue get baseValue; Set<skir.ValuePath> get changedPaths; List<EditorSetValue> get mutations;
/// Create a copy of EditorCommit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorCommitCopyWith<EditorCommit> get copyWith => _$EditorCommitCopyWithImpl<EditorCommit>(this as EditorCommit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorCommit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorCommit&&(identical(other.expectedRevision, _this.expectedRevision) || other.expectedRevision == _this.expectedRevision)&&(identical(other.localRevision, _this.localRevision) || other.localRevision == _this.localRevision)&&(identical(other.rootValue, _this.rootValue) || other.rootValue == _this.rootValue)&&(identical(other.baseValue, _this.baseValue) || other.baseValue == _this.baseValue)&&const DeepCollectionEquality().equals(other.changedPaths, _this.changedPaths)&&const DeepCollectionEquality().equals(other.mutations, _this.mutations));
}


@override
int get hashCode {
  final _this = this as EditorCommit;
  return Object.hash(runtimeType,_this.expectedRevision,_this.localRevision,_this.rootValue,_this.baseValue,const DeepCollectionEquality().hash(_this.changedPaths),const DeepCollectionEquality().hash(_this.mutations));
}

@override
String toString() {
  final _this = this as EditorCommit;
  return 'EditorCommit(expectedRevision: ${_this.expectedRevision}, localRevision: ${_this.localRevision}, rootValue: ${_this.rootValue}, baseValue: ${_this.baseValue}, changedPaths: ${_this.changedPaths}, mutations: ${_this.mutations})';
}


}

/// @nodoc
abstract mixin class $EditorCommitCopyWith<$Res>  {
  factory $EditorCommitCopyWith(EditorCommit value, $Res Function(EditorCommit) _then) = _$EditorCommitCopyWithImpl;
@useResult
$Res call({
 int expectedRevision, int localRevision, skir.DataValue rootValue, skir.DataValue baseValue, Set<skir.ValuePath> changedPaths, List<EditorSetValue> mutations
});




}
/// @nodoc
class _$EditorCommitCopyWithImpl<$Res>
    implements $EditorCommitCopyWith<$Res> {
  _$EditorCommitCopyWithImpl(this._self, this._then);

  final EditorCommit _self;
  final $Res Function(EditorCommit) _then;

/// Create a copy of EditorCommit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? expectedRevision = null,Object? localRevision = null,Object? rootValue = null,Object? baseValue = null,Object? changedPaths = null,Object? mutations = null,}) {
  return _then(EditorCommit(
expectedRevision: null == expectedRevision ? _self.expectedRevision : expectedRevision // ignore: cast_nullable_to_non_nullable
as int,localRevision: null == localRevision ? _self.localRevision : localRevision // ignore: cast_nullable_to_non_nullable
as int,rootValue: null == rootValue ? _self.rootValue : rootValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,baseValue: null == baseValue ? _self.baseValue : baseValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,changedPaths: null == changedPaths ? _self.changedPaths : changedPaths // ignore: cast_nullable_to_non_nullable
as Set<skir.ValuePath>,mutations: null == mutations ? _self.mutations : mutations // ignore: cast_nullable_to_non_nullable
as List<EditorSetValue>,
  ));
}

}


/// Adds pattern-matching-related methods to [EditorCommit].
extension EditorCommitPatterns on EditorCommit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorCommit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorCommit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorCommit value)  $default,){
final _that = this;
switch (_that) {
case _EditorCommit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorCommit value)?  $default,){
final _that = this;
switch (_that) {
case _EditorCommit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int expectedRevision,  int localRevision,  skir.DataValue rootValue,  skir.DataValue baseValue,  Set<skir.ValuePath> changedPaths,  List<EditorSetValue> mutations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorCommit() when $default != null:
return $default(_that.expectedRevision,_that.localRevision,_that.rootValue,_that.baseValue,_that.changedPaths,_that.mutations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int expectedRevision,  int localRevision,  skir.DataValue rootValue,  skir.DataValue baseValue,  Set<skir.ValuePath> changedPaths,  List<EditorSetValue> mutations)  $default,) {final _that = this;
switch (_that) {
case _EditorCommit():
return $default(_that.expectedRevision,_that.localRevision,_that.rootValue,_that.baseValue,_that.changedPaths,_that.mutations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int expectedRevision,  int localRevision,  skir.DataValue rootValue,  skir.DataValue baseValue,  Set<skir.ValuePath> changedPaths,  List<EditorSetValue> mutations)?  $default,) {final _that = this;
switch (_that) {
case _EditorCommit() when $default != null:
return $default(_that.expectedRevision,_that.localRevision,_that.rootValue,_that.baseValue,_that.changedPaths,_that.mutations);case _:
  return null;

}
}

}

/// @nodoc


class _EditorCommit implements EditorCommit {
  const _EditorCommit({required this.expectedRevision, required this.localRevision, required this.rootValue, required this.baseValue, required  Set<skir.ValuePath> changedPaths,  List<EditorSetValue> mutations = const []}): assert(expectedRevision >= 0, 'Expected revision must not be negative.'),assert(localRevision >= 0, 'Local revision must not be negative.'),_changedPaths = changedPaths,_mutations = mutations;
  

@override final  int expectedRevision;
@override final  int localRevision;
@override final  skir.DataValue rootValue;
@override final  skir.DataValue baseValue;
 final  Set<skir.ValuePath> _changedPaths;
@override Set<skir.ValuePath> get changedPaths {
  if (_changedPaths is EqualUnmodifiableSetView) return _changedPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_changedPaths);
}

 final  List<EditorSetValue> _mutations;
@override@JsonKey() List<EditorSetValue> get mutations {
  if (_mutations is EqualUnmodifiableListView) return _mutations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mutations);
}


/// Create a copy of EditorCommit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorCommitCopyWith<_EditorCommit> get copyWith => __$EditorCommitCopyWithImpl<_EditorCommit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorCommit&&(identical(other.expectedRevision, expectedRevision) || other.expectedRevision == expectedRevision)&&(identical(other.localRevision, localRevision) || other.localRevision == localRevision)&&(identical(other.rootValue, rootValue) || other.rootValue == rootValue)&&(identical(other.baseValue, baseValue) || other.baseValue == baseValue)&&const DeepCollectionEquality().equals(other.changedPaths, _changedPaths)&&const DeepCollectionEquality().equals(other.mutations, _mutations));
}


@override
int get hashCode {
    return Object.hash(runtimeType,expectedRevision,localRevision,rootValue,baseValue,const DeepCollectionEquality().hash(_changedPaths),const DeepCollectionEquality().hash(_mutations));
}

@override
String toString() {
    return 'EditorCommit(expectedRevision: $expectedRevision, localRevision: $localRevision, rootValue: $rootValue, baseValue: $baseValue, changedPaths: $changedPaths, mutations: $mutations)';
}


}

/// @nodoc
abstract mixin class _$EditorCommitCopyWith<$Res> implements $EditorCommitCopyWith<$Res> {
  factory _$EditorCommitCopyWith(_EditorCommit value, $Res Function(_EditorCommit) _then) = __$EditorCommitCopyWithImpl;
@override @useResult
$Res call({
 int expectedRevision, int localRevision, skir.DataValue rootValue, skir.DataValue baseValue, Set<skir.ValuePath> changedPaths, List<EditorSetValue> mutations
});




}
/// @nodoc
class __$EditorCommitCopyWithImpl<$Res>
    implements _$EditorCommitCopyWith<$Res> {
  __$EditorCommitCopyWithImpl(this._self, this._then);

  final _EditorCommit _self;
  final $Res Function(_EditorCommit) _then;

/// Create a copy of EditorCommit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? expectedRevision = null,Object? localRevision = null,Object? rootValue = null,Object? baseValue = null,Object? changedPaths = null,Object? mutations = null,}) {
  return _then(_EditorCommit(
expectedRevision: null == expectedRevision ? _self.expectedRevision : expectedRevision // ignore: cast_nullable_to_non_nullable
as int,localRevision: null == localRevision ? _self.localRevision : localRevision // ignore: cast_nullable_to_non_nullable
as int,rootValue: null == rootValue ? _self.rootValue : rootValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,baseValue: null == baseValue ? _self.baseValue : baseValue // ignore: cast_nullable_to_non_nullable
as skir.DataValue,changedPaths: null == changedPaths ? _self._changedPaths : changedPaths // ignore: cast_nullable_to_non_nullable
as Set<skir.ValuePath>,mutations: null == mutations ? _self._mutations : mutations // ignore: cast_nullable_to_non_nullable
as List<EditorSetValue>,
  ));
}


}

/// @nodoc
mixin _$EditorSetValue {

 skir.ValuePath get path; skir.DataValue get value;
/// Create a copy of EditorSetValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditorSetValueCopyWith<EditorSetValue> get copyWith => _$EditorSetValueCopyWithImpl<EditorSetValue>(this as EditorSetValue, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EditorSetValue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditorSetValue&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as EditorSetValue;
  return Object.hash(runtimeType,_this.path,_this.value);
}

@override
String toString() {
  final _this = this as EditorSetValue;
  return 'EditorSetValue(path: ${_this.path}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $EditorSetValueCopyWith<$Res>  {
  factory $EditorSetValueCopyWith(EditorSetValue value, $Res Function(EditorSetValue) _then) = _$EditorSetValueCopyWithImpl;
@useResult
$Res call({
 skir.ValuePath path, skir.DataValue value
});




}
/// @nodoc
class _$EditorSetValueCopyWithImpl<$Res>
    implements $EditorSetValueCopyWith<$Res> {
  _$EditorSetValueCopyWithImpl(this._self, this._then);

  final EditorSetValue _self;
  final $Res Function(EditorSetValue) _then;

/// Create a copy of EditorSetValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? value = null,}) {
  return _then(EditorSetValue(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,
  ));
}

}


/// Adds pattern-matching-related methods to [EditorSetValue].
extension EditorSetValuePatterns on EditorSetValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditorSetValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditorSetValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditorSetValue value)  $default,){
final _that = this;
switch (_that) {
case _EditorSetValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditorSetValue value)?  $default,){
final _that = this;
switch (_that) {
case _EditorSetValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ValuePath path,  skir.DataValue value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditorSetValue() when $default != null:
return $default(_that.path,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ValuePath path,  skir.DataValue value)  $default,) {final _that = this;
switch (_that) {
case _EditorSetValue():
return $default(_that.path,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ValuePath path,  skir.DataValue value)?  $default,) {final _that = this;
switch (_that) {
case _EditorSetValue() when $default != null:
return $default(_that.path,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _EditorSetValue implements EditorSetValue {
  const _EditorSetValue(this.path, this.value);
  

@override final  skir.ValuePath path;
@override final  skir.DataValue value;

/// Create a copy of EditorSetValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditorSetValueCopyWith<_EditorSetValue> get copyWith => __$EditorSetValueCopyWithImpl<_EditorSetValue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditorSetValue&&(identical(other.path, path) || other.path == path)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,value);
}

@override
String toString() {
    return 'EditorSetValue(path: $path, value: $value)';
}


}

/// @nodoc
abstract mixin class _$EditorSetValueCopyWith<$Res> implements $EditorSetValueCopyWith<$Res> {
  factory _$EditorSetValueCopyWith(_EditorSetValue value, $Res Function(_EditorSetValue) _then) = __$EditorSetValueCopyWithImpl;
@override @useResult
$Res call({
 skir.ValuePath path, skir.DataValue value
});




}
/// @nodoc
class __$EditorSetValueCopyWithImpl<$Res>
    implements _$EditorSetValueCopyWith<$Res> {
  __$EditorSetValueCopyWithImpl(this._self, this._then);

  final _EditorSetValue _self;
  final $Res Function(_EditorSetValue) _then;

/// Create a copy of EditorSetValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? value = null,}) {
  return _then(_EditorSetValue(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as skir.ValuePath,null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,
  ));
}


}

// dart format on
