// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_subjects.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringSubjectScope {

 skir.RecordId get organizationId; skir.RecordId get realmId; Map<skir.ResourceId, ResolvedTypeRef> get resources;
/// Create a copy of AuthoringSubjectScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSubjectScopeCopyWith<AuthoringSubjectScope> get copyWith => _$AuthoringSubjectScopeCopyWithImpl<AuthoringSubjectScope>(this as AuthoringSubjectScope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringSubjectScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSubjectScope&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId)&&const DeepCollectionEquality().equals(other.resources, _this.resources));
}


@override
int get hashCode {
  final _this = this as AuthoringSubjectScope;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId,const DeepCollectionEquality().hash(_this.resources));
}

@override
String toString() {
  final _this = this as AuthoringSubjectScope;
  return 'AuthoringSubjectScope(organizationId: ${_this.organizationId}, realmId: ${_this.realmId}, resources: ${_this.resources})';
}


}

/// @nodoc
abstract mixin class $AuthoringSubjectScopeCopyWith<$Res>  {
  factory $AuthoringSubjectScopeCopyWith(AuthoringSubjectScope value, $Res Function(AuthoringSubjectScope) _then) = _$AuthoringSubjectScopeCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, Map<skir.ResourceId, ResolvedTypeRef> resources
});




}
/// @nodoc
class _$AuthoringSubjectScopeCopyWithImpl<$Res>
    implements $AuthoringSubjectScopeCopyWith<$Res> {
  _$AuthoringSubjectScopeCopyWithImpl(this._self, this._then);

  final AuthoringSubjectScope _self;
  final $Res Function(AuthoringSubjectScope) _then;

/// Create a copy of AuthoringSubjectScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,Object? resources = null,}) {
  return _then(AuthoringSubjectScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,resources: null == resources ? _self.resources : resources // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, ResolvedTypeRef>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringSubjectScope].
extension AuthoringSubjectScopePatterns on AuthoringSubjectScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringSubjectScope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringSubjectScope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringSubjectScope value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringSubjectScope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringSubjectScope value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringSubjectScope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  Map<skir.ResourceId, ResolvedTypeRef> resources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringSubjectScope() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.resources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId organizationId,  skir.RecordId realmId,  Map<skir.ResourceId, ResolvedTypeRef> resources)  $default,) {final _that = this;
switch (_that) {
case _AuthoringSubjectScope():
return $default(_that.organizationId,_that.realmId,_that.resources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId organizationId,  skir.RecordId realmId,  Map<skir.ResourceId, ResolvedTypeRef> resources)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSubjectScope() when $default != null:
return $default(_that.organizationId,_that.realmId,_that.resources);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSubjectScope implements AuthoringSubjectScope {
  const _AuthoringSubjectScope({required this.organizationId, required this.realmId, required  Map<skir.ResourceId, ResolvedTypeRef> resources}): _resources = resources;


@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;
 final  Map<skir.ResourceId, ResolvedTypeRef> _resources;
@override Map<skir.ResourceId, ResolvedTypeRef> get resources {
  if (_resources is EqualUnmodifiableMapView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_resources);
}


/// Create a copy of AuthoringSubjectScope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSubjectScopeCopyWith<_AuthoringSubjectScope> get copyWith => __$AuthoringSubjectScopeCopyWithImpl<_AuthoringSubjectScope>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSubjectScope&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId)&&const DeepCollectionEquality().equals(other.resources, _resources));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId,const DeepCollectionEquality().hash(_resources));
}

@override
String toString() {
    return 'AuthoringSubjectScope(organizationId: $organizationId, realmId: $realmId, resources: $resources)';
}


}

/// @nodoc
abstract mixin class _$AuthoringSubjectScopeCopyWith<$Res> implements $AuthoringSubjectScopeCopyWith<$Res> {
  factory _$AuthoringSubjectScopeCopyWith(_AuthoringSubjectScope value, $Res Function(_AuthoringSubjectScope) _then) = __$AuthoringSubjectScopeCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId, Map<skir.ResourceId, ResolvedTypeRef> resources
});




}
/// @nodoc
class __$AuthoringSubjectScopeCopyWithImpl<$Res>
    implements _$AuthoringSubjectScopeCopyWith<$Res> {
  __$AuthoringSubjectScopeCopyWithImpl(this._self, this._then);

  final _AuthoringSubjectScope _self;
  final $Res Function(_AuthoringSubjectScope) _then;

/// Create a copy of AuthoringSubjectScope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,Object? resources = null,}) {
  return _then(_AuthoringSubjectScope(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, ResolvedTypeRef>,
  ));
}


}

/// @nodoc
mixin _$AuthoringSubjectProjection {

 RealmEditorCatalogSnapshot get catalog; CatalogGeneration get generation; int get sequence; Map<skir.ResourceId, TypedPresentationSubject> get subjects; Map<PresentationCollectionSourceId, PresentationCollectionSource> get collections; List<TypeDiagnostic> get diagnostics;
/// Create a copy of AuthoringSubjectProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSubjectProjectionCopyWith<AuthoringSubjectProjection> get copyWith => _$AuthoringSubjectProjectionCopyWithImpl<AuthoringSubjectProjection>(this as AuthoringSubjectProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringSubjectProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSubjectProjection&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.generation, _this.generation) || other.generation == _this.generation)&&(identical(other.sequence, _this.sequence) || other.sequence == _this.sequence)&&const DeepCollectionEquality().equals(other.subjects, _this.subjects)&&const DeepCollectionEquality().equals(other.collections, _this.collections)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as AuthoringSubjectProjection;
  return Object.hash(runtimeType,_this.catalog,_this.generation,_this.sequence,const DeepCollectionEquality().hash(_this.subjects),const DeepCollectionEquality().hash(_this.collections),const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as AuthoringSubjectProjection;
  return 'AuthoringSubjectProjection(catalog: ${_this.catalog}, generation: ${_this.generation}, sequence: ${_this.sequence}, subjects: ${_this.subjects}, collections: ${_this.collections}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $AuthoringSubjectProjectionCopyWith<$Res>  {
  factory $AuthoringSubjectProjectionCopyWith(AuthoringSubjectProjection value, $Res Function(AuthoringSubjectProjection) _then) = _$AuthoringSubjectProjectionCopyWithImpl;
@useResult
$Res call({
 RealmEditorCatalogSnapshot catalog, CatalogGeneration generation, int sequence, Map<skir.ResourceId, TypedPresentationSubject> subjects, Map<PresentationCollectionSourceId, PresentationCollectionSource> collections, List<TypeDiagnostic> diagnostics
});


$RealmEditorCatalogSnapshotCopyWith<$Res> get catalog;$CatalogGenerationCopyWith<$Res> get generation;

}
/// @nodoc
class _$AuthoringSubjectProjectionCopyWithImpl<$Res>
    implements $AuthoringSubjectProjectionCopyWith<$Res> {
  _$AuthoringSubjectProjectionCopyWithImpl(this._self, this._then);

  final AuthoringSubjectProjection _self;
  final $Res Function(AuthoringSubjectProjection) _then;

/// Create a copy of AuthoringSubjectProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,Object? generation = null,Object? sequence = null,Object? subjects = null,Object? collections = null,Object? diagnostics = null,}) {
  return _then(AuthoringSubjectProjection(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as RealmEditorCatalogSnapshot,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as CatalogGeneration,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,subjects: null == subjects ? _self.subjects : subjects // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, TypedPresentationSubject>,collections: null == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, PresentationCollectionSource>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}
/// Create a copy of AuthoringSubjectProjection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmEditorCatalogSnapshotCopyWith<$Res> get catalog {

  return $RealmEditorCatalogSnapshotCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}/// Create a copy of AuthoringSubjectProjection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogGenerationCopyWith<$Res> get generation {

  return $CatalogGenerationCopyWith<$Res>(_self.generation, (value) {
    return _then(_self.copyWith(generation: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoringSubjectProjection].
extension AuthoringSubjectProjectionPatterns on AuthoringSubjectProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringSubjectProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringSubjectProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringSubjectProjection value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringSubjectProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringSubjectProjection value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringSubjectProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RealmEditorCatalogSnapshot catalog,  CatalogGeneration generation,  int sequence,  Map<skir.ResourceId, TypedPresentationSubject> subjects,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections,  List<TypeDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringSubjectProjection() when $default != null:
return $default(_that.catalog,_that.generation,_that.sequence,_that.subjects,_that.collections,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RealmEditorCatalogSnapshot catalog,  CatalogGeneration generation,  int sequence,  Map<skir.ResourceId, TypedPresentationSubject> subjects,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections,  List<TypeDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _AuthoringSubjectProjection():
return $default(_that.catalog,_that.generation,_that.sequence,_that.subjects,_that.collections,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RealmEditorCatalogSnapshot catalog,  CatalogGeneration generation,  int sequence,  Map<skir.ResourceId, TypedPresentationSubject> subjects,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections,  List<TypeDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSubjectProjection() when $default != null:
return $default(_that.catalog,_that.generation,_that.sequence,_that.subjects,_that.collections,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSubjectProjection implements AuthoringSubjectProjection {
  const _AuthoringSubjectProjection({required this.catalog, required this.generation, required this.sequence, required  Map<skir.ResourceId, TypedPresentationSubject> subjects, required  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections, required  List<TypeDiagnostic> diagnostics}): _subjects = subjects,_collections = collections,_diagnostics = diagnostics;


@override final  RealmEditorCatalogSnapshot catalog;
@override final  CatalogGeneration generation;
@override final  int sequence;
 final  Map<skir.ResourceId, TypedPresentationSubject> _subjects;
@override Map<skir.ResourceId, TypedPresentationSubject> get subjects {
  if (_subjects is EqualUnmodifiableMapView) return _subjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_subjects);
}

 final  Map<PresentationCollectionSourceId, PresentationCollectionSource> _collections;
@override Map<PresentationCollectionSourceId, PresentationCollectionSource> get collections {
  if (_collections is EqualUnmodifiableMapView) return _collections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_collections);
}

 final  List<TypeDiagnostic> _diagnostics;
@override List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of AuthoringSubjectProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSubjectProjectionCopyWith<_AuthoringSubjectProjection> get copyWith => __$AuthoringSubjectProjectionCopyWithImpl<_AuthoringSubjectProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSubjectProjection&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&const DeepCollectionEquality().equals(other.subjects, _subjects)&&const DeepCollectionEquality().equals(other.collections, _collections)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,catalog,generation,sequence,const DeepCollectionEquality().hash(_subjects),const DeepCollectionEquality().hash(_collections),const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'AuthoringSubjectProjection(catalog: $catalog, generation: $generation, sequence: $sequence, subjects: $subjects, collections: $collections, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$AuthoringSubjectProjectionCopyWith<$Res> implements $AuthoringSubjectProjectionCopyWith<$Res> {
  factory _$AuthoringSubjectProjectionCopyWith(_AuthoringSubjectProjection value, $Res Function(_AuthoringSubjectProjection) _then) = __$AuthoringSubjectProjectionCopyWithImpl;
@override @useResult
$Res call({
 RealmEditorCatalogSnapshot catalog, CatalogGeneration generation, int sequence, Map<skir.ResourceId, TypedPresentationSubject> subjects, Map<PresentationCollectionSourceId, PresentationCollectionSource> collections, List<TypeDiagnostic> diagnostics
});


@override $RealmEditorCatalogSnapshotCopyWith<$Res> get catalog;@override $CatalogGenerationCopyWith<$Res> get generation;

}
/// @nodoc
class __$AuthoringSubjectProjectionCopyWithImpl<$Res>
    implements _$AuthoringSubjectProjectionCopyWith<$Res> {
  __$AuthoringSubjectProjectionCopyWithImpl(this._self, this._then);

  final _AuthoringSubjectProjection _self;
  final $Res Function(_AuthoringSubjectProjection) _then;

/// Create a copy of AuthoringSubjectProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,Object? generation = null,Object? sequence = null,Object? subjects = null,Object? collections = null,Object? diagnostics = null,}) {
  return _then(_AuthoringSubjectProjection(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as RealmEditorCatalogSnapshot,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as CatalogGeneration,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,subjects: null == subjects ? _self._subjects : subjects // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, TypedPresentationSubject>,collections: null == collections ? _self._collections : collections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, PresentationCollectionSource>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}

/// Create a copy of AuthoringSubjectProjection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmEditorCatalogSnapshotCopyWith<$Res> get catalog {

  return $RealmEditorCatalogSnapshotCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}/// Create a copy of AuthoringSubjectProjection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogGenerationCopyWith<$Res> get generation {

  return $CatalogGenerationCopyWith<$Res>(_self.generation, (value) {
    return _then(_self.copyWith(generation: value));
  });
}
}

// dart format on
