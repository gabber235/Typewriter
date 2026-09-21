// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'render_scope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResolvedPresentationDefinition {

 PresentationId get id; PresentationNode get root; List<PresentationInputParameter> get inputs; BindingId? get primaryInput;
/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedPresentationDefinitionCopyWith<ResolvedPresentationDefinition> get copyWith => _$ResolvedPresentationDefinitionCopyWithImpl<ResolvedPresentationDefinition>(this as ResolvedPresentationDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResolvedPresentationDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedPresentationDefinition&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.root, _this.root) || other.root == _this.root)&&const DeepCollectionEquality().equals(other.inputs, _this.inputs)&&(identical(other.primaryInput, _this.primaryInput) || other.primaryInput == _this.primaryInput));
}


@override
int get hashCode {
  final _this = this as ResolvedPresentationDefinition;
  return Object.hash(runtimeType,_this.id,_this.root,const DeepCollectionEquality().hash(_this.inputs),_this.primaryInput);
}

@override
String toString() {
  final _this = this as ResolvedPresentationDefinition;
  return 'ResolvedPresentationDefinition(id: ${_this.id}, root: ${_this.root}, inputs: ${_this.inputs}, primaryInput: ${_this.primaryInput})';
}


}

/// @nodoc
abstract mixin class $ResolvedPresentationDefinitionCopyWith<$Res>  {
  factory $ResolvedPresentationDefinitionCopyWith(ResolvedPresentationDefinition value, $Res Function(ResolvedPresentationDefinition) _then) = _$ResolvedPresentationDefinitionCopyWithImpl;
@useResult
$Res call({
 PresentationId id, PresentationNode root, List<PresentationInputParameter> inputs, BindingId? primaryInput
});


$PresentationIdCopyWith<$Res> get id;$PresentationNodeCopyWith<$Res> get root;$BindingIdCopyWith<$Res>? get primaryInput;

}
/// @nodoc
class _$ResolvedPresentationDefinitionCopyWithImpl<$Res>
    implements $ResolvedPresentationDefinitionCopyWith<$Res> {
  _$ResolvedPresentationDefinitionCopyWithImpl(this._self, this._then);

  final ResolvedPresentationDefinition _self;
  final $Res Function(ResolvedPresentationDefinition) _then;

/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? root = null,Object? inputs = null,Object? primaryInput = freezed,}) {
  return _then(ResolvedPresentationDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationId,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,inputs: null == inputs ? _self.inputs : inputs // ignore: cast_nullable_to_non_nullable
as List<PresentationInputParameter>,primaryInput: freezed == primaryInput ? _self.primaryInput : primaryInput // ignore: cast_nullable_to_non_nullable
as BindingId?,
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
}/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res>? get primaryInput {
    if (_self.primaryInput == null) {
    return null;
  }

  return $BindingIdCopyWith<$Res>(_self.primaryInput!, (value) {
    return _then(_self.copyWith(primaryInput: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PresentationId id,  PresentationNode root,  List<PresentationInputParameter> inputs,  BindingId? primaryInput)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedPresentationDefinition() when $default != null:
return $default(_that.id,_that.root,_that.inputs,_that.primaryInput);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PresentationId id,  PresentationNode root,  List<PresentationInputParameter> inputs,  BindingId? primaryInput)  $default,) {final _that = this;
switch (_that) {
case _ResolvedPresentationDefinition():
return $default(_that.id,_that.root,_that.inputs,_that.primaryInput);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PresentationId id,  PresentationNode root,  List<PresentationInputParameter> inputs,  BindingId? primaryInput)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedPresentationDefinition() when $default != null:
return $default(_that.id,_that.root,_that.inputs,_that.primaryInput);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedPresentationDefinition implements ResolvedPresentationDefinition {
  const _ResolvedPresentationDefinition({required this.id, required this.root,  List<PresentationInputParameter> inputs = const [], this.primaryInput}): _inputs = inputs;
  

@override final  PresentationId id;
@override final  PresentationNode root;
 final  List<PresentationInputParameter> _inputs;
@override@JsonKey() List<PresentationInputParameter> get inputs {
  if (_inputs is EqualUnmodifiableListView) return _inputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inputs);
}

@override final  BindingId? primaryInput;

/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedPresentationDefinitionCopyWith<_ResolvedPresentationDefinition> get copyWith => __$ResolvedPresentationDefinitionCopyWithImpl<_ResolvedPresentationDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedPresentationDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.root, root) || other.root == root)&&const DeepCollectionEquality().equals(other.inputs, _inputs)&&(identical(other.primaryInput, primaryInput) || other.primaryInput == primaryInput));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,root,const DeepCollectionEquality().hash(_inputs),primaryInput);
}

@override
String toString() {
    return 'ResolvedPresentationDefinition(id: $id, root: $root, inputs: $inputs, primaryInput: $primaryInput)';
}


}

/// @nodoc
abstract mixin class _$ResolvedPresentationDefinitionCopyWith<$Res> implements $ResolvedPresentationDefinitionCopyWith<$Res> {
  factory _$ResolvedPresentationDefinitionCopyWith(_ResolvedPresentationDefinition value, $Res Function(_ResolvedPresentationDefinition) _then) = __$ResolvedPresentationDefinitionCopyWithImpl;
@override @useResult
$Res call({
 PresentationId id, PresentationNode root, List<PresentationInputParameter> inputs, BindingId? primaryInput
});


@override $PresentationIdCopyWith<$Res> get id;@override $PresentationNodeCopyWith<$Res> get root;@override $BindingIdCopyWith<$Res>? get primaryInput;

}
/// @nodoc
class __$ResolvedPresentationDefinitionCopyWithImpl<$Res>
    implements _$ResolvedPresentationDefinitionCopyWith<$Res> {
  __$ResolvedPresentationDefinitionCopyWithImpl(this._self, this._then);

  final _ResolvedPresentationDefinition _self;
  final $Res Function(_ResolvedPresentationDefinition) _then;

/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? root = null,Object? inputs = null,Object? primaryInput = freezed,}) {
  return _then(_ResolvedPresentationDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationId,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,inputs: null == inputs ? _self._inputs : inputs // ignore: cast_nullable_to_non_nullable
as List<PresentationInputParameter>,primaryInput: freezed == primaryInput ? _self.primaryInput : primaryInput // ignore: cast_nullable_to_non_nullable
as BindingId?,
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
}/// Create a copy of ResolvedPresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res>? get primaryInput {
    if (_self.primaryInput == null) {
    return null;
  }

  return $BindingIdCopyWith<$Res>(_self.primaryInput!, (value) {
    return _then(_self.copyWith(primaryInput: value));
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
int get hashCode {
    return Object.hash(runtimeType,nodeId,binding);
}

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
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(identity));
}

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

 ExpressionContext get expressions; TypeRegistry get registry; ExpressionBudget get budget; BindingSetter get setBinding; ActionExecutor get executeAction; PresentationResolver get resolvePresentation; HeaderExpansionStore get expansionStore; EditorInteractionStarter? get startInteraction; RealmPresentationSearchSourceBuilder? get realmSearchSourceBuilder; ReferenceSearchSourceBuilder? get referenceSearchSourceBuilder; ReferenceResourceResolver? get resolveReferences; ReferenceEligibilityEvaluator? get referenceEligibility; List<skir.ResourceId> get referenceOrigins; ReferenceCandidatePolicyRegistry get referencePolicies; EditOwner? Function(BindingReference reference)? get editOwnerFor; RenderedBindingFocusController? get bindingFocusController; Map<PresentationCollectionSourceId, PresentationCollectionSource> get collections; Map<BindingId, BindingReference> get aliases; Map<BindingId, PresentationInputAccess> get inputAccess; Map<BindingId, BindingReference?> get ownerBindings; Map<HeaderItemCommandId, List<ShortcutActivator>> get headerShortcuts; Set<(String, BindingReference?,)> get suppressedHeaders; Map<String, Widget> get presentationSlots; Object? get expansionIdentity; bool get enabled; bool get readOnly; String get historyNamespace; Set<PresentationId> get activePresentations;
/// Create a copy of PresentationRenderScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationRenderScopeCopyWith<PresentationRenderScope> get copyWith => _$PresentationRenderScopeCopyWithImpl<PresentationRenderScope>(this as PresentationRenderScope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PresentationRenderScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationRenderScope&&(identical(other.expressions, _this.expressions) || other.expressions == _this.expressions)&&(identical(other.registry, _this.registry) || other.registry == _this.registry)&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&(identical(other.setBinding, _this.setBinding) || other.setBinding == _this.setBinding)&&(identical(other.executeAction, _this.executeAction) || other.executeAction == _this.executeAction)&&(identical(other.resolvePresentation, _this.resolvePresentation) || other.resolvePresentation == _this.resolvePresentation)&&(identical(other.expansionStore, _this.expansionStore) || other.expansionStore == _this.expansionStore)&&(identical(other.startInteraction, _this.startInteraction) || other.startInteraction == _this.startInteraction)&&(identical(other.realmSearchSourceBuilder, _this.realmSearchSourceBuilder) || other.realmSearchSourceBuilder == _this.realmSearchSourceBuilder)&&(identical(other.referenceSearchSourceBuilder, _this.referenceSearchSourceBuilder) || other.referenceSearchSourceBuilder == _this.referenceSearchSourceBuilder)&&(identical(other.resolveReferences, _this.resolveReferences) || other.resolveReferences == _this.resolveReferences)&&(identical(other.referenceEligibility, _this.referenceEligibility) || other.referenceEligibility == _this.referenceEligibility)&&const DeepCollectionEquality().equals(other.referenceOrigins, _this.referenceOrigins)&&(identical(other.referencePolicies, _this.referencePolicies) || other.referencePolicies == _this.referencePolicies)&&(identical(other.editOwnerFor, _this.editOwnerFor) || other.editOwnerFor == _this.editOwnerFor)&&(identical(other.bindingFocusController, _this.bindingFocusController) || other.bindingFocusController == _this.bindingFocusController)&&const DeepCollectionEquality().equals(other.collections, _this.collections)&&const DeepCollectionEquality().equals(other.aliases, _this.aliases)&&const DeepCollectionEquality().equals(other.inputAccess, _this.inputAccess)&&const DeepCollectionEquality().equals(other.ownerBindings, _this.ownerBindings)&&const DeepCollectionEquality().equals(other.headerShortcuts, _this.headerShortcuts)&&const DeepCollectionEquality().equals(other.suppressedHeaders, _this.suppressedHeaders)&&const DeepCollectionEquality().equals(other.presentationSlots, _this.presentationSlots)&&const DeepCollectionEquality().equals(other.expansionIdentity, _this.expansionIdentity)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.readOnly, _this.readOnly) || other.readOnly == _this.readOnly)&&(identical(other.historyNamespace, _this.historyNamespace) || other.historyNamespace == _this.historyNamespace)&&const DeepCollectionEquality().equals(other.activePresentations, _this.activePresentations));
}


@override
int get hashCode {
  final _this = this as PresentationRenderScope;
  return Object.hashAll([runtimeType,_this.expressions,_this.registry,_this.budget,_this.setBinding,_this.executeAction,_this.resolvePresentation,_this.expansionStore,_this.startInteraction,_this.realmSearchSourceBuilder,_this.referenceSearchSourceBuilder,_this.resolveReferences,_this.referenceEligibility,const DeepCollectionEquality().hash(_this.referenceOrigins),_this.referencePolicies,_this.editOwnerFor,_this.bindingFocusController,const DeepCollectionEquality().hash(_this.collections),const DeepCollectionEquality().hash(_this.aliases),const DeepCollectionEquality().hash(_this.inputAccess),const DeepCollectionEquality().hash(_this.ownerBindings),const DeepCollectionEquality().hash(_this.headerShortcuts),const DeepCollectionEquality().hash(_this.suppressedHeaders),const DeepCollectionEquality().hash(_this.presentationSlots),const DeepCollectionEquality().hash(_this.expansionIdentity),_this.enabled,_this.readOnly,_this.historyNamespace,const DeepCollectionEquality().hash(_this.activePresentations)]);
}

@override
String toString() {
  final _this = this as PresentationRenderScope;
  return 'PresentationRenderScope(expressions: ${_this.expressions}, registry: ${_this.registry}, budget: ${_this.budget}, setBinding: ${_this.setBinding}, executeAction: ${_this.executeAction}, resolvePresentation: ${_this.resolvePresentation}, expansionStore: ${_this.expansionStore}, startInteraction: ${_this.startInteraction}, realmSearchSourceBuilder: ${_this.realmSearchSourceBuilder}, referenceSearchSourceBuilder: ${_this.referenceSearchSourceBuilder}, resolveReferences: ${_this.resolveReferences}, referenceEligibility: ${_this.referenceEligibility}, referenceOrigins: ${_this.referenceOrigins}, referencePolicies: ${_this.referencePolicies}, editOwnerFor: ${_this.editOwnerFor}, bindingFocusController: ${_this.bindingFocusController}, collections: ${_this.collections}, aliases: ${_this.aliases}, inputAccess: ${_this.inputAccess}, ownerBindings: ${_this.ownerBindings}, headerShortcuts: ${_this.headerShortcuts}, suppressedHeaders: ${_this.suppressedHeaders}, presentationSlots: ${_this.presentationSlots}, expansionIdentity: ${_this.expansionIdentity}, enabled: ${_this.enabled}, readOnly: ${_this.readOnly}, historyNamespace: ${_this.historyNamespace}, activePresentations: ${_this.activePresentations})';
}


}

/// @nodoc
abstract mixin class $PresentationRenderScopeCopyWith<$Res>  {
  factory $PresentationRenderScopeCopyWith(PresentationRenderScope value, $Res Function(PresentationRenderScope) _then) = _$PresentationRenderScopeCopyWithImpl;
@useResult
$Res call({
 ExpressionContext expressions, TypeRegistry registry, ExpressionBudget budget, BindingSetter setBinding, ActionExecutor executeAction, PresentationResolver resolvePresentation, HeaderExpansionStore expansionStore, EditorInteractionStarter? startInteraction, RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder, ReferenceSearchSourceBuilder? referenceSearchSourceBuilder, ReferenceResourceResolver? resolveReferences, ReferenceEligibilityEvaluator? referenceEligibility, List<skir.ResourceId> referenceOrigins, ReferenceCandidatePolicyRegistry referencePolicies, EditOwner? Function(BindingReference reference)? editOwnerFor, RenderedBindingFocusController? bindingFocusController, Map<PresentationCollectionSourceId, PresentationCollectionSource> collections, Map<BindingId, BindingReference> aliases, Map<BindingId, PresentationInputAccess> inputAccess, Map<BindingId, BindingReference?> ownerBindings, Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts, Set<(String, BindingReference?,)> suppressedHeaders, Map<String, Widget> presentationSlots, Object? expansionIdentity, bool enabled, bool readOnly, String historyNamespace, Set<PresentationId> activePresentations
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
@pragma('vm:prefer-inline') @override $Res call({Object? expressions = null,Object? registry = null,Object? budget = null,Object? setBinding = null,Object? executeAction = null,Object? resolvePresentation = null,Object? expansionStore = null,Object? startInteraction = freezed,Object? realmSearchSourceBuilder = freezed,Object? referenceSearchSourceBuilder = freezed,Object? resolveReferences = freezed,Object? referenceEligibility = freezed,Object? referenceOrigins = null,Object? referencePolicies = null,Object? editOwnerFor = freezed,Object? bindingFocusController = freezed,Object? collections = null,Object? aliases = null,Object? inputAccess = null,Object? ownerBindings = null,Object? headerShortcuts = null,Object? suppressedHeaders = null,Object? presentationSlots = null,Object? expansionIdentity = freezed,Object? enabled = null,Object? readOnly = null,Object? historyNamespace = null,Object? activePresentations = null,}) {
  return _then(PresentationRenderScope(
expressions: null == expressions ? _self.expressions : expressions // ignore: cast_nullable_to_non_nullable
as ExpressionContext,registry: null == registry ? _self.registry : registry // ignore: cast_nullable_to_non_nullable
as TypeRegistry,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as ExpressionBudget,setBinding: null == setBinding ? _self.setBinding : setBinding // ignore: cast_nullable_to_non_nullable
as BindingSetter,executeAction: null == executeAction ? _self.executeAction : executeAction // ignore: cast_nullable_to_non_nullable
as ActionExecutor,resolvePresentation: null == resolvePresentation ? _self.resolvePresentation : resolvePresentation // ignore: cast_nullable_to_non_nullable
as PresentationResolver,expansionStore: null == expansionStore ? _self.expansionStore : expansionStore // ignore: cast_nullable_to_non_nullable
as HeaderExpansionStore,startInteraction: freezed == startInteraction ? _self.startInteraction : startInteraction // ignore: cast_nullable_to_non_nullable
as EditorInteractionStarter?,realmSearchSourceBuilder: freezed == realmSearchSourceBuilder ? _self.realmSearchSourceBuilder : realmSearchSourceBuilder // ignore: cast_nullable_to_non_nullable
as RealmPresentationSearchSourceBuilder?,referenceSearchSourceBuilder: freezed == referenceSearchSourceBuilder ? _self.referenceSearchSourceBuilder : referenceSearchSourceBuilder // ignore: cast_nullable_to_non_nullable
as ReferenceSearchSourceBuilder?,resolveReferences: freezed == resolveReferences ? _self.resolveReferences : resolveReferences // ignore: cast_nullable_to_non_nullable
as ReferenceResourceResolver?,referenceEligibility: freezed == referenceEligibility ? _self.referenceEligibility : referenceEligibility // ignore: cast_nullable_to_non_nullable
as ReferenceEligibilityEvaluator?,referenceOrigins: null == referenceOrigins ? _self.referenceOrigins : referenceOrigins // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,referencePolicies: null == referencePolicies ? _self.referencePolicies : referencePolicies // ignore: cast_nullable_to_non_nullable
as ReferenceCandidatePolicyRegistry,editOwnerFor: freezed == editOwnerFor ? _self.editOwnerFor : editOwnerFor // ignore: cast_nullable_to_non_nullable
as EditOwner? Function(BindingReference reference)?,bindingFocusController: freezed == bindingFocusController ? _self.bindingFocusController : bindingFocusController // ignore: cast_nullable_to_non_nullable
as RenderedBindingFocusController?,collections: null == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, PresentationCollectionSource>,aliases: null == aliases ? _self.aliases : aliases // ignore: cast_nullable_to_non_nullable
as Map<BindingId, BindingReference>,inputAccess: null == inputAccess ? _self.inputAccess : inputAccess // ignore: cast_nullable_to_non_nullable
as Map<BindingId, PresentationInputAccess>,ownerBindings: null == ownerBindings ? _self.ownerBindings : ownerBindings // ignore: cast_nullable_to_non_nullable
as Map<BindingId, BindingReference?>,headerShortcuts: null == headerShortcuts ? _self.headerShortcuts : headerShortcuts // ignore: cast_nullable_to_non_nullable
as Map<HeaderItemCommandId, List<ShortcutActivator>>,suppressedHeaders: null == suppressedHeaders ? _self.suppressedHeaders : suppressedHeaders // ignore: cast_nullable_to_non_nullable
as Set<(String, BindingReference?,)>,presentationSlots: null == presentationSlots ? _self.presentationSlots : presentationSlots // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExpressionContext expressions,  TypeRegistry registry,  ExpressionBudget budget,  BindingSetter setBinding,  ActionExecutor executeAction,  PresentationResolver resolvePresentation,  HeaderExpansionStore expansionStore,  EditorInteractionStarter? startInteraction,  RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder,  ReferenceSearchSourceBuilder? referenceSearchSourceBuilder,  ReferenceResourceResolver? resolveReferences,  ReferenceEligibilityEvaluator? referenceEligibility,  List<skir.ResourceId> referenceOrigins,  ReferenceCandidatePolicyRegistry referencePolicies,  EditOwner? Function(BindingReference reference)? editOwnerFor,  RenderedBindingFocusController? bindingFocusController,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections,  Map<BindingId, BindingReference> aliases,  Map<BindingId, PresentationInputAccess> inputAccess,  Map<BindingId, BindingReference?> ownerBindings,  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts,  Set<(String, BindingReference?,)> suppressedHeaders,  Map<String, Widget> presentationSlots,  Object? expansionIdentity,  bool enabled,  bool readOnly,  String historyNamespace,  Set<PresentationId> activePresentations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationRenderScope() when $default != null:
return $default(_that.expressions,_that.registry,_that.budget,_that.setBinding,_that.executeAction,_that.resolvePresentation,_that.expansionStore,_that.startInteraction,_that.realmSearchSourceBuilder,_that.referenceSearchSourceBuilder,_that.resolveReferences,_that.referenceEligibility,_that.referenceOrigins,_that.referencePolicies,_that.editOwnerFor,_that.bindingFocusController,_that.collections,_that.aliases,_that.inputAccess,_that.ownerBindings,_that.headerShortcuts,_that.suppressedHeaders,_that.presentationSlots,_that.expansionIdentity,_that.enabled,_that.readOnly,_that.historyNamespace,_that.activePresentations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExpressionContext expressions,  TypeRegistry registry,  ExpressionBudget budget,  BindingSetter setBinding,  ActionExecutor executeAction,  PresentationResolver resolvePresentation,  HeaderExpansionStore expansionStore,  EditorInteractionStarter? startInteraction,  RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder,  ReferenceSearchSourceBuilder? referenceSearchSourceBuilder,  ReferenceResourceResolver? resolveReferences,  ReferenceEligibilityEvaluator? referenceEligibility,  List<skir.ResourceId> referenceOrigins,  ReferenceCandidatePolicyRegistry referencePolicies,  EditOwner? Function(BindingReference reference)? editOwnerFor,  RenderedBindingFocusController? bindingFocusController,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections,  Map<BindingId, BindingReference> aliases,  Map<BindingId, PresentationInputAccess> inputAccess,  Map<BindingId, BindingReference?> ownerBindings,  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts,  Set<(String, BindingReference?,)> suppressedHeaders,  Map<String, Widget> presentationSlots,  Object? expansionIdentity,  bool enabled,  bool readOnly,  String historyNamespace,  Set<PresentationId> activePresentations)  $default,) {final _that = this;
switch (_that) {
case _PresentationRenderScope():
return $default(_that.expressions,_that.registry,_that.budget,_that.setBinding,_that.executeAction,_that.resolvePresentation,_that.expansionStore,_that.startInteraction,_that.realmSearchSourceBuilder,_that.referenceSearchSourceBuilder,_that.resolveReferences,_that.referenceEligibility,_that.referenceOrigins,_that.referencePolicies,_that.editOwnerFor,_that.bindingFocusController,_that.collections,_that.aliases,_that.inputAccess,_that.ownerBindings,_that.headerShortcuts,_that.suppressedHeaders,_that.presentationSlots,_that.expansionIdentity,_that.enabled,_that.readOnly,_that.historyNamespace,_that.activePresentations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExpressionContext expressions,  TypeRegistry registry,  ExpressionBudget budget,  BindingSetter setBinding,  ActionExecutor executeAction,  PresentationResolver resolvePresentation,  HeaderExpansionStore expansionStore,  EditorInteractionStarter? startInteraction,  RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder,  ReferenceSearchSourceBuilder? referenceSearchSourceBuilder,  ReferenceResourceResolver? resolveReferences,  ReferenceEligibilityEvaluator? referenceEligibility,  List<skir.ResourceId> referenceOrigins,  ReferenceCandidatePolicyRegistry referencePolicies,  EditOwner? Function(BindingReference reference)? editOwnerFor,  RenderedBindingFocusController? bindingFocusController,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections,  Map<BindingId, BindingReference> aliases,  Map<BindingId, PresentationInputAccess> inputAccess,  Map<BindingId, BindingReference?> ownerBindings,  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts,  Set<(String, BindingReference?,)> suppressedHeaders,  Map<String, Widget> presentationSlots,  Object? expansionIdentity,  bool enabled,  bool readOnly,  String historyNamespace,  Set<PresentationId> activePresentations)?  $default,) {final _that = this;
switch (_that) {
case _PresentationRenderScope() when $default != null:
return $default(_that.expressions,_that.registry,_that.budget,_that.setBinding,_that.executeAction,_that.resolvePresentation,_that.expansionStore,_that.startInteraction,_that.realmSearchSourceBuilder,_that.referenceSearchSourceBuilder,_that.resolveReferences,_that.referenceEligibility,_that.referenceOrigins,_that.referencePolicies,_that.editOwnerFor,_that.bindingFocusController,_that.collections,_that.aliases,_that.inputAccess,_that.ownerBindings,_that.headerShortcuts,_that.suppressedHeaders,_that.presentationSlots,_that.expansionIdentity,_that.enabled,_that.readOnly,_that.historyNamespace,_that.activePresentations);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationRenderScope extends PresentationRenderScope {
  const _PresentationRenderScope({required this.expressions, required this.registry, required this.budget, required this.setBinding, required this.executeAction, required this.resolvePresentation, required this.expansionStore, this.startInteraction, this.realmSearchSourceBuilder, this.referenceSearchSourceBuilder, this.resolveReferences, this.referenceEligibility,  List<skir.ResourceId> referenceOrigins = const [], this.referencePolicies = const ReferenceCandidatePolicyRegistry(), this.editOwnerFor, this.bindingFocusController,  Map<PresentationCollectionSourceId, PresentationCollectionSource> collections = const {},  Map<BindingId, BindingReference> aliases = const {},  Map<BindingId, PresentationInputAccess> inputAccess = const {},  Map<BindingId, BindingReference?> ownerBindings = const {},  Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts = const {},  Set<(String, BindingReference?,)> suppressedHeaders = const {},  Map<String, Widget> presentationSlots = const {}, this.expansionIdentity, this.enabled = true, this.readOnly = false, this.historyNamespace = "local",  Set<PresentationId> activePresentations = const {}}): _referenceOrigins = referenceOrigins,_collections = collections,_aliases = aliases,_inputAccess = inputAccess,_ownerBindings = ownerBindings,_headerShortcuts = headerShortcuts,_suppressedHeaders = suppressedHeaders,_presentationSlots = presentationSlots,_activePresentations = activePresentations,super._();
  

@override final  ExpressionContext expressions;
@override final  TypeRegistry registry;
@override final  ExpressionBudget budget;
@override final  BindingSetter setBinding;
@override final  ActionExecutor executeAction;
@override final  PresentationResolver resolvePresentation;
@override final  HeaderExpansionStore expansionStore;
@override final  EditorInteractionStarter? startInteraction;
@override final  RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder;
@override final  ReferenceSearchSourceBuilder? referenceSearchSourceBuilder;
@override final  ReferenceResourceResolver? resolveReferences;
@override final  ReferenceEligibilityEvaluator? referenceEligibility;
 final  List<skir.ResourceId> _referenceOrigins;
@override@JsonKey() List<skir.ResourceId> get referenceOrigins {
  if (_referenceOrigins is EqualUnmodifiableListView) return _referenceOrigins;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_referenceOrigins);
}

@override@JsonKey() final  ReferenceCandidatePolicyRegistry referencePolicies;
@override final  EditOwner? Function(BindingReference reference)? editOwnerFor;
@override final  RenderedBindingFocusController? bindingFocusController;
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

 final  Map<BindingId, PresentationInputAccess> _inputAccess;
@override@JsonKey() Map<BindingId, PresentationInputAccess> get inputAccess {
  if (_inputAccess is EqualUnmodifiableMapView) return _inputAccess;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_inputAccess);
}

 final  Map<BindingId, BindingReference?> _ownerBindings;
@override@JsonKey() Map<BindingId, BindingReference?> get ownerBindings {
  if (_ownerBindings is EqualUnmodifiableMapView) return _ownerBindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ownerBindings);
}

 final  Map<HeaderItemCommandId, List<ShortcutActivator>> _headerShortcuts;
@override@JsonKey() Map<HeaderItemCommandId, List<ShortcutActivator>> get headerShortcuts {
  if (_headerShortcuts is EqualUnmodifiableMapView) return _headerShortcuts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headerShortcuts);
}

 final  Set<(String, BindingReference?,)> _suppressedHeaders;
@override@JsonKey() Set<(String, BindingReference?,)> get suppressedHeaders {
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationRenderScope&&(identical(other.expressions, expressions) || other.expressions == expressions)&&(identical(other.registry, registry) || other.registry == registry)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.setBinding, setBinding) || other.setBinding == setBinding)&&(identical(other.executeAction, executeAction) || other.executeAction == executeAction)&&(identical(other.resolvePresentation, resolvePresentation) || other.resolvePresentation == resolvePresentation)&&(identical(other.expansionStore, expansionStore) || other.expansionStore == expansionStore)&&(identical(other.startInteraction, startInteraction) || other.startInteraction == startInteraction)&&(identical(other.realmSearchSourceBuilder, realmSearchSourceBuilder) || other.realmSearchSourceBuilder == realmSearchSourceBuilder)&&(identical(other.referenceSearchSourceBuilder, referenceSearchSourceBuilder) || other.referenceSearchSourceBuilder == referenceSearchSourceBuilder)&&(identical(other.resolveReferences, resolveReferences) || other.resolveReferences == resolveReferences)&&(identical(other.referenceEligibility, referenceEligibility) || other.referenceEligibility == referenceEligibility)&&const DeepCollectionEquality().equals(other.referenceOrigins, _referenceOrigins)&&(identical(other.referencePolicies, referencePolicies) || other.referencePolicies == referencePolicies)&&(identical(other.editOwnerFor, editOwnerFor) || other.editOwnerFor == editOwnerFor)&&(identical(other.bindingFocusController, bindingFocusController) || other.bindingFocusController == bindingFocusController)&&const DeepCollectionEquality().equals(other.collections, _collections)&&const DeepCollectionEquality().equals(other.aliases, _aliases)&&const DeepCollectionEquality().equals(other.inputAccess, _inputAccess)&&const DeepCollectionEquality().equals(other.ownerBindings, _ownerBindings)&&const DeepCollectionEquality().equals(other.headerShortcuts, _headerShortcuts)&&const DeepCollectionEquality().equals(other.suppressedHeaders, _suppressedHeaders)&&const DeepCollectionEquality().equals(other.presentationSlots, _presentationSlots)&&const DeepCollectionEquality().equals(other.expansionIdentity, expansionIdentity)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.historyNamespace, historyNamespace) || other.historyNamespace == historyNamespace)&&const DeepCollectionEquality().equals(other.activePresentations, _activePresentations));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,expressions,registry,budget,setBinding,executeAction,resolvePresentation,expansionStore,startInteraction,realmSearchSourceBuilder,referenceSearchSourceBuilder,resolveReferences,referenceEligibility,const DeepCollectionEquality().hash(_referenceOrigins),referencePolicies,editOwnerFor,bindingFocusController,const DeepCollectionEquality().hash(_collections),const DeepCollectionEquality().hash(_aliases),const DeepCollectionEquality().hash(_inputAccess),const DeepCollectionEquality().hash(_ownerBindings),const DeepCollectionEquality().hash(_headerShortcuts),const DeepCollectionEquality().hash(_suppressedHeaders),const DeepCollectionEquality().hash(_presentationSlots),const DeepCollectionEquality().hash(expansionIdentity),enabled,readOnly,historyNamespace,const DeepCollectionEquality().hash(_activePresentations)]);
}

@override
String toString() {
    return 'PresentationRenderScope(expressions: $expressions, registry: $registry, budget: $budget, setBinding: $setBinding, executeAction: $executeAction, resolvePresentation: $resolvePresentation, expansionStore: $expansionStore, startInteraction: $startInteraction, realmSearchSourceBuilder: $realmSearchSourceBuilder, referenceSearchSourceBuilder: $referenceSearchSourceBuilder, resolveReferences: $resolveReferences, referenceEligibility: $referenceEligibility, referenceOrigins: $referenceOrigins, referencePolicies: $referencePolicies, editOwnerFor: $editOwnerFor, bindingFocusController: $bindingFocusController, collections: $collections, aliases: $aliases, inputAccess: $inputAccess, ownerBindings: $ownerBindings, headerShortcuts: $headerShortcuts, suppressedHeaders: $suppressedHeaders, presentationSlots: $presentationSlots, expansionIdentity: $expansionIdentity, enabled: $enabled, readOnly: $readOnly, historyNamespace: $historyNamespace, activePresentations: $activePresentations)';
}


}

/// @nodoc
abstract mixin class _$PresentationRenderScopeCopyWith<$Res> implements $PresentationRenderScopeCopyWith<$Res> {
  factory _$PresentationRenderScopeCopyWith(_PresentationRenderScope value, $Res Function(_PresentationRenderScope) _then) = __$PresentationRenderScopeCopyWithImpl;
@override @useResult
$Res call({
 ExpressionContext expressions, TypeRegistry registry, ExpressionBudget budget, BindingSetter setBinding, ActionExecutor executeAction, PresentationResolver resolvePresentation, HeaderExpansionStore expansionStore, EditorInteractionStarter? startInteraction, RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder, ReferenceSearchSourceBuilder? referenceSearchSourceBuilder, ReferenceResourceResolver? resolveReferences, ReferenceEligibilityEvaluator? referenceEligibility, List<skir.ResourceId> referenceOrigins, ReferenceCandidatePolicyRegistry referencePolicies, EditOwner? Function(BindingReference reference)? editOwnerFor, RenderedBindingFocusController? bindingFocusController, Map<PresentationCollectionSourceId, PresentationCollectionSource> collections, Map<BindingId, BindingReference> aliases, Map<BindingId, PresentationInputAccess> inputAccess, Map<BindingId, BindingReference?> ownerBindings, Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts, Set<(String, BindingReference?,)> suppressedHeaders, Map<String, Widget> presentationSlots, Object? expansionIdentity, bool enabled, bool readOnly, String historyNamespace, Set<PresentationId> activePresentations
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
@override @pragma('vm:prefer-inline') $Res call({Object? expressions = null,Object? registry = null,Object? budget = null,Object? setBinding = null,Object? executeAction = null,Object? resolvePresentation = null,Object? expansionStore = null,Object? startInteraction = freezed,Object? realmSearchSourceBuilder = freezed,Object? referenceSearchSourceBuilder = freezed,Object? resolveReferences = freezed,Object? referenceEligibility = freezed,Object? referenceOrigins = null,Object? referencePolicies = null,Object? editOwnerFor = freezed,Object? bindingFocusController = freezed,Object? collections = null,Object? aliases = null,Object? inputAccess = null,Object? ownerBindings = null,Object? headerShortcuts = null,Object? suppressedHeaders = null,Object? presentationSlots = null,Object? expansionIdentity = freezed,Object? enabled = null,Object? readOnly = null,Object? historyNamespace = null,Object? activePresentations = null,}) {
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
as RealmPresentationSearchSourceBuilder?,referenceSearchSourceBuilder: freezed == referenceSearchSourceBuilder ? _self.referenceSearchSourceBuilder : referenceSearchSourceBuilder // ignore: cast_nullable_to_non_nullable
as ReferenceSearchSourceBuilder?,resolveReferences: freezed == resolveReferences ? _self.resolveReferences : resolveReferences // ignore: cast_nullable_to_non_nullable
as ReferenceResourceResolver?,referenceEligibility: freezed == referenceEligibility ? _self.referenceEligibility : referenceEligibility // ignore: cast_nullable_to_non_nullable
as ReferenceEligibilityEvaluator?,referenceOrigins: null == referenceOrigins ? _self._referenceOrigins : referenceOrigins // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,referencePolicies: null == referencePolicies ? _self.referencePolicies : referencePolicies // ignore: cast_nullable_to_non_nullable
as ReferenceCandidatePolicyRegistry,editOwnerFor: freezed == editOwnerFor ? _self.editOwnerFor : editOwnerFor // ignore: cast_nullable_to_non_nullable
as EditOwner? Function(BindingReference reference)?,bindingFocusController: freezed == bindingFocusController ? _self.bindingFocusController : bindingFocusController // ignore: cast_nullable_to_non_nullable
as RenderedBindingFocusController?,collections: null == collections ? _self._collections : collections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, PresentationCollectionSource>,aliases: null == aliases ? _self._aliases : aliases // ignore: cast_nullable_to_non_nullable
as Map<BindingId, BindingReference>,inputAccess: null == inputAccess ? _self._inputAccess : inputAccess // ignore: cast_nullable_to_non_nullable
as Map<BindingId, PresentationInputAccess>,ownerBindings: null == ownerBindings ? _self._ownerBindings : ownerBindings // ignore: cast_nullable_to_non_nullable
as Map<BindingId, BindingReference?>,headerShortcuts: null == headerShortcuts ? _self._headerShortcuts : headerShortcuts // ignore: cast_nullable_to_non_nullable
as Map<HeaderItemCommandId, List<ShortcutActivator>>,suppressedHeaders: null == suppressedHeaders ? _self._suppressedHeaders : suppressedHeaders // ignore: cast_nullable_to_non_nullable
as Set<(String, BindingReference?,)>,presentationSlots: null == presentationSlots ? _self._presentationSlots : presentationSlots // ignore: cast_nullable_to_non_nullable
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
