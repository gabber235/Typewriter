// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_presentation_host.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
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


/// Adds pattern matching related methods to [PortablePresentationBindingSchema].
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
/// with the given fields replaced by the non null parameter values.
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
/// with the given fields replaced by the non null parameter values.
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
/// with the given fields replaced by the non null parameter values.
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
/// with the given fields replaced by the non null parameter values.
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
/// with the given fields replaced by the non null parameter values.
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
/// with the given fields replaced by the non null parameter values.
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
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationBindingSchemaCopyWith<$Res> get schema {

  return $PortablePresentationBindingSchemaCopyWith<$Res>(_self.schema, (value) {
    return _then(_self.copyWith(schema: value));
  });
}
}


/// Adds pattern matching related methods to [PortablePresentationBinding].
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
/// with the given fields replaced by the non null parameter values.
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
/// with the given fields replaced by the non null parameter values.
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
/// with the given fields replaced by the non null parameter values.
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

 Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? get invokeCommand; Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? get watchSearch; Future<void> Function()? get reload; Future<void> Function()? get commit; ValueChanged<skir.ResourceId>? get openResource; Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? get prepareValue;
/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationCapabilitiesCopyWith<PortablePresentationCapabilities> get copyWith => _$PortablePresentationCapabilitiesCopyWithImpl<PortablePresentationCapabilities>(this as PortablePresentationCapabilities, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationCapabilities;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationCapabilities&&(identical(other.invokeCommand, _this.invokeCommand) || other.invokeCommand == _this.invokeCommand)&&(identical(other.watchSearch, _this.watchSearch) || other.watchSearch == _this.watchSearch)&&(identical(other.reload, _this.reload) || other.reload == _this.reload)&&(identical(other.commit, _this.commit) || other.commit == _this.commit)&&(identical(other.openResource, _this.openResource) || other.openResource == _this.openResource)&&(identical(other.prepareValue, _this.prepareValue) || other.prepareValue == _this.prepareValue));
}


@override
int get hashCode {
  final _this = this as PortablePresentationCapabilities;
  return Object.hash(runtimeType,_this.invokeCommand,_this.watchSearch,_this.reload,_this.commit,_this.openResource,_this.prepareValue);
}

@override
String toString() {
  final _this = this as PortablePresentationCapabilities;
  return 'PortablePresentationCapabilities(invokeCommand: ${_this.invokeCommand}, watchSearch: ${_this.watchSearch}, reload: ${_this.reload}, commit: ${_this.commit}, openResource: ${_this.openResource}, prepareValue: ${_this.prepareValue})';
}


}

/// @nodoc
abstract mixin class $PortablePresentationCapabilitiesCopyWith<$Res>  {
  factory $PortablePresentationCapabilitiesCopyWith(PortablePresentationCapabilities value, $Res Function(PortablePresentationCapabilities) _then) = _$PortablePresentationCapabilitiesCopyWithImpl;
@useResult
$Res call({
 Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, Future<void> Function()? reload, Future<void> Function()? commit, ValueChanged<skir.ResourceId>? openResource, Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue
});




}
/// @nodoc
class _$PortablePresentationCapabilitiesCopyWithImpl<$Res>
    implements $PortablePresentationCapabilitiesCopyWith<$Res> {
  _$PortablePresentationCapabilitiesCopyWithImpl(this._self, this._then);

  final PortablePresentationCapabilities _self;
  final $Res Function(PortablePresentationCapabilities) _then;

/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? invokeCommand = freezed,Object? watchSearch = freezed,Object? reload = freezed,Object? commit = freezed,Object? openResource = freezed,Object? prepareValue = freezed,}) {
  return _then(PortablePresentationCapabilities(
invokeCommand: freezed == invokeCommand ? _self.invokeCommand : invokeCommand // ignore: cast_nullable_to_non_nullable
as Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)?,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reload: freezed == reload ? _self.reload : reload // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,commit: freezed == commit ? _self.commit : commit // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,prepareValue: freezed == prepareValue ? _self.prepareValue : prepareValue // ignore: cast_nullable_to_non_nullable
as Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)?,
  ));
}

}


/// Adds pattern matching related methods to [PortablePresentationCapabilities].
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand,  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch,  Future<void> Function()? reload,  Future<void> Function()? commit,  ValueChanged<skir.ResourceId>? openResource,  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortablePresentationCapabilities() when $default != null:
return $default(_that.invokeCommand,_that.watchSearch,_that.reload,_that.commit,_that.openResource,_that.prepareValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand,  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch,  Future<void> Function()? reload,  Future<void> Function()? commit,  ValueChanged<skir.ResourceId>? openResource,  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue)  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationCapabilities():
return $default(_that.invokeCommand,_that.watchSearch,_that.reload,_that.commit,_that.openResource,_that.prepareValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand,  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch,  Future<void> Function()? reload,  Future<void> Function()? commit,  ValueChanged<skir.ResourceId>? openResource,  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue)?  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationCapabilities() when $default != null:
return $default(_that.invokeCommand,_that.watchSearch,_that.reload,_that.commit,_that.openResource,_that.prepareValue);case _:
  return null;

}
}

}

/// @nodoc


class _PortablePresentationCapabilities implements PortablePresentationCapabilities {
  const _PortablePresentationCapabilities({this.invokeCommand, this.watchSearch, this.reload, this.commit, this.openResource, this.prepareValue});


@override final  Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand;
@override final  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch;
@override final  Future<void> Function()? reload;
@override final  Future<void> Function()? commit;
@override final  ValueChanged<skir.ResourceId>? openResource;
@override final  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue;

/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePresentationCapabilitiesCopyWith<_PortablePresentationCapabilities> get copyWith => __$PortablePresentationCapabilitiesCopyWithImpl<_PortablePresentationCapabilities>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationCapabilities&&(identical(other.invokeCommand, invokeCommand) || other.invokeCommand == invokeCommand)&&(identical(other.watchSearch, watchSearch) || other.watchSearch == watchSearch)&&(identical(other.reload, reload) || other.reload == reload)&&(identical(other.commit, commit) || other.commit == commit)&&(identical(other.openResource, openResource) || other.openResource == openResource)&&(identical(other.prepareValue, prepareValue) || other.prepareValue == prepareValue));
}


@override
int get hashCode {
    return Object.hash(runtimeType,invokeCommand,watchSearch,reload,commit,openResource,prepareValue);
}

@override
String toString() {
    return 'PortablePresentationCapabilities(invokeCommand: $invokeCommand, watchSearch: $watchSearch, reload: $reload, commit: $commit, openResource: $openResource, prepareValue: $prepareValue)';
}


}

/// @nodoc
abstract mixin class _$PortablePresentationCapabilitiesCopyWith<$Res> implements $PortablePresentationCapabilitiesCopyWith<$Res> {
  factory _$PortablePresentationCapabilitiesCopyWith(_PortablePresentationCapabilities value, $Res Function(_PortablePresentationCapabilities) _then) = __$PortablePresentationCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, Future<void> Function()? reload, Future<void> Function()? commit, ValueChanged<skir.ResourceId>? openResource, Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue
});




}
/// @nodoc
class __$PortablePresentationCapabilitiesCopyWithImpl<$Res>
    implements _$PortablePresentationCapabilitiesCopyWith<$Res> {
  __$PortablePresentationCapabilitiesCopyWithImpl(this._self, this._then);

  final _PortablePresentationCapabilities _self;
  final $Res Function(_PortablePresentationCapabilities) _then;

/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invokeCommand = freezed,Object? watchSearch = freezed,Object? reload = freezed,Object? commit = freezed,Object? openResource = freezed,Object? prepareValue = freezed,}) {
  return _then(_PortablePresentationCapabilities(
invokeCommand: freezed == invokeCommand ? _self.invokeCommand : invokeCommand // ignore: cast_nullable_to_non_nullable
as Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)?,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reload: freezed == reload ? _self.reload : reload // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,commit: freezed == commit ? _self.commit : commit // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,prepareValue: freezed == prepareValue ? _self.prepareValue : prepareValue // ignore: cast_nullable_to_non_nullable
as Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)?,
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


/// Adds pattern matching related methods to [PortablePresentationWriteResult].
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
/// with the given fields replaced by the non null parameter values.
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
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PortablePresentationWriteRejected(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PortableCollectionRowProjection {

 skir.ResourceId get resource; skir.TypeSelection get configuration; String get label; skir.DataValue get row; skir.DataValue get key; String get canonicalKey; bool get selectable;
/// Create a copy of PortableCollectionRowProjection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableCollectionRowProjectionCopyWith<PortableCollectionRowProjection> get copyWith => _$PortableCollectionRowProjectionCopyWithImpl<PortableCollectionRowProjection>(this as PortableCollectionRowProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableCollectionRowProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableCollectionRowProjection&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.configuration, _this.configuration) || other.configuration == _this.configuration)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.row, _this.row) || other.row == _this.row)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.canonicalKey, _this.canonicalKey) || other.canonicalKey == _this.canonicalKey)&&(identical(other.selectable, _this.selectable) || other.selectable == _this.selectable));
}


@override
int get hashCode {
  final _this = this as PortableCollectionRowProjection;
  return Object.hash(runtimeType,_this.resource,_this.configuration,_this.label,_this.row,_this.key,_this.canonicalKey,_this.selectable);
}

@override
String toString() {
  final _this = this as PortableCollectionRowProjection;
  return 'PortableCollectionRowProjection(resource: ${_this.resource}, configuration: ${_this.configuration}, label: ${_this.label}, row: ${_this.row}, key: ${_this.key}, canonicalKey: ${_this.canonicalKey}, selectable: ${_this.selectable})';
}


}

/// @nodoc
abstract mixin class $PortableCollectionRowProjectionCopyWith<$Res>  {
  factory $PortableCollectionRowProjectionCopyWith(PortableCollectionRowProjection value, $Res Function(PortableCollectionRowProjection) _then) = _$PortableCollectionRowProjectionCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, skir.TypeSelection configuration, String label, skir.DataValue row, skir.DataValue key, String canonicalKey, bool selectable
});




}
/// @nodoc
class _$PortableCollectionRowProjectionCopyWithImpl<$Res>
    implements $PortableCollectionRowProjectionCopyWith<$Res> {
  _$PortableCollectionRowProjectionCopyWithImpl(this._self, this._then);

  final PortableCollectionRowProjection _self;
  final $Res Function(PortableCollectionRowProjection) _then;

/// Create a copy of PortableCollectionRowProjection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? configuration = null,Object? label = null,Object? row = null,Object? key = null,Object? canonicalKey = null,Object? selectable = null,}) {
  return _then(PortableCollectionRowProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as skir.DataValue,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as skir.DataValue,canonicalKey: null == canonicalKey ? _self.canonicalKey : canonicalKey // ignore: cast_nullable_to_non_nullable
as String,selectable: null == selectable ? _self.selectable : selectable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern matching related methods to [PortableCollectionRowProjection].
extension PortableCollectionRowProjectionPatterns on PortableCollectionRowProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableCollectionRowProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableCollectionRowProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableCollectionRowProjection value)  $default,){
final _that = this;
switch (_that) {
case _PortableCollectionRowProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableCollectionRowProjection value)?  $default,){
final _that = this;
switch (_that) {
case _PortableCollectionRowProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.TypeSelection configuration,  String label,  skir.DataValue row,  skir.DataValue key,  String canonicalKey,  bool selectable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableCollectionRowProjection() when $default != null:
return $default(_that.resource,_that.configuration,_that.label,_that.row,_that.key,_that.canonicalKey,_that.selectable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.TypeSelection configuration,  String label,  skir.DataValue row,  skir.DataValue key,  String canonicalKey,  bool selectable)  $default,) {final _that = this;
switch (_that) {
case _PortableCollectionRowProjection():
return $default(_that.resource,_that.configuration,_that.label,_that.row,_that.key,_that.canonicalKey,_that.selectable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId resource,  skir.TypeSelection configuration,  String label,  skir.DataValue row,  skir.DataValue key,  String canonicalKey,  bool selectable)?  $default,) {final _that = this;
switch (_that) {
case _PortableCollectionRowProjection() when $default != null:
return $default(_that.resource,_that.configuration,_that.label,_that.row,_that.key,_that.canonicalKey,_that.selectable);case _:
  return null;

}
}

}

/// @nodoc


class _PortableCollectionRowProjection implements PortableCollectionRowProjection {
  const _PortableCollectionRowProjection({required this.resource, required this.configuration, required this.label, required this.row, required this.key, required this.canonicalKey, required this.selectable});


@override final  skir.ResourceId resource;
@override final  skir.TypeSelection configuration;
@override final  String label;
@override final  skir.DataValue row;
@override final  skir.DataValue key;
@override final  String canonicalKey;
@override final  bool selectable;

/// Create a copy of PortableCollectionRowProjection
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableCollectionRowProjectionCopyWith<_PortableCollectionRowProjection> get copyWith => __$PortableCollectionRowProjectionCopyWithImpl<_PortableCollectionRowProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableCollectionRowProjection&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.configuration, configuration) || other.configuration == configuration)&&(identical(other.label, label) || other.label == label)&&(identical(other.row, row) || other.row == row)&&(identical(other.key, key) || other.key == key)&&(identical(other.canonicalKey, canonicalKey) || other.canonicalKey == canonicalKey)&&(identical(other.selectable, selectable) || other.selectable == selectable));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,configuration,label,row,key,canonicalKey,selectable);
}

@override
String toString() {
    return 'PortableCollectionRowProjection(resource: $resource, configuration: $configuration, label: $label, row: $row, key: $key, canonicalKey: $canonicalKey, selectable: $selectable)';
}


}

/// @nodoc
abstract mixin class _$PortableCollectionRowProjectionCopyWith<$Res> implements $PortableCollectionRowProjectionCopyWith<$Res> {
  factory _$PortableCollectionRowProjectionCopyWith(_PortableCollectionRowProjection value, $Res Function(_PortableCollectionRowProjection) _then) = __$PortableCollectionRowProjectionCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, skir.TypeSelection configuration, String label, skir.DataValue row, skir.DataValue key, String canonicalKey, bool selectable
});




}
/// @nodoc
class __$PortableCollectionRowProjectionCopyWithImpl<$Res>
    implements _$PortableCollectionRowProjectionCopyWith<$Res> {
  __$PortableCollectionRowProjectionCopyWithImpl(this._self, this._then);

  final _PortableCollectionRowProjection _self;
  final $Res Function(_PortableCollectionRowProjection) _then;

/// Create a copy of PortableCollectionRowProjection
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? configuration = null,Object? label = null,Object? row = null,Object? key = null,Object? canonicalKey = null,Object? selectable = null,}) {
  return _then(_PortableCollectionRowProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as skir.DataValue,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as skir.DataValue,canonicalKey: null == canonicalKey ? _self.canonicalKey : canonicalKey // ignore: cast_nullable_to_non_nullable
as String,selectable: null == selectable ? _self.selectable : selectable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$PortableCollectionProjection {

 skir.PresentationCollectionDefinition? get definition; List<PortableCollectionRowProjection> get rows; String? get problem;
/// Create a copy of PortableCollectionProjection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableCollectionProjectionCopyWith<PortableCollectionProjection> get copyWith => _$PortableCollectionProjectionCopyWithImpl<PortableCollectionProjection>(this as PortableCollectionProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableCollectionProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableCollectionProjection&&(identical(other.definition, _this.definition) || other.definition == _this.definition)&&const DeepCollectionEquality().equals(other.rows, _this.rows)&&(identical(other.problem, _this.problem) || other.problem == _this.problem));
}


@override
int get hashCode {
  final _this = this as PortableCollectionProjection;
  return Object.hash(runtimeType,_this.definition,const DeepCollectionEquality().hash(_this.rows),_this.problem);
}

@override
String toString() {
  final _this = this as PortableCollectionProjection;
  return 'PortableCollectionProjection(definition: ${_this.definition}, rows: ${_this.rows}, problem: ${_this.problem})';
}


}

/// @nodoc
abstract mixin class $PortableCollectionProjectionCopyWith<$Res>  {
  factory $PortableCollectionProjectionCopyWith(PortableCollectionProjection value, $Res Function(PortableCollectionProjection) _then) = _$PortableCollectionProjectionCopyWithImpl;
@useResult
$Res call({
 skir.PresentationCollectionDefinition? definition, List<PortableCollectionRowProjection> rows, String? problem
});




}
/// @nodoc
class _$PortableCollectionProjectionCopyWithImpl<$Res>
    implements $PortableCollectionProjectionCopyWith<$Res> {
  _$PortableCollectionProjectionCopyWithImpl(this._self, this._then);

  final PortableCollectionProjection _self;
  final $Res Function(PortableCollectionProjection) _then;

/// Create a copy of PortableCollectionProjection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definition = freezed,Object? rows = null,Object? problem = freezed,}) {
  return _then(PortableCollectionProjection(
definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.PresentationCollectionDefinition?,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<PortableCollectionRowProjection>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}



/// @nodoc


class _PortableCollectionProjection implements PortableCollectionProjection {
  const _PortableCollectionProjection({required this.definition, required  List<PortableCollectionRowProjection> rows, required this.problem}): _rows = rows;


@override final  skir.PresentationCollectionDefinition? definition;
 final  List<PortableCollectionRowProjection> _rows;
@override List<PortableCollectionRowProjection> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

@override final  String? problem;

/// Create a copy of PortableCollectionProjection
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableCollectionProjectionCopyWith<_PortableCollectionProjection> get copyWith => __$PortableCollectionProjectionCopyWithImpl<_PortableCollectionProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableCollectionProjection&&(identical(other.definition, definition) || other.definition == definition)&&const DeepCollectionEquality().equals(other.rows, _rows)&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode {
    return Object.hash(runtimeType,definition,const DeepCollectionEquality().hash(_rows),problem);
}

@override
String toString() {
    return 'PortableCollectionProjection._value(definition: $definition, rows: $rows, problem: $problem)';
}


}

/// @nodoc
abstract mixin class _$PortableCollectionProjectionCopyWith<$Res> implements $PortableCollectionProjectionCopyWith<$Res> {
  factory _$PortableCollectionProjectionCopyWith(_PortableCollectionProjection value, $Res Function(_PortableCollectionProjection) _then) = __$PortableCollectionProjectionCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationCollectionDefinition? definition, List<PortableCollectionRowProjection> rows, String? problem
});




}
/// @nodoc
class __$PortableCollectionProjectionCopyWithImpl<$Res>
    implements _$PortableCollectionProjectionCopyWith<$Res> {
  __$PortableCollectionProjectionCopyWithImpl(this._self, this._then);

  final _PortableCollectionProjection _self;
  final $Res Function(_PortableCollectionProjection) _then;

/// Create a copy of PortableCollectionProjection
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definition = freezed,Object? rows = null,Object? problem = freezed,}) {
  return _then(_PortableCollectionProjection(
definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.PresentationCollectionDefinition?,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<PortableCollectionRowProjection>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PortableResourceProjection {

 skir.ResourceId get resource; skir.TypeSelection get configuration; String get label; skir.DataValue get value;
/// Create a copy of PortableResourceProjection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableResourceProjectionCopyWith<PortableResourceProjection> get copyWith => _$PortableResourceProjectionCopyWithImpl<PortableResourceProjection>(this as PortableResourceProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableResourceProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableResourceProjection&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.configuration, _this.configuration) || other.configuration == _this.configuration)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as PortableResourceProjection;
  return Object.hash(runtimeType,_this.resource,_this.configuration,_this.label,_this.value);
}

@override
String toString() {
  final _this = this as PortableResourceProjection;
  return 'PortableResourceProjection(resource: ${_this.resource}, configuration: ${_this.configuration}, label: ${_this.label}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $PortableResourceProjectionCopyWith<$Res>  {
  factory $PortableResourceProjectionCopyWith(PortableResourceProjection value, $Res Function(PortableResourceProjection) _then) = _$PortableResourceProjectionCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, skir.TypeSelection configuration, String label, skir.DataValue value
});




}
/// @nodoc
class _$PortableResourceProjectionCopyWithImpl<$Res>
    implements $PortableResourceProjectionCopyWith<$Res> {
  _$PortableResourceProjectionCopyWithImpl(this._self, this._then);

  final PortableResourceProjection _self;
  final $Res Function(PortableResourceProjection) _then;

/// Create a copy of PortableResourceProjection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? configuration = null,Object? label = null,Object? value = null,}) {
  return _then(PortableResourceProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,
  ));
}

}


/// Adds pattern matching related methods to [PortableResourceProjection].
extension PortableResourceProjectionPatterns on PortableResourceProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableResourceProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableResourceProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableResourceProjection value)  $default,){
final _that = this;
switch (_that) {
case _PortableResourceProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableResourceProjection value)?  $default,){
final _that = this;
switch (_that) {
case _PortableResourceProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.TypeSelection configuration,  String label,  skir.DataValue value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableResourceProjection() when $default != null:
return $default(_that.resource,_that.configuration,_that.label,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.TypeSelection configuration,  String label,  skir.DataValue value)  $default,) {final _that = this;
switch (_that) {
case _PortableResourceProjection():
return $default(_that.resource,_that.configuration,_that.label,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId resource,  skir.TypeSelection configuration,  String label,  skir.DataValue value)?  $default,) {final _that = this;
switch (_that) {
case _PortableResourceProjection() when $default != null:
return $default(_that.resource,_that.configuration,_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _PortableResourceProjection implements PortableResourceProjection {
  const _PortableResourceProjection({required this.resource, required this.configuration, required this.label, required this.value});


@override final  skir.ResourceId resource;
@override final  skir.TypeSelection configuration;
@override final  String label;
@override final  skir.DataValue value;

/// Create a copy of PortableResourceProjection
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableResourceProjectionCopyWith<_PortableResourceProjection> get copyWith => __$PortableResourceProjectionCopyWithImpl<_PortableResourceProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableResourceProjection&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.configuration, configuration) || other.configuration == configuration)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,configuration,label,value);
}

@override
String toString() {
    return 'PortableResourceProjection(resource: $resource, configuration: $configuration, label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$PortableResourceProjectionCopyWith<$Res> implements $PortableResourceProjectionCopyWith<$Res> {
  factory _$PortableResourceProjectionCopyWith(_PortableResourceProjection value, $Res Function(_PortableResourceProjection) _then) = __$PortableResourceProjectionCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, skir.TypeSelection configuration, String label, skir.DataValue value
});




}
/// @nodoc
class __$PortableResourceProjectionCopyWithImpl<$Res>
    implements _$PortableResourceProjectionCopyWith<$Res> {
  __$PortableResourceProjectionCopyWithImpl(this._self, this._then);

  final _PortableResourceProjection _self;
  final $Res Function(_PortableResourceProjection) _then;

/// Create a copy of PortableResourceProjection
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? configuration = null,Object? label = null,Object? value = null,}) {
  return _then(_PortableResourceProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,
  ));
}


}

/// @nodoc
mixin _$PortablePageGraphPlacement {

 int get x; int get y; int get width; int get height;
/// Create a copy of PortablePageGraphPlacement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePageGraphPlacementCopyWith<PortablePageGraphPlacement> get copyWith => _$PortablePageGraphPlacementCopyWithImpl<PortablePageGraphPlacement>(this as PortablePageGraphPlacement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePageGraphPlacement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePageGraphPlacement&&(identical(other.x, _this.x) || other.x == _this.x)&&(identical(other.y, _this.y) || other.y == _this.y)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height));
}


@override
int get hashCode {
  final _this = this as PortablePageGraphPlacement;
  return Object.hash(runtimeType,_this.x,_this.y,_this.width,_this.height);
}

@override
String toString() {
  final _this = this as PortablePageGraphPlacement;
  return 'PortablePageGraphPlacement(x: ${_this.x}, y: ${_this.y}, width: ${_this.width}, height: ${_this.height})';
}


}

/// @nodoc
abstract mixin class $PortablePageGraphPlacementCopyWith<$Res>  {
  factory $PortablePageGraphPlacementCopyWith(PortablePageGraphPlacement value, $Res Function(PortablePageGraphPlacement) _then) = _$PortablePageGraphPlacementCopyWithImpl;
@useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class _$PortablePageGraphPlacementCopyWithImpl<$Res>
    implements $PortablePageGraphPlacementCopyWith<$Res> {
  _$PortablePageGraphPlacementCopyWithImpl(this._self, this._then);

  final PortablePageGraphPlacement _self;
  final $Res Function(PortablePageGraphPlacement) _then;

/// Create a copy of PortablePageGraphPlacement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(PortablePageGraphPlacement(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern matching related methods to [PortablePageGraphPlacement].
extension PortablePageGraphPlacementPatterns on PortablePageGraphPlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortablePageGraphPlacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortablePageGraphPlacement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortablePageGraphPlacement value)  $default,){
final _that = this;
switch (_that) {
case _PortablePageGraphPlacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortablePageGraphPlacement value)?  $default,){
final _that = this;
switch (_that) {
case _PortablePageGraphPlacement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortablePageGraphPlacement() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _PortablePageGraphPlacement():
return $default(_that.x,_that.y,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int x,  int y,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _PortablePageGraphPlacement() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _PortablePageGraphPlacement implements PortablePageGraphPlacement {
  const _PortablePageGraphPlacement({required this.x, required this.y, required this.width, required this.height});


@override final  int x;
@override final  int y;
@override final  int width;
@override final  int height;

/// Create a copy of PortablePageGraphPlacement
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePageGraphPlacementCopyWith<_PortablePageGraphPlacement> get copyWith => __$PortablePageGraphPlacementCopyWithImpl<_PortablePageGraphPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePageGraphPlacement&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode {
    return Object.hash(runtimeType,x,y,width,height);
}

@override
String toString() {
    return 'PortablePageGraphPlacement(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$PortablePageGraphPlacementCopyWith<$Res> implements $PortablePageGraphPlacementCopyWith<$Res> {
  factory _$PortablePageGraphPlacementCopyWith(_PortablePageGraphPlacement value, $Res Function(_PortablePageGraphPlacement) _then) = __$PortablePageGraphPlacementCopyWithImpl;
@override @useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class __$PortablePageGraphPlacementCopyWithImpl<$Res>
    implements _$PortablePageGraphPlacementCopyWith<$Res> {
  __$PortablePageGraphPlacementCopyWithImpl(this._self, this._then);

  final _PortablePageGraphPlacement _self;
  final $Res Function(_PortablePageGraphPlacement) _then;

/// Create a copy of PortablePageGraphPlacement
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_PortablePageGraphPlacement(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PortablePageEntryProjection {

 skir.ResourceId get resource; skir.LinkOccurrence get occurrence; PortableResourceProjection get resourceProjection; PortablePageGraphPlacement? get graph;
/// Create a copy of PortablePageEntryProjection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePageEntryProjectionCopyWith<PortablePageEntryProjection> get copyWith => _$PortablePageEntryProjectionCopyWithImpl<PortablePageEntryProjection>(this as PortablePageEntryProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePageEntryProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePageEntryProjection&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.occurrence, _this.occurrence) || other.occurrence == _this.occurrence)&&(identical(other.resourceProjection, _this.resourceProjection) || other.resourceProjection == _this.resourceProjection)&&(identical(other.graph, _this.graph) || other.graph == _this.graph));
}


@override
int get hashCode {
  final _this = this as PortablePageEntryProjection;
  return Object.hash(runtimeType,_this.resource,_this.occurrence,_this.resourceProjection,_this.graph);
}

@override
String toString() {
  final _this = this as PortablePageEntryProjection;
  return 'PortablePageEntryProjection(resource: ${_this.resource}, occurrence: ${_this.occurrence}, resourceProjection: ${_this.resourceProjection}, graph: ${_this.graph})';
}


}

/// @nodoc
abstract mixin class $PortablePageEntryProjectionCopyWith<$Res>  {
  factory $PortablePageEntryProjectionCopyWith(PortablePageEntryProjection value, $Res Function(PortablePageEntryProjection) _then) = _$PortablePageEntryProjectionCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, skir.LinkOccurrence occurrence, PortableResourceProjection resourceProjection, PortablePageGraphPlacement? graph
});


$PortableResourceProjectionCopyWith<$Res> get resourceProjection;$PortablePageGraphPlacementCopyWith<$Res>? get graph;

}
/// @nodoc
class _$PortablePageEntryProjectionCopyWithImpl<$Res>
    implements $PortablePageEntryProjectionCopyWith<$Res> {
  _$PortablePageEntryProjectionCopyWithImpl(this._self, this._then);

  final PortablePageEntryProjection _self;
  final $Res Function(PortablePageEntryProjection) _then;

/// Create a copy of PortablePageEntryProjection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? occurrence = null,Object? resourceProjection = null,Object? graph = freezed,}) {
  return _then(PortablePageEntryProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,occurrence: null == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence,resourceProjection: null == resourceProjection ? _self.resourceProjection : resourceProjection // ignore: cast_nullable_to_non_nullable
as PortableResourceProjection,graph: freezed == graph ? _self.graph : graph // ignore: cast_nullable_to_non_nullable
as PortablePageGraphPlacement?,
  ));
}
/// Create a copy of PortablePageEntryProjection
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableResourceProjectionCopyWith<$Res> get resourceProjection {

  return $PortableResourceProjectionCopyWith<$Res>(_self.resourceProjection, (value) {
    return _then(_self.copyWith(resourceProjection: value));
  });
}/// Create a copy of PortablePageEntryProjection
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePageGraphPlacementCopyWith<$Res>? get graph {
    if (_self.graph == null) {
    return null;
  }

  return $PortablePageGraphPlacementCopyWith<$Res>(_self.graph!, (value) {
    return _then(_self.copyWith(graph: value));
  });
}
}


/// Adds pattern matching related methods to [PortablePageEntryProjection].
extension PortablePageEntryProjectionPatterns on PortablePageEntryProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortablePageEntryProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortablePageEntryProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortablePageEntryProjection value)  $default,){
final _that = this;
switch (_that) {
case _PortablePageEntryProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortablePageEntryProjection value)?  $default,){
final _that = this;
switch (_that) {
case _PortablePageEntryProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.LinkOccurrence occurrence,  PortableResourceProjection resourceProjection,  PortablePageGraphPlacement? graph)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortablePageEntryProjection() when $default != null:
return $default(_that.resource,_that.occurrence,_that.resourceProjection,_that.graph);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.LinkOccurrence occurrence,  PortableResourceProjection resourceProjection,  PortablePageGraphPlacement? graph)  $default,) {final _that = this;
switch (_that) {
case _PortablePageEntryProjection():
return $default(_that.resource,_that.occurrence,_that.resourceProjection,_that.graph);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId resource,  skir.LinkOccurrence occurrence,  PortableResourceProjection resourceProjection,  PortablePageGraphPlacement? graph)?  $default,) {final _that = this;
switch (_that) {
case _PortablePageEntryProjection() when $default != null:
return $default(_that.resource,_that.occurrence,_that.resourceProjection,_that.graph);case _:
  return null;

}
}

}

/// @nodoc


class _PortablePageEntryProjection implements PortablePageEntryProjection {
  const _PortablePageEntryProjection({required this.resource, required this.occurrence, required this.resourceProjection, this.graph});


@override final  skir.ResourceId resource;
@override final  skir.LinkOccurrence occurrence;
@override final  PortableResourceProjection resourceProjection;
@override final  PortablePageGraphPlacement? graph;

/// Create a copy of PortablePageEntryProjection
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePageEntryProjectionCopyWith<_PortablePageEntryProjection> get copyWith => __$PortablePageEntryProjectionCopyWithImpl<_PortablePageEntryProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePageEntryProjection&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.occurrence, occurrence) || other.occurrence == occurrence)&&(identical(other.resourceProjection, resourceProjection) || other.resourceProjection == resourceProjection)&&(identical(other.graph, graph) || other.graph == graph));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,occurrence,resourceProjection,graph);
}

@override
String toString() {
    return 'PortablePageEntryProjection(resource: $resource, occurrence: $occurrence, resourceProjection: $resourceProjection, graph: $graph)';
}


}

/// @nodoc
abstract mixin class _$PortablePageEntryProjectionCopyWith<$Res> implements $PortablePageEntryProjectionCopyWith<$Res> {
  factory _$PortablePageEntryProjectionCopyWith(_PortablePageEntryProjection value, $Res Function(_PortablePageEntryProjection) _then) = __$PortablePageEntryProjectionCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, skir.LinkOccurrence occurrence, PortableResourceProjection resourceProjection, PortablePageGraphPlacement? graph
});


@override $PortableResourceProjectionCopyWith<$Res> get resourceProjection;@override $PortablePageGraphPlacementCopyWith<$Res>? get graph;

}
/// @nodoc
class __$PortablePageEntryProjectionCopyWithImpl<$Res>
    implements _$PortablePageEntryProjectionCopyWith<$Res> {
  __$PortablePageEntryProjectionCopyWithImpl(this._self, this._then);

  final _PortablePageEntryProjection _self;
  final $Res Function(_PortablePageEntryProjection) _then;

/// Create a copy of PortablePageEntryProjection
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? occurrence = null,Object? resourceProjection = null,Object? graph = freezed,}) {
  return _then(_PortablePageEntryProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,occurrence: null == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence,resourceProjection: null == resourceProjection ? _self.resourceProjection : resourceProjection // ignore: cast_nullable_to_non_nullable
as PortableResourceProjection,graph: freezed == graph ? _self.graph : graph // ignore: cast_nullable_to_non_nullable
as PortablePageGraphPlacement?,
  ));
}

/// Create a copy of PortablePageEntryProjection
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableResourceProjectionCopyWith<$Res> get resourceProjection {

  return $PortableResourceProjectionCopyWith<$Res>(_self.resourceProjection, (value) {
    return _then(_self.copyWith(resourceProjection: value));
  });
}/// Create a copy of PortablePageEntryProjection
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePageGraphPlacementCopyWith<$Res>? get graph {
    if (_self.graph == null) {
    return null;
  }

  return $PortablePageGraphPlacementCopyWith<$Res>(_self.graph!, (value) {
    return _then(_self.copyWith(graph: value));
  });
}
}

/// @nodoc
mixin _$PortablePageEdgeProjection {

 String get id; skir.ResourceId get source; skir.ResourceId get target;
/// Create a copy of PortablePageEdgeProjection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePageEdgeProjectionCopyWith<PortablePageEdgeProjection> get copyWith => _$PortablePageEdgeProjectionCopyWithImpl<PortablePageEdgeProjection>(this as PortablePageEdgeProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePageEdgeProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePageEdgeProjection&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.target, _this.target) || other.target == _this.target));
}


@override
int get hashCode {
  final _this = this as PortablePageEdgeProjection;
  return Object.hash(runtimeType,_this.id,_this.source,_this.target);
}

@override
String toString() {
  final _this = this as PortablePageEdgeProjection;
  return 'PortablePageEdgeProjection(id: ${_this.id}, source: ${_this.source}, target: ${_this.target})';
}


}

/// @nodoc
abstract mixin class $PortablePageEdgeProjectionCopyWith<$Res>  {
  factory $PortablePageEdgeProjectionCopyWith(PortablePageEdgeProjection value, $Res Function(PortablePageEdgeProjection) _then) = _$PortablePageEdgeProjectionCopyWithImpl;
@useResult
$Res call({
 String id, skir.ResourceId source, skir.ResourceId target
});




}
/// @nodoc
class _$PortablePageEdgeProjectionCopyWithImpl<$Res>
    implements $PortablePageEdgeProjectionCopyWith<$Res> {
  _$PortablePageEdgeProjectionCopyWithImpl(this._self, this._then);

  final PortablePageEdgeProjection _self;
  final $Res Function(PortablePageEdgeProjection) _then;

/// Create a copy of PortablePageEdgeProjection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? target = null,}) {
  return _then(PortablePageEdgeProjection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}

}


/// Adds pattern matching related methods to [PortablePageEdgeProjection].
extension PortablePageEdgeProjectionPatterns on PortablePageEdgeProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortablePageEdgeProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortablePageEdgeProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortablePageEdgeProjection value)  $default,){
final _that = this;
switch (_that) {
case _PortablePageEdgeProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortablePageEdgeProjection value)?  $default,){
final _that = this;
switch (_that) {
case _PortablePageEdgeProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  skir.ResourceId source,  skir.ResourceId target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortablePageEdgeProjection() when $default != null:
return $default(_that.id,_that.source,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  skir.ResourceId source,  skir.ResourceId target)  $default,) {final _that = this;
switch (_that) {
case _PortablePageEdgeProjection():
return $default(_that.id,_that.source,_that.target);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  skir.ResourceId source,  skir.ResourceId target)?  $default,) {final _that = this;
switch (_that) {
case _PortablePageEdgeProjection() when $default != null:
return $default(_that.id,_that.source,_that.target);case _:
  return null;

}
}

}

/// @nodoc


class _PortablePageEdgeProjection implements PortablePageEdgeProjection {
  const _PortablePageEdgeProjection({required this.id, required this.source, required this.target});


@override final  String id;
@override final  skir.ResourceId source;
@override final  skir.ResourceId target;

/// Create a copy of PortablePageEdgeProjection
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePageEdgeProjectionCopyWith<_PortablePageEdgeProjection> get copyWith => __$PortablePageEdgeProjectionCopyWithImpl<_PortablePageEdgeProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePageEdgeProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,source,target);
}

@override
String toString() {
    return 'PortablePageEdgeProjection(id: $id, source: $source, target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortablePageEdgeProjectionCopyWith<$Res> implements $PortablePageEdgeProjectionCopyWith<$Res> {
  factory _$PortablePageEdgeProjectionCopyWith(_PortablePageEdgeProjection value, $Res Function(_PortablePageEdgeProjection) _then) = __$PortablePageEdgeProjectionCopyWithImpl;
@override @useResult
$Res call({
 String id, skir.ResourceId source, skir.ResourceId target
});




}
/// @nodoc
class __$PortablePageEdgeProjectionCopyWithImpl<$Res>
    implements _$PortablePageEdgeProjectionCopyWith<$Res> {
  __$PortablePageEdgeProjectionCopyWithImpl(this._self, this._then);

  final _PortablePageEdgeProjection _self;
  final $Res Function(_PortablePageEdgeProjection) _then;

/// Create a copy of PortablePageEdgeProjection
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? target = null,}) {
  return _then(_PortablePageEdgeProjection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}


}

/// @nodoc
mixin _$PortableTimelinePlacement {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableTimelinePlacement);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableTimelinePlacement()';
}


}

/// @nodoc
class $PortableTimelinePlacementCopyWith<$Res>  {
$PortableTimelinePlacementCopyWith(PortableTimelinePlacement _, $Res Function(PortableTimelinePlacement) __);
}


/// Adds pattern matching related methods to [PortableTimelinePlacement].
extension PortableTimelinePlacementPatterns on PortableTimelinePlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortableTimelineKeyframe value)?  keyframe,TResult Function( PortableTimelineSegment value)?  segment,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortableTimelineKeyframe() when keyframe != null:
return keyframe(_that);case PortableTimelineSegment() when segment != null:
return segment(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortableTimelineKeyframe value)  keyframe,required TResult Function( PortableTimelineSegment value)  segment,}){
final _that = this;
switch (_that) {
case PortableTimelineKeyframe():
return keyframe(_that);case PortableTimelineSegment():
return segment(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortableTimelineKeyframe value)?  keyframe,TResult? Function( PortableTimelineSegment value)?  segment,}){
final _that = this;
switch (_that) {
case PortableTimelineKeyframe() when keyframe != null:
return keyframe(_that);case PortableTimelineSegment() when segment != null:
return segment(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int frame)?  keyframe,TResult Function( int startFrame,  int endFrame)?  segment,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortableTimelineKeyframe() when keyframe != null:
return keyframe(_that.frame);case PortableTimelineSegment() when segment != null:
return segment(_that.startFrame,_that.endFrame);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int frame)  keyframe,required TResult Function( int startFrame,  int endFrame)  segment,}) {final _that = this;
switch (_that) {
case PortableTimelineKeyframe():
return keyframe(_that.frame);case PortableTimelineSegment():
return segment(_that.startFrame,_that.endFrame);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int frame)?  keyframe,TResult? Function( int startFrame,  int endFrame)?  segment,}) {final _that = this;
switch (_that) {
case PortableTimelineKeyframe() when keyframe != null:
return keyframe(_that.frame);case PortableTimelineSegment() when segment != null:
return segment(_that.startFrame,_that.endFrame);case _:
  return null;

}
}

}

/// @nodoc


class PortableTimelineKeyframe implements PortableTimelinePlacement {
  const PortableTimelineKeyframe(this.frame);


 final  int frame;

/// Create a copy of PortableTimelinePlacement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableTimelineKeyframeCopyWith<PortableTimelineKeyframe> get copyWith => _$PortableTimelineKeyframeCopyWithImpl<PortableTimelineKeyframe>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableTimelineKeyframe&&(identical(other.frame, frame) || other.frame == frame));
}


@override
int get hashCode {
    return Object.hash(runtimeType,frame);
}

@override
String toString() {
    return 'PortableTimelinePlacement.keyframe(frame: $frame)';
}


}

/// @nodoc
abstract mixin class $PortableTimelineKeyframeCopyWith<$Res> implements $PortableTimelinePlacementCopyWith<$Res> {
  factory $PortableTimelineKeyframeCopyWith(PortableTimelineKeyframe value, $Res Function(PortableTimelineKeyframe) _then) = _$PortableTimelineKeyframeCopyWithImpl;
@useResult
$Res call({
 int frame
});




}
/// @nodoc
class _$PortableTimelineKeyframeCopyWithImpl<$Res>
    implements $PortableTimelineKeyframeCopyWith<$Res> {
  _$PortableTimelineKeyframeCopyWithImpl(this._self, this._then);

  final PortableTimelineKeyframe _self;
  final $Res Function(PortableTimelineKeyframe) _then;

/// Create a copy of PortableTimelinePlacement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? frame = null,}) {
  return _then(PortableTimelineKeyframe(
null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class PortableTimelineSegment implements PortableTimelinePlacement {
  const PortableTimelineSegment(this.startFrame, this.endFrame);


 final  int startFrame;
 final  int endFrame;

/// Create a copy of PortableTimelinePlacement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableTimelineSegmentCopyWith<PortableTimelineSegment> get copyWith => _$PortableTimelineSegmentCopyWithImpl<PortableTimelineSegment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableTimelineSegment&&(identical(other.startFrame, startFrame) || other.startFrame == startFrame)&&(identical(other.endFrame, endFrame) || other.endFrame == endFrame));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startFrame,endFrame);
}

@override
String toString() {
    return 'PortableTimelinePlacement.segment(startFrame: $startFrame, endFrame: $endFrame)';
}


}

/// @nodoc
abstract mixin class $PortableTimelineSegmentCopyWith<$Res> implements $PortableTimelinePlacementCopyWith<$Res> {
  factory $PortableTimelineSegmentCopyWith(PortableTimelineSegment value, $Res Function(PortableTimelineSegment) _then) = _$PortableTimelineSegmentCopyWithImpl;
@useResult
$Res call({
 int startFrame, int endFrame
});




}
/// @nodoc
class _$PortableTimelineSegmentCopyWithImpl<$Res>
    implements $PortableTimelineSegmentCopyWith<$Res> {
  _$PortableTimelineSegmentCopyWithImpl(this._self, this._then);

  final PortableTimelineSegment _self;
  final $Res Function(PortableTimelineSegment) _then;

/// Create a copy of PortableTimelinePlacement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startFrame = null,Object? endFrame = null,}) {
  return _then(PortableTimelineSegment(
null == startFrame ? _self.startFrame : startFrame // ignore: cast_nullable_to_non_nullable
as int,null == endFrame ? _self.endFrame : endFrame // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PortableTimelineCueProjection {

 skir.ResourceId get resource; String get label; PortableTimelinePlacement get placement; List<PortableTimelineCueProjection> get children;
/// Create a copy of PortableTimelineCueProjection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableTimelineCueProjectionCopyWith<PortableTimelineCueProjection> get copyWith => _$PortableTimelineCueProjectionCopyWithImpl<PortableTimelineCueProjection>(this as PortableTimelineCueProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableTimelineCueProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableTimelineCueProjection&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.placement, _this.placement) || other.placement == _this.placement)&&const DeepCollectionEquality().equals(other.children, _this.children));
}


@override
int get hashCode {
  final _this = this as PortableTimelineCueProjection;
  return Object.hash(runtimeType,_this.resource,_this.label,_this.placement,const DeepCollectionEquality().hash(_this.children));
}

@override
String toString() {
  final _this = this as PortableTimelineCueProjection;
  return 'PortableTimelineCueProjection(resource: ${_this.resource}, label: ${_this.label}, placement: ${_this.placement}, children: ${_this.children})';
}


}

/// @nodoc
abstract mixin class $PortableTimelineCueProjectionCopyWith<$Res>  {
  factory $PortableTimelineCueProjectionCopyWith(PortableTimelineCueProjection value, $Res Function(PortableTimelineCueProjection) _then) = _$PortableTimelineCueProjectionCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, String label, PortableTimelinePlacement placement, List<PortableTimelineCueProjection> children
});


$PortableTimelinePlacementCopyWith<$Res> get placement;

}
/// @nodoc
class _$PortableTimelineCueProjectionCopyWithImpl<$Res>
    implements $PortableTimelineCueProjectionCopyWith<$Res> {
  _$PortableTimelineCueProjectionCopyWithImpl(this._self, this._then);

  final PortableTimelineCueProjection _self;
  final $Res Function(PortableTimelineCueProjection) _then;

/// Create a copy of PortableTimelineCueProjection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? label = null,Object? placement = null,Object? children = null,}) {
  return _then(PortableTimelineCueProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as PortableTimelinePlacement,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<PortableTimelineCueProjection>,
  ));
}
/// Create a copy of PortableTimelineCueProjection
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableTimelinePlacementCopyWith<$Res> get placement {

  return $PortableTimelinePlacementCopyWith<$Res>(_self.placement, (value) {
    return _then(_self.copyWith(placement: value));
  });
}
}



/// @nodoc


class _PortableTimelineCueProjection implements PortableTimelineCueProjection {
  const _PortableTimelineCueProjection({required this.resource, required this.label, required this.placement, required  List<PortableTimelineCueProjection> children}): _children = children;


@override final  skir.ResourceId resource;
@override final  String label;
@override final  PortableTimelinePlacement placement;
 final  List<PortableTimelineCueProjection> _children;
@override List<PortableTimelineCueProjection> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of PortableTimelineCueProjection
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableTimelineCueProjectionCopyWith<_PortableTimelineCueProjection> get copyWith => __$PortableTimelineCueProjectionCopyWithImpl<_PortableTimelineCueProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableTimelineCueProjection&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.label, label) || other.label == label)&&(identical(other.placement, placement) || other.placement == placement)&&const DeepCollectionEquality().equals(other.children, _children));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,label,placement,const DeepCollectionEquality().hash(_children));
}

@override
String toString() {
    return 'PortableTimelineCueProjection._value(resource: $resource, label: $label, placement: $placement, children: $children)';
}


}

/// @nodoc
abstract mixin class _$PortableTimelineCueProjectionCopyWith<$Res> implements $PortableTimelineCueProjectionCopyWith<$Res> {
  factory _$PortableTimelineCueProjectionCopyWith(_PortableTimelineCueProjection value, $Res Function(_PortableTimelineCueProjection) _then) = __$PortableTimelineCueProjectionCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, String label, PortableTimelinePlacement placement, List<PortableTimelineCueProjection> children
});


@override $PortableTimelinePlacementCopyWith<$Res> get placement;

}
/// @nodoc
class __$PortableTimelineCueProjectionCopyWithImpl<$Res>
    implements _$PortableTimelineCueProjectionCopyWith<$Res> {
  __$PortableTimelineCueProjectionCopyWithImpl(this._self, this._then);

  final _PortableTimelineCueProjection _self;
  final $Res Function(_PortableTimelineCueProjection) _then;

/// Create a copy of PortableTimelineCueProjection
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? label = null,Object? placement = null,Object? children = null,}) {
  return _then(_PortableTimelineCueProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as PortableTimelinePlacement,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<PortableTimelineCueProjection>,
  ));
}

/// Create a copy of PortableTimelineCueProjection
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableTimelinePlacementCopyWith<$Res> get placement {

  return $PortableTimelinePlacementCopyWith<$Res>(_self.placement, (value) {
    return _then(_self.copyWith(placement: value));
  });
}
}

/// @nodoc
mixin _$PortablePageProjection {

 List<PortablePageEntryProjection> get entries; List<PortablePageEdgeProjection> get edges; Map<skir.ResourceId, List<PortableTimelineCueProjection>> get timeline; String? get problem;
/// Create a copy of PortablePageProjection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePageProjectionCopyWith<PortablePageProjection> get copyWith => _$PortablePageProjectionCopyWithImpl<PortablePageProjection>(this as PortablePageProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePageProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePageProjection&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&const DeepCollectionEquality().equals(other.edges, _this.edges)&&const DeepCollectionEquality().equals(other.timeline, _this.timeline)&&(identical(other.problem, _this.problem) || other.problem == _this.problem));
}


@override
int get hashCode {
  final _this = this as PortablePageProjection;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.entries),const DeepCollectionEquality().hash(_this.edges),const DeepCollectionEquality().hash(_this.timeline),_this.problem);
}

@override
String toString() {
  final _this = this as PortablePageProjection;
  return 'PortablePageProjection(entries: ${_this.entries}, edges: ${_this.edges}, timeline: ${_this.timeline}, problem: ${_this.problem})';
}


}

/// @nodoc
abstract mixin class $PortablePageProjectionCopyWith<$Res>  {
  factory $PortablePageProjectionCopyWith(PortablePageProjection value, $Res Function(PortablePageProjection) _then) = _$PortablePageProjectionCopyWithImpl;
@useResult
$Res call({
 List<PortablePageEntryProjection> entries, List<PortablePageEdgeProjection> edges, Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline, String? problem
});




}
/// @nodoc
class _$PortablePageProjectionCopyWithImpl<$Res>
    implements $PortablePageProjectionCopyWith<$Res> {
  _$PortablePageProjectionCopyWithImpl(this._self, this._then);

  final PortablePageProjection _self;
  final $Res Function(PortablePageProjection) _then;

/// Create a copy of PortablePageProjection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,Object? edges = null,Object? timeline = null,Object? problem = freezed,}) {
  return _then(PortablePageProjection(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<PortablePageEntryProjection>,edges: null == edges ? _self.edges : edges // ignore: cast_nullable_to_non_nullable
as List<PortablePageEdgeProjection>,timeline: null == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<PortableTimelineCueProjection>>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}



/// @nodoc


class _PortablePageProjection implements PortablePageProjection {
  const _PortablePageProjection({required  List<PortablePageEntryProjection> entries, required  List<PortablePageEdgeProjection> edges, required  Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline, required this.problem}): _entries = entries,_edges = edges,_timeline = timeline;


 final  List<PortablePageEntryProjection> _entries;
@override List<PortablePageEntryProjection> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<PortablePageEdgeProjection> _edges;
@override List<PortablePageEdgeProjection> get edges {
  if (_edges is EqualUnmodifiableListView) return _edges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_edges);
}

 final  Map<skir.ResourceId, List<PortableTimelineCueProjection>> _timeline;
@override Map<skir.ResourceId, List<PortableTimelineCueProjection>> get timeline {
  if (_timeline is EqualUnmodifiableMapView) return _timeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_timeline);
}

@override final  String? problem;

/// Create a copy of PortablePageProjection
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePageProjectionCopyWith<_PortablePageProjection> get copyWith => __$PortablePageProjectionCopyWithImpl<_PortablePageProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePageProjection&&const DeepCollectionEquality().equals(other.entries, _entries)&&const DeepCollectionEquality().equals(other.edges, _edges)&&const DeepCollectionEquality().equals(other.timeline, _timeline)&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_edges),const DeepCollectionEquality().hash(_timeline),problem);
}

@override
String toString() {
    return 'PortablePageProjection._value(entries: $entries, edges: $edges, timeline: $timeline, problem: $problem)';
}


}

/// @nodoc
abstract mixin class _$PortablePageProjectionCopyWith<$Res> implements $PortablePageProjectionCopyWith<$Res> {
  factory _$PortablePageProjectionCopyWith(_PortablePageProjection value, $Res Function(_PortablePageProjection) _then) = __$PortablePageProjectionCopyWithImpl;
@override @useResult
$Res call({
 List<PortablePageEntryProjection> entries, List<PortablePageEdgeProjection> edges, Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline, String? problem
});




}
/// @nodoc
class __$PortablePageProjectionCopyWithImpl<$Res>
    implements _$PortablePageProjectionCopyWith<$Res> {
  __$PortablePageProjectionCopyWithImpl(this._self, this._then);

  final _PortablePageProjection _self;
  final $Res Function(_PortablePageProjection) _then;

/// Create a copy of PortablePageProjection
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,Object? edges = null,Object? timeline = null,Object? problem = freezed,}) {
  return _then(_PortablePageProjection(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<PortablePageEntryProjection>,edges: null == edges ? _self._edges : edges // ignore: cast_nullable_to_non_nullable
as List<PortablePageEdgeProjection>,timeline: null == timeline ? _self._timeline : timeline // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<PortableTimelineCueProjection>>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
