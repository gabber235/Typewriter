// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_editor_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogRoute&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.realmId, realmId) || other.realmId == realmId));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId,realmId);

@override
String toString() {
  return 'RealmEditorCatalogRoute(organizationId: $organizationId, realmId: $realmId)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,organizationId,realmId);

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

 TypeCatalog get catalog; CatalogGeneration get generation; Map<PresentationId, PresentationDefinition> get presentations; Map<ConversionId, ConversionDefinition> get conversions; Map<CapabilityId, CapabilityDefinition> get capabilities; Map<String, RealmEditorSubtypeResult> get subtypeResults; List<TypeDiagnostic> get diagnostics; Map<String, RealmElementCatalogEntry> get elements;
/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmEditorCatalogSnapshotCopyWith<RealmEditorCatalogSnapshot> get copyWith => _$RealmEditorCatalogSnapshotCopyWithImpl<RealmEditorCatalogSnapshot>(this as RealmEditorCatalogSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogSnapshot&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.generation, generation) || other.generation == generation)&&const DeepCollectionEquality().equals(other.presentations, presentations)&&const DeepCollectionEquality().equals(other.conversions, conversions)&&const DeepCollectionEquality().equals(other.capabilities, capabilities)&&const DeepCollectionEquality().equals(other.subtypeResults, subtypeResults)&&const DeepCollectionEquality().equals(other.diagnostics, diagnostics)&&const DeepCollectionEquality().equals(other.elements, elements));
}


@override
int get hashCode => Object.hash(runtimeType,catalog,generation,const DeepCollectionEquality().hash(presentations),const DeepCollectionEquality().hash(conversions),const DeepCollectionEquality().hash(capabilities),const DeepCollectionEquality().hash(subtypeResults),const DeepCollectionEquality().hash(diagnostics),const DeepCollectionEquality().hash(elements));

@override
String toString() {
  return 'RealmEditorCatalogSnapshot(catalog: $catalog, generation: $generation, presentations: $presentations, conversions: $conversions, capabilities: $capabilities, subtypeResults: $subtypeResults, diagnostics: $diagnostics, elements: $elements)';
}


}

/// @nodoc
abstract mixin class $RealmEditorCatalogSnapshotCopyWith<$Res>  {
  factory $RealmEditorCatalogSnapshotCopyWith(RealmEditorCatalogSnapshot value, $Res Function(RealmEditorCatalogSnapshot) _then) = _$RealmEditorCatalogSnapshotCopyWithImpl;
@useResult
$Res call({
 TypeCatalog catalog, CatalogGeneration generation, Map<PresentationId, PresentationDefinition> presentations, Map<ConversionId, ConversionDefinition> conversions, Map<CapabilityId, CapabilityDefinition> capabilities, Map<String, RealmEditorSubtypeResult> subtypeResults, List<TypeDiagnostic> diagnostics, Map<String, RealmElementCatalogEntry> elements
});


$TypeCatalogCopyWith<$Res> get catalog;$CatalogGenerationCopyWith<$Res> get generation;

}
/// @nodoc
class _$RealmEditorCatalogSnapshotCopyWithImpl<$Res>
    implements $RealmEditorCatalogSnapshotCopyWith<$Res> {
  _$RealmEditorCatalogSnapshotCopyWithImpl(this._self, this._then);

  final RealmEditorCatalogSnapshot _self;
  final $Res Function(RealmEditorCatalogSnapshot) _then;

/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,Object? generation = null,Object? presentations = null,Object? conversions = null,Object? capabilities = null,Object? subtypeResults = null,Object? diagnostics = null,Object? elements = null,}) {
  return _then(_self.copyWith(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as TypeCatalog,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as CatalogGeneration,presentations: null == presentations ? _self.presentations : presentations // ignore: cast_nullable_to_non_nullable
as Map<PresentationId, PresentationDefinition>,conversions: null == conversions ? _self.conversions : conversions // ignore: cast_nullable_to_non_nullable
as Map<ConversionId, ConversionDefinition>,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as Map<CapabilityId, CapabilityDefinition>,subtypeResults: null == subtypeResults ? _self.subtypeResults : subtypeResults // ignore: cast_nullable_to_non_nullable
as Map<String, RealmEditorSubtypeResult>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,elements: null == elements ? _self.elements : elements // ignore: cast_nullable_to_non_nullable
as Map<String, RealmElementCatalogEntry>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeCatalog catalog,  CatalogGeneration generation,  Map<PresentationId, PresentationDefinition> presentations,  Map<ConversionId, ConversionDefinition> conversions,  Map<CapabilityId, CapabilityDefinition> capabilities,  Map<String, RealmEditorSubtypeResult> subtypeResults,  List<TypeDiagnostic> diagnostics,  Map<String, RealmElementCatalogEntry> elements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmEditorCatalogSnapshot() when $default != null:
return $default(_that.catalog,_that.generation,_that.presentations,_that.conversions,_that.capabilities,_that.subtypeResults,_that.diagnostics,_that.elements);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeCatalog catalog,  CatalogGeneration generation,  Map<PresentationId, PresentationDefinition> presentations,  Map<ConversionId, ConversionDefinition> conversions,  Map<CapabilityId, CapabilityDefinition> capabilities,  Map<String, RealmEditorSubtypeResult> subtypeResults,  List<TypeDiagnostic> diagnostics,  Map<String, RealmElementCatalogEntry> elements)  $default,) {final _that = this;
switch (_that) {
case _RealmEditorCatalogSnapshot():
return $default(_that.catalog,_that.generation,_that.presentations,_that.conversions,_that.capabilities,_that.subtypeResults,_that.diagnostics,_that.elements);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeCatalog catalog,  CatalogGeneration generation,  Map<PresentationId, PresentationDefinition> presentations,  Map<ConversionId, ConversionDefinition> conversions,  Map<CapabilityId, CapabilityDefinition> capabilities,  Map<String, RealmEditorSubtypeResult> subtypeResults,  List<TypeDiagnostic> diagnostics,  Map<String, RealmElementCatalogEntry> elements)?  $default,) {final _that = this;
switch (_that) {
case _RealmEditorCatalogSnapshot() when $default != null:
return $default(_that.catalog,_that.generation,_that.presentations,_that.conversions,_that.capabilities,_that.subtypeResults,_that.diagnostics,_that.elements);case _:
  return null;

}
}

}

/// @nodoc


class _RealmEditorCatalogSnapshot extends RealmEditorCatalogSnapshot {
  const _RealmEditorCatalogSnapshot({required this.catalog, required this.generation, final  Map<PresentationId, PresentationDefinition> presentations = const {}, final  Map<ConversionId, ConversionDefinition> conversions = const {}, final  Map<CapabilityId, CapabilityDefinition> capabilities = const {}, final  Map<String, RealmEditorSubtypeResult> subtypeResults = const {}, final  List<TypeDiagnostic> diagnostics = const [], final  Map<String, RealmElementCatalogEntry> elements = const {}}): _presentations = presentations,_conversions = conversions,_capabilities = capabilities,_subtypeResults = subtypeResults,_diagnostics = diagnostics,_elements = elements,super._();
  

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


/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmEditorCatalogSnapshotCopyWith<_RealmEditorCatalogSnapshot> get copyWith => __$RealmEditorCatalogSnapshotCopyWithImpl<_RealmEditorCatalogSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmEditorCatalogSnapshot&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.generation, generation) || other.generation == generation)&&const DeepCollectionEquality().equals(other._presentations, _presentations)&&const DeepCollectionEquality().equals(other._conversions, _conversions)&&const DeepCollectionEquality().equals(other._capabilities, _capabilities)&&const DeepCollectionEquality().equals(other._subtypeResults, _subtypeResults)&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics)&&const DeepCollectionEquality().equals(other._elements, _elements));
}


@override
int get hashCode => Object.hash(runtimeType,catalog,generation,const DeepCollectionEquality().hash(_presentations),const DeepCollectionEquality().hash(_conversions),const DeepCollectionEquality().hash(_capabilities),const DeepCollectionEquality().hash(_subtypeResults),const DeepCollectionEquality().hash(_diagnostics),const DeepCollectionEquality().hash(_elements));

@override
String toString() {
  return 'RealmEditorCatalogSnapshot(catalog: $catalog, generation: $generation, presentations: $presentations, conversions: $conversions, capabilities: $capabilities, subtypeResults: $subtypeResults, diagnostics: $diagnostics, elements: $elements)';
}


}

/// @nodoc
abstract mixin class _$RealmEditorCatalogSnapshotCopyWith<$Res> implements $RealmEditorCatalogSnapshotCopyWith<$Res> {
  factory _$RealmEditorCatalogSnapshotCopyWith(_RealmEditorCatalogSnapshot value, $Res Function(_RealmEditorCatalogSnapshot) _then) = __$RealmEditorCatalogSnapshotCopyWithImpl;
@override @useResult
$Res call({
 TypeCatalog catalog, CatalogGeneration generation, Map<PresentationId, PresentationDefinition> presentations, Map<ConversionId, ConversionDefinition> conversions, Map<CapabilityId, CapabilityDefinition> capabilities, Map<String, RealmEditorSubtypeResult> subtypeResults, List<TypeDiagnostic> diagnostics, Map<String, RealmElementCatalogEntry> elements
});


@override $TypeCatalogCopyWith<$Res> get catalog;@override $CatalogGenerationCopyWith<$Res> get generation;

}
/// @nodoc
class __$RealmEditorCatalogSnapshotCopyWithImpl<$Res>
    implements _$RealmEditorCatalogSnapshotCopyWith<$Res> {
  __$RealmEditorCatalogSnapshotCopyWithImpl(this._self, this._then);

  final _RealmEditorCatalogSnapshot _self;
  final $Res Function(_RealmEditorCatalogSnapshot) _then;

/// Create a copy of RealmEditorCatalogSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,Object? generation = null,Object? presentations = null,Object? conversions = null,Object? capabilities = null,Object? subtypeResults = null,Object? diagnostics = null,Object? elements = null,}) {
  return _then(_RealmEditorCatalogSnapshot(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as TypeCatalog,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as CatalogGeneration,presentations: null == presentations ? _self._presentations : presentations // ignore: cast_nullable_to_non_nullable
as Map<PresentationId, PresentationDefinition>,conversions: null == conversions ? _self._conversions : conversions // ignore: cast_nullable_to_non_nullable
as Map<ConversionId, ConversionDefinition>,capabilities: null == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as Map<CapabilityId, CapabilityDefinition>,subtypeResults: null == subtypeResults ? _self._subtypeResults : subtypeResults // ignore: cast_nullable_to_non_nullable
as Map<String, RealmEditorSubtypeResult>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<TypeDiagnostic>,elements: null == elements ? _self._elements : elements // ignore: cast_nullable_to_non_nullable
as Map<String, RealmElementCatalogEntry>,
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
int get hashCode => Object.hash(runtimeType,snapshot);

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
int get hashCode => Object.hash(runtimeType,currentGeneration);

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
  const RealmEditorCatalogFetchUnavailable(final  List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics;
  

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogFetchUnavailable&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

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
int get hashCode => Object.hash(runtimeType,generation);

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
  const RealmEditorCatalogWatchUnavailable(final  List<TypeDiagnostic> diagnostics): _diagnostics = diagnostics;
  

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorCatalogWatchUnavailable&&const DeepCollectionEquality().equals(other._diagnostics, _diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));

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
