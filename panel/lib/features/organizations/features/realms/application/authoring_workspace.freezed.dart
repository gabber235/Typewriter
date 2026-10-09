// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_workspace.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringDocument {

 CheckedEditorCatalog get catalog; Map<skir.ResourceId, skir.AuthoringResource> get entries; List<skir.LinkProjection> get links; int get revision; List<skir.InitializationDiagnostic> get initializationFindings;
/// Create a copy of AuthoringDocument
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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


/// Adds pattern-matching-related methods to [AuthoringDocument].
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(AuthoringScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringScope].
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(_AuthoringScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}


}

/// @nodoc
mixin _$AuthoringGroupId {

 int get value;
/// Create a copy of AuthoringGroupId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringGroupIdCopyWith<AuthoringGroupId> get copyWith => _$AuthoringGroupIdCopyWithImpl<AuthoringGroupId>(this as AuthoringGroupId, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringGroupId;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupId&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as AuthoringGroupId;
  return Object.hash(runtimeType,_this.value);
}

@override
String toString() {
  final _this = this as AuthoringGroupId;
  return 'AuthoringGroupId(value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $AuthoringGroupIdCopyWith<$Res>  {
  factory $AuthoringGroupIdCopyWith(AuthoringGroupId value, $Res Function(AuthoringGroupId) _then) = _$AuthoringGroupIdCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$AuthoringGroupIdCopyWithImpl<$Res>
    implements $AuthoringGroupIdCopyWith<$Res> {
  _$AuthoringGroupIdCopyWithImpl(this._self, this._then);

  final AuthoringGroupId _self;
  final $Res Function(AuthoringGroupId) _then;

/// Create a copy of AuthoringGroupId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(AuthoringGroupId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringGroupId].
extension AuthoringGroupIdPatterns on AuthoringGroupId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringGroupId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringGroupId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringGroupId value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringGroupId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringGroupId value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringGroupId() when $default != null:
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
case _AuthoringGroupId() when $default != null:
return $default(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value)  $default,) {final _that = this;
switch (_that) {
case _AuthoringGroupId():
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
case _AuthoringGroupId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringGroupId implements AuthoringGroupId {
  const _AuthoringGroupId(this.value);


@override final  int value;

/// Create a copy of AuthoringGroupId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringGroupIdCopyWith<_AuthoringGroupId> get copyWith => __$AuthoringGroupIdCopyWithImpl<_AuthoringGroupId>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringGroupId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString() {
    return 'AuthoringGroupId(value: $value)';
}


}

/// @nodoc
abstract mixin class _$AuthoringGroupIdCopyWith<$Res> implements $AuthoringGroupIdCopyWith<$Res> {
  factory _$AuthoringGroupIdCopyWith(_AuthoringGroupId value, $Res Function(_AuthoringGroupId) _then) = __$AuthoringGroupIdCopyWithImpl;
@override @useResult
$Res call({
 int value
});




}
/// @nodoc
class __$AuthoringGroupIdCopyWithImpl<$Res>
    implements _$AuthoringGroupIdCopyWith<$Res> {
  __$AuthoringGroupIdCopyWithImpl(this._self, this._then);

  final _AuthoringGroupId _self;
  final $Res Function(_AuthoringGroupId) _then;

/// Create a copy of AuthoringGroupId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_AuthoringGroupId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$AuthoringGroupPhase {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupPhase);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoringGroupPhase()';
}


}

/// @nodoc
class $AuthoringGroupPhaseCopyWith<$Res>  {
$AuthoringGroupPhaseCopyWith(AuthoringGroupPhase _, $Res Function(AuthoringGroupPhase) __);
}


/// Adds pattern-matching-related methods to [AuthoringGroupPhase].
extension AuthoringGroupPhasePatterns on AuthoringGroupPhase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthoringGroupDirty value)?  dirty,TResult Function( AuthoringGroupAwaitingDependency value)?  awaitingDependency,TResult Function( AuthoringGroupSaving value)?  saving,TResult Function( AuthoringGroupCommittedAwaitingRefresh value)?  committedAwaitingRefresh,TResult Function( AuthoringGroupConflict value)?  conflict,TResult Function( AuthoringGroupRejected value)?  rejected,TResult Function( AuthoringGroupCatalogChanged value)?  catalogChanged,TResult Function( AuthoringGroupUncertain value)?  uncertain,TResult Function( AuthoringGroupResourceMissing value)?  resourceMissing,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthoringGroupDirty() when dirty != null:
return dirty(_that);case AuthoringGroupAwaitingDependency() when awaitingDependency != null:
return awaitingDependency(_that);case AuthoringGroupSaving() when saving != null:
return saving(_that);case AuthoringGroupCommittedAwaitingRefresh() when committedAwaitingRefresh != null:
return committedAwaitingRefresh(_that);case AuthoringGroupConflict() when conflict != null:
return conflict(_that);case AuthoringGroupRejected() when rejected != null:
return rejected(_that);case AuthoringGroupCatalogChanged() when catalogChanged != null:
return catalogChanged(_that);case AuthoringGroupUncertain() when uncertain != null:
return uncertain(_that);case AuthoringGroupResourceMissing() when resourceMissing != null:
return resourceMissing(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthoringGroupDirty value)  dirty,required TResult Function( AuthoringGroupAwaitingDependency value)  awaitingDependency,required TResult Function( AuthoringGroupSaving value)  saving,required TResult Function( AuthoringGroupCommittedAwaitingRefresh value)  committedAwaitingRefresh,required TResult Function( AuthoringGroupConflict value)  conflict,required TResult Function( AuthoringGroupRejected value)  rejected,required TResult Function( AuthoringGroupCatalogChanged value)  catalogChanged,required TResult Function( AuthoringGroupUncertain value)  uncertain,required TResult Function( AuthoringGroupResourceMissing value)  resourceMissing,}){
final _that = this;
switch (_that) {
case AuthoringGroupDirty():
return dirty(_that);case AuthoringGroupAwaitingDependency():
return awaitingDependency(_that);case AuthoringGroupSaving():
return saving(_that);case AuthoringGroupCommittedAwaitingRefresh():
return committedAwaitingRefresh(_that);case AuthoringGroupConflict():
return conflict(_that);case AuthoringGroupRejected():
return rejected(_that);case AuthoringGroupCatalogChanged():
return catalogChanged(_that);case AuthoringGroupUncertain():
return uncertain(_that);case AuthoringGroupResourceMissing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthoringGroupDirty value)?  dirty,TResult? Function( AuthoringGroupAwaitingDependency value)?  awaitingDependency,TResult? Function( AuthoringGroupSaving value)?  saving,TResult? Function( AuthoringGroupCommittedAwaitingRefresh value)?  committedAwaitingRefresh,TResult? Function( AuthoringGroupConflict value)?  conflict,TResult? Function( AuthoringGroupRejected value)?  rejected,TResult? Function( AuthoringGroupCatalogChanged value)?  catalogChanged,TResult? Function( AuthoringGroupUncertain value)?  uncertain,TResult? Function( AuthoringGroupResourceMissing value)?  resourceMissing,}){
final _that = this;
switch (_that) {
case AuthoringGroupDirty() when dirty != null:
return dirty(_that);case AuthoringGroupAwaitingDependency() when awaitingDependency != null:
return awaitingDependency(_that);case AuthoringGroupSaving() when saving != null:
return saving(_that);case AuthoringGroupCommittedAwaitingRefresh() when committedAwaitingRefresh != null:
return committedAwaitingRefresh(_that);case AuthoringGroupConflict() when conflict != null:
return conflict(_that);case AuthoringGroupRejected() when rejected != null:
return rejected(_that);case AuthoringGroupCatalogChanged() when catalogChanged != null:
return catalogChanged(_that);case AuthoringGroupUncertain() when uncertain != null:
return uncertain(_that);case AuthoringGroupResourceMissing() when resourceMissing != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  dirty,TResult Function( Set<AuthoringGroupId> groups)?  awaitingDependency,TResult Function()?  saving,TResult Function( Object? cause)?  committedAwaitingRefresh,TResult Function( String message,  skir.EditExpectation? expected,  skir.EditExpectation? actual)?  conflict,TResult Function( String message,  Object? cause)?  rejected,TResult Function()?  catalogChanged,TResult Function( Object cause)?  uncertain,TResult Function( skir.ResourceId resource,  AuthoringDocument proposal)?  resourceMissing,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthoringGroupDirty() when dirty != null:
return dirty();case AuthoringGroupAwaitingDependency() when awaitingDependency != null:
return awaitingDependency(_that.groups);case AuthoringGroupSaving() when saving != null:
return saving();case AuthoringGroupCommittedAwaitingRefresh() when committedAwaitingRefresh != null:
return committedAwaitingRefresh(_that.cause);case AuthoringGroupConflict() when conflict != null:
return conflict(_that.message,_that.expected,_that.actual);case AuthoringGroupRejected() when rejected != null:
return rejected(_that.message,_that.cause);case AuthoringGroupCatalogChanged() when catalogChanged != null:
return catalogChanged();case AuthoringGroupUncertain() when uncertain != null:
return uncertain(_that.cause);case AuthoringGroupResourceMissing() when resourceMissing != null:
return resourceMissing(_that.resource,_that.proposal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  dirty,required TResult Function( Set<AuthoringGroupId> groups)  awaitingDependency,required TResult Function()  saving,required TResult Function( Object? cause)  committedAwaitingRefresh,required TResult Function( String message,  skir.EditExpectation? expected,  skir.EditExpectation? actual)  conflict,required TResult Function( String message,  Object? cause)  rejected,required TResult Function()  catalogChanged,required TResult Function( Object cause)  uncertain,required TResult Function( skir.ResourceId resource,  AuthoringDocument proposal)  resourceMissing,}) {final _that = this;
switch (_that) {
case AuthoringGroupDirty():
return dirty();case AuthoringGroupAwaitingDependency():
return awaitingDependency(_that.groups);case AuthoringGroupSaving():
return saving();case AuthoringGroupCommittedAwaitingRefresh():
return committedAwaitingRefresh(_that.cause);case AuthoringGroupConflict():
return conflict(_that.message,_that.expected,_that.actual);case AuthoringGroupRejected():
return rejected(_that.message,_that.cause);case AuthoringGroupCatalogChanged():
return catalogChanged();case AuthoringGroupUncertain():
return uncertain(_that.cause);case AuthoringGroupResourceMissing():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  dirty,TResult? Function( Set<AuthoringGroupId> groups)?  awaitingDependency,TResult? Function()?  saving,TResult? Function( Object? cause)?  committedAwaitingRefresh,TResult? Function( String message,  skir.EditExpectation? expected,  skir.EditExpectation? actual)?  conflict,TResult? Function( String message,  Object? cause)?  rejected,TResult? Function()?  catalogChanged,TResult? Function( Object cause)?  uncertain,TResult? Function( skir.ResourceId resource,  AuthoringDocument proposal)?  resourceMissing,}) {final _that = this;
switch (_that) {
case AuthoringGroupDirty() when dirty != null:
return dirty();case AuthoringGroupAwaitingDependency() when awaitingDependency != null:
return awaitingDependency(_that.groups);case AuthoringGroupSaving() when saving != null:
return saving();case AuthoringGroupCommittedAwaitingRefresh() when committedAwaitingRefresh != null:
return committedAwaitingRefresh(_that.cause);case AuthoringGroupConflict() when conflict != null:
return conflict(_that.message,_that.expected,_that.actual);case AuthoringGroupRejected() when rejected != null:
return rejected(_that.message,_that.cause);case AuthoringGroupCatalogChanged() when catalogChanged != null:
return catalogChanged();case AuthoringGroupUncertain() when uncertain != null:
return uncertain(_that.cause);case AuthoringGroupResourceMissing() when resourceMissing != null:
return resourceMissing(_that.resource,_that.proposal);case _:
  return null;

}
}

}

/// @nodoc


class AuthoringGroupDirty implements AuthoringGroupPhase {
  const AuthoringGroupDirty();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupDirty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoringGroupPhase.dirty()';
}


}




/// @nodoc


class AuthoringGroupAwaitingDependency implements AuthoringGroupPhase {
  const AuthoringGroupAwaitingDependency( Set<AuthoringGroupId> groups): _groups = groups;


 final  Set<AuthoringGroupId> _groups;
 Set<AuthoringGroupId> get groups {
  if (_groups is EqualUnmodifiableSetView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_groups);
}


/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringGroupAwaitingDependencyCopyWith<AuthoringGroupAwaitingDependency> get copyWith => _$AuthoringGroupAwaitingDependencyCopyWithImpl<AuthoringGroupAwaitingDependency>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupAwaitingDependency&&const DeepCollectionEquality().equals(other.groups, _groups));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_groups));
}

@override
String toString() {
    return 'AuthoringGroupPhase.awaitingDependency(groups: $groups)';
}


}

/// @nodoc
abstract mixin class $AuthoringGroupAwaitingDependencyCopyWith<$Res> implements $AuthoringGroupPhaseCopyWith<$Res> {
  factory $AuthoringGroupAwaitingDependencyCopyWith(AuthoringGroupAwaitingDependency value, $Res Function(AuthoringGroupAwaitingDependency) _then) = _$AuthoringGroupAwaitingDependencyCopyWithImpl;
@useResult
$Res call({
 Set<AuthoringGroupId> groups
});




}
/// @nodoc
class _$AuthoringGroupAwaitingDependencyCopyWithImpl<$Res>
    implements $AuthoringGroupAwaitingDependencyCopyWith<$Res> {
  _$AuthoringGroupAwaitingDependencyCopyWithImpl(this._self, this._then);

  final AuthoringGroupAwaitingDependency _self;
  final $Res Function(AuthoringGroupAwaitingDependency) _then;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? groups = null,}) {
  return _then(AuthoringGroupAwaitingDependency(
null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as Set<AuthoringGroupId>,
  ));
}


}

/// @nodoc


class AuthoringGroupSaving implements AuthoringGroupPhase {
  const AuthoringGroupSaving();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupSaving);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoringGroupPhase.saving()';
}


}




/// @nodoc


class AuthoringGroupCommittedAwaitingRefresh implements AuthoringGroupPhase {
  const AuthoringGroupCommittedAwaitingRefresh(this.cause);


 final  Object? cause;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringGroupCommittedAwaitingRefreshCopyWith<AuthoringGroupCommittedAwaitingRefresh> get copyWith => _$AuthoringGroupCommittedAwaitingRefreshCopyWithImpl<AuthoringGroupCommittedAwaitingRefresh>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupCommittedAwaitingRefresh&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'AuthoringGroupPhase.committedAwaitingRefresh(cause: $cause)';
}


}

/// @nodoc
abstract mixin class $AuthoringGroupCommittedAwaitingRefreshCopyWith<$Res> implements $AuthoringGroupPhaseCopyWith<$Res> {
  factory $AuthoringGroupCommittedAwaitingRefreshCopyWith(AuthoringGroupCommittedAwaitingRefresh value, $Res Function(AuthoringGroupCommittedAwaitingRefresh) _then) = _$AuthoringGroupCommittedAwaitingRefreshCopyWithImpl;
@useResult
$Res call({
 Object? cause
});




}
/// @nodoc
class _$AuthoringGroupCommittedAwaitingRefreshCopyWithImpl<$Res>
    implements $AuthoringGroupCommittedAwaitingRefreshCopyWith<$Res> {
  _$AuthoringGroupCommittedAwaitingRefreshCopyWithImpl(this._self, this._then);

  final AuthoringGroupCommittedAwaitingRefresh _self;
  final $Res Function(AuthoringGroupCommittedAwaitingRefresh) _then;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cause = freezed,}) {
  return _then(AuthoringGroupCommittedAwaitingRefresh(
freezed == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc


class AuthoringGroupConflict implements AuthoringGroupPhase {
  const AuthoringGroupConflict(this.message, this.expected, this.actual);


 final  String message;
 final  skir.EditExpectation? expected;
 final  skir.EditExpectation? actual;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringGroupConflictCopyWith<AuthoringGroupConflict> get copyWith => _$AuthoringGroupConflictCopyWithImpl<AuthoringGroupConflict>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupConflict&&(identical(other.message, message) || other.message == message)&&(identical(other.expected, expected) || other.expected == expected)&&(identical(other.actual, actual) || other.actual == actual));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,expected,actual);
}

@override
String toString() {
    return 'AuthoringGroupPhase.conflict(message: $message, expected: $expected, actual: $actual)';
}


}

/// @nodoc
abstract mixin class $AuthoringGroupConflictCopyWith<$Res> implements $AuthoringGroupPhaseCopyWith<$Res> {
  factory $AuthoringGroupConflictCopyWith(AuthoringGroupConflict value, $Res Function(AuthoringGroupConflict) _then) = _$AuthoringGroupConflictCopyWithImpl;
@useResult
$Res call({
 String message, skir.EditExpectation? expected, skir.EditExpectation? actual
});




}
/// @nodoc
class _$AuthoringGroupConflictCopyWithImpl<$Res>
    implements $AuthoringGroupConflictCopyWith<$Res> {
  _$AuthoringGroupConflictCopyWithImpl(this._self, this._then);

  final AuthoringGroupConflict _self;
  final $Res Function(AuthoringGroupConflict) _then;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? expected = freezed,Object? actual = freezed,}) {
  return _then(AuthoringGroupConflict(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,freezed == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as skir.EditExpectation?,freezed == actual ? _self.actual : actual // ignore: cast_nullable_to_non_nullable
as skir.EditExpectation?,
  ));
}


}

/// @nodoc


class AuthoringGroupRejected implements AuthoringGroupPhase {
  const AuthoringGroupRejected(this.message, this.cause);


 final  String message;
 final  Object? cause;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringGroupRejectedCopyWith<AuthoringGroupRejected> get copyWith => _$AuthoringGroupRejectedCopyWithImpl<AuthoringGroupRejected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupRejected&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'AuthoringGroupPhase.rejected(message: $message, cause: $cause)';
}


}

/// @nodoc
abstract mixin class $AuthoringGroupRejectedCopyWith<$Res> implements $AuthoringGroupPhaseCopyWith<$Res> {
  factory $AuthoringGroupRejectedCopyWith(AuthoringGroupRejected value, $Res Function(AuthoringGroupRejected) _then) = _$AuthoringGroupRejectedCopyWithImpl;
@useResult
$Res call({
 String message, Object? cause
});




}
/// @nodoc
class _$AuthoringGroupRejectedCopyWithImpl<$Res>
    implements $AuthoringGroupRejectedCopyWith<$Res> {
  _$AuthoringGroupRejectedCopyWithImpl(this._self, this._then);

  final AuthoringGroupRejected _self;
  final $Res Function(AuthoringGroupRejected) _then;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = freezed,}) {
  return _then(AuthoringGroupRejected(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,freezed == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc


class AuthoringGroupCatalogChanged implements AuthoringGroupPhase {
  const AuthoringGroupCatalogChanged();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupCatalogChanged);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoringGroupPhase.catalogChanged()';
}


}




/// @nodoc


class AuthoringGroupUncertain implements AuthoringGroupPhase {
  const AuthoringGroupUncertain(this.cause);


 final  Object cause;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringGroupUncertainCopyWith<AuthoringGroupUncertain> get copyWith => _$AuthoringGroupUncertainCopyWithImpl<AuthoringGroupUncertain>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupUncertain&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'AuthoringGroupPhase.uncertain(cause: $cause)';
}


}

/// @nodoc
abstract mixin class $AuthoringGroupUncertainCopyWith<$Res> implements $AuthoringGroupPhaseCopyWith<$Res> {
  factory $AuthoringGroupUncertainCopyWith(AuthoringGroupUncertain value, $Res Function(AuthoringGroupUncertain) _then) = _$AuthoringGroupUncertainCopyWithImpl;
@useResult
$Res call({
 Object cause
});




}
/// @nodoc
class _$AuthoringGroupUncertainCopyWithImpl<$Res>
    implements $AuthoringGroupUncertainCopyWith<$Res> {
  _$AuthoringGroupUncertainCopyWithImpl(this._self, this._then);

  final AuthoringGroupUncertain _self;
  final $Res Function(AuthoringGroupUncertain) _then;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cause = null,}) {
  return _then(AuthoringGroupUncertain(
null == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc


class AuthoringGroupResourceMissing implements AuthoringGroupPhase {
  const AuthoringGroupResourceMissing(this.resource, this.proposal);


 final  skir.ResourceId resource;
 final  AuthoringDocument proposal;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringGroupResourceMissingCopyWith<AuthoringGroupResourceMissing> get copyWith => _$AuthoringGroupResourceMissingCopyWithImpl<AuthoringGroupResourceMissing>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroupResourceMissing&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.proposal, proposal) || other.proposal == proposal));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,proposal);
}

@override
String toString() {
    return 'AuthoringGroupPhase.resourceMissing(resource: $resource, proposal: $proposal)';
}


}

/// @nodoc
abstract mixin class $AuthoringGroupResourceMissingCopyWith<$Res> implements $AuthoringGroupPhaseCopyWith<$Res> {
  factory $AuthoringGroupResourceMissingCopyWith(AuthoringGroupResourceMissing value, $Res Function(AuthoringGroupResourceMissing) _then) = _$AuthoringGroupResourceMissingCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, AuthoringDocument proposal
});


$AuthoringDocumentCopyWith<$Res> get proposal;

}
/// @nodoc
class _$AuthoringGroupResourceMissingCopyWithImpl<$Res>
    implements $AuthoringGroupResourceMissingCopyWith<$Res> {
  _$AuthoringGroupResourceMissingCopyWithImpl(this._self, this._then);

  final AuthoringGroupResourceMissing _self;
  final $Res Function(AuthoringGroupResourceMissing) _then;

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? proposal = null,}) {
  return _then(AuthoringGroupResourceMissing(
null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,null == proposal ? _self.proposal : proposal // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,
  ));
}

/// Create a copy of AuthoringGroupPhase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get proposal {

  return $AuthoringDocumentCopyWith<$Res>(_self.proposal, (value) {
    return _then(_self.copyWith(proposal: value));
  });
}
}

/// @nodoc
mixin _$AuthoringGroup {

 AuthoringGroupId get id; String get label; EditorCommitPolicy get policy; AuthoringGroupPhase get phase; Set<skir.ResourceId> get resources; int get operationCount; AuthoringDocument get original;
/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringGroupCopyWith<AuthoringGroup> get copyWith => _$AuthoringGroupCopyWithImpl<AuthoringGroup>(this as AuthoringGroup, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringGroup&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.policy, _this.policy) || other.policy == _this.policy)&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&const DeepCollectionEquality().equals(other.resources, _this.resources)&&(identical(other.operationCount, _this.operationCount) || other.operationCount == _this.operationCount)&&(identical(other.original, _this.original) || other.original == _this.original));
}


@override
int get hashCode {
  final _this = this as AuthoringGroup;
  return Object.hash(runtimeType,_this.id,_this.label,_this.policy,_this.phase,const DeepCollectionEquality().hash(_this.resources),_this.operationCount,_this.original);
}

@override
String toString() {
  final _this = this as AuthoringGroup;
  return 'AuthoringGroup(id: ${_this.id}, label: ${_this.label}, policy: ${_this.policy}, phase: ${_this.phase}, resources: ${_this.resources}, operationCount: ${_this.operationCount}, original: ${_this.original})';
}


}

/// @nodoc
abstract mixin class $AuthoringGroupCopyWith<$Res>  {
  factory $AuthoringGroupCopyWith(AuthoringGroup value, $Res Function(AuthoringGroup) _then) = _$AuthoringGroupCopyWithImpl;
@useResult
$Res call({
 AuthoringGroupId id, String label, EditorCommitPolicy policy, AuthoringGroupPhase phase, Set<skir.ResourceId> resources, int operationCount, AuthoringDocument original
});


$AuthoringGroupIdCopyWith<$Res> get id;$AuthoringGroupPhaseCopyWith<$Res> get phase;$AuthoringDocumentCopyWith<$Res> get original;

}
/// @nodoc
class _$AuthoringGroupCopyWithImpl<$Res>
    implements $AuthoringGroupCopyWith<$Res> {
  _$AuthoringGroupCopyWithImpl(this._self, this._then);

  final AuthoringGroup _self;
  final $Res Function(AuthoringGroup) _then;

/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? policy = null,Object? phase = null,Object? resources = null,Object? operationCount = null,Object? original = null,}) {
  return _then(AuthoringGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as AuthoringGroupId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as EditorCommitPolicy,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AuthoringGroupPhase,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as Set<skir.ResourceId>,operationCount: null == operationCount ? _self.operationCount : operationCount // ignore: cast_nullable_to_non_nullable
as int,original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,
  ));
}
/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringGroupIdCopyWith<$Res> get id {

  return $AuthoringGroupIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringGroupPhaseCopyWith<$Res> get phase {

  return $AuthoringGroupPhaseCopyWith<$Res>(_self.phase, (value) {
    return _then(_self.copyWith(phase: value));
  });
}/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get original {

  return $AuthoringDocumentCopyWith<$Res>(_self.original, (value) {
    return _then(_self.copyWith(original: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoringGroup].
extension AuthoringGroupPatterns on AuthoringGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringGroup value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringGroup value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringGroupId id,  String label,  EditorCommitPolicy policy,  AuthoringGroupPhase phase,  Set<skir.ResourceId> resources,  int operationCount,  AuthoringDocument original)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringGroup() when $default != null:
return $default(_that.id,_that.label,_that.policy,_that.phase,_that.resources,_that.operationCount,_that.original);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringGroupId id,  String label,  EditorCommitPolicy policy,  AuthoringGroupPhase phase,  Set<skir.ResourceId> resources,  int operationCount,  AuthoringDocument original)  $default,) {final _that = this;
switch (_that) {
case _AuthoringGroup():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringGroupId id,  String label,  EditorCommitPolicy policy,  AuthoringGroupPhase phase,  Set<skir.ResourceId> resources,  int operationCount,  AuthoringDocument original)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringGroup() when $default != null:
return $default(_that.id,_that.label,_that.policy,_that.phase,_that.resources,_that.operationCount,_that.original);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringGroup implements AuthoringGroup {
  const _AuthoringGroup({required this.id, required this.label, required this.policy, required this.phase, required  Set<skir.ResourceId> resources, required this.operationCount, required this.original}): _resources = resources;


@override final  AuthoringGroupId id;
@override final  String label;
@override final  EditorCommitPolicy policy;
@override final  AuthoringGroupPhase phase;
 final  Set<skir.ResourceId> _resources;
@override Set<skir.ResourceId> get resources {
  if (_resources is EqualUnmodifiableSetView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resources);
}

@override final  int operationCount;
@override final  AuthoringDocument original;

/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringGroupCopyWith<_AuthoringGroup> get copyWith => __$AuthoringGroupCopyWithImpl<_AuthoringGroup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.resources, _resources)&&(identical(other.operationCount, operationCount) || other.operationCount == operationCount)&&(identical(other.original, original) || other.original == original));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,label,policy,phase,const DeepCollectionEquality().hash(_resources),operationCount,original);
}

@override
String toString() {
    return 'AuthoringGroup(id: $id, label: $label, policy: $policy, phase: $phase, resources: $resources, operationCount: $operationCount, original: $original)';
}


}

/// @nodoc
abstract mixin class _$AuthoringGroupCopyWith<$Res> implements $AuthoringGroupCopyWith<$Res> {
  factory _$AuthoringGroupCopyWith(_AuthoringGroup value, $Res Function(_AuthoringGroup) _then) = __$AuthoringGroupCopyWithImpl;
@override @useResult
$Res call({
 AuthoringGroupId id, String label, EditorCommitPolicy policy, AuthoringGroupPhase phase, Set<skir.ResourceId> resources, int operationCount, AuthoringDocument original
});


@override $AuthoringGroupIdCopyWith<$Res> get id;@override $AuthoringGroupPhaseCopyWith<$Res> get phase;@override $AuthoringDocumentCopyWith<$Res> get original;

}
/// @nodoc
class __$AuthoringGroupCopyWithImpl<$Res>
    implements _$AuthoringGroupCopyWith<$Res> {
  __$AuthoringGroupCopyWithImpl(this._self, this._then);

  final _AuthoringGroup _self;
  final $Res Function(_AuthoringGroup) _then;

/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? policy = null,Object? phase = null,Object? resources = null,Object? operationCount = null,Object? original = null,}) {
  return _then(_AuthoringGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as AuthoringGroupId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as EditorCommitPolicy,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AuthoringGroupPhase,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as Set<skir.ResourceId>,operationCount: null == operationCount ? _self.operationCount : operationCount // ignore: cast_nullable_to_non_nullable
as int,original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as AuthoringDocument,
  ));
}

/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringGroupIdCopyWith<$Res> get id {

  return $AuthoringGroupIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringGroupPhaseCopyWith<$Res> get phase {

  return $AuthoringGroupPhaseCopyWith<$Res>(_self.phase, (value) {
    return _then(_self.copyWith(phase: value));
  });
}/// Create a copy of AuthoringGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res> get original {

  return $AuthoringDocumentCopyWith<$Res>(_self.original, (value) {
    return _then(_self.copyWith(original: value));
  });
}
}

/// @nodoc
mixin _$AuthoringWorkspaceState {

 AuthoringDocument? get confirmed; AuthoringDocument? get working; Map<AuthoringGroupId, AuthoringGroup> get groups; Object? get failure;
/// Create a copy of AuthoringWorkspaceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringWorkspaceStateCopyWith<AuthoringWorkspaceState> get copyWith => _$AuthoringWorkspaceStateCopyWithImpl<AuthoringWorkspaceState>(this as AuthoringWorkspaceState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringWorkspaceState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringWorkspaceState&&(identical(other.confirmed, _this.confirmed) || other.confirmed == _this.confirmed)&&(identical(other.working, _this.working) || other.working == _this.working)&&const DeepCollectionEquality().equals(other.groups, _this.groups)&&const DeepCollectionEquality().equals(other.failure, _this.failure));
}


@override
int get hashCode {
  final _this = this as AuthoringWorkspaceState;
  return Object.hash(runtimeType,_this.confirmed,_this.working,const DeepCollectionEquality().hash(_this.groups),const DeepCollectionEquality().hash(_this.failure));
}

@override
String toString() {
  final _this = this as AuthoringWorkspaceState;
  return 'AuthoringWorkspaceState(confirmed: ${_this.confirmed}, working: ${_this.working}, groups: ${_this.groups}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $AuthoringWorkspaceStateCopyWith<$Res>  {
  factory $AuthoringWorkspaceStateCopyWith(AuthoringWorkspaceState value, $Res Function(AuthoringWorkspaceState) _then) = _$AuthoringWorkspaceStateCopyWithImpl;
@useResult
$Res call({
 AuthoringDocument? confirmed, AuthoringDocument? working, Map<AuthoringGroupId, AuthoringGroup> groups, Object? failure
});


$AuthoringDocumentCopyWith<$Res>? get confirmed;$AuthoringDocumentCopyWith<$Res>? get working;

}
/// @nodoc
class _$AuthoringWorkspaceStateCopyWithImpl<$Res>
    implements $AuthoringWorkspaceStateCopyWith<$Res> {
  _$AuthoringWorkspaceStateCopyWithImpl(this._self, this._then);

  final AuthoringWorkspaceState _self;
  final $Res Function(AuthoringWorkspaceState) _then;

/// Create a copy of AuthoringWorkspaceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? confirmed = freezed,Object? working = freezed,Object? groups = null,Object? failure = freezed,}) {
  return _then(AuthoringWorkspaceState(
confirmed: freezed == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as AuthoringDocument?,working: freezed == working ? _self.working : working // ignore: cast_nullable_to_non_nullable
as AuthoringDocument?,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as Map<AuthoringGroupId, AuthoringGroup>,failure: freezed == failure ? _self.failure : failure ,
  ));
}
/// Create a copy of AuthoringWorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res>? get confirmed {
    if (_self.confirmed == null) {
    return null;
  }

  return $AuthoringDocumentCopyWith<$Res>(_self.confirmed!, (value) {
    return _then(_self.copyWith(confirmed: value));
  });
}/// Create a copy of AuthoringWorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res>? get working {
    if (_self.working == null) {
    return null;
  }

  return $AuthoringDocumentCopyWith<$Res>(_self.working!, (value) {
    return _then(_self.copyWith(working: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoringWorkspaceState].
extension AuthoringWorkspaceStatePatterns on AuthoringWorkspaceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringWorkspaceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringWorkspaceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringWorkspaceState value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringWorkspaceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringWorkspaceState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringWorkspaceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringDocument? confirmed,  AuthoringDocument? working,  Map<AuthoringGroupId, AuthoringGroup> groups,  Object? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringWorkspaceState() when $default != null:
return $default(_that.confirmed,_that.working,_that.groups,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringDocument? confirmed,  AuthoringDocument? working,  Map<AuthoringGroupId, AuthoringGroup> groups,  Object? failure)  $default,) {final _that = this;
switch (_that) {
case _AuthoringWorkspaceState():
return $default(_that.confirmed,_that.working,_that.groups,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringDocument? confirmed,  AuthoringDocument? working,  Map<AuthoringGroupId, AuthoringGroup> groups,  Object? failure)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringWorkspaceState() when $default != null:
return $default(_that.confirmed,_that.working,_that.groups,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringWorkspaceState implements AuthoringWorkspaceState {
  const _AuthoringWorkspaceState({this.confirmed, this.working,  Map<AuthoringGroupId, AuthoringGroup> groups = const {}, this.failure}): _groups = groups;


@override final  AuthoringDocument? confirmed;
@override final  AuthoringDocument? working;
 final  Map<AuthoringGroupId, AuthoringGroup> _groups;
@override@JsonKey() Map<AuthoringGroupId, AuthoringGroup> get groups {
  if (_groups is EqualUnmodifiableMapView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_groups);
}

@override final  Object? failure;

/// Create a copy of AuthoringWorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringWorkspaceStateCopyWith<_AuthoringWorkspaceState> get copyWith => __$AuthoringWorkspaceStateCopyWithImpl<_AuthoringWorkspaceState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringWorkspaceState&&(identical(other.confirmed, confirmed) || other.confirmed == confirmed)&&(identical(other.working, working) || other.working == working)&&const DeepCollectionEquality().equals(other.groups, _groups)&&const DeepCollectionEquality().equals(other.failure, failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,confirmed,working,const DeepCollectionEquality().hash(_groups),const DeepCollectionEquality().hash(failure));
}

@override
String toString() {
    return 'AuthoringWorkspaceState(confirmed: $confirmed, working: $working, groups: $groups, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$AuthoringWorkspaceStateCopyWith<$Res> implements $AuthoringWorkspaceStateCopyWith<$Res> {
  factory _$AuthoringWorkspaceStateCopyWith(_AuthoringWorkspaceState value, $Res Function(_AuthoringWorkspaceState) _then) = __$AuthoringWorkspaceStateCopyWithImpl;
@override @useResult
$Res call({
 AuthoringDocument? confirmed, AuthoringDocument? working, Map<AuthoringGroupId, AuthoringGroup> groups, Object? failure
});


@override $AuthoringDocumentCopyWith<$Res>? get confirmed;@override $AuthoringDocumentCopyWith<$Res>? get working;

}
/// @nodoc
class __$AuthoringWorkspaceStateCopyWithImpl<$Res>
    implements _$AuthoringWorkspaceStateCopyWith<$Res> {
  __$AuthoringWorkspaceStateCopyWithImpl(this._self, this._then);

  final _AuthoringWorkspaceState _self;
  final $Res Function(_AuthoringWorkspaceState) _then;

/// Create a copy of AuthoringWorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? confirmed = freezed,Object? working = freezed,Object? groups = null,Object? failure = freezed,}) {
  return _then(_AuthoringWorkspaceState(
confirmed: freezed == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as AuthoringDocument?,working: freezed == working ? _self.working : working // ignore: cast_nullable_to_non_nullable
as AuthoringDocument?,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as Map<AuthoringGroupId, AuthoringGroup>,failure: freezed == failure ? _self.failure : failure ,
  ));
}

/// Create a copy of AuthoringWorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res>? get confirmed {
    if (_self.confirmed == null) {
    return null;
  }

  return $AuthoringDocumentCopyWith<$Res>(_self.confirmed!, (value) {
    return _then(_self.copyWith(confirmed: value));
  });
}/// Create a copy of AuthoringWorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringDocumentCopyWith<$Res>? get working {
    if (_self.working == null) {
    return null;
  }

  return $AuthoringDocumentCopyWith<$Res>(_self.working!, (value) {
    return _then(_self.copyWith(working: value));
  });
}
}

/// @nodoc
mixin _$AuthoringEditResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringEditResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoringEditResult()';
}


}

/// @nodoc
class $AuthoringEditResultCopyWith<$Res>  {
$AuthoringEditResultCopyWith(AuthoringEditResult _, $Res Function(AuthoringEditResult) __);
}


/// Adds pattern-matching-related methods to [AuthoringEditResult].
extension AuthoringEditResultPatterns on AuthoringEditResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthoringEditStaged value)?  staged,TResult Function( AuthoringEditUnchanged value)?  unchanged,TResult Function( AuthoringEditRejected value)?  rejected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthoringEditStaged() when staged != null:
return staged(_that);case AuthoringEditUnchanged() when unchanged != null:
return unchanged(_that);case AuthoringEditRejected() when rejected != null:
return rejected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthoringEditStaged value)  staged,required TResult Function( AuthoringEditUnchanged value)  unchanged,required TResult Function( AuthoringEditRejected value)  rejected,}){
final _that = this;
switch (_that) {
case AuthoringEditStaged():
return staged(_that);case AuthoringEditUnchanged():
return unchanged(_that);case AuthoringEditRejected():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthoringEditStaged value)?  staged,TResult? Function( AuthoringEditUnchanged value)?  unchanged,TResult? Function( AuthoringEditRejected value)?  rejected,}){
final _that = this;
switch (_that) {
case AuthoringEditStaged() when staged != null:
return staged(_that);case AuthoringEditUnchanged() when unchanged != null:
return unchanged(_that);case AuthoringEditRejected() when rejected != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( AuthoringGroupId group)?  staged,TResult Function()?  unchanged,TResult Function( String message,  Object? cause)?  rejected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthoringEditStaged() when staged != null:
return staged(_that.group);case AuthoringEditUnchanged() when unchanged != null:
return unchanged();case AuthoringEditRejected() when rejected != null:
return rejected(_that.message,_that.cause);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( AuthoringGroupId group)  staged,required TResult Function()  unchanged,required TResult Function( String message,  Object? cause)  rejected,}) {final _that = this;
switch (_that) {
case AuthoringEditStaged():
return staged(_that.group);case AuthoringEditUnchanged():
return unchanged();case AuthoringEditRejected():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( AuthoringGroupId group)?  staged,TResult? Function()?  unchanged,TResult? Function( String message,  Object? cause)?  rejected,}) {final _that = this;
switch (_that) {
case AuthoringEditStaged() when staged != null:
return staged(_that.group);case AuthoringEditUnchanged() when unchanged != null:
return unchanged();case AuthoringEditRejected() when rejected != null:
return rejected(_that.message,_that.cause);case _:
  return null;

}
}

}

/// @nodoc


class AuthoringEditStaged implements AuthoringEditResult {
  const AuthoringEditStaged(this.group);


 final  AuthoringGroupId group;

/// Create a copy of AuthoringEditResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringEditStagedCopyWith<AuthoringEditStaged> get copyWith => _$AuthoringEditStagedCopyWithImpl<AuthoringEditStaged>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringEditStaged&&(identical(other.group, group) || other.group == group));
}


@override
int get hashCode {
    return Object.hash(runtimeType,group);
}

@override
String toString() {
    return 'AuthoringEditResult.staged(group: $group)';
}


}

/// @nodoc
abstract mixin class $AuthoringEditStagedCopyWith<$Res> implements $AuthoringEditResultCopyWith<$Res> {
  factory $AuthoringEditStagedCopyWith(AuthoringEditStaged value, $Res Function(AuthoringEditStaged) _then) = _$AuthoringEditStagedCopyWithImpl;
@useResult
$Res call({
 AuthoringGroupId group
});


$AuthoringGroupIdCopyWith<$Res> get group;

}
/// @nodoc
class _$AuthoringEditStagedCopyWithImpl<$Res>
    implements $AuthoringEditStagedCopyWith<$Res> {
  _$AuthoringEditStagedCopyWithImpl(this._self, this._then);

  final AuthoringEditStaged _self;
  final $Res Function(AuthoringEditStaged) _then;

/// Create a copy of AuthoringEditResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? group = null,}) {
  return _then(AuthoringEditStaged(
null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as AuthoringGroupId,
  ));
}

/// Create a copy of AuthoringEditResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringGroupIdCopyWith<$Res> get group {

  return $AuthoringGroupIdCopyWith<$Res>(_self.group, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}

/// @nodoc


class AuthoringEditUnchanged implements AuthoringEditResult {
  const AuthoringEditUnchanged();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringEditUnchanged);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AuthoringEditResult.unchanged()';
}


}




/// @nodoc


class AuthoringEditRejected implements AuthoringEditResult {
  const AuthoringEditRejected(this.message, this.cause);


 final  String message;
 final  Object? cause;

/// Create a copy of AuthoringEditResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringEditRejectedCopyWith<AuthoringEditRejected> get copyWith => _$AuthoringEditRejectedCopyWithImpl<AuthoringEditRejected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringEditRejected&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'AuthoringEditResult.rejected(message: $message, cause: $cause)';
}


}

/// @nodoc
abstract mixin class $AuthoringEditRejectedCopyWith<$Res> implements $AuthoringEditResultCopyWith<$Res> {
  factory $AuthoringEditRejectedCopyWith(AuthoringEditRejected value, $Res Function(AuthoringEditRejected) _then) = _$AuthoringEditRejectedCopyWithImpl;
@useResult
$Res call({
 String message, Object? cause
});




}
/// @nodoc
class _$AuthoringEditRejectedCopyWithImpl<$Res>
    implements $AuthoringEditRejectedCopyWith<$Res> {
  _$AuthoringEditRejectedCopyWithImpl(this._self, this._then);

  final AuthoringEditRejected _self;
  final $Res Function(AuthoringEditRejected) _then;

/// Create a copy of AuthoringEditResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = freezed,}) {
  return _then(AuthoringEditRejected(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,freezed == cause ? _self.cause : cause ,
  ));
}


}

// dart format on
