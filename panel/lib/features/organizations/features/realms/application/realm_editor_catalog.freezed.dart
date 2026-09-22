// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_editor_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmEditorCatalogRoute {

 skir.RecordId get organizationId; skir.RecordId get realmId;
/// Create a copy of RealmEditorCatalogRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogRouteCopyWith<RealmEditorCatalogRoute> get copyWith => _$RealmEditorCatalogRouteCopyWithImpl<RealmEditorCatalogRoute>(this as RealmEditorCatalogRoute, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmEditorCatalogRoute;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogRoute&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.realmId, _this.realmId) || other.realmId == _this.realmId));
}


@override
int get hashCode {
  final _this = this as RealmEditorCatalogRoute;
  return Object.hash(runtimeType,_this.organizationId,_this.realmId);
}

@override
String toString() {
  final _this = this as RealmEditorCatalogRoute;
  return 'RealmEditorCatalogRoute(organizationId: ${_this.organizationId}, realmId: ${_this.realmId})';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogRouteCopyWith<$Res>  {
  factory $RealmEditorCatalogRouteCopyWith(RealmEditorCatalogRoute value, $Res Function(RealmEditorCatalogRoute) _then) = _$RealmEditorCatalogRouteCopyWithImpl;
@useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId
});




}
/// @nodoc
class _$RealmEditorCatalogRouteCopyWithImpl<$Res>
    implements $RealmEditorCatalogRouteCopyWith<$Res> {
  _$RealmEditorCatalogRouteCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogRoute _self;
  final $Res Function(RealmEditorCatalogRoute) _then;

/// Create a copy of RealmEditorCatalogRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(RealmEditorCatalogRoute(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmEditorCatalogRoute].
extension RealmEditorCatalogRoutePatterns on RealmEditorCatalogRoute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmEditorCatalogRoute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmEditorCatalogRoute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmEditorCatalogRoute value)  $default,){
final _that = this;
switch (_that) {
case _RealmEditorCatalogRoute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmEditorCatalogRoute value)?  $default,){
final _that = this;
switch (_that) {
case _RealmEditorCatalogRoute() when $default != null:
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
case _RealmEditorCatalogRoute() when $default != null:
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
case _RealmEditorCatalogRoute():
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
case _RealmEditorCatalogRoute() when $default != null:
return $default(_that.organizationId,_that.realmId);case _:
  return null;

}
}

}

/// @nodoc


class _RealmEditorCatalogRoute extends RealmEditorCatalogRoute {
  const _RealmEditorCatalogRoute({required this.organizationId, required this.realmId}): super._();


@override final  skir.RecordId organizationId;
@override final  skir.RecordId realmId;

/// Create a copy of RealmEditorCatalogRoute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmEditorCatalogRouteCopyWith<_RealmEditorCatalogRoute> get copyWith => __$RealmEditorCatalogRouteCopyWithImpl<_RealmEditorCatalogRoute>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmEditorCatalogRoute&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationId,realmId);
}

@override
String toString() {
    return 'RealmEditorCatalogRoute(organizationId: $organizationId, realmId: $realmId)';
}


}

/// @nodoc
abstract mixin class _$RealmEditorCatalogRouteCopyWith<$Res> implements $RealmEditorCatalogRouteCopyWith<$Res> {
  factory _$RealmEditorCatalogRouteCopyWith(_RealmEditorCatalogRoute value, $Res Function(_RealmEditorCatalogRoute) _then) = __$RealmEditorCatalogRouteCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId organizationId, skir.RecordId realmId
});




}
/// @nodoc
class __$RealmEditorCatalogRouteCopyWithImpl<$Res>
    implements _$RealmEditorCatalogRouteCopyWith<$Res> {
  __$RealmEditorCatalogRouteCopyWithImpl(this._self, this._then);

  final _RealmEditorCatalogRoute _self;
  final $Res Function(_RealmEditorCatalogRoute) _then;

/// Create a copy of RealmEditorCatalogRoute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? realmId = null,}) {
  return _then(_RealmEditorCatalogRoute(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}


}

/// @nodoc
mixin _$RealmEditorCatalogSnapshot {

 TypeCatalog get catalog; CatalogGeneration get generation; Map<PresentationId, PresentationDefinition> get presentations; Map<ConversionId, ConversionDefinition> get conversions; Map<CapabilityId, CapabilityDefinition> get capabilities; Map<String, RealmEditorSubtypeResult> get subtypeResults; List<TypeDiagnostic> get diagnostics; Map<String, RealmElementCatalogEntry> get elements; RealmPageCatalog get pageCatalog; Map<ResourceDefinitionId, RealmResourceDefinition> get resourceDefinitions; Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> get creationSlots; Map<String, RealmRelationDefinition> get relations; Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition> get collectionProjections; List<RealmAuthoringCompilationProjection> get compilationProjections; RealmAuthoringSearchDefinition? get authoringSearch;
/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogSnapshotCopyWith<RealmEditorCatalogSnapshot> get copyWith => _$RealmEditorCatalogSnapshotCopyWithImpl<RealmEditorCatalogSnapshot>(this as RealmEditorCatalogSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmEditorCatalogSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogSnapshot&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.generation, _this.generation) || other.generation == _this.generation)&&const DeepCollectionEquality().equals(other.presentations, _this.presentations)&&const DeepCollectionEquality().equals(other.conversions, _this.conversions)&&const DeepCollectionEquality().equals(other.capabilities, _this.capabilities)&&const DeepCollectionEquality().equals(other.subtypeResults, _this.subtypeResults)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics)&&const DeepCollectionEquality().equals(other.elements, _this.elements)&&(identical(other.pageCatalog, _this.pageCatalog) || other.pageCatalog == _this.pageCatalog)&&const DeepCollectionEquality().equals(other.resourceDefinitions, _this.resourceDefinitions)&&const DeepCollectionEquality().equals(other.creationSlots, _this.creationSlots)&&const DeepCollectionEquality().equals(other.relations, _this.relations)&&const DeepCollectionEquality().equals(other.collectionProjections, _this.collectionProjections)&&const DeepCollectionEquality().equals(other.compilationProjections, _this.compilationProjections)&&(identical(other.authoringSearch, _this.authoringSearch) || other.authoringSearch == _this.authoringSearch));
}


@override
int get hashCode {
  final _this = this as RealmEditorCatalogSnapshot;
  return Object.hash(runtimeType,_this.catalog,_this.generation,const DeepCollectionEquality().hash(_this.presentations),const DeepCollectionEquality().hash(_this.conversions),const DeepCollectionEquality().hash(_this.capabilities),const DeepCollectionEquality().hash(_this.subtypeResults),const DeepCollectionEquality().hash(_this.diagnostics),const DeepCollectionEquality().hash(_this.elements),_this.pageCatalog,const DeepCollectionEquality().hash(_this.resourceDefinitions),const DeepCollectionEquality().hash(_this.creationSlots),const DeepCollectionEquality().hash(_this.relations),const DeepCollectionEquality().hash(_this.collectionProjections),const DeepCollectionEquality().hash(_this.compilationProjections),_this.authoringSearch);
}

@override
String toString() {
  final _this = this as RealmEditorCatalogSnapshot;
  return 'RealmEditorCatalogSnapshot(catalog: ${_this.catalog}, generation: ${_this.generation}, presentations: ${_this.presentations}, conversions: ${_this.conversions}, capabilities: ${_this.capabilities}, subtypeResults: ${_this.subtypeResults}, diagnostics: ${_this.diagnostics}, elements: ${_this.elements}, pageCatalog: ${_this.pageCatalog}, resourceDefinitions: ${_this.resourceDefinitions}, creationSlots: ${_this.creationSlots}, relations: ${_this.relations}, collectionProjections: ${_this.collectionProjections}, compilationProjections: ${_this.compilationProjections}, authoringSearch: ${_this.authoringSearch})';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogSnapshotCopyWith<$Res>  {
  factory $RealmEditorCatalogSnapshotCopyWith(RealmEditorCatalogSnapshot value, $Res Function(RealmEditorCatalogSnapshot) _then) = _$RealmEditorCatalogSnapshotCopyWithImpl;
@useResult
$Res call({
 TypeCatalog catalog, CatalogGeneration generation, Map<PresentationId, PresentationDefinition> presentations, Map<ConversionId, ConversionDefinition> conversions, Map<CapabilityId, CapabilityDefinition> capabilities, Map<String, RealmEditorSubtypeResult> subtypeResults, List<TypeDiagnostic> diagnostics, Map<String, RealmElementCatalogEntry> elements, RealmPageCatalog pageCatalog, Map<ResourceDefinitionId, RealmResourceDefinition> resourceDefinitions, Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> creationSlots, Map<String, RealmRelationDefinition> relations, Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition> collectionProjections, List<RealmAuthoringCompilationProjection> compilationProjections, RealmAuthoringSearchDefinition? authoringSearch
});


$TypeCatalogCopyWith<$Res> get catalog;$CatalogGenerationCopyWith<$Res> get generation;$RealmPageCatalogCopyWith<$Res> get pageCatalog;$RealmAuthoringSearchDefinitionCopyWith<$Res>? get authoringSearch;

}
/// @nodoc
class _$RealmEditorCatalogSnapshotCopyWithImpl<$Res>
    implements $RealmEditorCatalogSnapshotCopyWith<$Res> {
  _$RealmEditorCatalogSnapshotCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogSnapshot _self;
  final $Res Function(RealmEditorCatalogSnapshot) _then;

/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,Object? generation = null,Object? presentations = null,Object? conversions = null,Object? capabilities = null,Object? subtypeResults = null,Object? diagnostics = null,Object? elements = null,Object? pageCatalog = null,Object? resourceDefinitions = null,Object? creationSlots = null,Object? relations = null,Object? collectionProjections = null,Object? compilationProjections = null,Object? authoringSearch = freezed,}) {
  return _then(RealmEditorCatalogSnapshot(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as TypeCatalog,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as CatalogGeneration,presentations: null == presentations ? _self.presentations : presentations // ignore: cast_nullable_to_non_nullable
as Map<PresentationId, PresentationDefinition>,conversions: null == conversions ? _self.conversions : conversions // ignore: cast_nullable_to_non_nullable
as Map<ConversionId, ConversionDefinition>,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as Map<CapabilityId, CapabilityDefinition>,subtypeResults: null == subtypeResults ? _self.subtypeResults : subtypeResults // ignore: cast_nullable_to_non_nullable
as Map<String, RealmEditorSubtypeResult>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,elements: null == elements ? _self.elements : elements // ignore: cast_nullable_to_non_nullable
as Map<String, RealmElementCatalogEntry>,pageCatalog: null == pageCatalog ? _self.pageCatalog : pageCatalog // ignore: cast_nullable_to_non_nullable
as RealmPageCatalog,resourceDefinitions: null == resourceDefinitions ? _self.resourceDefinitions : resourceDefinitions // ignore: cast_nullable_to_non_nullable
as Map<ResourceDefinitionId, RealmResourceDefinition>,creationSlots: null == creationSlots ? _self.creationSlots : creationSlots // ignore: cast_nullable_to_non_nullable
as Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot>,relations: null == relations ? _self.relations : relations // ignore: cast_nullable_to_non_nullable
as Map<String, RealmRelationDefinition>,collectionProjections: null == collectionProjections ? _self.collectionProjections : collectionProjections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition>,compilationProjections: null == compilationProjections ? _self.compilationProjections : compilationProjections // ignore: cast_nullable_to_non_nullable
as List<RealmAuthoringCompilationProjection>,authoringSearch: freezed == authoringSearch ? _self.authoringSearch : authoringSearch // ignore: cast_nullable_to_non_nullable
as RealmAuthoringSearchDefinition?,
  ));
}
/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeCatalogCopyWith<$Res> get catalog {

  return $TypeCatalogCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogGenerationCopyWith<$Res> get generation {

  return $CatalogGenerationCopyWith<$Res>(_self.generation, (value) {
    return _then(_self.copyWith(generation: value));
  });
}/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPageCatalogCopyWith<$Res> get pageCatalog {

  return $RealmPageCatalogCopyWith<$Res>(_self.pageCatalog, (value) {
    return _then(_self.copyWith(pageCatalog: value));
  });
}/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmAuthoringSearchDefinitionCopyWith<$Res>? get authoringSearch {
    if (_self.authoringSearch == null) {
    return null;
  }

  return $RealmAuthoringSearchDefinitionCopyWith<$Res>(_self.authoringSearch!, (value) {
    return _then(_self.copyWith(authoringSearch: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmEditorCatalogSnapshot].
extension RealmEditorCatalogSnapshotPatterns on RealmEditorCatalogSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmEditorCatalogSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmEditorCatalogSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmEditorCatalogSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _RealmEditorCatalogSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmEditorCatalogSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _RealmEditorCatalogSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeCatalog catalog,  CatalogGeneration generation,  Map<PresentationId, PresentationDefinition> presentations,  Map<ConversionId, ConversionDefinition> conversions,  Map<CapabilityId, CapabilityDefinition> capabilities,  Map<String, RealmEditorSubtypeResult> subtypeResults,  List<TypeDiagnostic> diagnostics,  Map<String, RealmElementCatalogEntry> elements,  RealmPageCatalog pageCatalog,  Map<ResourceDefinitionId, RealmResourceDefinition> resourceDefinitions,  Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> creationSlots,  Map<String, RealmRelationDefinition> relations,  Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition> collectionProjections,  List<RealmAuthoringCompilationProjection> compilationProjections,  RealmAuthoringSearchDefinition? authoringSearch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmEditorCatalogSnapshot() when $default != null:
return $default(_that.catalog,_that.generation,_that.presentations,_that.conversions,_that.capabilities,_that.subtypeResults,_that.diagnostics,_that.elements,_that.pageCatalog,_that.resourceDefinitions,_that.creationSlots,_that.relations,_that.collectionProjections,_that.compilationProjections,_that.authoringSearch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeCatalog catalog,  CatalogGeneration generation,  Map<PresentationId, PresentationDefinition> presentations,  Map<ConversionId, ConversionDefinition> conversions,  Map<CapabilityId, CapabilityDefinition> capabilities,  Map<String, RealmEditorSubtypeResult> subtypeResults,  List<TypeDiagnostic> diagnostics,  Map<String, RealmElementCatalogEntry> elements,  RealmPageCatalog pageCatalog,  Map<ResourceDefinitionId, RealmResourceDefinition> resourceDefinitions,  Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> creationSlots,  Map<String, RealmRelationDefinition> relations,  Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition> collectionProjections,  List<RealmAuthoringCompilationProjection> compilationProjections,  RealmAuthoringSearchDefinition? authoringSearch)  $default,) {final _that = this;
switch (_that) {
case _RealmEditorCatalogSnapshot():
return $default(_that.catalog,_that.generation,_that.presentations,_that.conversions,_that.capabilities,_that.subtypeResults,_that.diagnostics,_that.elements,_that.pageCatalog,_that.resourceDefinitions,_that.creationSlots,_that.relations,_that.collectionProjections,_that.compilationProjections,_that.authoringSearch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeCatalog catalog,  CatalogGeneration generation,  Map<PresentationId, PresentationDefinition> presentations,  Map<ConversionId, ConversionDefinition> conversions,  Map<CapabilityId, CapabilityDefinition> capabilities,  Map<String, RealmEditorSubtypeResult> subtypeResults,  List<TypeDiagnostic> diagnostics,  Map<String, RealmElementCatalogEntry> elements,  RealmPageCatalog pageCatalog,  Map<ResourceDefinitionId, RealmResourceDefinition> resourceDefinitions,  Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> creationSlots,  Map<String, RealmRelationDefinition> relations,  Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition> collectionProjections,  List<RealmAuthoringCompilationProjection> compilationProjections,  RealmAuthoringSearchDefinition? authoringSearch)?  $default,) {final _that = this;
switch (_that) {
case _RealmEditorCatalogSnapshot() when $default != null:
return $default(_that.catalog,_that.generation,_that.presentations,_that.conversions,_that.capabilities,_that.subtypeResults,_that.diagnostics,_that.elements,_that.pageCatalog,_that.resourceDefinitions,_that.creationSlots,_that.relations,_that.collectionProjections,_that.compilationProjections,_that.authoringSearch);case _:
  return null;

}
}

}

/// @nodoc


class _RealmEditorCatalogSnapshot implements RealmEditorCatalogSnapshot {
  const _RealmEditorCatalogSnapshot({required this.catalog, required this.generation,  Map<PresentationId, PresentationDefinition> presentations = const {},  Map<ConversionId, ConversionDefinition> conversions = const {},  Map<CapabilityId, CapabilityDefinition> capabilities = const {},  Map<String, RealmEditorSubtypeResult> subtypeResults = const {},  List<TypeDiagnostic> diagnostics = const [],  Map<String, RealmElementCatalogEntry> elements = const {}, this.pageCatalog = const RealmPageCatalog(),  Map<ResourceDefinitionId, RealmResourceDefinition> resourceDefinitions = const {},  Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> creationSlots = const {},  Map<String, RealmRelationDefinition> relations = const {},  Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition> collectionProjections = const {},  List<RealmAuthoringCompilationProjection> compilationProjections = const [], this.authoringSearch}): _presentations = presentations,_conversions = conversions,_capabilities = capabilities,_subtypeResults = subtypeResults,_diagnostics = diagnostics,_elements = elements,_resourceDefinitions = resourceDefinitions,_creationSlots = creationSlots,_relations = relations,_collectionProjections = collectionProjections,_compilationProjections = compilationProjections;


@override final  TypeCatalog catalog;
@override final  CatalogGeneration generation;
 final  Map<PresentationId, PresentationDefinition> _presentations;
@override@JsonKey() Map<PresentationId, PresentationDefinition> get presentations {
  if (_presentations is EqualUnmodifiableMapView) return _presentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_presentations);
}

 final  Map<ConversionId, ConversionDefinition> _conversions;
@override@JsonKey() Map<ConversionId, ConversionDefinition> get conversions {
  if (_conversions is EqualUnmodifiableMapView) return _conversions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_conversions);
}

 final  Map<CapabilityId, CapabilityDefinition> _capabilities;
@override@JsonKey() Map<CapabilityId, CapabilityDefinition> get capabilities {
  if (_capabilities is EqualUnmodifiableMapView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_capabilities);
}

 final  Map<String, RealmEditorSubtypeResult> _subtypeResults;
@override@JsonKey() Map<String, RealmEditorSubtypeResult> get subtypeResults {
  if (_subtypeResults is EqualUnmodifiableMapView) return _subtypeResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_subtypeResults);
}

 final  List<TypeDiagnostic> _diagnostics;
@override@JsonKey() List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

 final  Map<String, RealmElementCatalogEntry> _elements;
@override@JsonKey() Map<String, RealmElementCatalogEntry> get elements {
  if (_elements is EqualUnmodifiableMapView) return _elements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_elements);
}

@override@JsonKey() final  RealmPageCatalog pageCatalog;
 final  Map<ResourceDefinitionId, RealmResourceDefinition> _resourceDefinitions;
@override@JsonKey() Map<ResourceDefinitionId, RealmResourceDefinition> get resourceDefinitions {
  if (_resourceDefinitions is EqualUnmodifiableMapView) return _resourceDefinitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_resourceDefinitions);
}

 final  Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> _creationSlots;
@override@JsonKey() Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> get creationSlots {
  if (_creationSlots is EqualUnmodifiableMapView) return _creationSlots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_creationSlots);
}

 final  Map<String, RealmRelationDefinition> _relations;
@override@JsonKey() Map<String, RealmRelationDefinition> get relations {
  if (_relations is EqualUnmodifiableMapView) return _relations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_relations);
}

 final  Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition> _collectionProjections;
@override@JsonKey() Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition> get collectionProjections {
  if (_collectionProjections is EqualUnmodifiableMapView) return _collectionProjections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_collectionProjections);
}

 final  List<RealmAuthoringCompilationProjection> _compilationProjections;
@override@JsonKey() List<RealmAuthoringCompilationProjection> get compilationProjections {
  if (_compilationProjections is EqualUnmodifiableListView) return _compilationProjections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_compilationProjections);
}

@override final  RealmAuthoringSearchDefinition? authoringSearch;

/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmEditorCatalogSnapshotCopyWith<_RealmEditorCatalogSnapshot> get copyWith => __$RealmEditorCatalogSnapshotCopyWithImpl<_RealmEditorCatalogSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmEditorCatalogSnapshot&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.generation, generation) || other.generation == generation)&&const DeepCollectionEquality().equals(other.presentations, _presentations)&&const DeepCollectionEquality().equals(other.conversions, _conversions)&&const DeepCollectionEquality().equals(other.capabilities, _capabilities)&&const DeepCollectionEquality().equals(other.subtypeResults, _subtypeResults)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics)&&const DeepCollectionEquality().equals(other.elements, _elements)&&(identical(other.pageCatalog, pageCatalog) || other.pageCatalog == pageCatalog)&&const DeepCollectionEquality().equals(other.resourceDefinitions, _resourceDefinitions)&&const DeepCollectionEquality().equals(other.creationSlots, _creationSlots)&&const DeepCollectionEquality().equals(other.relations, _relations)&&const DeepCollectionEquality().equals(other.collectionProjections, _collectionProjections)&&const DeepCollectionEquality().equals(other.compilationProjections, _compilationProjections)&&(identical(other.authoringSearch, authoringSearch) || other.authoringSearch == authoringSearch));
}


@override
int get hashCode {
    return Object.hash(runtimeType,catalog,generation,const DeepCollectionEquality().hash(_presentations),const DeepCollectionEquality().hash(_conversions),const DeepCollectionEquality().hash(_capabilities),const DeepCollectionEquality().hash(_subtypeResults),const DeepCollectionEquality().hash(_diagnostics),const DeepCollectionEquality().hash(_elements),pageCatalog,const DeepCollectionEquality().hash(_resourceDefinitions),const DeepCollectionEquality().hash(_creationSlots),const DeepCollectionEquality().hash(_relations),const DeepCollectionEquality().hash(_collectionProjections),const DeepCollectionEquality().hash(_compilationProjections),authoringSearch);
}

@override
String toString() {
    return 'RealmEditorCatalogSnapshot(catalog: $catalog, generation: $generation, presentations: $presentations, conversions: $conversions, capabilities: $capabilities, subtypeResults: $subtypeResults, diagnostics: $diagnostics, elements: $elements, pageCatalog: $pageCatalog, resourceDefinitions: $resourceDefinitions, creationSlots: $creationSlots, relations: $relations, collectionProjections: $collectionProjections, compilationProjections: $compilationProjections, authoringSearch: $authoringSearch)';
}


}

/// @nodoc
abstract mixin class _$RealmEditorCatalogSnapshotCopyWith<$Res> implements $RealmEditorCatalogSnapshotCopyWith<$Res> {
  factory _$RealmEditorCatalogSnapshotCopyWith(_RealmEditorCatalogSnapshot value, $Res Function(_RealmEditorCatalogSnapshot) _then) = __$RealmEditorCatalogSnapshotCopyWithImpl;
@override @useResult
$Res call({
 TypeCatalog catalog, CatalogGeneration generation, Map<PresentationId, PresentationDefinition> presentations, Map<ConversionId, ConversionDefinition> conversions, Map<CapabilityId, CapabilityDefinition> capabilities, Map<String, RealmEditorSubtypeResult> subtypeResults, List<TypeDiagnostic> diagnostics, Map<String, RealmElementCatalogEntry> elements, RealmPageCatalog pageCatalog, Map<ResourceDefinitionId, RealmResourceDefinition> resourceDefinitions, Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> creationSlots, Map<String, RealmRelationDefinition> relations, Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition> collectionProjections, List<RealmAuthoringCompilationProjection> compilationProjections, RealmAuthoringSearchDefinition? authoringSearch
});


@override $TypeCatalogCopyWith<$Res> get catalog;@override $CatalogGenerationCopyWith<$Res> get generation;@override $RealmPageCatalogCopyWith<$Res> get pageCatalog;@override $RealmAuthoringSearchDefinitionCopyWith<$Res>? get authoringSearch;

}
/// @nodoc
class __$RealmEditorCatalogSnapshotCopyWithImpl<$Res>
    implements _$RealmEditorCatalogSnapshotCopyWith<$Res> {
  __$RealmEditorCatalogSnapshotCopyWithImpl(this._self, this._then);

  final _RealmEditorCatalogSnapshot _self;
  final $Res Function(_RealmEditorCatalogSnapshot) _then;

/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,Object? generation = null,Object? presentations = null,Object? conversions = null,Object? capabilities = null,Object? subtypeResults = null,Object? diagnostics = null,Object? elements = null,Object? pageCatalog = null,Object? resourceDefinitions = null,Object? creationSlots = null,Object? relations = null,Object? collectionProjections = null,Object? compilationProjections = null,Object? authoringSearch = freezed,}) {
  return _then(_RealmEditorCatalogSnapshot(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as TypeCatalog,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as CatalogGeneration,presentations: null == presentations ? _self._presentations : presentations // ignore: cast_nullable_to_non_nullable
as Map<PresentationId, PresentationDefinition>,conversions: null == conversions ? _self._conversions : conversions // ignore: cast_nullable_to_non_nullable
as Map<ConversionId, ConversionDefinition>,capabilities: null == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as Map<CapabilityId, CapabilityDefinition>,subtypeResults: null == subtypeResults ? _self._subtypeResults : subtypeResults // ignore: cast_nullable_to_non_nullable
as Map<String, RealmEditorSubtypeResult>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,elements: null == elements ? _self._elements : elements // ignore: cast_nullable_to_non_nullable
as Map<String, RealmElementCatalogEntry>,pageCatalog: null == pageCatalog ? _self.pageCatalog : pageCatalog // ignore: cast_nullable_to_non_nullable
as RealmPageCatalog,resourceDefinitions: null == resourceDefinitions ? _self._resourceDefinitions : resourceDefinitions // ignore: cast_nullable_to_non_nullable
as Map<ResourceDefinitionId, RealmResourceDefinition>,creationSlots: null == creationSlots ? _self._creationSlots : creationSlots // ignore: cast_nullable_to_non_nullable
as Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot>,relations: null == relations ? _self._relations : relations // ignore: cast_nullable_to_non_nullable
as Map<String, RealmRelationDefinition>,collectionProjections: null == collectionProjections ? _self._collectionProjections : collectionProjections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition>,compilationProjections: null == compilationProjections ? _self._compilationProjections : compilationProjections // ignore: cast_nullable_to_non_nullable
as List<RealmAuthoringCompilationProjection>,authoringSearch: freezed == authoringSearch ? _self.authoringSearch : authoringSearch // ignore: cast_nullable_to_non_nullable
as RealmAuthoringSearchDefinition?,
  ));
}

/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeCatalogCopyWith<$Res> get catalog {

  return $TypeCatalogCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogGenerationCopyWith<$Res> get generation {

  return $CatalogGenerationCopyWith<$Res>(_self.generation, (value) {
    return _then(_self.copyWith(generation: value));
  });
}/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPageCatalogCopyWith<$Res> get pageCatalog {

  return $RealmPageCatalogCopyWith<$Res>(_self.pageCatalog, (value) {
    return _then(_self.copyWith(pageCatalog: value));
  });
}/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmAuthoringSearchDefinitionCopyWith<$Res>? get authoringSearch {
    if (_self.authoringSearch == null) {
    return null;
  }

  return $RealmAuthoringSearchDefinitionCopyWith<$Res>(_self.authoringSearch!, (value) {
    return _then(_self.copyWith(authoringSearch: value));
  });
}
}

/// @nodoc
mixin _$RealmAuthoringSearchDefinition {

 Set<ResourceDefinitionId> get definitions; List<SearchSelectorDefinition> get selectors; List<RealmAuthoringSearchFacetDefinition> get facets;
/// Create a copy of RealmAuthoringSearchDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmAuthoringSearchDefinitionCopyWith<RealmAuthoringSearchDefinition> get copyWith => _$RealmAuthoringSearchDefinitionCopyWithImpl<RealmAuthoringSearchDefinition>(this as RealmAuthoringSearchDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmAuthoringSearchDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmAuthoringSearchDefinition&&const DeepCollectionEquality().equals(other.definitions, _this.definitions)&&const DeepCollectionEquality().equals(other.selectors, _this.selectors)&&const DeepCollectionEquality().equals(other.facets, _this.facets));
}


@override
int get hashCode {
  final _this = this as RealmAuthoringSearchDefinition;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.definitions),const DeepCollectionEquality().hash(_this.selectors),const DeepCollectionEquality().hash(_this.facets));
}

@override
String toString() {
  final _this = this as RealmAuthoringSearchDefinition;
  return 'RealmAuthoringSearchDefinition(definitions: ${_this.definitions}, selectors: ${_this.selectors}, facets: ${_this.facets})';
}


}

/// @nodoc
abstract mixin class $RealmAuthoringSearchDefinitionCopyWith<$Res>  {
  factory $RealmAuthoringSearchDefinitionCopyWith(RealmAuthoringSearchDefinition value, $Res Function(RealmAuthoringSearchDefinition) _then) = _$RealmAuthoringSearchDefinitionCopyWithImpl;
@useResult
$Res call({
 Set<ResourceDefinitionId> definitions, List<SearchSelectorDefinition> selectors, List<RealmAuthoringSearchFacetDefinition> facets
});




}
/// @nodoc
class _$RealmAuthoringSearchDefinitionCopyWithImpl<$Res>
    implements $RealmAuthoringSearchDefinitionCopyWith<$Res> {
  _$RealmAuthoringSearchDefinitionCopyWithImpl(this._self, this._then);

  final RealmAuthoringSearchDefinition _self;
  final $Res Function(RealmAuthoringSearchDefinition) _then;

/// Create a copy of RealmAuthoringSearchDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definitions = null,Object? selectors = null,Object? facets = null,}) {
  return _then(RealmAuthoringSearchDefinition(
definitions: null == definitions ? _self.definitions : definitions // ignore: cast_nullable_to_non_nullable
as Set<ResourceDefinitionId>,selectors: null == selectors ? _self.selectors : selectors // ignore: cast_nullable_to_non_nullable
as List<SearchSelectorDefinition>,facets: null == facets ? _self.facets : facets // ignore: cast_nullable_to_non_nullable
as List<RealmAuthoringSearchFacetDefinition>,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmAuthoringSearchDefinition].
extension RealmAuthoringSearchDefinitionPatterns on RealmAuthoringSearchDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmAuthoringSearchDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmAuthoringSearchDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmAuthoringSearchDefinition value)  $default,){
final _that = this;
switch (_that) {
case _RealmAuthoringSearchDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmAuthoringSearchDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _RealmAuthoringSearchDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<ResourceDefinitionId> definitions,  List<SearchSelectorDefinition> selectors,  List<RealmAuthoringSearchFacetDefinition> facets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmAuthoringSearchDefinition() when $default != null:
return $default(_that.definitions,_that.selectors,_that.facets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<ResourceDefinitionId> definitions,  List<SearchSelectorDefinition> selectors,  List<RealmAuthoringSearchFacetDefinition> facets)  $default,) {final _that = this;
switch (_that) {
case _RealmAuthoringSearchDefinition():
return $default(_that.definitions,_that.selectors,_that.facets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<ResourceDefinitionId> definitions,  List<SearchSelectorDefinition> selectors,  List<RealmAuthoringSearchFacetDefinition> facets)?  $default,) {final _that = this;
switch (_that) {
case _RealmAuthoringSearchDefinition() when $default != null:
return $default(_that.definitions,_that.selectors,_that.facets);case _:
  return null;

}
}

}

/// @nodoc


class _RealmAuthoringSearchDefinition implements RealmAuthoringSearchDefinition {
  const _RealmAuthoringSearchDefinition({ Set<ResourceDefinitionId> definitions = const {},  List<SearchSelectorDefinition> selectors = const [],  List<RealmAuthoringSearchFacetDefinition> facets = const []}): _definitions = definitions,_selectors = selectors,_facets = facets;


 final  Set<ResourceDefinitionId> _definitions;
@override@JsonKey() Set<ResourceDefinitionId> get definitions {
  if (_definitions is EqualUnmodifiableSetView) return _definitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_definitions);
}

 final  List<SearchSelectorDefinition> _selectors;
@override@JsonKey() List<SearchSelectorDefinition> get selectors {
  if (_selectors is EqualUnmodifiableListView) return _selectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectors);
}

 final  List<RealmAuthoringSearchFacetDefinition> _facets;
@override@JsonKey() List<RealmAuthoringSearchFacetDefinition> get facets {
  if (_facets is EqualUnmodifiableListView) return _facets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_facets);
}


/// Create a copy of RealmAuthoringSearchDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmAuthoringSearchDefinitionCopyWith<_RealmAuthoringSearchDefinition> get copyWith => __$RealmAuthoringSearchDefinitionCopyWithImpl<_RealmAuthoringSearchDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmAuthoringSearchDefinition&&const DeepCollectionEquality().equals(other.definitions, _definitions)&&const DeepCollectionEquality().equals(other.selectors, _selectors)&&const DeepCollectionEquality().equals(other.facets, _facets));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_definitions),const DeepCollectionEquality().hash(_selectors),const DeepCollectionEquality().hash(_facets));
}

@override
String toString() {
    return 'RealmAuthoringSearchDefinition(definitions: $definitions, selectors: $selectors, facets: $facets)';
}


}

/// @nodoc
abstract mixin class _$RealmAuthoringSearchDefinitionCopyWith<$Res> implements $RealmAuthoringSearchDefinitionCopyWith<$Res> {
  factory _$RealmAuthoringSearchDefinitionCopyWith(_RealmAuthoringSearchDefinition value, $Res Function(_RealmAuthoringSearchDefinition) _then) = __$RealmAuthoringSearchDefinitionCopyWithImpl;
@override @useResult
$Res call({
 Set<ResourceDefinitionId> definitions, List<SearchSelectorDefinition> selectors, List<RealmAuthoringSearchFacetDefinition> facets
});




}
/// @nodoc
class __$RealmAuthoringSearchDefinitionCopyWithImpl<$Res>
    implements _$RealmAuthoringSearchDefinitionCopyWith<$Res> {
  __$RealmAuthoringSearchDefinitionCopyWithImpl(this._self, this._then);

  final _RealmAuthoringSearchDefinition _self;
  final $Res Function(_RealmAuthoringSearchDefinition) _then;

/// Create a copy of RealmAuthoringSearchDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definitions = null,Object? selectors = null,Object? facets = null,}) {
  return _then(_RealmAuthoringSearchDefinition(
definitions: null == definitions ? _self._definitions : definitions // ignore: cast_nullable_to_non_nullable
as Set<ResourceDefinitionId>,selectors: null == selectors ? _self._selectors : selectors // ignore: cast_nullable_to_non_nullable
as List<SearchSelectorDefinition>,facets: null == facets ? _self._facets : facets // ignore: cast_nullable_to_non_nullable
as List<RealmAuthoringSearchFacetDefinition>,
  ));
}


}

/// @nodoc
mixin _$RealmAuthoringSearchFacetDefinition {

 String get id; String get label; String get selectorId;
/// Create a copy of RealmAuthoringSearchFacetDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmAuthoringSearchFacetDefinitionCopyWith<RealmAuthoringSearchFacetDefinition> get copyWith => _$RealmAuthoringSearchFacetDefinitionCopyWithImpl<RealmAuthoringSearchFacetDefinition>(this as RealmAuthoringSearchFacetDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmAuthoringSearchFacetDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmAuthoringSearchFacetDefinition&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.selectorId, _this.selectorId) || other.selectorId == _this.selectorId));
}


@override
int get hashCode {
  final _this = this as RealmAuthoringSearchFacetDefinition;
  return Object.hash(runtimeType,_this.id,_this.label,_this.selectorId);
}

@override
String toString() {
  final _this = this as RealmAuthoringSearchFacetDefinition;
  return 'RealmAuthoringSearchFacetDefinition(id: ${_this.id}, label: ${_this.label}, selectorId: ${_this.selectorId})';
}


}

/// @nodoc
abstract mixin class $RealmAuthoringSearchFacetDefinitionCopyWith<$Res>  {
  factory $RealmAuthoringSearchFacetDefinitionCopyWith(RealmAuthoringSearchFacetDefinition value, $Res Function(RealmAuthoringSearchFacetDefinition) _then) = _$RealmAuthoringSearchFacetDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String label, String selectorId
});




}
/// @nodoc
class _$RealmAuthoringSearchFacetDefinitionCopyWithImpl<$Res>
    implements $RealmAuthoringSearchFacetDefinitionCopyWith<$Res> {
  _$RealmAuthoringSearchFacetDefinitionCopyWithImpl(this._self, this._then);

  final RealmAuthoringSearchFacetDefinition _self;
  final $Res Function(RealmAuthoringSearchFacetDefinition) _then;

/// Create a copy of RealmAuthoringSearchFacetDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? selectorId = null,}) {
  return _then(RealmAuthoringSearchFacetDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,selectorId: null == selectorId ? _self.selectorId : selectorId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmAuthoringSearchFacetDefinition].
extension RealmAuthoringSearchFacetDefinitionPatterns on RealmAuthoringSearchFacetDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmAuthoringSearchFacetDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmAuthoringSearchFacetDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmAuthoringSearchFacetDefinition value)  $default,){
final _that = this;
switch (_that) {
case _RealmAuthoringSearchFacetDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmAuthoringSearchFacetDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _RealmAuthoringSearchFacetDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String selectorId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmAuthoringSearchFacetDefinition() when $default != null:
return $default(_that.id,_that.label,_that.selectorId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String selectorId)  $default,) {final _that = this;
switch (_that) {
case _RealmAuthoringSearchFacetDefinition():
return $default(_that.id,_that.label,_that.selectorId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String selectorId)?  $default,) {final _that = this;
switch (_that) {
case _RealmAuthoringSearchFacetDefinition() when $default != null:
return $default(_that.id,_that.label,_that.selectorId);case _:
  return null;

}
}

}

/// @nodoc


class _RealmAuthoringSearchFacetDefinition implements RealmAuthoringSearchFacetDefinition {
  const _RealmAuthoringSearchFacetDefinition({required this.id, required this.label, required this.selectorId});


@override final  String id;
@override final  String label;
@override final  String selectorId;

/// Create a copy of RealmAuthoringSearchFacetDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmAuthoringSearchFacetDefinitionCopyWith<_RealmAuthoringSearchFacetDefinition> get copyWith => __$RealmAuthoringSearchFacetDefinitionCopyWithImpl<_RealmAuthoringSearchFacetDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmAuthoringSearchFacetDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.selectorId, selectorId) || other.selectorId == selectorId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,label,selectorId);
}

@override
String toString() {
    return 'RealmAuthoringSearchFacetDefinition(id: $id, label: $label, selectorId: $selectorId)';
}


}

/// @nodoc
abstract mixin class _$RealmAuthoringSearchFacetDefinitionCopyWith<$Res> implements $RealmAuthoringSearchFacetDefinitionCopyWith<$Res> {
  factory _$RealmAuthoringSearchFacetDefinitionCopyWith(_RealmAuthoringSearchFacetDefinition value, $Res Function(_RealmAuthoringSearchFacetDefinition) _then) = __$RealmAuthoringSearchFacetDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String selectorId
});




}
/// @nodoc
class __$RealmAuthoringSearchFacetDefinitionCopyWithImpl<$Res>
    implements _$RealmAuthoringSearchFacetDefinitionCopyWith<$Res> {
  __$RealmAuthoringSearchFacetDefinitionCopyWithImpl(this._self, this._then);

  final _RealmAuthoringSearchFacetDefinition _self;
  final $Res Function(_RealmAuthoringSearchFacetDefinition) _then;

/// Create a copy of RealmAuthoringSearchFacetDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? selectorId = null,}) {
  return _then(_RealmAuthoringSearchFacetDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,selectorId: null == selectorId ? _self.selectorId : selectorId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RealmAuthoringCreationContext {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmAuthoringCreationContext);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmAuthoringCreationContext()';
}


}

/// @nodoc
class $RealmAuthoringCreationContextCopyWith<$Res>  {
$RealmAuthoringCreationContextCopyWith(RealmAuthoringCreationContext _, $Res Function(RealmAuthoringCreationContext) __);
}


/// Adds pattern-matching-related methods to [RealmAuthoringCreationContext].
extension RealmAuthoringCreationContextPatterns on RealmAuthoringCreationContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RealmStandaloneCreationContext value)?  standalone,TResult Function( RealmDeclaredRelationCreationContext value)?  declaredRelation,TResult Function( RealmReferencePathCreationContext value)?  referencePath,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RealmStandaloneCreationContext() when standalone != null:
return standalone(_that);case RealmDeclaredRelationCreationContext() when declaredRelation != null:
return declaredRelation(_that);case RealmReferencePathCreationContext() when referencePath != null:
return referencePath(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RealmStandaloneCreationContext value)  standalone,required TResult Function( RealmDeclaredRelationCreationContext value)  declaredRelation,required TResult Function( RealmReferencePathCreationContext value)  referencePath,}){
final _that = this;
switch (_that) {
case RealmStandaloneCreationContext():
return standalone(_that);case RealmDeclaredRelationCreationContext():
return declaredRelation(_that);case RealmReferencePathCreationContext():
return referencePath(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RealmStandaloneCreationContext value)?  standalone,TResult? Function( RealmDeclaredRelationCreationContext value)?  declaredRelation,TResult? Function( RealmReferencePathCreationContext value)?  referencePath,}){
final _that = this;
switch (_that) {
case RealmStandaloneCreationContext() when standalone != null:
return standalone(_that);case RealmDeclaredRelationCreationContext() when declaredRelation != null:
return declaredRelation(_that);case RealmReferencePathCreationContext() when referencePath != null:
return referencePath(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  standalone,TResult Function( RealmCreationHostFilter hosts,  RealmCreationHostCardinality cardinality,  String relation,  RealmCreationRelationDirection direction)?  declaredRelation,TResult Function( RealmCreationHostFilter hosts,  RealmCreationHostCardinality cardinality,  DataPath path)?  referencePath,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RealmStandaloneCreationContext() when standalone != null:
return standalone();case RealmDeclaredRelationCreationContext() when declaredRelation != null:
return declaredRelation(_that.hosts,_that.cardinality,_that.relation,_that.direction);case RealmReferencePathCreationContext() when referencePath != null:
return referencePath(_that.hosts,_that.cardinality,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  standalone,required TResult Function( RealmCreationHostFilter hosts,  RealmCreationHostCardinality cardinality,  String relation,  RealmCreationRelationDirection direction)  declaredRelation,required TResult Function( RealmCreationHostFilter hosts,  RealmCreationHostCardinality cardinality,  DataPath path)  referencePath,}) {final _that = this;
switch (_that) {
case RealmStandaloneCreationContext():
return standalone();case RealmDeclaredRelationCreationContext():
return declaredRelation(_that.hosts,_that.cardinality,_that.relation,_that.direction);case RealmReferencePathCreationContext():
return referencePath(_that.hosts,_that.cardinality,_that.path);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  standalone,TResult? Function( RealmCreationHostFilter hosts,  RealmCreationHostCardinality cardinality,  String relation,  RealmCreationRelationDirection direction)?  declaredRelation,TResult? Function( RealmCreationHostFilter hosts,  RealmCreationHostCardinality cardinality,  DataPath path)?  referencePath,}) {final _that = this;
switch (_that) {
case RealmStandaloneCreationContext() when standalone != null:
return standalone();case RealmDeclaredRelationCreationContext() when declaredRelation != null:
return declaredRelation(_that.hosts,_that.cardinality,_that.relation,_that.direction);case RealmReferencePathCreationContext() when referencePath != null:
return referencePath(_that.hosts,_that.cardinality,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class RealmStandaloneCreationContext implements RealmAuthoringCreationContext {
  const RealmStandaloneCreationContext();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmStandaloneCreationContext);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmAuthoringCreationContext.standalone()';
}


}




/// @nodoc


class RealmDeclaredRelationCreationContext implements RealmAuthoringCreationContext {
  const RealmDeclaredRelationCreationContext({required this.hosts, required this.cardinality, required this.relation, required this.direction});


 final  RealmCreationHostFilter hosts;
 final  RealmCreationHostCardinality cardinality;
 final  String relation;
 final  RealmCreationRelationDirection direction;

/// Create a copy of RealmAuthoringCreationContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmDeclaredRelationCreationContextCopyWith<RealmDeclaredRelationCreationContext> get copyWith => _$RealmDeclaredRelationCreationContextCopyWithImpl<RealmDeclaredRelationCreationContext>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmDeclaredRelationCreationContext&&(identical(other.hosts, hosts) || other.hosts == hosts)&&(identical(other.cardinality, cardinality) || other.cardinality == cardinality)&&(identical(other.relation, relation) || other.relation == relation)&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode {
    return Object.hash(runtimeType,hosts,cardinality,relation,direction);
}

@override
String toString() {
    return 'RealmAuthoringCreationContext.declaredRelation(hosts: $hosts, cardinality: $cardinality, relation: $relation, direction: $direction)';
}


}

/// @nodoc
abstract mixin class $RealmDeclaredRelationCreationContextCopyWith<$Res> implements $RealmAuthoringCreationContextCopyWith<$Res> {
  factory $RealmDeclaredRelationCreationContextCopyWith(RealmDeclaredRelationCreationContext value, $Res Function(RealmDeclaredRelationCreationContext) _then) = _$RealmDeclaredRelationCreationContextCopyWithImpl;
@useResult
$Res call({
 RealmCreationHostFilter hosts, RealmCreationHostCardinality cardinality, String relation, RealmCreationRelationDirection direction
});


$RealmCreationHostFilterCopyWith<$Res> get hosts;

}
/// @nodoc
class _$RealmDeclaredRelationCreationContextCopyWithImpl<$Res>
    implements $RealmDeclaredRelationCreationContextCopyWith<$Res> {
  _$RealmDeclaredRelationCreationContextCopyWithImpl(this._self, this._then);

  final RealmDeclaredRelationCreationContext _self;
  final $Res Function(RealmDeclaredRelationCreationContext) _then;

/// Create a copy of RealmAuthoringCreationContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hosts = null,Object? cardinality = null,Object? relation = null,Object? direction = null,}) {
  return _then(RealmDeclaredRelationCreationContext(
hosts: null == hosts ? _self.hosts : hosts // ignore: cast_nullable_to_non_nullable
as RealmCreationHostFilter,cardinality: null == cardinality ? _self.cardinality : cardinality // ignore: cast_nullable_to_non_nullable
as RealmCreationHostCardinality,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as RealmCreationRelationDirection,
  ));
}

/// Create a copy of RealmAuthoringCreationContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmCreationHostFilterCopyWith<$Res> get hosts {

  return $RealmCreationHostFilterCopyWith<$Res>(_self.hosts, (value) {
    return _then(_self.copyWith(hosts: value));
  });
}
}

/// @nodoc


class RealmReferencePathCreationContext implements RealmAuthoringCreationContext {
  const RealmReferencePathCreationContext({required this.hosts, required this.cardinality, required this.path});


 final  RealmCreationHostFilter hosts;
 final  RealmCreationHostCardinality cardinality;
 final  DataPath path;

/// Create a copy of RealmAuthoringCreationContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmReferencePathCreationContextCopyWith<RealmReferencePathCreationContext> get copyWith => _$RealmReferencePathCreationContextCopyWithImpl<RealmReferencePathCreationContext>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmReferencePathCreationContext&&(identical(other.hosts, hosts) || other.hosts == hosts)&&(identical(other.cardinality, cardinality) || other.cardinality == cardinality)&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,hosts,cardinality,path);
}

@override
String toString() {
    return 'RealmAuthoringCreationContext.referencePath(hosts: $hosts, cardinality: $cardinality, path: $path)';
}


}

/// @nodoc
abstract mixin class $RealmReferencePathCreationContextCopyWith<$Res> implements $RealmAuthoringCreationContextCopyWith<$Res> {
  factory $RealmReferencePathCreationContextCopyWith(RealmReferencePathCreationContext value, $Res Function(RealmReferencePathCreationContext) _then) = _$RealmReferencePathCreationContextCopyWithImpl;
@useResult
$Res call({
 RealmCreationHostFilter hosts, RealmCreationHostCardinality cardinality, DataPath path
});


$RealmCreationHostFilterCopyWith<$Res> get hosts;$DataPathCopyWith<$Res> get path;

}
/// @nodoc
class _$RealmReferencePathCreationContextCopyWithImpl<$Res>
    implements $RealmReferencePathCreationContextCopyWith<$Res> {
  _$RealmReferencePathCreationContextCopyWithImpl(this._self, this._then);

  final RealmReferencePathCreationContext _self;
  final $Res Function(RealmReferencePathCreationContext) _then;

/// Create a copy of RealmAuthoringCreationContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hosts = null,Object? cardinality = null,Object? path = null,}) {
  return _then(RealmReferencePathCreationContext(
hosts: null == hosts ? _self.hosts : hosts // ignore: cast_nullable_to_non_nullable
as RealmCreationHostFilter,cardinality: null == cardinality ? _self.cardinality : cardinality // ignore: cast_nullable_to_non_nullable
as RealmCreationHostCardinality,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,
  ));
}

/// Create a copy of RealmAuthoringCreationContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmCreationHostFilterCopyWith<$Res> get hosts {

  return $RealmCreationHostFilterCopyWith<$Res>(_self.hosts, (value) {
    return _then(_self.copyWith(hosts: value));
  });
}/// Create a copy of RealmAuthoringCreationContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {

  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}
}

/// @nodoc
mixin _$RealmCreationHostFilter {

 Set<ResourceDefinitionId> get definitions; TypeExpression? get assignableTo;
/// Create a copy of RealmCreationHostFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmCreationHostFilterCopyWith<RealmCreationHostFilter> get copyWith => _$RealmCreationHostFilterCopyWithImpl<RealmCreationHostFilter>(this as RealmCreationHostFilter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmCreationHostFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmCreationHostFilter&&const DeepCollectionEquality().equals(other.definitions, _this.definitions)&&(identical(other.assignableTo, _this.assignableTo) || other.assignableTo == _this.assignableTo));
}


@override
int get hashCode {
  final _this = this as RealmCreationHostFilter;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.definitions),_this.assignableTo);
}

@override
String toString() {
  final _this = this as RealmCreationHostFilter;
  return 'RealmCreationHostFilter(definitions: ${_this.definitions}, assignableTo: ${_this.assignableTo})';
}


}

/// @nodoc
abstract mixin class $RealmCreationHostFilterCopyWith<$Res>  {
  factory $RealmCreationHostFilterCopyWith(RealmCreationHostFilter value, $Res Function(RealmCreationHostFilter) _then) = _$RealmCreationHostFilterCopyWithImpl;
@useResult
$Res call({
 Set<ResourceDefinitionId> definitions, TypeExpression? assignableTo
});


$TypeExpressionCopyWith<$Res>? get assignableTo;

}
/// @nodoc
class _$RealmCreationHostFilterCopyWithImpl<$Res>
    implements $RealmCreationHostFilterCopyWith<$Res> {
  _$RealmCreationHostFilterCopyWithImpl(this._self, this._then);

  final RealmCreationHostFilter _self;
  final $Res Function(RealmCreationHostFilter) _then;

/// Create a copy of RealmCreationHostFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definitions = null,Object? assignableTo = freezed,}) {
  return _then(RealmCreationHostFilter(
definitions: null == definitions ? _self.definitions : definitions // ignore: cast_nullable_to_non_nullable
as Set<ResourceDefinitionId>,assignableTo: freezed == assignableTo ? _self.assignableTo : assignableTo // ignore: cast_nullable_to_non_nullable
as TypeExpression?,
  ));
}
/// Create a copy of RealmCreationHostFilter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res>? get assignableTo {
    if (_self.assignableTo == null) {
    return null;
  }

  return $TypeExpressionCopyWith<$Res>(_self.assignableTo!, (value) {
    return _then(_self.copyWith(assignableTo: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmCreationHostFilter].
extension RealmCreationHostFilterPatterns on RealmCreationHostFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmCreationHostFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmCreationHostFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmCreationHostFilter value)  $default,){
final _that = this;
switch (_that) {
case _RealmCreationHostFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmCreationHostFilter value)?  $default,){
final _that = this;
switch (_that) {
case _RealmCreationHostFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<ResourceDefinitionId> definitions,  TypeExpression? assignableTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmCreationHostFilter() when $default != null:
return $default(_that.definitions,_that.assignableTo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<ResourceDefinitionId> definitions,  TypeExpression? assignableTo)  $default,) {final _that = this;
switch (_that) {
case _RealmCreationHostFilter():
return $default(_that.definitions,_that.assignableTo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<ResourceDefinitionId> definitions,  TypeExpression? assignableTo)?  $default,) {final _that = this;
switch (_that) {
case _RealmCreationHostFilter() when $default != null:
return $default(_that.definitions,_that.assignableTo);case _:
  return null;

}
}

}

/// @nodoc


class _RealmCreationHostFilter implements RealmCreationHostFilter {
  const _RealmCreationHostFilter({ Set<ResourceDefinitionId> definitions = const {}, this.assignableTo}): _definitions = definitions;


 final  Set<ResourceDefinitionId> _definitions;
@override@JsonKey() Set<ResourceDefinitionId> get definitions {
  if (_definitions is EqualUnmodifiableSetView) return _definitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_definitions);
}

@override final  TypeExpression? assignableTo;

/// Create a copy of RealmCreationHostFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmCreationHostFilterCopyWith<_RealmCreationHostFilter> get copyWith => __$RealmCreationHostFilterCopyWithImpl<_RealmCreationHostFilter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmCreationHostFilter&&const DeepCollectionEquality().equals(other.definitions, _definitions)&&(identical(other.assignableTo, assignableTo) || other.assignableTo == assignableTo));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_definitions),assignableTo);
}

@override
String toString() {
    return 'RealmCreationHostFilter(definitions: $definitions, assignableTo: $assignableTo)';
}


}

/// @nodoc
abstract mixin class _$RealmCreationHostFilterCopyWith<$Res> implements $RealmCreationHostFilterCopyWith<$Res> {
  factory _$RealmCreationHostFilterCopyWith(_RealmCreationHostFilter value, $Res Function(_RealmCreationHostFilter) _then) = __$RealmCreationHostFilterCopyWithImpl;
@override @useResult
$Res call({
 Set<ResourceDefinitionId> definitions, TypeExpression? assignableTo
});


@override $TypeExpressionCopyWith<$Res>? get assignableTo;

}
/// @nodoc
class __$RealmCreationHostFilterCopyWithImpl<$Res>
    implements _$RealmCreationHostFilterCopyWith<$Res> {
  __$RealmCreationHostFilterCopyWithImpl(this._self, this._then);

  final _RealmCreationHostFilter _self;
  final $Res Function(_RealmCreationHostFilter) _then;

/// Create a copy of RealmCreationHostFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definitions = null,Object? assignableTo = freezed,}) {
  return _then(_RealmCreationHostFilter(
definitions: null == definitions ? _self._definitions : definitions // ignore: cast_nullable_to_non_nullable
as Set<ResourceDefinitionId>,assignableTo: freezed == assignableTo ? _self.assignableTo : assignableTo // ignore: cast_nullable_to_non_nullable
as TypeExpression?,
  ));
}

/// Create a copy of RealmCreationHostFilter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res>? get assignableTo {
    if (_self.assignableTo == null) {
    return null;
  }

  return $TypeExpressionCopyWith<$Res>(_self.assignableTo!, (value) {
    return _then(_self.copyWith(assignableTo: value));
  });
}
}

/// @nodoc
mixin _$RealmAuthoringCreationSlot {

 AuthoringCreationSlotId get id; String get label; ResourceDefinitionId get creates; RealmAuthoringCreationContext get context; List<ResolvedTypeRef> get concreteRoots;
/// Create a copy of RealmAuthoringCreationSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmAuthoringCreationSlotCopyWith<RealmAuthoringCreationSlot> get copyWith => _$RealmAuthoringCreationSlotCopyWithImpl<RealmAuthoringCreationSlot>(this as RealmAuthoringCreationSlot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmAuthoringCreationSlot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmAuthoringCreationSlot&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.creates, _this.creates) || other.creates == _this.creates)&&(identical(other.context, _this.context) || other.context == _this.context)&&const DeepCollectionEquality().equals(other.concreteRoots, _this.concreteRoots));
}


@override
int get hashCode {
  final _this = this as RealmAuthoringCreationSlot;
  return Object.hash(runtimeType,_this.id,_this.label,_this.creates,_this.context,const DeepCollectionEquality().hash(_this.concreteRoots));
}

@override
String toString() {
  final _this = this as RealmAuthoringCreationSlot;
  return 'RealmAuthoringCreationSlot(id: ${_this.id}, label: ${_this.label}, creates: ${_this.creates}, context: ${_this.context}, concreteRoots: ${_this.concreteRoots})';
}


}

/// @nodoc
abstract mixin class $RealmAuthoringCreationSlotCopyWith<$Res>  {
  factory $RealmAuthoringCreationSlotCopyWith(RealmAuthoringCreationSlot value, $Res Function(RealmAuthoringCreationSlot) _then) = _$RealmAuthoringCreationSlotCopyWithImpl;
@useResult
$Res call({
 AuthoringCreationSlotId id, String label, ResourceDefinitionId creates, RealmAuthoringCreationContext context, List<ResolvedTypeRef> concreteRoots
});


$RealmAuthoringCreationContextCopyWith<$Res> get context;

}
/// @nodoc
class _$RealmAuthoringCreationSlotCopyWithImpl<$Res>
    implements $RealmAuthoringCreationSlotCopyWith<$Res> {
  _$RealmAuthoringCreationSlotCopyWithImpl(this._self, this._then);

  final RealmAuthoringCreationSlot _self;
  final $Res Function(RealmAuthoringCreationSlot) _then;

/// Create a copy of RealmAuthoringCreationSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? creates = null,Object? context = null,Object? concreteRoots = null,}) {
  return _then(RealmAuthoringCreationSlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as AuthoringCreationSlotId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,creates: null == creates ? _self.creates : creates // ignore: cast_nullable_to_non_nullable
as ResourceDefinitionId,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as RealmAuthoringCreationContext,concreteRoots: null == concreteRoots ? _self.concreteRoots : concreteRoots // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,
  ));
}
/// Create a copy of RealmAuthoringCreationSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmAuthoringCreationContextCopyWith<$Res> get context {

  return $RealmAuthoringCreationContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmAuthoringCreationSlot].
extension RealmAuthoringCreationSlotPatterns on RealmAuthoringCreationSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmAuthoringCreationSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmAuthoringCreationSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmAuthoringCreationSlot value)  $default,){
final _that = this;
switch (_that) {
case _RealmAuthoringCreationSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmAuthoringCreationSlot value)?  $default,){
final _that = this;
switch (_that) {
case _RealmAuthoringCreationSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringCreationSlotId id,  String label,  ResourceDefinitionId creates,  RealmAuthoringCreationContext context,  List<ResolvedTypeRef> concreteRoots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmAuthoringCreationSlot() when $default != null:
return $default(_that.id,_that.label,_that.creates,_that.context,_that.concreteRoots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringCreationSlotId id,  String label,  ResourceDefinitionId creates,  RealmAuthoringCreationContext context,  List<ResolvedTypeRef> concreteRoots)  $default,) {final _that = this;
switch (_that) {
case _RealmAuthoringCreationSlot():
return $default(_that.id,_that.label,_that.creates,_that.context,_that.concreteRoots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringCreationSlotId id,  String label,  ResourceDefinitionId creates,  RealmAuthoringCreationContext context,  List<ResolvedTypeRef> concreteRoots)?  $default,) {final _that = this;
switch (_that) {
case _RealmAuthoringCreationSlot() when $default != null:
return $default(_that.id,_that.label,_that.creates,_that.context,_that.concreteRoots);case _:
  return null;

}
}

}

/// @nodoc


class _RealmAuthoringCreationSlot extends RealmAuthoringCreationSlot {
  const _RealmAuthoringCreationSlot({required this.id, required this.label, required this.creates, required this.context, required  List<ResolvedTypeRef> concreteRoots}): _concreteRoots = concreteRoots,super._();


@override final  AuthoringCreationSlotId id;
@override final  String label;
@override final  ResourceDefinitionId creates;
@override final  RealmAuthoringCreationContext context;
 final  List<ResolvedTypeRef> _concreteRoots;
@override List<ResolvedTypeRef> get concreteRoots {
  if (_concreteRoots is EqualUnmodifiableListView) return _concreteRoots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_concreteRoots);
}


/// Create a copy of RealmAuthoringCreationSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmAuthoringCreationSlotCopyWith<_RealmAuthoringCreationSlot> get copyWith => __$RealmAuthoringCreationSlotCopyWithImpl<_RealmAuthoringCreationSlot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmAuthoringCreationSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.creates, creates) || other.creates == creates)&&(identical(other.context, context) || other.context == context)&&const DeepCollectionEquality().equals(other.concreteRoots, _concreteRoots));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,label,creates,context,const DeepCollectionEquality().hash(_concreteRoots));
}

@override
String toString() {
    return 'RealmAuthoringCreationSlot(id: $id, label: $label, creates: $creates, context: $context, concreteRoots: $concreteRoots)';
}


}

/// @nodoc
abstract mixin class _$RealmAuthoringCreationSlotCopyWith<$Res> implements $RealmAuthoringCreationSlotCopyWith<$Res> {
  factory _$RealmAuthoringCreationSlotCopyWith(_RealmAuthoringCreationSlot value, $Res Function(_RealmAuthoringCreationSlot) _then) = __$RealmAuthoringCreationSlotCopyWithImpl;
@override @useResult
$Res call({
 AuthoringCreationSlotId id, String label, ResourceDefinitionId creates, RealmAuthoringCreationContext context, List<ResolvedTypeRef> concreteRoots
});


@override $RealmAuthoringCreationContextCopyWith<$Res> get context;

}
/// @nodoc
class __$RealmAuthoringCreationSlotCopyWithImpl<$Res>
    implements _$RealmAuthoringCreationSlotCopyWith<$Res> {
  __$RealmAuthoringCreationSlotCopyWithImpl(this._self, this._then);

  final _RealmAuthoringCreationSlot _self;
  final $Res Function(_RealmAuthoringCreationSlot) _then;

/// Create a copy of RealmAuthoringCreationSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? creates = null,Object? context = null,Object? concreteRoots = null,}) {
  return _then(_RealmAuthoringCreationSlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as AuthoringCreationSlotId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,creates: null == creates ? _self.creates : creates // ignore: cast_nullable_to_non_nullable
as ResourceDefinitionId,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as RealmAuthoringCreationContext,concreteRoots: null == concreteRoots ? _self._concreteRoots : concreteRoots // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,
  ));
}

/// Create a copy of RealmAuthoringCreationSlot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmAuthoringCreationContextCopyWith<$Res> get context {

  return $RealmAuthoringCreationContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

/// @nodoc
mixin _$RealmEditorCatalogFetchResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogFetchResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmEditorCatalogFetchResult()';
}


}

/// @nodoc
class $RealmEditorCatalogFetchResultCopyWith<$Res>  {
$RealmEditorCatalogFetchResultCopyWith(RealmEditorCatalogFetchResult _, $Res Function(RealmEditorCatalogFetchResult) __);
}


/// Adds pattern-matching-related methods to [RealmEditorCatalogFetchResult].
extension RealmEditorCatalogFetchResultPatterns on RealmEditorCatalogFetchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RealmEditorCatalogFetched value)?  fetched,TResult Function( RealmEditorCatalogGenerationMismatch value)?  generationMismatch,TResult Function( RealmEditorCatalogFetchUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RealmEditorCatalogFetched() when fetched != null:
return fetched(_that);case RealmEditorCatalogGenerationMismatch() when generationMismatch != null:
return generationMismatch(_that);case RealmEditorCatalogFetchUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RealmEditorCatalogFetched value)  fetched,required TResult Function( RealmEditorCatalogGenerationMismatch value)  generationMismatch,required TResult Function( RealmEditorCatalogFetchUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case RealmEditorCatalogFetched():
return fetched(_that);case RealmEditorCatalogGenerationMismatch():
return generationMismatch(_that);case RealmEditorCatalogFetchUnavailable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RealmEditorCatalogFetched value)?  fetched,TResult? Function( RealmEditorCatalogGenerationMismatch value)?  generationMismatch,TResult? Function( RealmEditorCatalogFetchUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case RealmEditorCatalogFetched() when fetched != null:
return fetched(_that);case RealmEditorCatalogGenerationMismatch() when generationMismatch != null:
return generationMismatch(_that);case RealmEditorCatalogFetchUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( RealmEditorCatalogSnapshot snapshot)?  fetched,TResult Function( CatalogGeneration currentGeneration)?  generationMismatch,TResult Function( List<TypeDiagnostic> diagnostics)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RealmEditorCatalogFetched() when fetched != null:
return fetched(_that.snapshot);case RealmEditorCatalogGenerationMismatch() when generationMismatch != null:
return generationMismatch(_that.currentGeneration);case RealmEditorCatalogFetchUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( RealmEditorCatalogSnapshot snapshot)  fetched,required TResult Function( CatalogGeneration currentGeneration)  generationMismatch,required TResult Function( List<TypeDiagnostic> diagnostics)  unavailable,}) {final _that = this;
switch (_that) {
case RealmEditorCatalogFetched():
return fetched(_that.snapshot);case RealmEditorCatalogGenerationMismatch():
return generationMismatch(_that.currentGeneration);case RealmEditorCatalogFetchUnavailable():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( RealmEditorCatalogSnapshot snapshot)?  fetched,TResult? Function( CatalogGeneration currentGeneration)?  generationMismatch,TResult? Function( List<TypeDiagnostic> diagnostics)?  unavailable,}) {final _that = this;
switch (_that) {
case RealmEditorCatalogFetched() when fetched != null:
return fetched(_that.snapshot);case RealmEditorCatalogGenerationMismatch() when generationMismatch != null:
return generationMismatch(_that.currentGeneration);case RealmEditorCatalogFetchUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class RealmEditorCatalogFetched implements RealmEditorCatalogFetchResult {
  const RealmEditorCatalogFetched(this.snapshot);


 final  RealmEditorCatalogSnapshot snapshot;

/// Create a copy of RealmEditorCatalogFetchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogFetchedCopyWith<RealmEditorCatalogFetched> get copyWith => _$RealmEditorCatalogFetchedCopyWithImpl<RealmEditorCatalogFetched>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogFetched&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot));
}


@override
int get hashCode {
    return Object.hash(runtimeType,snapshot);
}

@override
String toString() {
    return 'RealmEditorCatalogFetchResult.fetched(snapshot: $snapshot)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogFetchedCopyWith<$Res> implements $RealmEditorCatalogFetchResultCopyWith<$Res> {
  factory $RealmEditorCatalogFetchedCopyWith(RealmEditorCatalogFetched value, $Res Function(RealmEditorCatalogFetched) _then) = _$RealmEditorCatalogFetchedCopyWithImpl;
@useResult
$Res call({
 RealmEditorCatalogSnapshot snapshot
});


$RealmEditorCatalogSnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class _$RealmEditorCatalogFetchedCopyWithImpl<$Res>
    implements $RealmEditorCatalogFetchedCopyWith<$Res> {
  _$RealmEditorCatalogFetchedCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogFetched _self;
  final $Res Function(RealmEditorCatalogFetched) _then;

/// Create a copy of RealmEditorCatalogFetchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? snapshot = null,}) {
  return _then(RealmEditorCatalogFetched(
null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as RealmEditorCatalogSnapshot,
  ));
}

/// Create a copy of RealmEditorCatalogFetchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmEditorCatalogSnapshotCopyWith<$Res> get snapshot {

  return $RealmEditorCatalogSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}

/// @nodoc


class RealmEditorCatalogGenerationMismatch implements RealmEditorCatalogFetchResult {
  const RealmEditorCatalogGenerationMismatch(this.currentGeneration);


 final  CatalogGeneration currentGeneration;

/// Create a copy of RealmEditorCatalogFetchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogGenerationMismatchCopyWith<RealmEditorCatalogGenerationMismatch> get copyWith => _$RealmEditorCatalogGenerationMismatchCopyWithImpl<RealmEditorCatalogGenerationMismatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogGenerationMismatch&&(identical(other.currentGeneration, currentGeneration) || other.currentGeneration == currentGeneration));
}


@override
int get hashCode {
    return Object.hash(runtimeType,currentGeneration);
}

@override
String toString() {
    return 'RealmEditorCatalogFetchResult.generationMismatch(currentGeneration: $currentGeneration)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogGenerationMismatchCopyWith<$Res> implements $RealmEditorCatalogFetchResultCopyWith<$Res> {
  factory $RealmEditorCatalogGenerationMismatchCopyWith(RealmEditorCatalogGenerationMismatch value, $Res Function(RealmEditorCatalogGenerationMismatch) _then) = _$RealmEditorCatalogGenerationMismatchCopyWithImpl;
@useResult
$Res call({
 CatalogGeneration currentGeneration
});


$CatalogGenerationCopyWith<$Res> get currentGeneration;

}
/// @nodoc
class _$RealmEditorCatalogGenerationMismatchCopyWithImpl<$Res>
    implements $RealmEditorCatalogGenerationMismatchCopyWith<$Res> {
  _$RealmEditorCatalogGenerationMismatchCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogGenerationMismatch _self;
  final $Res Function(RealmEditorCatalogGenerationMismatch) _then;

/// Create a copy of RealmEditorCatalogFetchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? currentGeneration = null,}) {
  return _then(RealmEditorCatalogGenerationMismatch(
null == currentGeneration ? _self.currentGeneration : currentGeneration // ignore: cast_nullable_to_non_nullable
as CatalogGeneration,
  ));
}

/// Create a copy of RealmEditorCatalogFetchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogGenerationCopyWith<$Res> get currentGeneration {

  return $CatalogGenerationCopyWith<$Res>(_self.currentGeneration, (value) {
    return _then(_self.copyWith(currentGeneration: value));
  });
}
}

/// @nodoc


class RealmEditorCatalogFetchUnavailable implements RealmEditorCatalogFetchResult {
  const RealmEditorCatalogFetchUnavailable( List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics;


 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of RealmEditorCatalogFetchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogFetchUnavailableCopyWith<RealmEditorCatalogFetchUnavailable> get copyWith => _$RealmEditorCatalogFetchUnavailableCopyWithImpl<RealmEditorCatalogFetchUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogFetchUnavailable&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'RealmEditorCatalogFetchResult.unavailable(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogFetchUnavailableCopyWith<$Res> implements $RealmEditorCatalogFetchResultCopyWith<$Res> {
  factory $RealmEditorCatalogFetchUnavailableCopyWith(RealmEditorCatalogFetchUnavailable value, $Res Function(RealmEditorCatalogFetchUnavailable) _then) = _$RealmEditorCatalogFetchUnavailableCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$RealmEditorCatalogFetchUnavailableCopyWithImpl<$Res>
    implements $RealmEditorCatalogFetchUnavailableCopyWith<$Res> {
  _$RealmEditorCatalogFetchUnavailableCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogFetchUnavailable _self;
  final $Res Function(RealmEditorCatalogFetchUnavailable) _then;

/// Create a copy of RealmEditorCatalogFetchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(RealmEditorCatalogFetchUnavailable(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$TypeInitializationRequirement {

 DataPath get path; TypeExpression get expected; TypeInitializationRequirementReason get reason;
/// Create a copy of TypeInitializationRequirement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeInitializationRequirementCopyWith<TypeInitializationRequirement> get copyWith => _$TypeInitializationRequirementCopyWithImpl<TypeInitializationRequirement>(this as TypeInitializationRequirement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TypeInitializationRequirement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeInitializationRequirement&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.expected, _this.expected) || other.expected == _this.expected)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}


@override
int get hashCode {
  final _this = this as TypeInitializationRequirement;
  return Object.hash(runtimeType,_this.path,_this.expected,_this.reason);
}

@override
String toString() {
  final _this = this as TypeInitializationRequirement;
  return 'TypeInitializationRequirement(path: ${_this.path}, expected: ${_this.expected}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $TypeInitializationRequirementCopyWith<$Res>  {
  factory $TypeInitializationRequirementCopyWith(TypeInitializationRequirement value, $Res Function(TypeInitializationRequirement) _then) = _$TypeInitializationRequirementCopyWithImpl;
@useResult
$Res call({
 DataPath path, TypeExpression expected, TypeInitializationRequirementReason reason
});


$DataPathCopyWith<$Res> get path;$TypeExpressionCopyWith<$Res> get expected;

}
/// @nodoc
class _$TypeInitializationRequirementCopyWithImpl<$Res>
    implements $TypeInitializationRequirementCopyWith<$Res> {
  _$TypeInitializationRequirementCopyWithImpl(this._self, this._then);

  final TypeInitializationRequirement _self;
  final $Res Function(TypeInitializationRequirement) _then;

/// Create a copy of TypeInitializationRequirement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? expected = null,Object? reason = null,}) {
  return _then(TypeInitializationRequirement(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as TypeExpression,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as TypeInitializationRequirementReason,
  ));
}
/// Create a copy of TypeInitializationRequirement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {

  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}/// Create a copy of TypeInitializationRequirement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get expected {

  return $TypeExpressionCopyWith<$Res>(_self.expected, (value) {
    return _then(_self.copyWith(expected: value));
  });
}
}


/// Adds pattern-matching-related methods to [TypeInitializationRequirement].
extension TypeInitializationRequirementPatterns on TypeInitializationRequirement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypeInitializationRequirement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypeInitializationRequirement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypeInitializationRequirement value)  $default,){
final _that = this;
switch (_that) {
case _TypeInitializationRequirement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypeInitializationRequirement value)?  $default,){
final _that = this;
switch (_that) {
case _TypeInitializationRequirement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DataPath path,  TypeExpression expected,  TypeInitializationRequirementReason reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypeInitializationRequirement() when $default != null:
return $default(_that.path,_that.expected,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DataPath path,  TypeExpression expected,  TypeInitializationRequirementReason reason)  $default,) {final _that = this;
switch (_that) {
case _TypeInitializationRequirement():
return $default(_that.path,_that.expected,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DataPath path,  TypeExpression expected,  TypeInitializationRequirementReason reason)?  $default,) {final _that = this;
switch (_that) {
case _TypeInitializationRequirement() when $default != null:
return $default(_that.path,_that.expected,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _TypeInitializationRequirement implements TypeInitializationRequirement {
  const _TypeInitializationRequirement({required this.path, required this.expected, required this.reason});


@override final  DataPath path;
@override final  TypeExpression expected;
@override final  TypeInitializationRequirementReason reason;

/// Create a copy of TypeInitializationRequirement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypeInitializationRequirementCopyWith<_TypeInitializationRequirement> get copyWith => __$TypeInitializationRequirementCopyWithImpl<_TypeInitializationRequirement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypeInitializationRequirement&&(identical(other.path, path) || other.path == path)&&(identical(other.expected, expected) || other.expected == expected)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,expected,reason);
}

@override
String toString() {
    return 'TypeInitializationRequirement(path: $path, expected: $expected, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$TypeInitializationRequirementCopyWith<$Res> implements $TypeInitializationRequirementCopyWith<$Res> {
  factory _$TypeInitializationRequirementCopyWith(_TypeInitializationRequirement value, $Res Function(_TypeInitializationRequirement) _then) = __$TypeInitializationRequirementCopyWithImpl;
@override @useResult
$Res call({
 DataPath path, TypeExpression expected, TypeInitializationRequirementReason reason
});


@override $DataPathCopyWith<$Res> get path;@override $TypeExpressionCopyWith<$Res> get expected;

}
/// @nodoc
class __$TypeInitializationRequirementCopyWithImpl<$Res>
    implements _$TypeInitializationRequirementCopyWith<$Res> {
  __$TypeInitializationRequirementCopyWithImpl(this._self, this._then);

  final _TypeInitializationRequirement _self;
  final $Res Function(_TypeInitializationRequirement) _then;

/// Create a copy of TypeInitializationRequirement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? expected = null,Object? reason = null,}) {
  return _then(_TypeInitializationRequirement(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as DataPath,expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as TypeExpression,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as TypeInitializationRequirementReason,
  ));
}

/// Create a copy of TypeInitializationRequirement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res> get path {

  return $DataPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}/// Create a copy of TypeInitializationRequirement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get expected {

  return $TypeExpressionCopyWith<$Res>(_self.expected, (value) {
    return _then(_self.copyWith(expected: value));
  });
}
}

/// @nodoc
mixin _$TypeInitializationDraft {

 ResolvedTypeRef get rootType; DataValue? get suppliedValue; List<TypeInitializationRequirement> get requirements;
/// Create a copy of TypeInitializationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeInitializationDraftCopyWith<TypeInitializationDraft> get copyWith => _$TypeInitializationDraftCopyWithImpl<TypeInitializationDraft>(this as TypeInitializationDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TypeInitializationDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeInitializationDraft&&(identical(other.rootType, _this.rootType) || other.rootType == _this.rootType)&&(identical(other.suppliedValue, _this.suppliedValue) || other.suppliedValue == _this.suppliedValue)&&const DeepCollectionEquality().equals(other.requirements, _this.requirements));
}


@override
int get hashCode {
  final _this = this as TypeInitializationDraft;
  return Object.hash(runtimeType,_this.rootType,_this.suppliedValue,const DeepCollectionEquality().hash(_this.requirements));
}

@override
String toString() {
  final _this = this as TypeInitializationDraft;
  return 'TypeInitializationDraft(rootType: ${_this.rootType}, suppliedValue: ${_this.suppliedValue}, requirements: ${_this.requirements})';
}


}

/// @nodoc
abstract mixin class $TypeInitializationDraftCopyWith<$Res>  {
  factory $TypeInitializationDraftCopyWith(TypeInitializationDraft value, $Res Function(TypeInitializationDraft) _then) = _$TypeInitializationDraftCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef rootType, DataValue? suppliedValue, List<TypeInitializationRequirement> requirements
});


$ResolvedTypeRefCopyWith<$Res> get rootType;$DataValueCopyWith<$Res>? get suppliedValue;

}
/// @nodoc
class _$TypeInitializationDraftCopyWithImpl<$Res>
    implements $TypeInitializationDraftCopyWith<$Res> {
  _$TypeInitializationDraftCopyWithImpl(this._self, this._then);

  final TypeInitializationDraft _self;
  final $Res Function(TypeInitializationDraft) _then;

/// Create a copy of TypeInitializationDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rootType = null,Object? suppliedValue = freezed,Object? requirements = null,}) {
  return _then(TypeInitializationDraft(
rootType: null == rootType ? _self.rootType : rootType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,suppliedValue: freezed == suppliedValue ? _self.suppliedValue : suppliedValue // ignore: cast_nullable_to_non_nullable
as DataValue?,requirements: null == requirements ? _self.requirements : requirements // ignore: cast_nullable_to_non_nullable
as List<TypeInitializationRequirement>,
  ));
}
/// Create a copy of TypeInitializationDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get rootType {

  return $ResolvedTypeRefCopyWith<$Res>(_self.rootType, (value) {
    return _then(_self.copyWith(rootType: value));
  });
}/// Create a copy of TypeInitializationDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res>? get suppliedValue {
    if (_self.suppliedValue == null) {
    return null;
  }

  return $DataValueCopyWith<$Res>(_self.suppliedValue!, (value) {
    return _then(_self.copyWith(suppliedValue: value));
  });
}
}


/// Adds pattern-matching-related methods to [TypeInitializationDraft].
extension TypeInitializationDraftPatterns on TypeInitializationDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypeInitializationDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypeInitializationDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypeInitializationDraft value)  $default,){
final _that = this;
switch (_that) {
case _TypeInitializationDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypeInitializationDraft value)?  $default,){
final _that = this;
switch (_that) {
case _TypeInitializationDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTypeRef rootType,  DataValue? suppliedValue,  List<TypeInitializationRequirement> requirements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypeInitializationDraft() when $default != null:
return $default(_that.rootType,_that.suppliedValue,_that.requirements);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTypeRef rootType,  DataValue? suppliedValue,  List<TypeInitializationRequirement> requirements)  $default,) {final _that = this;
switch (_that) {
case _TypeInitializationDraft():
return $default(_that.rootType,_that.suppliedValue,_that.requirements);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTypeRef rootType,  DataValue? suppliedValue,  List<TypeInitializationRequirement> requirements)?  $default,) {final _that = this;
switch (_that) {
case _TypeInitializationDraft() when $default != null:
return $default(_that.rootType,_that.suppliedValue,_that.requirements);case _:
  return null;

}
}

}

/// @nodoc


class _TypeInitializationDraft implements TypeInitializationDraft {
  const _TypeInitializationDraft({required this.rootType, required this.suppliedValue, required  List<TypeInitializationRequirement> requirements}): _requirements = requirements;


@override final  ResolvedTypeRef rootType;
@override final  DataValue? suppliedValue;
 final  List<TypeInitializationRequirement> _requirements;
@override List<TypeInitializationRequirement> get requirements {
  if (_requirements is EqualUnmodifiableListView) return _requirements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requirements);
}


/// Create a copy of TypeInitializationDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypeInitializationDraftCopyWith<_TypeInitializationDraft> get copyWith => __$TypeInitializationDraftCopyWithImpl<_TypeInitializationDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypeInitializationDraft&&(identical(other.rootType, rootType) || other.rootType == rootType)&&(identical(other.suppliedValue, suppliedValue) || other.suppliedValue == suppliedValue)&&const DeepCollectionEquality().equals(other.requirements, _requirements));
}


@override
int get hashCode {
    return Object.hash(runtimeType,rootType,suppliedValue,const DeepCollectionEquality().hash(_requirements));
}

@override
String toString() {
    return 'TypeInitializationDraft(rootType: $rootType, suppliedValue: $suppliedValue, requirements: $requirements)';
}


}

/// @nodoc
abstract mixin class _$TypeInitializationDraftCopyWith<$Res> implements $TypeInitializationDraftCopyWith<$Res> {
  factory _$TypeInitializationDraftCopyWith(_TypeInitializationDraft value, $Res Function(_TypeInitializationDraft) _then) = __$TypeInitializationDraftCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTypeRef rootType, DataValue? suppliedValue, List<TypeInitializationRequirement> requirements
});


@override $ResolvedTypeRefCopyWith<$Res> get rootType;@override $DataValueCopyWith<$Res>? get suppliedValue;

}
/// @nodoc
class __$TypeInitializationDraftCopyWithImpl<$Res>
    implements _$TypeInitializationDraftCopyWith<$Res> {
  __$TypeInitializationDraftCopyWithImpl(this._self, this._then);

  final _TypeInitializationDraft _self;
  final $Res Function(_TypeInitializationDraft) _then;

/// Create a copy of TypeInitializationDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rootType = null,Object? suppliedValue = freezed,Object? requirements = null,}) {
  return _then(_TypeInitializationDraft(
rootType: null == rootType ? _self.rootType : rootType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,suppliedValue: freezed == suppliedValue ? _self.suppliedValue : suppliedValue // ignore: cast_nullable_to_non_nullable
as DataValue?,requirements: null == requirements ? _self._requirements : requirements // ignore: cast_nullable_to_non_nullable
as List<TypeInitializationRequirement>,
  ));
}

/// Create a copy of TypeInitializationDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get rootType {

  return $ResolvedTypeRefCopyWith<$Res>(_self.rootType, (value) {
    return _then(_self.copyWith(rootType: value));
  });
}/// Create a copy of TypeInitializationDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res>? get suppliedValue {
    if (_self.suppliedValue == null) {
    return null;
  }

  return $DataValueCopyWith<$Res>(_self.suppliedValue!, (value) {
    return _then(_self.copyWith(suppliedValue: value));
  });
}
}

/// @nodoc
mixin _$RealmTypedValueInitializationResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmTypedValueInitializationResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmTypedValueInitializationResult()';
}


}

/// @nodoc
class $RealmTypedValueInitializationResultCopyWith<$Res>  {
$RealmTypedValueInitializationResultCopyWith(RealmTypedValueInitializationResult _, $Res Function(RealmTypedValueInitializationResult) __);
}


/// Adds pattern-matching-related methods to [RealmTypedValueInitializationResult].
extension RealmTypedValueInitializationResultPatterns on RealmTypedValueInitializationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RealmTypedValueInitialized value)?  initialized,TResult Function( RealmTypedValueInitializationNeedsInput value)?  needsInput,TResult Function( RealmTypedValueInitializationRejected value)?  rejected,TResult Function( RealmTypedValueInitializationGenerationMismatch value)?  generationMismatch,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RealmTypedValueInitialized() when initialized != null:
return initialized(_that);case RealmTypedValueInitializationNeedsInput() when needsInput != null:
return needsInput(_that);case RealmTypedValueInitializationRejected() when rejected != null:
return rejected(_that);case RealmTypedValueInitializationGenerationMismatch() when generationMismatch != null:
return generationMismatch(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RealmTypedValueInitialized value)  initialized,required TResult Function( RealmTypedValueInitializationNeedsInput value)  needsInput,required TResult Function( RealmTypedValueInitializationRejected value)  rejected,required TResult Function( RealmTypedValueInitializationGenerationMismatch value)  generationMismatch,}){
final _that = this;
switch (_that) {
case RealmTypedValueInitialized():
return initialized(_that);case RealmTypedValueInitializationNeedsInput():
return needsInput(_that);case RealmTypedValueInitializationRejected():
return rejected(_that);case RealmTypedValueInitializationGenerationMismatch():
return generationMismatch(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RealmTypedValueInitialized value)?  initialized,TResult? Function( RealmTypedValueInitializationNeedsInput value)?  needsInput,TResult? Function( RealmTypedValueInitializationRejected value)?  rejected,TResult? Function( RealmTypedValueInitializationGenerationMismatch value)?  generationMismatch,}){
final _that = this;
switch (_that) {
case RealmTypedValueInitialized() when initialized != null:
return initialized(_that);case RealmTypedValueInitializationNeedsInput() when needsInput != null:
return needsInput(_that);case RealmTypedValueInitializationRejected() when rejected != null:
return rejected(_that);case RealmTypedValueInitializationGenerationMismatch() when generationMismatch != null:
return generationMismatch(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TypedValueEnvelope value)?  initialized,TResult Function( TypeInitializationDraft draft)?  needsInput,TResult Function( List<TypeDiagnostic> diagnostics)?  rejected,TResult Function( CatalogGeneration generation)?  generationMismatch,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RealmTypedValueInitialized() when initialized != null:
return initialized(_that.value);case RealmTypedValueInitializationNeedsInput() when needsInput != null:
return needsInput(_that.draft);case RealmTypedValueInitializationRejected() when rejected != null:
return rejected(_that.diagnostics);case RealmTypedValueInitializationGenerationMismatch() when generationMismatch != null:
return generationMismatch(_that.generation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TypedValueEnvelope value)  initialized,required TResult Function( TypeInitializationDraft draft)  needsInput,required TResult Function( List<TypeDiagnostic> diagnostics)  rejected,required TResult Function( CatalogGeneration generation)  generationMismatch,}) {final _that = this;
switch (_that) {
case RealmTypedValueInitialized():
return initialized(_that.value);case RealmTypedValueInitializationNeedsInput():
return needsInput(_that.draft);case RealmTypedValueInitializationRejected():
return rejected(_that.diagnostics);case RealmTypedValueInitializationGenerationMismatch():
return generationMismatch(_that.generation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TypedValueEnvelope value)?  initialized,TResult? Function( TypeInitializationDraft draft)?  needsInput,TResult? Function( List<TypeDiagnostic> diagnostics)?  rejected,TResult? Function( CatalogGeneration generation)?  generationMismatch,}) {final _that = this;
switch (_that) {
case RealmTypedValueInitialized() when initialized != null:
return initialized(_that.value);case RealmTypedValueInitializationNeedsInput() when needsInput != null:
return needsInput(_that.draft);case RealmTypedValueInitializationRejected() when rejected != null:
return rejected(_that.diagnostics);case RealmTypedValueInitializationGenerationMismatch() when generationMismatch != null:
return generationMismatch(_that.generation);case _:
  return null;

}
}

}

/// @nodoc


class RealmTypedValueInitialized implements RealmTypedValueInitializationResult {
  const RealmTypedValueInitialized(this.value);


 final  TypedValueEnvelope value;

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmTypedValueInitializedCopyWith<RealmTypedValueInitialized> get copyWith => _$RealmTypedValueInitializedCopyWithImpl<RealmTypedValueInitialized>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmTypedValueInitialized&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString() {
    return 'RealmTypedValueInitializationResult.initialized(value: $value)';
}


}

/// @nodoc
abstract mixin class $RealmTypedValueInitializedCopyWith<$Res> implements $RealmTypedValueInitializationResultCopyWith<$Res> {
  factory $RealmTypedValueInitializedCopyWith(RealmTypedValueInitialized value, $Res Function(RealmTypedValueInitialized) _then) = _$RealmTypedValueInitializedCopyWithImpl;
@useResult
$Res call({
 TypedValueEnvelope value
});


$TypedValueEnvelopeCopyWith<$Res> get value;

}
/// @nodoc
class _$RealmTypedValueInitializedCopyWithImpl<$Res>
    implements $RealmTypedValueInitializedCopyWith<$Res> {
  _$RealmTypedValueInitializedCopyWithImpl(this._self, this._then);

  final RealmTypedValueInitialized _self;
  final $Res Function(RealmTypedValueInitialized) _then;

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(RealmTypedValueInitialized(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TypedValueEnvelope,
  ));
}

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypedValueEnvelopeCopyWith<$Res> get value {

  return $TypedValueEnvelopeCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class RealmTypedValueInitializationNeedsInput implements RealmTypedValueInitializationResult {
  const RealmTypedValueInitializationNeedsInput(this.draft);


 final  TypeInitializationDraft draft;

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmTypedValueInitializationNeedsInputCopyWith<RealmTypedValueInitializationNeedsInput> get copyWith => _$RealmTypedValueInitializationNeedsInputCopyWithImpl<RealmTypedValueInitializationNeedsInput>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmTypedValueInitializationNeedsInput&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode {
    return Object.hash(runtimeType,draft);
}

@override
String toString() {
    return 'RealmTypedValueInitializationResult.needsInput(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $RealmTypedValueInitializationNeedsInputCopyWith<$Res> implements $RealmTypedValueInitializationResultCopyWith<$Res> {
  factory $RealmTypedValueInitializationNeedsInputCopyWith(RealmTypedValueInitializationNeedsInput value, $Res Function(RealmTypedValueInitializationNeedsInput) _then) = _$RealmTypedValueInitializationNeedsInputCopyWithImpl;
@useResult
$Res call({
 TypeInitializationDraft draft
});


$TypeInitializationDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$RealmTypedValueInitializationNeedsInputCopyWithImpl<$Res>
    implements $RealmTypedValueInitializationNeedsInputCopyWith<$Res> {
  _$RealmTypedValueInitializationNeedsInputCopyWithImpl(this._self, this._then);

  final RealmTypedValueInitializationNeedsInput _self;
  final $Res Function(RealmTypedValueInitializationNeedsInput) _then;

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(RealmTypedValueInitializationNeedsInput(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as TypeInitializationDraft,
  ));
}

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeInitializationDraftCopyWith<$Res> get draft {

  return $TypeInitializationDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class RealmTypedValueInitializationRejected implements RealmTypedValueInitializationResult {
  const RealmTypedValueInitializationRejected( List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics;


 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmTypedValueInitializationRejectedCopyWith<RealmTypedValueInitializationRejected> get copyWith => _$RealmTypedValueInitializationRejectedCopyWithImpl<RealmTypedValueInitializationRejected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmTypedValueInitializationRejected&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'RealmTypedValueInitializationResult.rejected(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $RealmTypedValueInitializationRejectedCopyWith<$Res> implements $RealmTypedValueInitializationResultCopyWith<$Res> {
  factory $RealmTypedValueInitializationRejectedCopyWith(RealmTypedValueInitializationRejected value, $Res Function(RealmTypedValueInitializationRejected) _then) = _$RealmTypedValueInitializationRejectedCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$RealmTypedValueInitializationRejectedCopyWithImpl<$Res>
    implements $RealmTypedValueInitializationRejectedCopyWith<$Res> {
  _$RealmTypedValueInitializationRejectedCopyWithImpl(this._self, this._then);

  final RealmTypedValueInitializationRejected _self;
  final $Res Function(RealmTypedValueInitializationRejected) _then;

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(RealmTypedValueInitializationRejected(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

/// @nodoc


class RealmTypedValueInitializationGenerationMismatch implements RealmTypedValueInitializationResult {
  const RealmTypedValueInitializationGenerationMismatch(this.generation);


 final  CatalogGeneration generation;

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmTypedValueInitializationGenerationMismatchCopyWith<RealmTypedValueInitializationGenerationMismatch> get copyWith => _$RealmTypedValueInitializationGenerationMismatchCopyWithImpl<RealmTypedValueInitializationGenerationMismatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmTypedValueInitializationGenerationMismatch&&(identical(other.generation, generation) || other.generation == generation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,generation);
}

@override
String toString() {
    return 'RealmTypedValueInitializationResult.generationMismatch(generation: $generation)';
}


}

/// @nodoc
abstract mixin class $RealmTypedValueInitializationGenerationMismatchCopyWith<$Res> implements $RealmTypedValueInitializationResultCopyWith<$Res> {
  factory $RealmTypedValueInitializationGenerationMismatchCopyWith(RealmTypedValueInitializationGenerationMismatch value, $Res Function(RealmTypedValueInitializationGenerationMismatch) _then) = _$RealmTypedValueInitializationGenerationMismatchCopyWithImpl;
@useResult
$Res call({
 CatalogGeneration generation
});


$CatalogGenerationCopyWith<$Res> get generation;

}
/// @nodoc
class _$RealmTypedValueInitializationGenerationMismatchCopyWithImpl<$Res>
    implements $RealmTypedValueInitializationGenerationMismatchCopyWith<$Res> {
  _$RealmTypedValueInitializationGenerationMismatchCopyWithImpl(this._self, this._then);

  final RealmTypedValueInitializationGenerationMismatch _self;
  final $Res Function(RealmTypedValueInitializationGenerationMismatch) _then;

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? generation = null,}) {
  return _then(RealmTypedValueInitializationGenerationMismatch(
null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as CatalogGeneration,
  ));
}

/// Create a copy of RealmTypedValueInitializationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogGenerationCopyWith<$Res> get generation {

  return $CatalogGenerationCopyWith<$Res>(_self.generation, (value) {
    return _then(_self.copyWith(generation: value));
  });
}
}

/// @nodoc
mixin _$RealmEditorCatalogWatchEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogWatchEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmEditorCatalogWatchEvent()';
}


}

/// @nodoc
class $RealmEditorCatalogWatchEventCopyWith<$Res>  {
$RealmEditorCatalogWatchEventCopyWith(RealmEditorCatalogWatchEvent _, $Res Function(RealmEditorCatalogWatchEvent) __);
}


/// Adds pattern-matching-related methods to [RealmEditorCatalogWatchEvent].
extension RealmEditorCatalogWatchEventPatterns on RealmEditorCatalogWatchEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RealmEditorCatalogInvalidated value)?  invalidated,TResult Function( RealmEditorCatalogWatchUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RealmEditorCatalogInvalidated() when invalidated != null:
return invalidated(_that);case RealmEditorCatalogWatchUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RealmEditorCatalogInvalidated value)  invalidated,required TResult Function( RealmEditorCatalogWatchUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case RealmEditorCatalogInvalidated():
return invalidated(_that);case RealmEditorCatalogWatchUnavailable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RealmEditorCatalogInvalidated value)?  invalidated,TResult? Function( RealmEditorCatalogWatchUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case RealmEditorCatalogInvalidated() when invalidated != null:
return invalidated(_that);case RealmEditorCatalogWatchUnavailable() when unavailable != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CatalogGeneration generation)?  invalidated,TResult Function( List<TypeDiagnostic> diagnostics)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RealmEditorCatalogInvalidated() when invalidated != null:
return invalidated(_that.generation);case RealmEditorCatalogWatchUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CatalogGeneration generation)  invalidated,required TResult Function( List<TypeDiagnostic> diagnostics)  unavailable,}) {final _that = this;
switch (_that) {
case RealmEditorCatalogInvalidated():
return invalidated(_that.generation);case RealmEditorCatalogWatchUnavailable():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CatalogGeneration generation)?  invalidated,TResult? Function( List<TypeDiagnostic> diagnostics)?  unavailable,}) {final _that = this;
switch (_that) {
case RealmEditorCatalogInvalidated() when invalidated != null:
return invalidated(_that.generation);case RealmEditorCatalogWatchUnavailable() when unavailable != null:
return unavailable(_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class RealmEditorCatalogInvalidated implements RealmEditorCatalogWatchEvent {
  const RealmEditorCatalogInvalidated(this.generation);


 final  CatalogGeneration generation;

/// Create a copy of RealmEditorCatalogWatchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogInvalidatedCopyWith<RealmEditorCatalogInvalidated> get copyWith => _$RealmEditorCatalogInvalidatedCopyWithImpl<RealmEditorCatalogInvalidated>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogInvalidated&&(identical(other.generation, generation) || other.generation == generation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,generation);
}

@override
String toString() {
    return 'RealmEditorCatalogWatchEvent.invalidated(generation: $generation)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogInvalidatedCopyWith<$Res> implements $RealmEditorCatalogWatchEventCopyWith<$Res> {
  factory $RealmEditorCatalogInvalidatedCopyWith(RealmEditorCatalogInvalidated value, $Res Function(RealmEditorCatalogInvalidated) _then) = _$RealmEditorCatalogInvalidatedCopyWithImpl;
@useResult
$Res call({
 CatalogGeneration generation
});


$CatalogGenerationCopyWith<$Res> get generation;

}
/// @nodoc
class _$RealmEditorCatalogInvalidatedCopyWithImpl<$Res>
    implements $RealmEditorCatalogInvalidatedCopyWith<$Res> {
  _$RealmEditorCatalogInvalidatedCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogInvalidated _self;
  final $Res Function(RealmEditorCatalogInvalidated) _then;

/// Create a copy of RealmEditorCatalogWatchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? generation = null,}) {
  return _then(RealmEditorCatalogInvalidated(
null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as CatalogGeneration,
  ));
}

/// Create a copy of RealmEditorCatalogWatchEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogGenerationCopyWith<$Res> get generation {

  return $CatalogGenerationCopyWith<$Res>(_self.generation, (value) {
    return _then(_self.copyWith(generation: value));
  });
}
}

/// @nodoc


class RealmEditorCatalogWatchUnavailable implements RealmEditorCatalogWatchEvent {
  const RealmEditorCatalogWatchUnavailable( List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics;


 final  List<TypeDiagnostic> _diagnostics;
 List<TypeDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of RealmEditorCatalogWatchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogWatchUnavailableCopyWith<RealmEditorCatalogWatchUnavailable> get copyWith => _$RealmEditorCatalogWatchUnavailableCopyWithImpl<RealmEditorCatalogWatchUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogWatchUnavailable&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'RealmEditorCatalogWatchEvent.unavailable(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogWatchUnavailableCopyWith<$Res> implements $RealmEditorCatalogWatchEventCopyWith<$Res> {
  factory $RealmEditorCatalogWatchUnavailableCopyWith(RealmEditorCatalogWatchUnavailable value, $Res Function(RealmEditorCatalogWatchUnavailable) _then) = _$RealmEditorCatalogWatchUnavailableCopyWithImpl;
@useResult
$Res call({
 List<TypeDiagnostic> diagnostics
});




}
/// @nodoc
class _$RealmEditorCatalogWatchUnavailableCopyWithImpl<$Res>
    implements $RealmEditorCatalogWatchUnavailableCopyWith<$Res> {
  _$RealmEditorCatalogWatchUnavailableCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogWatchUnavailable _self;
  final $Res Function(RealmEditorCatalogWatchUnavailable) _then;

/// Create a copy of RealmEditorCatalogWatchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(RealmEditorCatalogWatchUnavailable(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,
  ));
}


}

// dart format on
