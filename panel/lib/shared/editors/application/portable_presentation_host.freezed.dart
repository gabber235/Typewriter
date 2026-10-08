// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_presentation_host.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortablePresentationBindingSchema {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationBindingSchema);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortablePresentationBindingSchema()';
}


}

/// @nodoc
class $PortablePresentationBindingSchemaCopyWith<$Res>  {
$PortablePresentationBindingSchemaCopyWith(PortablePresentationBindingSchema _, $Res Function(PortablePresentationBindingSchema) __);
}


/// Adds pattern-matching-related methods to [PortablePresentationBindingSchema].
extension PortablePresentationBindingSchemaPatterns on PortablePresentationBindingSchema {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CompletePortablePresentationBinding value)?  complete,TResult Function( PartialPortablePresentationBinding value)?  partial,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CompletePortablePresentationBinding() when complete != null:
return complete(_that);case PartialPortablePresentationBinding() when partial != null:
return partial(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CompletePortablePresentationBinding value)  complete,required TResult Function( PartialPortablePresentationBinding value)  partial,}){
final _that = this;
switch (_that) {
case CompletePortablePresentationBinding():
return complete(_that);case PartialPortablePresentationBinding():
return partial(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CompletePortablePresentationBinding value)?  complete,TResult? Function( PartialPortablePresentationBinding value)?  partial,}){
final _that = this;
switch (_that) {
case CompletePortablePresentationBinding() when complete != null:
return complete(_that);case PartialPortablePresentationBinding() when partial != null:
return partial(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.TypeUse use)?  complete,TResult Function( skir.TypeSelection selection)?  partial,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CompletePortablePresentationBinding() when complete != null:
return complete(_that.use);case PartialPortablePresentationBinding() when partial != null:
return partial(_that.selection);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.TypeUse use)  complete,required TResult Function( skir.TypeSelection selection)  partial,}) {final _that = this;
switch (_that) {
case CompletePortablePresentationBinding():
return complete(_that.use);case PartialPortablePresentationBinding():
return partial(_that.selection);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.TypeUse use)?  complete,TResult? Function( skir.TypeSelection selection)?  partial,}) {final _that = this;
switch (_that) {
case CompletePortablePresentationBinding() when complete != null:
return complete(_that.use);case PartialPortablePresentationBinding() when partial != null:
return partial(_that.selection);case _:
  return null;

}
}

}

/// @nodoc


class CompletePortablePresentationBinding implements PortablePresentationBindingSchema {
  const CompletePortablePresentationBinding(this.use);
  

 final  skir.TypeUse use;

/// Create a copy of PortablePresentationBindingSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletePortablePresentationBindingCopyWith<CompletePortablePresentationBinding> get copyWith => _$CompletePortablePresentationBindingCopyWithImpl<CompletePortablePresentationBinding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletePortablePresentationBinding&&(identical(other.use, use) || other.use == use));
}


@override
int get hashCode {
    return Object.hash(runtimeType,use);
}

@override
String toString() {
    return 'PortablePresentationBindingSchema.complete(use: $use)';
}


}

/// @nodoc
abstract mixin class $CompletePortablePresentationBindingCopyWith<$Res> implements $PortablePresentationBindingSchemaCopyWith<$Res> {
  factory $CompletePortablePresentationBindingCopyWith(CompletePortablePresentationBinding value, $Res Function(CompletePortablePresentationBinding) _then) = _$CompletePortablePresentationBindingCopyWithImpl;
@useResult
$Res call({
 skir.TypeUse use
});




}
/// @nodoc
class _$CompletePortablePresentationBindingCopyWithImpl<$Res>
    implements $CompletePortablePresentationBindingCopyWith<$Res> {
  _$CompletePortablePresentationBindingCopyWithImpl(this._self, this._then);

  final CompletePortablePresentationBinding _self;
  final $Res Function(CompletePortablePresentationBinding) _then;

/// Create a copy of PortablePresentationBindingSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? use = null,}) {
  return _then(CompletePortablePresentationBinding(
null == use ? _self.use : use // ignore: cast_nullable_to_non_nullable
as skir.TypeUse,
  ));
}


}

/// @nodoc


class PartialPortablePresentationBinding implements PortablePresentationBindingSchema {
  const PartialPortablePresentationBinding(this.selection);
  

 final  skir.TypeSelection selection;

/// Create a copy of PortablePresentationBindingSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartialPortablePresentationBindingCopyWith<PartialPortablePresentationBinding> get copyWith => _$PartialPortablePresentationBindingCopyWithImpl<PartialPortablePresentationBinding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PartialPortablePresentationBinding&&(identical(other.selection, selection) || other.selection == selection));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selection);
}

@override
String toString() {
    return 'PortablePresentationBindingSchema.partial(selection: $selection)';
}


}

/// @nodoc
abstract mixin class $PartialPortablePresentationBindingCopyWith<$Res> implements $PortablePresentationBindingSchemaCopyWith<$Res> {
  factory $PartialPortablePresentationBindingCopyWith(PartialPortablePresentationBinding value, $Res Function(PartialPortablePresentationBinding) _then) = _$PartialPortablePresentationBindingCopyWithImpl;
@useResult
$Res call({
 skir.TypeSelection selection
});




}
/// @nodoc
class _$PartialPortablePresentationBindingCopyWithImpl<$Res>
    implements $PartialPortablePresentationBindingCopyWith<$Res> {
  _$PartialPortablePresentationBindingCopyWithImpl(this._self, this._then);

  final PartialPortablePresentationBinding _self;
  final $Res Function(PartialPortablePresentationBinding) _then;

/// Create a copy of PortablePresentationBindingSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? selection = null,}) {
  return _then(PartialPortablePresentationBinding(
null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,
  ));
}


}

/// @nodoc
mixin _$PortablePresentationBinding {

 PortablePresentationBindingSchema get schema; skir.DataValue get value; bool get editable; skir.ValueLocation? get location;
/// Create a copy of PortablePresentationBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationBindingCopyWith<PortablePresentationBinding> get copyWith => _$PortablePresentationBindingCopyWithImpl<PortablePresentationBinding>(this as PortablePresentationBinding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationBinding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationBinding&&(identical(other.schema, _this.schema) || other.schema == _this.schema)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.editable, _this.editable) || other.editable == _this.editable)&&(identical(other.location, _this.location) || other.location == _this.location));
}


@override
int get hashCode {
  final _this = this as PortablePresentationBinding;
  return Object.hash(runtimeType,_this.schema,_this.value,_this.editable,_this.location);
}

@override
String toString() {
  final _this = this as PortablePresentationBinding;
  return 'PortablePresentationBinding(schema: ${_this.schema}, value: ${_this.value}, editable: ${_this.editable}, location: ${_this.location})';
}


}

/// @nodoc
abstract mixin class $PortablePresentationBindingCopyWith<$Res>  {
  factory $PortablePresentationBindingCopyWith(PortablePresentationBinding value, $Res Function(PortablePresentationBinding) _then) = _$PortablePresentationBindingCopyWithImpl;
@useResult
$Res call({
 PortablePresentationBindingSchema schema, skir.DataValue value, bool editable, skir.ValueLocation? location
});


$PortablePresentationBindingSchemaCopyWith<$Res> get schema;

}
/// @nodoc
class _$PortablePresentationBindingCopyWithImpl<$Res>
    implements $PortablePresentationBindingCopyWith<$Res> {
  _$PortablePresentationBindingCopyWithImpl(this._self, this._then);

  final PortablePresentationBinding _self;
  final $Res Function(PortablePresentationBinding) _then;

/// Create a copy of PortablePresentationBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schema = null,Object? value = null,Object? editable = null,Object? location = freezed,}) {
  return _then(PortablePresentationBinding(
schema: null == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as PortablePresentationBindingSchema,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,editable: null == editable ? _self.editable : editable // ignore: cast_nullable_to_non_nullable
as bool,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,
  ));
}
/// Create a copy of PortablePresentationBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationBindingSchemaCopyWith<$Res> get schema {
  
  return $PortablePresentationBindingSchemaCopyWith<$Res>(_self.schema, (value) {
    return _then(_self.copyWith(schema: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortablePresentationBinding].
extension PortablePresentationBindingPatterns on PortablePresentationBinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortablePresentationBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortablePresentationBinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortablePresentationBinding value)  $default,){
final _that = this;
switch (_that) {
case _PortablePresentationBinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortablePresentationBinding value)?  $default,){
final _that = this;
switch (_that) {
case _PortablePresentationBinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortablePresentationBindingSchema schema,  skir.DataValue value,  bool editable,  skir.ValueLocation? location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortablePresentationBinding() when $default != null:
return $default(_that.schema,_that.value,_that.editable,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortablePresentationBindingSchema schema,  skir.DataValue value,  bool editable,  skir.ValueLocation? location)  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationBinding():
return $default(_that.schema,_that.value,_that.editable,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortablePresentationBindingSchema schema,  skir.DataValue value,  bool editable,  skir.ValueLocation? location)?  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationBinding() when $default != null:
return $default(_that.schema,_that.value,_that.editable,_that.location);case _:
  return null;

}
}

}

/// @nodoc


class _PortablePresentationBinding implements PortablePresentationBinding {
  const _PortablePresentationBinding({required this.schema, required this.value, this.editable = false, this.location});
  

@override final  PortablePresentationBindingSchema schema;
@override final  skir.DataValue value;
@override@JsonKey() final  bool editable;
@override final  skir.ValueLocation? location;

/// Create a copy of PortablePresentationBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePresentationBindingCopyWith<_PortablePresentationBinding> get copyWith => __$PortablePresentationBindingCopyWithImpl<_PortablePresentationBinding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationBinding&&(identical(other.schema, schema) || other.schema == schema)&&(identical(other.value, value) || other.value == value)&&(identical(other.editable, editable) || other.editable == editable)&&(identical(other.location, location) || other.location == location));
}


@override
int get hashCode {
    return Object.hash(runtimeType,schema,value,editable,location);
}

@override
String toString() {
    return 'PortablePresentationBinding(schema: $schema, value: $value, editable: $editable, location: $location)';
}


}

/// @nodoc
abstract mixin class _$PortablePresentationBindingCopyWith<$Res> implements $PortablePresentationBindingCopyWith<$Res> {
  factory _$PortablePresentationBindingCopyWith(_PortablePresentationBinding value, $Res Function(_PortablePresentationBinding) _then) = __$PortablePresentationBindingCopyWithImpl;
@override @useResult
$Res call({
 PortablePresentationBindingSchema schema, skir.DataValue value, bool editable, skir.ValueLocation? location
});


@override $PortablePresentationBindingSchemaCopyWith<$Res> get schema;

}
/// @nodoc
class __$PortablePresentationBindingCopyWithImpl<$Res>
    implements _$PortablePresentationBindingCopyWith<$Res> {
  __$PortablePresentationBindingCopyWithImpl(this._self, this._then);

  final _PortablePresentationBinding _self;
  final $Res Function(_PortablePresentationBinding) _then;

/// Create a copy of PortablePresentationBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schema = null,Object? value = null,Object? editable = null,Object? location = freezed,}) {
  return _then(_PortablePresentationBinding(
schema: null == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as PortablePresentationBindingSchema,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,editable: null == editable ? _self.editable : editable // ignore: cast_nullable_to_non_nullable
as bool,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,
  ));
}

/// Create a copy of PortablePresentationBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationBindingSchemaCopyWith<$Res> get schema {
  
  return $PortablePresentationBindingSchemaCopyWith<$Res>(_self.schema, (value) {
    return _then(_self.copyWith(schema: value));
  });
}
}

/// @nodoc
mixin _$PortablePresentationDocument {

 CheckedEditorCatalog get catalog; skir.PresentationNode get root; Map<skir.ExpressionBindingId, PortablePresentationBinding> get bindings; skir.EvaluationBudget get budget; skir.PresentationRole? get role; skir.PresentationMaterial? get material; Set<skir.PresentationId> get activePresentations; Map<String, skir.PresentationNode> get slots;



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationDocument&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.root, _this.root) || other.root == _this.root)&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.material, _this.material) || other.material == _this.material)&&const DeepCollectionEquality().equals(other.activePresentations, _this.activePresentations)&&const DeepCollectionEquality().equals(other.slots, _this.slots));
}


@override
int get hashCode {
  final _this = this as PortablePresentationDocument;
  return Object.hash(runtimeType,_this.catalog,_this.root,const DeepCollectionEquality().hash(_this.bindings),_this.budget,_this.role,_this.material,const DeepCollectionEquality().hash(_this.activePresentations),const DeepCollectionEquality().hash(_this.slots));
}

@override
String toString() {
  final _this = this as PortablePresentationDocument;
  return 'PortablePresentationDocument(catalog: ${_this.catalog}, root: ${_this.root}, bindings: ${_this.bindings}, budget: ${_this.budget}, role: ${_this.role}, material: ${_this.material}, activePresentations: ${_this.activePresentations}, slots: ${_this.slots})';
}


}





/// @nodoc


class _PortablePresentationDocument extends PortablePresentationDocument {
  const _PortablePresentationDocument({required this.catalog, required this.root, required  Map<skir.ExpressionBindingId, PortablePresentationBinding> bindings, required this.budget, required this.role, required this.material, required  Set<skir.PresentationId> activePresentations, required  Map<String, skir.PresentationNode> slots}): _bindings = bindings,_activePresentations = activePresentations,_slots = slots,super._();
  

@override final  CheckedEditorCatalog catalog;
@override final  skir.PresentationNode root;
 final  Map<skir.ExpressionBindingId, PortablePresentationBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortablePresentationBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;
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





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationDocument&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.root, root) || other.root == root)&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.role, role) || other.role == role)&&(identical(other.material, material) || other.material == material)&&const DeepCollectionEquality().equals(other.activePresentations, _activePresentations)&&const DeepCollectionEquality().equals(other.slots, _slots));
}


@override
int get hashCode {
    return Object.hash(runtimeType,catalog,root,const DeepCollectionEquality().hash(_bindings),budget,role,material,const DeepCollectionEquality().hash(_activePresentations),const DeepCollectionEquality().hash(_slots));
}

@override
String toString() {
    return 'PortablePresentationDocument._value(catalog: $catalog, root: $root, bindings: $bindings, budget: $budget, role: $role, material: $material, activePresentations: $activePresentations, slots: $slots)';
}


}




/// @nodoc
mixin _$PortablePresentationCapabilities {

 Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? get invokeCommand; Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? get watchSearch; Future<void> Function()? get reload; Future<void> Function()? get commit; ValueChanged<skir.ResourceId>? get openResource; Future<skir.PreparedCreation> Function(skir.InitializationRequest request)? get prepareCreation;
/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationCapabilitiesCopyWith<PortablePresentationCapabilities> get copyWith => _$PortablePresentationCapabilitiesCopyWithImpl<PortablePresentationCapabilities>(this as PortablePresentationCapabilities, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationCapabilities;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationCapabilities&&(identical(other.invokeCommand, _this.invokeCommand) || other.invokeCommand == _this.invokeCommand)&&(identical(other.watchSearch, _this.watchSearch) || other.watchSearch == _this.watchSearch)&&(identical(other.reload, _this.reload) || other.reload == _this.reload)&&(identical(other.commit, _this.commit) || other.commit == _this.commit)&&(identical(other.openResource, _this.openResource) || other.openResource == _this.openResource)&&(identical(other.prepareCreation, _this.prepareCreation) || other.prepareCreation == _this.prepareCreation));
}


@override
int get hashCode {
  final _this = this as PortablePresentationCapabilities;
  return Object.hash(runtimeType,_this.invokeCommand,_this.watchSearch,_this.reload,_this.commit,_this.openResource,_this.prepareCreation);
}

@override
String toString() {
  final _this = this as PortablePresentationCapabilities;
  return 'PortablePresentationCapabilities(invokeCommand: ${_this.invokeCommand}, watchSearch: ${_this.watchSearch}, reload: ${_this.reload}, commit: ${_this.commit}, openResource: ${_this.openResource}, prepareCreation: ${_this.prepareCreation})';
}


}

/// @nodoc
abstract mixin class $PortablePresentationCapabilitiesCopyWith<$Res>  {
  factory $PortablePresentationCapabilitiesCopyWith(PortablePresentationCapabilities value, $Res Function(PortablePresentationCapabilities) _then) = _$PortablePresentationCapabilitiesCopyWithImpl;
@useResult
$Res call({
 Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, Future<void> Function()? reload, Future<void> Function()? commit, ValueChanged<skir.ResourceId>? openResource, Future<skir.PreparedCreation> Function(skir.InitializationRequest request)? prepareCreation
});




}
/// @nodoc
class _$PortablePresentationCapabilitiesCopyWithImpl<$Res>
    implements $PortablePresentationCapabilitiesCopyWith<$Res> {
  _$PortablePresentationCapabilitiesCopyWithImpl(this._self, this._then);

  final PortablePresentationCapabilities _self;
  final $Res Function(PortablePresentationCapabilities) _then;

/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? invokeCommand = freezed,Object? watchSearch = freezed,Object? reload = freezed,Object? commit = freezed,Object? openResource = freezed,Object? prepareCreation = freezed,}) {
  return _then(PortablePresentationCapabilities(
invokeCommand: freezed == invokeCommand ? _self.invokeCommand : invokeCommand // ignore: cast_nullable_to_non_nullable
as Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)?,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reload: freezed == reload ? _self.reload : reload // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,commit: freezed == commit ? _self.commit : commit // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,prepareCreation: freezed == prepareCreation ? _self.prepareCreation : prepareCreation // ignore: cast_nullable_to_non_nullable
as Future<skir.PreparedCreation> Function(skir.InitializationRequest request)?,
  ));
}

}


/// Adds pattern-matching-related methods to [PortablePresentationCapabilities].
extension PortablePresentationCapabilitiesPatterns on PortablePresentationCapabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortablePresentationCapabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortablePresentationCapabilities() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortablePresentationCapabilities value)  $default,){
final _that = this;
switch (_that) {
case _PortablePresentationCapabilities():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortablePresentationCapabilities value)?  $default,){
final _that = this;
switch (_that) {
case _PortablePresentationCapabilities() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand,  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch,  Future<void> Function()? reload,  Future<void> Function()? commit,  ValueChanged<skir.ResourceId>? openResource,  Future<skir.PreparedCreation> Function(skir.InitializationRequest request)? prepareCreation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortablePresentationCapabilities() when $default != null:
return $default(_that.invokeCommand,_that.watchSearch,_that.reload,_that.commit,_that.openResource,_that.prepareCreation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand,  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch,  Future<void> Function()? reload,  Future<void> Function()? commit,  ValueChanged<skir.ResourceId>? openResource,  Future<skir.PreparedCreation> Function(skir.InitializationRequest request)? prepareCreation)  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationCapabilities():
return $default(_that.invokeCommand,_that.watchSearch,_that.reload,_that.commit,_that.openResource,_that.prepareCreation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand,  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch,  Future<void> Function()? reload,  Future<void> Function()? commit,  ValueChanged<skir.ResourceId>? openResource,  Future<skir.PreparedCreation> Function(skir.InitializationRequest request)? prepareCreation)?  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationCapabilities() when $default != null:
return $default(_that.invokeCommand,_that.watchSearch,_that.reload,_that.commit,_that.openResource,_that.prepareCreation);case _:
  return null;

}
}

}

/// @nodoc


class _PortablePresentationCapabilities implements PortablePresentationCapabilities {
  const _PortablePresentationCapabilities({this.invokeCommand, this.watchSearch, this.reload, this.commit, this.openResource, this.prepareCreation});
  

@override final  Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand;
@override final  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch;
@override final  Future<void> Function()? reload;
@override final  Future<void> Function()? commit;
@override final  ValueChanged<skir.ResourceId>? openResource;
@override final  Future<skir.PreparedCreation> Function(skir.InitializationRequest request)? prepareCreation;

/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePresentationCapabilitiesCopyWith<_PortablePresentationCapabilities> get copyWith => __$PortablePresentationCapabilitiesCopyWithImpl<_PortablePresentationCapabilities>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationCapabilities&&(identical(other.invokeCommand, invokeCommand) || other.invokeCommand == invokeCommand)&&(identical(other.watchSearch, watchSearch) || other.watchSearch == watchSearch)&&(identical(other.reload, reload) || other.reload == reload)&&(identical(other.commit, commit) || other.commit == commit)&&(identical(other.openResource, openResource) || other.openResource == openResource)&&(identical(other.prepareCreation, prepareCreation) || other.prepareCreation == prepareCreation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,invokeCommand,watchSearch,reload,commit,openResource,prepareCreation);
}

@override
String toString() {
    return 'PortablePresentationCapabilities(invokeCommand: $invokeCommand, watchSearch: $watchSearch, reload: $reload, commit: $commit, openResource: $openResource, prepareCreation: $prepareCreation)';
}


}

/// @nodoc
abstract mixin class _$PortablePresentationCapabilitiesCopyWith<$Res> implements $PortablePresentationCapabilitiesCopyWith<$Res> {
  factory _$PortablePresentationCapabilitiesCopyWith(_PortablePresentationCapabilities value, $Res Function(_PortablePresentationCapabilities) _then) = __$PortablePresentationCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, Future<void> Function()? reload, Future<void> Function()? commit, ValueChanged<skir.ResourceId>? openResource, Future<skir.PreparedCreation> Function(skir.InitializationRequest request)? prepareCreation
});




}
/// @nodoc
class __$PortablePresentationCapabilitiesCopyWithImpl<$Res>
    implements _$PortablePresentationCapabilitiesCopyWith<$Res> {
  __$PortablePresentationCapabilitiesCopyWithImpl(this._self, this._then);

  final _PortablePresentationCapabilities _self;
  final $Res Function(_PortablePresentationCapabilities) _then;

/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invokeCommand = freezed,Object? watchSearch = freezed,Object? reload = freezed,Object? commit = freezed,Object? openResource = freezed,Object? prepareCreation = freezed,}) {
  return _then(_PortablePresentationCapabilities(
invokeCommand: freezed == invokeCommand ? _self.invokeCommand : invokeCommand // ignore: cast_nullable_to_non_nullable
as Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)?,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reload: freezed == reload ? _self.reload : reload // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,commit: freezed == commit ? _self.commit : commit // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,prepareCreation: freezed == prepareCreation ? _self.prepareCreation : prepareCreation // ignore: cast_nullable_to_non_nullable
as Future<skir.PreparedCreation> Function(skir.InitializationRequest request)?,
  ));
}


}

/// @nodoc
mixin _$PortablePresentationWriteResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationWriteResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortablePresentationWriteResult()';
}


}

/// @nodoc
class $PortablePresentationWriteResultCopyWith<$Res>  {
$PortablePresentationWriteResultCopyWith(PortablePresentationWriteResult _, $Res Function(PortablePresentationWriteResult) __);
}


/// Adds pattern-matching-related methods to [PortablePresentationWriteResult].
extension PortablePresentationWriteResultPatterns on PortablePresentationWriteResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortablePresentationWriteApplied value)?  applied,TResult Function( PortablePresentationWriteRejected value)?  rejected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortablePresentationWriteApplied() when applied != null:
return applied(_that);case PortablePresentationWriteRejected() when rejected != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortablePresentationWriteApplied value)  applied,required TResult Function( PortablePresentationWriteRejected value)  rejected,}){
final _that = this;
switch (_that) {
case PortablePresentationWriteApplied():
return applied(_that);case PortablePresentationWriteRejected():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortablePresentationWriteApplied value)?  applied,TResult? Function( PortablePresentationWriteRejected value)?  rejected,}){
final _that = this;
switch (_that) {
case PortablePresentationWriteApplied() when applied != null:
return applied(_that);case PortablePresentationWriteRejected() when rejected != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  applied,TResult Function( String message)?  rejected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortablePresentationWriteApplied() when applied != null:
return applied();case PortablePresentationWriteRejected() when rejected != null:
return rejected(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  applied,required TResult Function( String message)  rejected,}) {final _that = this;
switch (_that) {
case PortablePresentationWriteApplied():
return applied();case PortablePresentationWriteRejected():
return rejected(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  applied,TResult? Function( String message)?  rejected,}) {final _that = this;
switch (_that) {
case PortablePresentationWriteApplied() when applied != null:
return applied();case PortablePresentationWriteRejected() when rejected != null:
return rejected(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class PortablePresentationWriteApplied implements PortablePresentationWriteResult {
  const PortablePresentationWriteApplied();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationWriteApplied);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortablePresentationWriteResult.applied()';
}


}




/// @nodoc


class PortablePresentationWriteRejected implements PortablePresentationWriteResult {
  const PortablePresentationWriteRejected(this.message);
  

 final  String message;

/// Create a copy of PortablePresentationWriteResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationWriteRejectedCopyWith<PortablePresentationWriteRejected> get copyWith => _$PortablePresentationWriteRejectedCopyWithImpl<PortablePresentationWriteRejected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationWriteRejected&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'PortablePresentationWriteResult.rejected(message: $message)';
}


}

/// @nodoc
abstract mixin class $PortablePresentationWriteRejectedCopyWith<$Res> implements $PortablePresentationWriteResultCopyWith<$Res> {
  factory $PortablePresentationWriteRejectedCopyWith(PortablePresentationWriteRejected value, $Res Function(PortablePresentationWriteRejected) _then) = _$PortablePresentationWriteRejectedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PortablePresentationWriteRejectedCopyWithImpl<$Res>
    implements $PortablePresentationWriteRejectedCopyWith<$Res> {
  _$PortablePresentationWriteRejectedCopyWithImpl(this._self, this._then);

  final PortablePresentationWriteRejected _self;
  final $Res Function(PortablePresentationWriteRejected) _then;

/// Create a copy of PortablePresentationWriteResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PortablePresentationWriteRejected(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
