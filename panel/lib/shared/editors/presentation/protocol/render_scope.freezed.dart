// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'render_scope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResolvedPresentationDefinition {

 PresentationId get id; PresentationNode get root;
/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedPresentationDefinitionCopyWith<ResolvedPresentationDefinition> get copyWith => _$ResolvedPresentationDefinitionCopyWithImpl<ResolvedPresentationDefinition>(this as ResolvedPresentationDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedPresentationDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.root, root) || other.root == root));
}


@override
int get hashCode => Object.hash(runtimeType,id,root);

@override
String toString() {
  return 'ResolvedPresentationDefinition(id: $id, root: $root)';
}


}

/// @nodoc
abstract mixin class $ResolvedPresentationDefinitionCopyWith<$Res>  {
  factory $ResolvedPresentationDefinitionCopyWith(ResolvedPresentationDefinition value, $Res Function(ResolvedPresentationDefinition) _then) = _$ResolvedPresentationDefinitionCopyWithImpl;
@useResult
$Res call({
 PresentationId id, PresentationNode root
});


$PresentationIdCopyWith<$Res> get id;$PresentationNodeCopyWith<$Res> get root;

}
/// @nodoc
class _$ResolvedPresentationDefinitionCopyWithImpl<$Res>
    implements $ResolvedPresentationDefinitionCopyWith<$Res> {
  _$ResolvedPresentationDefinitionCopyWithImpl(this._self, this._then);

  final ResolvedPresentationDefinition _self;
  final $Res Function(ResolvedPresentationDefinition) _then;

/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? root = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationId,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}
/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationIdCopyWith<$Res> get id {
  
  return $PresentationIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get root {
  
  return $PresentationNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResolvedPresentationDefinition].
extension ResolvedPresentationDefinitionPatterns on ResolvedPresentationDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedPresentationDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedPresentationDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedPresentationDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedPresentationDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedPresentationDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedPresentationDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PresentationId id,  PresentationNode root)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedPresentationDefinition() when $default != null:
return $default(_that.id,_that.root);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PresentationId id,  PresentationNode root)  $default,) {final _that = this;
switch (_that) {
case _ResolvedPresentationDefinition():
return $default(_that.id,_that.root);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PresentationId id,  PresentationNode root)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedPresentationDefinition() when $default != null:
return $default(_that.id,_that.root);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedPresentationDefinition implements ResolvedPresentationDefinition {
  const _ResolvedPresentationDefinition({required this.id, required this.root});
  

@override final  PresentationId id;
@override final  PresentationNode root;

/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedPresentationDefinitionCopyWith<_ResolvedPresentationDefinition> get copyWith => __$ResolvedPresentationDefinitionCopyWithImpl<_ResolvedPresentationDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedPresentationDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.root, root) || other.root == root));
}


@override
int get hashCode => Object.hash(runtimeType,id,root);

@override
String toString() {
  return 'ResolvedPresentationDefinition(id: $id, root: $root)';
}


}

/// @nodoc
abstract mixin class _$ResolvedPresentationDefinitionCopyWith<$Res> implements $ResolvedPresentationDefinitionCopyWith<$Res> {
  factory _$ResolvedPresentationDefinitionCopyWith(_ResolvedPresentationDefinition value, $Res Function(_ResolvedPresentationDefinition) _then) = __$ResolvedPresentationDefinitionCopyWithImpl;
@override @useResult
$Res call({
 PresentationId id, PresentationNode root
});


@override $PresentationIdCopyWith<$Res> get id;@override $PresentationNodeCopyWith<$Res> get root;

}
/// @nodoc
class __$ResolvedPresentationDefinitionCopyWithImpl<$Res>
    implements _$ResolvedPresentationDefinitionCopyWith<$Res> {
  __$ResolvedPresentationDefinitionCopyWithImpl(this._self, this._then);

  final _ResolvedPresentationDefinition _self;
  final $Res Function(_ResolvedPresentationDefinition) _then;

/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? root = null,}) {
  return _then(_ResolvedPresentationDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationId,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,
  ));
}

/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationIdCopyWith<$Res> get id {
  
  return $PresentationIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get root {
  
  return $PresentationNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}

/// @nodoc
mixin _$HeaderExpansionKey {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeaderExpansionKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HeaderExpansionKey()';
}


}

/// @nodoc
class $HeaderExpansionKeyCopyWith<$Res>  {
$HeaderExpansionKeyCopyWith(HeaderExpansionKey _, $Res Function(HeaderExpansionKey) __);
}


/// Adds pattern-matching-related methods to [HeaderExpansionKey].
extension HeaderExpansionKeyPatterns on HeaderExpansionKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NodeHeaderExpansionKey value)?  node,TResult Function( InstanceHeaderExpansionKey value)?  instance,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NodeHeaderExpansionKey() when node != null:
return node(_that);case InstanceHeaderExpansionKey() when instance != null:
return instance(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NodeHeaderExpansionKey value)  node,required TResult Function( InstanceHeaderExpansionKey value)  instance,}){
final _that = this;
switch (_that) {
case NodeHeaderExpansionKey():
return node(_that);case InstanceHeaderExpansionKey():
return instance(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NodeHeaderExpansionKey value)?  node,TResult? Function( InstanceHeaderExpansionKey value)?  instance,}){
final _that = this;
switch (_that) {
case NodeHeaderExpansionKey() when node != null:
return node(_that);case InstanceHeaderExpansionKey() when instance != null:
return instance(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String nodeId,  BindingReference? binding)?  node,TResult Function( Object identity)?  instance,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NodeHeaderExpansionKey() when node != null:
return node(_that.nodeId,_that.binding);case InstanceHeaderExpansionKey() when instance != null:
return instance(_that.identity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String nodeId,  BindingReference? binding)  node,required TResult Function( Object identity)  instance,}) {final _that = this;
switch (_that) {
case NodeHeaderExpansionKey():
return node(_that.nodeId,_that.binding);case InstanceHeaderExpansionKey():
return instance(_that.identity);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String nodeId,  BindingReference? binding)?  node,TResult? Function( Object identity)?  instance,}) {final _that = this;
switch (_that) {
case NodeHeaderExpansionKey() when node != null:
return node(_that.nodeId,_that.binding);case InstanceHeaderExpansionKey() when instance != null:
return instance(_that.identity);case _:
  return null;

}
}

}

/// @nodoc


class NodeHeaderExpansionKey implements HeaderExpansionKey {
  const NodeHeaderExpansionKey({required this.nodeId, required this.binding});
  

 final  String nodeId;
 final  BindingReference? binding;

/// Create a copy of HeaderExpansionKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeHeaderExpansionKeyCopyWith<NodeHeaderExpansionKey> get copyWith => _$NodeHeaderExpansionKeyCopyWithImpl<NodeHeaderExpansionKey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeHeaderExpansionKey&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.binding, binding) || other.binding == binding));
}


@override
int get hashCode => Object.hash(runtimeType,nodeId,binding);

@override
String toString() {
  return 'HeaderExpansionKey.node(nodeId: $nodeId, binding: $binding)';
}


}

/// @nodoc
abstract mixin class $NodeHeaderExpansionKeyCopyWith<$Res> implements $HeaderExpansionKeyCopyWith<$Res> {
  factory $NodeHeaderExpansionKeyCopyWith(NodeHeaderExpansionKey value, $Res Function(NodeHeaderExpansionKey) _then) = _$NodeHeaderExpansionKeyCopyWithImpl;
@useResult
$Res call({
 String nodeId, BindingReference? binding
});


$BindingReferenceCopyWith<$Res>? get binding;

}
/// @nodoc
class _$NodeHeaderExpansionKeyCopyWithImpl<$Res>
    implements $NodeHeaderExpansionKeyCopyWith<$Res> {
  _$NodeHeaderExpansionKeyCopyWithImpl(this._self, this._then);

  final NodeHeaderExpansionKey _self;
  final $Res Function(NodeHeaderExpansionKey) _then;

/// Create a copy of HeaderExpansionKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? nodeId = null,Object? binding = freezed,}) {
  return _then(NodeHeaderExpansionKey(
nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,binding: freezed == binding ? _self.binding : binding // ignore: cast_nullable_to_non_nullable
as BindingReference?,
  ));
}

/// Create a copy of HeaderExpansionKey
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingReferenceCopyWith<$Res>? get binding {
    if (_self.binding == null) {
    return null;
  }

  return $BindingReferenceCopyWith<$Res>(_self.binding!, (value) {
    return _then(_self.copyWith(binding: value));
  });
}
}

/// @nodoc


class InstanceHeaderExpansionKey implements HeaderExpansionKey {
  const InstanceHeaderExpansionKey(this.identity);
  

 final  Object identity;

/// Create a copy of HeaderExpansionKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstanceHeaderExpansionKeyCopyWith<InstanceHeaderExpansionKey> get copyWith => _$InstanceHeaderExpansionKeyCopyWithImpl<InstanceHeaderExpansionKey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstanceHeaderExpansionKey&&const DeepCollectionEquality().equals(other.identity, identity));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(identity));

@override
String toString() {
  return 'HeaderExpansionKey.instance(identity: $identity)';
}


}

/// @nodoc
abstract mixin class $InstanceHeaderExpansionKeyCopyWith<$Res> implements $HeaderExpansionKeyCopyWith<$Res> {
  factory $InstanceHeaderExpansionKeyCopyWith(InstanceHeaderExpansionKey value, $Res Function(InstanceHeaderExpansionKey) _then) = _$InstanceHeaderExpansionKeyCopyWithImpl;
@useResult
$Res call({
 Object identity
});




}
/// @nodoc
class _$InstanceHeaderExpansionKeyCopyWithImpl<$Res>
    implements $InstanceHeaderExpansionKeyCopyWith<$Res> {
  _$InstanceHeaderExpansionKeyCopyWithImpl(this._self, this._then);

  final InstanceHeaderExpansionKey _self;
  final $Res Function(InstanceHeaderExpansionKey) _then;

/// Create a copy of HeaderExpansionKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? identity = null,}) {
  return _then(InstanceHeaderExpansionKey(
null == identity ? _self.identity : identity ,
  ));
}


}

/// @nodoc
mixin _$PresentationRenderScope {

 ExpressionContext get expressions; TypeRegistry get registry; ExpressionBudget get budget; BindingSetter get setBinding; ActionExecutor get executeAction; PresentationResolver get resolvePresentation; HeaderExpansionStore get expansionStore; EditorInteractionStarter? get startInteraction; RealmPresentationSearchSourceBuilder? get realmSearchSourceBuilder; Map<PresentationCollectionSourceId, PresentationCollectionSource> get collections; Map<BindingId, BindingReference> get aliases; Map<HeaderItemCommandId, List<ShortcutActivator>> get headerShortcuts; Set<(String, BindingReference?)> get suppressedHeaders; Map<String, Widget> get presentationSlots; Object? get expansionIdentity; bool get enabled; bool get readOnly; String get historyNamespace; Set<PresentationId> get activePresentations;
/// Create a copy of PresentationRenderScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationRenderScopeCopyWith<PresentationRenderScope> get copyWith => _$PresentationRenderScopeCopyWithImpl<PresentationRenderScope>(this as PresentationRenderScope, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationRenderScope&&(identical(other.expressions, expressions) || other.expressions == expressions)&&(identical(other.registry, registry) || other.registry == registry)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.setBinding, setBinding) || other.setBinding == setBinding)&&(identical(other.executeAction, executeAction) || other.executeAction == executeAction)&&(identical(other.resolvePresentation, resolvePresentation) || other.resolvePresentation == resolvePresentation)&&(identical(other.expansionStore, expansionStore) || other.expansionStore == expansionStore)&&(identical(other.startInteraction, startInteraction) || other.startInteraction == startInteraction)&&(identical(other.realmSearchSourceBuilder, realmSearchSourceBuilder) || other.realmSearchSourceBuilder == realmSearchSourceBuilder)&&const DeepCollectionEquality().equals(other.collections, collections)&&const DeepCollectionEquality().equals(other.aliases, aliases)&&const DeepCollectionEquality().equals(other.headerShortcuts, headerShortcuts)&&const DeepCollectionEquality().equals(other.suppressedHeaders, suppressedHeaders)&&const DeepCollectionEquality().equals(other.presentationSlots, presentationSlots)&&const DeepCollectionEquality().equals(other.expansionIdentity, expansionIdentity)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.historyNamespace, historyNamespace) || other.historyNamespace == historyNamespace)&&const DeepCollectionEquality().equals(other.activePresentations, activePresentations));
}


@override
int get hashCode => Object.hashAll([runtimeType,expressions,registry,budget,setBinding,executeAction,resolvePresentation,expansionStore,startInteraction,realmSearchSourceBuilder,const DeepCollectionEquality().hash(collections),const DeepCollectionEquality().hash(aliases),const DeepCollectionEquality().hash(headerShortcuts),const DeepCollectionEquality().hash(suppressedHeaders),const DeepCollectionEquality().hash(presentationSlots),const DeepCollectionEquality().hash(expansionIdentity),enabled,readOnly,historyNamespace,const DeepCollectionEquality().hash(activePresentations)]);

@override
String toString() {
  return 'PresentationRenderScope(expressions: $expressions, registry: $registry, budget: $budget, setBinding: $setBinding, executeAction: $executeAction, resolvePresentation: $resolvePresentation, expansionStore: $expansionStore, startInteraction: $startInteraction, realmSearchSourceBuilder: $realmSearchSourceBuilder, collections: $collections, aliases: $aliases, headerShortcuts: $headerShortcuts, suppressedHeaders: $suppressedHeaders, presentationSlots: $presentationSlots, expansionIdentity: $expansionIdentity, enabled: $enabled, readOnly: $readOnly, historyNamespace: $historyNamespace, activePresentations: $activePresentations)';
}


}

/// @nodoc
abstract mixin class $PresentationRenderScopeCopyWith<$Res>  {
  factory $PresentationRenderScopeCopyWith(PresentationRenderScope value, $Res Function(PresentationRenderScope) _then) = _$PresentationRenderScopeCopyWithImpl;
@useResult
$Res call({
 ExpressionContext expressions, TypeRegistry registry, ExpressionBudget budget, BindingSetter setBinding, ActionExecutor executeAction, PresentationResolver resolvePresentation, HeaderExpansionStore expansionStore, EditorInteractionStarter? startInteraction, RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder, Map<PresentationCollectionSourceId, PresentationCollectionSource> collections, Map<BindingId, BindingReference> aliases, Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts, Set<(String, BindingReference?)> suppressedHeaders, Map<String, Widget> presentationSlots, Object? expansionIdentity, bool enabled, bool readOnly, String historyNamespace, Set<PresentationId> activePresentations
});


$ExpressionContextCopyWith<$Res> get expressions;$ExpressionBudgetCopyWith<$Res> get budget;

}
/// @nodoc
class _$PresentationRenderScopeCopyWithImpl<$Res>
    implements $PresentationRenderScopeCopyWith<$Res> {
  _$PresentationRenderScopeCopyWithImpl(this._self, this._then);

  final PresentationRenderScope _self;
  final $Res Function(PresentationRenderScope) _then;

/// Create a copy of PresentationRenderScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? expressions = null,Object? registry = null,Object? budget = null,Object? setBinding = null,Object? executeAction = null,Object? resolvePresentation = null,Object? expansionStore = null,Object? startInteraction = freezed,Object? realmSearchSourceBuilder = freezed,Object? collections = null,Object? aliases = null,Object? headerShortcuts = null,Object? suppressedHeaders = null,Object? presentationSlots = null,Object? expansionIdentity = freezed,Object? enabled = null,Object? readOnly = null,Object? historyNamespace = null,Object? activePresentations = null,}) {
  return _then(_self.copyWith(
expressions: null == expressions ? _self.expressions : expressions // ignore: cast_nullable_to_non_nullable
as ExpressionContext,registry: null == registry ? _self.registry : registry // ignore: cast_nullable_to_non_nullable
as TypeRegistry,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as ExpressionBudget,setBinding: null == setBinding ? _self.setBinding : setBinding // ignore: cast_nullable_to_non_nullable
as BindingSetter,executeAction: null == executeAction ? _self.executeAction : executeAction // ignore: cast_nullable_to_non_nullable
as ActionExecutor,resolvePresentation: null == resolvePresentation ? _self.resolvePresentation : resolvePresentation // ignore: cast_nullable_to_non_nullable
as PresentationResolver,expansionStore: null == expansionStore ? _self.expansionStore : expansionStore // ignore: cast_nullable_to_non_nullable
as HeaderExpansionStore,startInteraction: freezed == startInteraction ? _self.startInteraction : startInteraction // ignore: cast_nullable_to_non_nullable
as EditorInteractionStarter?,realmSearchSourceBuilder: freezed == realmSearchSourceBuilder ? _self.realmSearchSourceBuilder : realmSearchSourceBuilder // ignore: cast_nullable_to_non_nullable
as RealmPresentationSearchSourceBuilder?,collections: null == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, PresentationCollectionSource>,aliases: null == aliases ? _self.aliases : aliases // ignore: cast_nullable_to_non_nullable
as Map<BindingId, BindingReference>,headerShortcuts: null == headerShortcuts ? _self.headerShortcuts : headerShortcuts // ignore: cast_nullable_to_non_nullable
as Map<HeaderItemCommandId, List<ShortcutActivator>>,suppressedHeaders: null == suppressedHeaders ? _self.suppressedHeaders : suppressedHeaders // ignore: cast_nullable_to_non_nullable
as Set<(String, BindingReference?)>,presentationSlots: null == presentationSlots ? _self.presentationSlots : presentationSlots // ignore: cast_nullable_to_non_nullable
as Map<String, Widget>,expansionIdentity: freezed == expansionIdentity ? _self.expansionIdentity : expansionIdentity ,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,historyNamespace: null == historyNamespace ? _self.historyNamespace : historyNamespace // ignore: cast_nullable_to_non_nullable
as String,activePresentations: null == activePresentations ? _self.activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<PresentationId>,
  ));
}
/// Create a copy of PresentationRenderScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpressionContextCopyWith<$Res> get expressions {
  
  return $ExpressionContextCopyWith<$Res>(_self.expressions, (value) {
    return _then(_self.copyWith(expressions: value));
  });
}/// Create a copy of PresentationRenderScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpressionBudgetCopyWith<$Res> get budget {
  
  return $ExpressionBudgetCopyWith<$Res>(_self.budget, (value) {
    return _then(_self.copyWith(budget: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationRenderScope].
extension PresentationRenderScopePatterns on PresentationRenderScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationRenderScope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationRenderScope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationRenderScope value)  $default,){
final _that = this;
switch (_that) {
case _PresentationRenderScope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationRenderScope value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationRenderScope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExpressionContext expressions,  TypeRegistry registry,  ExpressionBudget budget,  BindingSetter setBinding,  ActionExecutor executeAction,  PresentationResolver resolvePresentation,  HeaderExpansionStore expansionStore,  EditorInteractionStarter? startInteraction,  RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections,  Map<BindingId, BindingReference> aliases,  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts,  Set<(String, BindingReference?)> suppressedHeaders,  Map<String, Widget> presentationSlots,  Object? expansionIdentity,  bool enabled,  bool readOnly,  String historyNamespace,  Set<PresentationId> activePresentations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationRenderScope() when $default != null:
return $default(_that.expressions,_that.registry,_that.budget,_that.setBinding,_that.executeAction,_that.resolvePresentation,_that.expansionStore,_that.startInteraction,_that.realmSearchSourceBuilder,_that.collections,_that.aliases,_that.headerShortcuts,_that.suppressedHeaders,_that.presentationSlots,_that.expansionIdentity,_that.enabled,_that.readOnly,_that.historyNamespace,_that.activePresentations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExpressionContext expressions,  TypeRegistry registry,  ExpressionBudget budget,  BindingSetter setBinding,  ActionExecutor executeAction,  PresentationResolver resolvePresentation,  HeaderExpansionStore expansionStore,  EditorInteractionStarter? startInteraction,  RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections,  Map<BindingId, BindingReference> aliases,  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts,  Set<(String, BindingReference?)> suppressedHeaders,  Map<String, Widget> presentationSlots,  Object? expansionIdentity,  bool enabled,  bool readOnly,  String historyNamespace,  Set<PresentationId> activePresentations)  $default,) {final _that = this;
switch (_that) {
case _PresentationRenderScope():
return $default(_that.expressions,_that.registry,_that.budget,_that.setBinding,_that.executeAction,_that.resolvePresentation,_that.expansionStore,_that.startInteraction,_that.realmSearchSourceBuilder,_that.collections,_that.aliases,_that.headerShortcuts,_that.suppressedHeaders,_that.presentationSlots,_that.expansionIdentity,_that.enabled,_that.readOnly,_that.historyNamespace,_that.activePresentations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExpressionContext expressions,  TypeRegistry registry,  ExpressionBudget budget,  BindingSetter setBinding,  ActionExecutor executeAction,  PresentationResolver resolvePresentation,  HeaderExpansionStore expansionStore,  EditorInteractionStarter? startInteraction,  RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections,  Map<BindingId, BindingReference> aliases,  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts,  Set<(String, BindingReference?)> suppressedHeaders,  Map<String, Widget> presentationSlots,  Object? expansionIdentity,  bool enabled,  bool readOnly,  String historyNamespace,  Set<PresentationId> activePresentations)?  $default,) {final _that = this;
switch (_that) {
case _PresentationRenderScope() when $default != null:
return $default(_that.expressions,_that.registry,_that.budget,_that.setBinding,_that.executeAction,_that.resolvePresentation,_that.expansionStore,_that.startInteraction,_that.realmSearchSourceBuilder,_that.collections,_that.aliases,_that.headerShortcuts,_that.suppressedHeaders,_that.presentationSlots,_that.expansionIdentity,_that.enabled,_that.readOnly,_that.historyNamespace,_that.activePresentations);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationRenderScope extends PresentationRenderScope {
  const _PresentationRenderScope({required this.expressions, required this.registry, required this.budget, required this.setBinding, required this.executeAction, required this.resolvePresentation, required this.expansionStore, this.startInteraction, this.realmSearchSourceBuilder, final  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections = const {}, final  Map<BindingId, BindingReference> aliases = const {}, final  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts = const {}, final  Set<(String, BindingReference?)> suppressedHeaders = const {}, final  Map<String, Widget> presentationSlots = const {}, this.expansionIdentity, this.enabled = true, this.readOnly = false, this.historyNamespace = "local", final  Set<PresentationId> activePresentations = const {}}): _collections = collections,_aliases = aliases,_headerShortcuts = headerShortcuts,_suppressedHeaders = suppressedHeaders,_presentationSlots = presentationSlots,_activePresentations = activePresentations,super._();
  

@override final  ExpressionContext expressions;
@override final  TypeRegistry registry;
@override final  ExpressionBudget budget;
@override final  BindingSetter setBinding;
@override final  ActionExecutor executeAction;
@override final  PresentationResolver resolvePresentation;
@override final  HeaderExpansionStore expansionStore;
@override final  EditorInteractionStarter? startInteraction;
@override final  RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder;
 final  Map<PresentationCollectionSourceId, PresentationCollectionSource> _collections;
@override@JsonKey() Map<PresentationCollectionSourceId, PresentationCollectionSource> get collections {
  if (_collections is EqualUnmodifiableMapView) return _collections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_collections);
}

 final  Map<BindingId, BindingReference> _aliases;
@override@JsonKey() Map<BindingId, BindingReference> get aliases {
  if (_aliases is EqualUnmodifiableMapView) return _aliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_aliases);
}

 final  Map<HeaderItemCommandId, List<ShortcutActivator>> _headerShortcuts;
@override@JsonKey() Map<HeaderItemCommandId, List<ShortcutActivator>> get headerShortcuts {
  if (_headerShortcuts is EqualUnmodifiableMapView) return _headerShortcuts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headerShortcuts);
}

 final  Set<(String, BindingReference?)> _suppressedHeaders;
@override@JsonKey() Set<(String, BindingReference?)> get suppressedHeaders {
  if (_suppressedHeaders is EqualUnmodifiableSetView) return _suppressedHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_suppressedHeaders);
}

 final  Map<String, Widget> _presentationSlots;
@override@JsonKey() Map<String, Widget> get presentationSlots {
  if (_presentationSlots is EqualUnmodifiableMapView) return _presentationSlots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_presentationSlots);
}

@override final  Object? expansionIdentity;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  bool readOnly;
@override@JsonKey() final  String historyNamespace;
 final  Set<PresentationId> _activePresentations;
@override@JsonKey() Set<PresentationId> get activePresentations {
  if (_activePresentations is EqualUnmodifiableSetView) return _activePresentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activePresentations);
}


/// Create a copy of PresentationRenderScope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationRenderScopeCopyWith<_PresentationRenderScope> get copyWith => __$PresentationRenderScopeCopyWithImpl<_PresentationRenderScope>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationRenderScope&&(identical(other.expressions, expressions) || other.expressions == expressions)&&(identical(other.registry, registry) || other.registry == registry)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.setBinding, setBinding) || other.setBinding == setBinding)&&(identical(other.executeAction, executeAction) || other.executeAction == executeAction)&&(identical(other.resolvePresentation, resolvePresentation) || other.resolvePresentation == resolvePresentation)&&(identical(other.expansionStore, expansionStore) || other.expansionStore == expansionStore)&&(identical(other.startInteraction, startInteraction) || other.startInteraction == startInteraction)&&(identical(other.realmSearchSourceBuilder, realmSearchSourceBuilder) || other.realmSearchSourceBuilder == realmSearchSourceBuilder)&&const DeepCollectionEquality().equals(other._collections, _collections)&&const DeepCollectionEquality().equals(other._aliases, _aliases)&&const DeepCollectionEquality().equals(other._headerShortcuts, _headerShortcuts)&&const DeepCollectionEquality().equals(other._suppressedHeaders, _suppressedHeaders)&&const DeepCollectionEquality().equals(other._presentationSlots, _presentationSlots)&&const DeepCollectionEquality().equals(other.expansionIdentity, expansionIdentity)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.historyNamespace, historyNamespace) || other.historyNamespace == historyNamespace)&&const DeepCollectionEquality().equals(other._activePresentations, _activePresentations));
}


@override
int get hashCode => Object.hashAll([runtimeType,expressions,registry,budget,setBinding,executeAction,resolvePresentation,expansionStore,startInteraction,realmSearchSourceBuilder,const DeepCollectionEquality().hash(_collections),const DeepCollectionEquality().hash(_aliases),const DeepCollectionEquality().hash(_headerShortcuts),const DeepCollectionEquality().hash(_suppressedHeaders),const DeepCollectionEquality().hash(_presentationSlots),const DeepCollectionEquality().hash(expansionIdentity),enabled,readOnly,historyNamespace,const DeepCollectionEquality().hash(_activePresentations)]);

@override
String toString() {
  return 'PresentationRenderScope(expressions: $expressions, registry: $registry, budget: $budget, setBinding: $setBinding, executeAction: $executeAction, resolvePresentation: $resolvePresentation, expansionStore: $expansionStore, startInteraction: $startInteraction, realmSearchSourceBuilder: $realmSearchSourceBuilder, collections: $collections, aliases: $aliases, headerShortcuts: $headerShortcuts, suppressedHeaders: $suppressedHeaders, presentationSlots: $presentationSlots, expansionIdentity: $expansionIdentity, enabled: $enabled, readOnly: $readOnly, historyNamespace: $historyNamespace, activePresentations: $activePresentations)';
}


}

/// @nodoc
abstract mixin class _$PresentationRenderScopeCopyWith<$Res> implements $PresentationRenderScopeCopyWith<$Res> {
  factory _$PresentationRenderScopeCopyWith(_PresentationRenderScope value, $Res Function(_PresentationRenderScope) _then) = __$PresentationRenderScopeCopyWithImpl;
@override @useResult
$Res call({
 ExpressionContext expressions, TypeRegistry registry, ExpressionBudget budget, BindingSetter setBinding, ActionExecutor executeAction, PresentationResolver resolvePresentation, HeaderExpansionStore expansionStore, EditorInteractionStarter? startInteraction, RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder, Map<PresentationCollectionSourceId, PresentationCollectionSource> collections, Map<BindingId, BindingReference> aliases, Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts, Set<(String, BindingReference?)> suppressedHeaders, Map<String, Widget> presentationSlots, Object? expansionIdentity, bool enabled, bool readOnly, String historyNamespace, Set<PresentationId> activePresentations
});


@override $ExpressionContextCopyWith<$Res> get expressions;@override $ExpressionBudgetCopyWith<$Res> get budget;

}
/// @nodoc
class __$PresentationRenderScopeCopyWithImpl<$Res>
    implements _$PresentationRenderScopeCopyWith<$Res> {
  __$PresentationRenderScopeCopyWithImpl(this._self, this._then);

  final _PresentationRenderScope _self;
  final $Res Function(_PresentationRenderScope) _then;

/// Create a copy of PresentationRenderScope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? expressions = null,Object? registry = null,Object? budget = null,Object? setBinding = null,Object? executeAction = null,Object? resolvePresentation = null,Object? expansionStore = null,Object? startInteraction = freezed,Object? realmSearchSourceBuilder = freezed,Object? collections = null,Object? aliases = null,Object? headerShortcuts = null,Object? suppressedHeaders = null,Object? presentationSlots = null,Object? expansionIdentity = freezed,Object? enabled = null,Object? readOnly = null,Object? historyNamespace = null,Object? activePresentations = null,}) {
  return _then(_PresentationRenderScope(
expressions: null == expressions ? _self.expressions : expressions // ignore: cast_nullable_to_non_nullable
as ExpressionContext,registry: null == registry ? _self.registry : registry // ignore: cast_nullable_to_non_nullable
as TypeRegistry,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as ExpressionBudget,setBinding: null == setBinding ? _self.setBinding : setBinding // ignore: cast_nullable_to_non_nullable
as BindingSetter,executeAction: null == executeAction ? _self.executeAction : executeAction // ignore: cast_nullable_to_non_nullable
as ActionExecutor,resolvePresentation: null == resolvePresentation ? _self.resolvePresentation : resolvePresentation // ignore: cast_nullable_to_non_nullable
as PresentationResolver,expansionStore: null == expansionStore ? _self.expansionStore : expansionStore // ignore: cast_nullable_to_non_nullable
as HeaderExpansionStore,startInteraction: freezed == startInteraction ? _self.startInteraction : startInteraction // ignore: cast_nullable_to_non_nullable
as EditorInteractionStarter?,realmSearchSourceBuilder: freezed == realmSearchSourceBuilder ? _self.realmSearchSourceBuilder : realmSearchSourceBuilder // ignore: cast_nullable_to_non_nullable
as RealmPresentationSearchSourceBuilder?,collections: null == collections ? _self._collections : collections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, PresentationCollectionSource>,aliases: null == aliases ? _self._aliases : aliases // ignore: cast_nullable_to_non_nullable
as Map<BindingId, BindingReference>,headerShortcuts: null == headerShortcuts ? _self._headerShortcuts : headerShortcuts // ignore: cast_nullable_to_non_nullable
as Map<HeaderItemCommandId, List<ShortcutActivator>>,suppressedHeaders: null == suppressedHeaders ? _self._suppressedHeaders : suppressedHeaders // ignore: cast_nullable_to_non_nullable
as Set<(String, BindingReference?)>,presentationSlots: null == presentationSlots ? _self._presentationSlots : presentationSlots // ignore: cast_nullable_to_non_nullable
as Map<String, Widget>,expansionIdentity: freezed == expansionIdentity ? _self.expansionIdentity : expansionIdentity ,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,historyNamespace: null == historyNamespace ? _self.historyNamespace : historyNamespace // ignore: cast_nullable_to_non_nullable
as String,activePresentations: null == activePresentations ? _self._activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<PresentationId>,
  ));
}

/// Create a copy of PresentationRenderScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpressionContextCopyWith<$Res> get expressions {
  
  return $ExpressionContextCopyWith<$Res>(_self.expressions, (value) {
    return _then(_self.copyWith(expressions: value));
  });
}/// Create a copy of PresentationRenderScope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpressionBudgetCopyWith<$Res> get budget {
  
  return $ExpressionBudgetCopyWith<$Res>(_self.budget, (value) {
    return _then(_self.copyWith(budget: value));
  });
}
}

// dart format on
