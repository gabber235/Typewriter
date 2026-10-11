// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_presentation_renderer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortablePresentationScope {

 Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings; skir.EvaluationBudget get budget; bool get readOnly; bool get enabled; Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? get watchSearch; ValueChanged<String>? get reportStatus; Future<void> Function()? get commit; CheckedEditorCatalog? get catalog; skir.ResourceId? get resource; String? get searchHistoryNamespace; ValueChanged<skir.ResourceId>? get openResource; skir.PresentationRole? get role; skir.PresentationMaterial? get material; Set<skir.PresentationId> get activePresentations; Map<String, skir.PresentationNode> get slots; Map<String, PortableSlotBuilder> get slotBuilders; PortablePresentationHost? get host; Map<skir.ExpressionBindingId, PortableBindingSetter> get projectedWriters;
/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<PortablePresentationScope> get copyWith => _$PortablePresentationScopeCopyWithImpl<PortablePresentationScope>(this as PortablePresentationScope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationScope&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&(identical(other.readOnly, _this.readOnly) || other.readOnly == _this.readOnly)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.watchSearch, _this.watchSearch) || other.watchSearch == _this.watchSearch)&&(identical(other.reportStatus, _this.reportStatus) || other.reportStatus == _this.reportStatus)&&(identical(other.commit, _this.commit) || other.commit == _this.commit)&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.searchHistoryNamespace, _this.searchHistoryNamespace) || other.searchHistoryNamespace == _this.searchHistoryNamespace)&&(identical(other.openResource, _this.openResource) || other.openResource == _this.openResource)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.material, _this.material) || other.material == _this.material)&&const DeepCollectionEquality().equals(other.activePresentations, _this.activePresentations)&&const DeepCollectionEquality().equals(other.slots, _this.slots)&&const DeepCollectionEquality().equals(other.slotBuilders, _this.slotBuilders)&&(identical(other.host, _this.host) || other.host == _this.host)&&const DeepCollectionEquality().equals(other.projectedWriters, _this.projectedWriters));
}


@override
int get hashCode {
  final _this = this as PortablePresentationScope;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.bindings),_this.budget,_this.readOnly,_this.enabled,_this.watchSearch,_this.reportStatus,_this.commit,_this.catalog,_this.resource,_this.searchHistoryNamespace,_this.openResource,_this.role,_this.material,const DeepCollectionEquality().hash(_this.activePresentations),const DeepCollectionEquality().hash(_this.slots),const DeepCollectionEquality().hash(_this.slotBuilders),_this.host,const DeepCollectionEquality().hash(_this.projectedWriters));
}

@override
String toString() {
  final _this = this as PortablePresentationScope;
  return 'PortablePresentationScope(bindings: ${_this.bindings}, budget: ${_this.budget}, readOnly: ${_this.readOnly}, enabled: ${_this.enabled}, watchSearch: ${_this.watchSearch}, reportStatus: ${_this.reportStatus}, commit: ${_this.commit}, catalog: ${_this.catalog}, resource: ${_this.resource}, searchHistoryNamespace: ${_this.searchHistoryNamespace}, openResource: ${_this.openResource}, role: ${_this.role}, material: ${_this.material}, activePresentations: ${_this.activePresentations}, slots: ${_this.slots}, slotBuilders: ${_this.slotBuilders}, host: ${_this.host}, projectedWriters: ${_this.projectedWriters})';
}


}

/// @nodoc
abstract mixin class $PortablePresentationScopeCopyWith<$Res>  {
  factory $PortablePresentationScopeCopyWith(PortablePresentationScope value, $Res Function(PortablePresentationScope) _then) = _$PortablePresentationScopeCopyWithImpl;
@useResult
$Res call({
 Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, bool readOnly, bool enabled, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, ValueChanged<String>? reportStatus, Future<void> Function()? commit, CheckedEditorCatalog? catalog, skir.ResourceId? resource, String? searchHistoryNamespace, ValueChanged<skir.ResourceId>? openResource, skir.PresentationRole? role, skir.PresentationMaterial? material, Set<skir.PresentationId> activePresentations, Map<String, skir.PresentationNode> slots, Map<String, PortableSlotBuilder> slotBuilders, PortablePresentationHost? host, Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters
});




}
/// @nodoc
class _$PortablePresentationScopeCopyWithImpl<$Res>
    implements $PortablePresentationScopeCopyWith<$Res> {
  _$PortablePresentationScopeCopyWithImpl(this._self, this._then);

  final PortablePresentationScope _self;
  final $Res Function(PortablePresentationScope) _then;

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bindings = null,Object? budget = null,Object? readOnly = null,Object? enabled = null,Object? watchSearch = freezed,Object? reportStatus = freezed,Object? commit = freezed,Object? catalog = freezed,Object? resource = freezed,Object? searchHistoryNamespace = freezed,Object? openResource = freezed,Object? role = freezed,Object? material = freezed,Object? activePresentations = null,Object? slots = null,Object? slotBuilders = null,Object? host = freezed,Object? projectedWriters = null,}) {
  return _then(PortablePresentationScope(
bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reportStatus: freezed == reportStatus ? _self.reportStatus : reportStatus // ignore: cast_nullable_to_non_nullable
as ValueChanged<String>?,commit: freezed == commit ? _self.commit : commit // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,resource: freezed == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,searchHistoryNamespace: freezed == searchHistoryNamespace ? _self.searchHistoryNamespace : searchHistoryNamespace // ignore: cast_nullable_to_non_nullable
as String?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial?,activePresentations: null == activePresentations ? _self.activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationId>,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,slotBuilders: null == slotBuilders ? _self.slotBuilders : slotBuilders // ignore: cast_nullable_to_non_nullable
as Map<String, PortableSlotBuilder>,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost?,projectedWriters: null == projectedWriters ? _self.projectedWriters : projectedWriters // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableBindingSetter>,
  ));
}

}



/// @nodoc


class _PortablePresentationScope extends PortablePresentationScope {
  const _PortablePresentationScope({required  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, required this.budget, required this.readOnly, required this.enabled, required this.watchSearch, required this.reportStatus, required this.commit, required this.catalog, required this.resource, required this.searchHistoryNamespace, required this.openResource, required this.role, required this.material, required  Set<skir.PresentationId> activePresentations, required  Map<String, skir.PresentationNode> slots, required  Map<String, PortableSlotBuilder> slotBuilders, required this.host, required  Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters}): _bindings = bindings,_activePresentations = activePresentations,_slots = slots,_slotBuilders = slotBuilders,_projectedWriters = projectedWriters,super._();


 final  Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;
@override final  bool readOnly;
@override final  bool enabled;
@override final  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch;
@override final  ValueChanged<String>? reportStatus;
@override final  Future<void> Function()? commit;
@override final  CheckedEditorCatalog? catalog;
@override final  skir.ResourceId? resource;
@override final  String? searchHistoryNamespace;
@override final  ValueChanged<skir.ResourceId>? openResource;
@override final  skir.PresentationRole? role;
@override final  skir.PresentationMaterial? material;
 final  Set<skir.PresentationId> _activePresentations;
@override Set<skir.PresentationId> get activePresentations {
  if (_activePresentations is EqualUnmodifiableSetView) return _activePresentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activePresentations);
}

 final  Map<String, skir.PresentationNode> _slots;
@override Map<String, skir.PresentationNode> get slots {
  if (_slots is EqualUnmodifiableMapView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slots);
}

 final  Map<String, PortableSlotBuilder> _slotBuilders;
@override Map<String, PortableSlotBuilder> get slotBuilders {
  if (_slotBuilders is EqualUnmodifiableMapView) return _slotBuilders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slotBuilders);
}

@override final  PortablePresentationHost? host;
 final  Map<skir.ExpressionBindingId, PortableBindingSetter> _projectedWriters;
@override Map<skir.ExpressionBindingId, PortableBindingSetter> get projectedWriters {
  if (_projectedWriters is EqualUnmodifiableMapView) return _projectedWriters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_projectedWriters);
}


/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePresentationScopeCopyWith<_PortablePresentationScope> get copyWith => __$PortablePresentationScopeCopyWithImpl<_PortablePresentationScope>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationScope&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.watchSearch, watchSearch) || other.watchSearch == watchSearch)&&(identical(other.reportStatus, reportStatus) || other.reportStatus == reportStatus)&&(identical(other.commit, commit) || other.commit == commit)&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.searchHistoryNamespace, searchHistoryNamespace) || other.searchHistoryNamespace == searchHistoryNamespace)&&(identical(other.openResource, openResource) || other.openResource == openResource)&&(identical(other.role, role) || other.role == role)&&(identical(other.material, material) || other.material == material)&&const DeepCollectionEquality().equals(other.activePresentations, _activePresentations)&&const DeepCollectionEquality().equals(other.slots, _slots)&&const DeepCollectionEquality().equals(other.slotBuilders, _slotBuilders)&&(identical(other.host, host) || other.host == host)&&const DeepCollectionEquality().equals(other.projectedWriters, _projectedWriters));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_bindings),budget,readOnly,enabled,watchSearch,reportStatus,commit,catalog,resource,searchHistoryNamespace,openResource,role,material,const DeepCollectionEquality().hash(_activePresentations),const DeepCollectionEquality().hash(_slots),const DeepCollectionEquality().hash(_slotBuilders),host,const DeepCollectionEquality().hash(_projectedWriters));
}

@override
String toString() {
    return 'PortablePresentationScope._value(bindings: $bindings, budget: $budget, readOnly: $readOnly, enabled: $enabled, watchSearch: $watchSearch, reportStatus: $reportStatus, commit: $commit, catalog: $catalog, resource: $resource, searchHistoryNamespace: $searchHistoryNamespace, openResource: $openResource, role: $role, material: $material, activePresentations: $activePresentations, slots: $slots, slotBuilders: $slotBuilders, host: $host, projectedWriters: $projectedWriters)';
}


}

/// @nodoc
abstract mixin class _$PortablePresentationScopeCopyWith<$Res> implements $PortablePresentationScopeCopyWith<$Res> {
  factory _$PortablePresentationScopeCopyWith(_PortablePresentationScope value, $Res Function(_PortablePresentationScope) _then) = __$PortablePresentationScopeCopyWithImpl;
@override @useResult
$Res call({
 Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, bool readOnly, bool enabled, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, ValueChanged<String>? reportStatus, Future<void> Function()? commit, CheckedEditorCatalog? catalog, skir.ResourceId? resource, String? searchHistoryNamespace, ValueChanged<skir.ResourceId>? openResource, skir.PresentationRole? role, skir.PresentationMaterial? material, Set<skir.PresentationId> activePresentations, Map<String, skir.PresentationNode> slots, Map<String, PortableSlotBuilder> slotBuilders, PortablePresentationHost? host, Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters
});




}
/// @nodoc
class __$PortablePresentationScopeCopyWithImpl<$Res>
    implements _$PortablePresentationScopeCopyWith<$Res> {
  __$PortablePresentationScopeCopyWithImpl(this._self, this._then);

  final _PortablePresentationScope _self;
  final $Res Function(_PortablePresentationScope) _then;

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bindings = null,Object? budget = null,Object? readOnly = null,Object? enabled = null,Object? watchSearch = freezed,Object? reportStatus = freezed,Object? commit = freezed,Object? catalog = freezed,Object? resource = freezed,Object? searchHistoryNamespace = freezed,Object? openResource = freezed,Object? role = freezed,Object? material = freezed,Object? activePresentations = null,Object? slots = null,Object? slotBuilders = null,Object? host = freezed,Object? projectedWriters = null,}) {
  return _then(_PortablePresentationScope(
bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reportStatus: freezed == reportStatus ? _self.reportStatus : reportStatus // ignore: cast_nullable_to_non_nullable
as ValueChanged<String>?,commit: freezed == commit ? _self.commit : commit // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,resource: freezed == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,searchHistoryNamespace: freezed == searchHistoryNamespace ? _self.searchHistoryNamespace : searchHistoryNamespace // ignore: cast_nullable_to_non_nullable
as String?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial?,activePresentations: null == activePresentations ? _self._activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationId>,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,slotBuilders: null == slotBuilders ? _self._slotBuilders : slotBuilders // ignore: cast_nullable_to_non_nullable
as Map<String, PortableSlotBuilder>,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost?,projectedWriters: null == projectedWriters ? _self._projectedWriters : projectedWriters // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableBindingSetter>,
  ));
}


}

// dart format on
