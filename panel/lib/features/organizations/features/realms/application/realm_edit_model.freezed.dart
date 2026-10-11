// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_edit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmPreparedEdit {

 skir.PreparedEdit get request; List<skir.InitializationDiagnostic> get findings;
/// Create a copy of RealmPreparedEdit
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPreparedEditCopyWith<RealmPreparedEdit> get copyWith => _$RealmPreparedEditCopyWithImpl<RealmPreparedEdit>(this as RealmPreparedEdit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmPreparedEdit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPreparedEdit&&(identical(other.request, _this.request) || other.request == _this.request)&&const DeepCollectionEquality().equals(other.findings, _this.findings));
}


@override
int get hashCode {
  final _this = this as RealmPreparedEdit;
  return Object.hash(runtimeType,_this.request,const DeepCollectionEquality().hash(_this.findings));
}

@override
String toString() {
  final _this = this as RealmPreparedEdit;
  return 'RealmPreparedEdit(request: ${_this.request}, findings: ${_this.findings})';
}


}

/// @nodoc
abstract mixin class $RealmPreparedEditCopyWith<$Res>  {
  factory $RealmPreparedEditCopyWith(RealmPreparedEdit value, $Res Function(RealmPreparedEdit) _then) = _$RealmPreparedEditCopyWithImpl;
@useResult
$Res call({
 skir.PreparedEdit request, List<skir.InitializationDiagnostic> findings
});




}
/// @nodoc
class _$RealmPreparedEditCopyWithImpl<$Res>
    implements $RealmPreparedEditCopyWith<$Res> {
  _$RealmPreparedEditCopyWithImpl(this._self, this._then);

  final RealmPreparedEdit _self;
  final $Res Function(RealmPreparedEdit) _then;

/// Create a copy of RealmPreparedEdit
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? request = null,Object? findings = null,}) {
  return _then(RealmPreparedEdit(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as skir.PreparedEdit,findings: null == findings ? _self.findings : findings // ignore: cast_nullable_to_non_nullable
as List<skir.InitializationDiagnostic>,
  ));
}

}


/// Adds pattern matching related methods to [RealmPreparedEdit].
extension RealmPreparedEditPatterns on RealmPreparedEdit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmPreparedEdit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmPreparedEdit() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmPreparedEdit value)  $default,){
final _that = this;
switch (_that) {
case _RealmPreparedEdit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmPreparedEdit value)?  $default,){
final _that = this;
switch (_that) {
case _RealmPreparedEdit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PreparedEdit request,  List<skir.InitializationDiagnostic> findings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmPreparedEdit() when $default != null:
return $default(_that.request,_that.findings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PreparedEdit request,  List<skir.InitializationDiagnostic> findings)  $default,) {final _that = this;
switch (_that) {
case _RealmPreparedEdit():
return $default(_that.request,_that.findings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PreparedEdit request,  List<skir.InitializationDiagnostic> findings)?  $default,) {final _that = this;
switch (_that) {
case _RealmPreparedEdit() when $default != null:
return $default(_that.request,_that.findings);case _:
  return null;

}
}

}

/// @nodoc


class _RealmPreparedEdit implements RealmPreparedEdit {
  const _RealmPreparedEdit({required this.request,  List<skir.InitializationDiagnostic> findings = const []}): _findings = findings;


@override final  skir.PreparedEdit request;
 final  List<skir.InitializationDiagnostic> _findings;
@override@JsonKey() List<skir.InitializationDiagnostic> get findings {
  if (_findings is EqualUnmodifiableListView) return _findings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_findings);
}


/// Create a copy of RealmPreparedEdit
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmPreparedEditCopyWith<_RealmPreparedEdit> get copyWith => __$RealmPreparedEditCopyWithImpl<_RealmPreparedEdit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmPreparedEdit&&(identical(other.request, request) || other.request == request)&&const DeepCollectionEquality().equals(other.findings, _findings));
}


@override
int get hashCode {
    return Object.hash(runtimeType,request,const DeepCollectionEquality().hash(_findings));
}

@override
String toString() {
    return 'RealmPreparedEdit(request: $request, findings: $findings)';
}


}

/// @nodoc
abstract mixin class _$RealmPreparedEditCopyWith<$Res> implements $RealmPreparedEditCopyWith<$Res> {
  factory _$RealmPreparedEditCopyWith(_RealmPreparedEdit value, $Res Function(_RealmPreparedEdit) _then) = __$RealmPreparedEditCopyWithImpl;
@override @useResult
$Res call({
 skir.PreparedEdit request, List<skir.InitializationDiagnostic> findings
});




}
/// @nodoc
class __$RealmPreparedEditCopyWithImpl<$Res>
    implements _$RealmPreparedEditCopyWith<$Res> {
  __$RealmPreparedEditCopyWithImpl(this._self, this._then);

  final _RealmPreparedEdit _self;
  final $Res Function(_RealmPreparedEdit) _then;

/// Create a copy of RealmPreparedEdit
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? request = null,Object? findings = null,}) {
  return _then(_RealmPreparedEdit(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as skir.PreparedEdit,findings: null == findings ? _self._findings : findings // ignore: cast_nullable_to_non_nullable
as List<skir.InitializationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$AuthoringDocument {

 CheckedEditorCatalog get catalog; Map<skir.ResourceId, skir.AuthoringResource> get entries; List<skir.LinkProjection> get links; int get revision; List<skir.InitializationDiagnostic> get initializationFindings;
/// Create a copy of AuthoringDocument
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<AuthoringDocument> get copyWith => _$AuthoringDocumentCopyWithImpl<AuthoringDocument>(this as AuthoringDocument, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringDocument&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&const DeepCollectionEquality().equals(other.links, _this.links)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&const DeepCollectionEquality().equals(other.initializationFindings, _this.initializationFindings));
}


@override
int get hashCode {
  final _this = this as AuthoringDocument;
  return Object.hash(runtimeType,_this.catalog,const DeepCollectionEquality().hash(_this.entries),const DeepCollectionEquality().hash(_this.links),_this.revision,const DeepCollectionEquality().hash(_this.initializationFindings));
}

@override
String toString() {
  final _this = this as AuthoringDocument;
  return 'AuthoringDocument(catalog: ${_this.catalog}, entries: ${_this.entries}, links: ${_this.links}, revision: ${_this.revision}, initializationFindings: ${_this.initializationFindings})';
}


}

/// @nodoc
abstract mixin class $AuthoringDocumentCopyWith<$Res>  {
  factory $AuthoringDocumentCopyWith(AuthoringDocument value, $Res Function(AuthoringDocument) _then) = _$AuthoringDocumentCopyWithImpl;
@useResult
$Res call({
 CheckedEditorCatalog catalog, Map<skir.ResourceId, skir.AuthoringResource> entries, List<skir.LinkProjection> links, int revision, List<skir.InitializationDiagnostic> initializationFindings
});




}
/// @nodoc
class _$AuthoringDocumentCopyWithImpl<$Res>
    implements $AuthoringDocumentCopyWith<$Res> {
  _$AuthoringDocumentCopyWithImpl(this._self, this._then);

  final AuthoringDocument _self;
  final $Res Function(AuthoringDocument) _then;

/// Create a copy of AuthoringDocument
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,Object? entries = null,Object? links = null,Object? revision = null,Object? initializationFindings = null,}) {
  return _then(AuthoringDocument(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.AuthoringResource>,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<skir.LinkProjection>,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,initializationFindings: null == initializationFindings ? _self.initializationFindings : initializationFindings // ignore: cast_nullable_to_non_nullable
as List<skir.InitializationDiagnostic>,
  ));
}

}


/// Adds pattern matching related methods to [AuthoringDocument].
extension AuthoringDocumentPatterns on AuthoringDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringDocument() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringDocument value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringDocument value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CheckedEditorCatalog catalog,  Map<skir.ResourceId, skir.AuthoringResource> entries,  List<skir.LinkProjection> links,  int revision,  List<skir.InitializationDiagnostic> initializationFindings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringDocument() when $default != null:
return $default(_that.catalog,_that.entries,_that.links,_that.revision,_that.initializationFindings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CheckedEditorCatalog catalog,  Map<skir.ResourceId, skir.AuthoringResource> entries,  List<skir.LinkProjection> links,  int revision,  List<skir.InitializationDiagnostic> initializationFindings)  $default,) {final _that = this;
switch (_that) {
case _AuthoringDocument():
return $default(_that.catalog,_that.entries,_that.links,_that.revision,_that.initializationFindings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CheckedEditorCatalog catalog,  Map<skir.ResourceId, skir.AuthoringResource> entries,  List<skir.LinkProjection> links,  int revision,  List<skir.InitializationDiagnostic> initializationFindings)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringDocument() when $default != null:
return $default(_that.catalog,_that.entries,_that.links,_that.revision,_that.initializationFindings);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringDocument extends AuthoringDocument {
  const _AuthoringDocument({required this.catalog, required  Map<skir.ResourceId, skir.AuthoringResource> entries, required  List<skir.LinkProjection> links, this.revision = 0,  List<skir.InitializationDiagnostic> initializationFindings = const []}): _entries = entries,_links = links,_initializationFindings = initializationFindings,super._();


@override final  CheckedEditorCatalog catalog;
 final  Map<skir.ResourceId, skir.AuthoringResource> _entries;
@override Map<skir.ResourceId, skir.AuthoringResource> get entries {
  if (_entries is EqualUnmodifiableMapView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_entries);
}

 final  List<skir.LinkProjection> _links;
@override List<skir.LinkProjection> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}

@override@JsonKey() final  int revision;
 final  List<skir.InitializationDiagnostic> _initializationFindings;
@override@JsonKey() List<skir.InitializationDiagnostic> get initializationFindings {
  if (_initializationFindings is EqualUnmodifiableListView) return _initializationFindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_initializationFindings);
}


/// Create a copy of AuthoringDocument
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringDocumentCopyWith<_AuthoringDocument> get copyWith => __$AuthoringDocumentCopyWithImpl<_AuthoringDocument>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringDocument&&(identical(other.catalog, catalog) || other.catalog == catalog)&&const DeepCollectionEquality().equals(other.entries, _entries)&&const DeepCollectionEquality().equals(other.links, _links)&&(identical(other.revision, revision) || other.revision == revision)&&const DeepCollectionEquality().equals(other.initializationFindings, _initializationFindings));
}


@override
int get hashCode {
    return Object.hash(runtimeType,catalog,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_links),revision,const DeepCollectionEquality().hash(_initializationFindings));
}

@override
String toString() {
    return 'AuthoringDocument(catalog: $catalog, entries: $entries, links: $links, revision: $revision, initializationFindings: $initializationFindings)';
}


}

/// @nodoc
abstract mixin class _$AuthoringDocumentCopyWith<$Res> implements $AuthoringDocumentCopyWith<$Res> {
  factory _$AuthoringDocumentCopyWith(_AuthoringDocument value, $Res Function(_AuthoringDocument) _then) = __$AuthoringDocumentCopyWithImpl;
@override @useResult
$Res call({
 CheckedEditorCatalog catalog, Map<skir.ResourceId, skir.AuthoringResource> entries, List<skir.LinkProjection> links, int revision, List<skir.InitializationDiagnostic> initializationFindings
});




}
/// @nodoc
class __$AuthoringDocumentCopyWithImpl<$Res>
    implements _$AuthoringDocumentCopyWith<$Res> {
  __$AuthoringDocumentCopyWithImpl(this._self, this._then);

  final _AuthoringDocument _self;
  final $Res Function(_AuthoringDocument) _then;

/// Create a copy of AuthoringDocument
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,Object? entries = null,Object? links = null,Object? revision = null,Object? initializationFindings = null,}) {
  return _then(_AuthoringDocument(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, skir.AuthoringResource>,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<skir.LinkProjection>,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,initializationFindings: null == initializationFindings ? _self._initializationFindings : initializationFindings // ignore: cast_nullable_to_non_nullable
as List<skir.InitializationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$AuthoringScope {

 skir.RecordId get organizationId; skir.RecordId get realmId;
/// Create a copy of AuthoringScope
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringScopeCopyWith<AuthoringScope> get copyWith => _$AuthoringScopeCopyWithImpl<AuthoringScope>(this as AuthoringScope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringScope&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId));
}


@override
int get hashCode {
  final _this = this as AuthoringScope;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId);
}

@override
String toString() {
  final _this = this as AuthoringScope;
  return 'AuthoringScope(organizationId: ${_this.organizationId}, realmId: ${_this.realmId})';
}


}

/// @nodoc
abstract mixin class $AuthoringScopeCopyWith<$Res>  {
  factory $AuthoringScopeCopyWith(AuthoringScope value, $Res Function(AuthoringScope) _then) = _$AuthoringScopeCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId
});




}
/// @nodoc
class _$AuthoringScopeCopyWithImpl<$Res>
    implements $AuthoringScopeCopyWith<$Res> {
  _$AuthoringScopeCopyWithImpl(this._self, this._then);

  final AuthoringScope _self;
  final $Res Function(AuthoringScope) _then;

/// Create a copy of AuthoringScope
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(AuthoringScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}

}


/// Adds pattern matching related methods to [AuthoringScope].
extension AuthoringScopePatterns on AuthoringScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringScope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringScope() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringScope value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringScope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringScope value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringScope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringScope() when $default != null:
return $default(_that.organizationId,_that.realmId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId)  $default,) {final _that = this;
switch (_that) {
case _AuthoringScope():
return $default(_that.organizationId,_that.realmId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringScope() when $default != null:
return $default(_that.organizationId,_that.realmId);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringScope implements AuthoringScope {
  const _AuthoringScope({required this.organizationId, required this.realmId});


@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;

/// Create a copy of AuthoringScope
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringScopeCopyWith<_AuthoringScope> get copyWith => __$AuthoringScopeCopyWithImpl<_AuthoringScope>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringScope&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId);
}

@override
String toString() {
    return 'AuthoringScope(organizationId: $organizationId, realmId: $realmId)';
}


}

/// @nodoc
abstract mixin class _$AuthoringScopeCopyWith<$Res> implements $AuthoringScopeCopyWith<$Res> {
  factory _$AuthoringScopeCopyWith(_AuthoringScope value, $Res Function(_AuthoringScope) _then) = __$AuthoringScopeCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId
});




}
/// @nodoc
class __$AuthoringScopeCopyWithImpl<$Res>
    implements _$AuthoringScopeCopyWith<$Res> {
  __$AuthoringScopeCopyWithImpl(this._self, this._then);

  final _AuthoringScope _self;
  final $Res Function(_AuthoringScope) _then;

/// Create a copy of AuthoringScope
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(_AuthoringScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}


}

// dart format on
