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

 CheckedEditorCatalog get catalog; skir.PresentationNode get root; Map<skir.ExpressionBindingId, PortablePresentationBinding> get bindings; skir.EvaluationBudget get budget; PortableExpressionQueries? get queries; ResourceDiagnosticReader get resourceDiagnostics; List<PortablePresentationDiagnostic> get diagnostics; PortableDiagnosticFallback get diagnosticFallback; skir.PresentationRole? get role; skir.PresentationMaterial? get material;/// Values the presentation reads from its surroundings: the material's
/// declarations, or those of a presentation built without material.
 List<skir.PresentationContextInput> get contextInputs; Set<skir.PresentationId> get activePresentations; Map<String, skir.PresentationNode> get slots;



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationDocument&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.root, _this.root) || other.root == _this.root)&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&(identical(other.queries, _this.queries) || other.queries == _this.queries)&&(identical(other.resourceDiagnostics, _this.resourceDiagnostics) || other.resourceDiagnostics == _this.resourceDiagnostics)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics)&&(identical(other.diagnosticFallback, _this.diagnosticFallback) || other.diagnosticFallback == _this.diagnosticFallback)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.material, _this.material) || other.material == _this.material)&&const DeepCollectionEquality().equals(other.contextInputs, _this.contextInputs)&&const DeepCollectionEquality().equals(other.activePresentations, _this.activePresentations)&&const DeepCollectionEquality().equals(other.slots, _this.slots));
}


@override
int get hashCode {
  final _this = this as PortablePresentationDocument;
  return Object.hash(runtimeType,_this.catalog,_this.root,const DeepCollectionEquality().hash(_this.bindings),_this.budget,_this.queries,_this.resourceDiagnostics,const DeepCollectionEquality().hash(_this.diagnostics),_this.diagnosticFallback,_this.role,_this.material,const DeepCollectionEquality().hash(_this.contextInputs),const DeepCollectionEquality().hash(_this.activePresentations),const DeepCollectionEquality().hash(_this.slots));
}

@override
String toString() {
  final _this = this as PortablePresentationDocument;
  return 'PortablePresentationDocument(catalog: ${_this.catalog}, root: ${_this.root}, bindings: ${_this.bindings}, budget: ${_this.budget}, queries: ${_this.queries}, resourceDiagnostics: ${_this.resourceDiagnostics}, diagnostics: ${_this.diagnostics}, diagnosticFallback: ${_this.diagnosticFallback}, role: ${_this.role}, material: ${_this.material}, contextInputs: ${_this.contextInputs}, activePresentations: ${_this.activePresentations}, slots: ${_this.slots})';
}


}





/// @nodoc


class _PortablePresentationDocument extends PortablePresentationDocument {
  const _PortablePresentationDocument({required this.catalog, required this.root, required  Map<skir.ExpressionBindingId, PortablePresentationBinding> bindings, required this.budget, required this.queries, required this.resourceDiagnostics, required  List<PortablePresentationDiagnostic> diagnostics, required this.diagnosticFallback, required this.role, required this.material, required  List<skir.PresentationContextInput> contextInputs, required  Set<skir.PresentationId> activePresentations, required  Map<String, skir.PresentationNode> slots}): _bindings = bindings,_diagnostics = diagnostics,_contextInputs = contextInputs,_activePresentations = activePresentations,_slots = slots,super._();
  

@override final  CheckedEditorCatalog catalog;
@override final  skir.PresentationNode root;
 final  Map<skir.ExpressionBindingId, PortablePresentationBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortablePresentationBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;
@override final  PortableExpressionQueries? queries;
@override final  ResourceDiagnosticReader resourceDiagnostics;
 final  List<PortablePresentationDiagnostic> _diagnostics;
@override List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

@override final  PortableDiagnosticFallback diagnosticFallback;
@override final  skir.PresentationRole? role;
@override final  skir.PresentationMaterial? material;
/// Values the presentation reads from its surroundings: the material's
/// declarations, or those of a presentation built without material.
 final  List<skir.PresentationContextInput> _contextInputs;
/// Values the presentation reads from its surroundings: the material's
/// declarations, or those of a presentation built without material.
@override List<skir.PresentationContextInput> get contextInputs {
  if (_contextInputs is EqualUnmodifiableListView) return _contextInputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contextInputs);
}

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationDocument&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.root, root) || other.root == root)&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.queries, queries) || other.queries == queries)&&(identical(other.resourceDiagnostics, resourceDiagnostics) || other.resourceDiagnostics == resourceDiagnostics)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics)&&(identical(other.diagnosticFallback, diagnosticFallback) || other.diagnosticFallback == diagnosticFallback)&&(identical(other.role, role) || other.role == role)&&(identical(other.material, material) || other.material == material)&&const DeepCollectionEquality().equals(other.contextInputs, _contextInputs)&&const DeepCollectionEquality().equals(other.activePresentations, _activePresentations)&&const DeepCollectionEquality().equals(other.slots, _slots));
}


@override
int get hashCode {
    return Object.hash(runtimeType,catalog,root,const DeepCollectionEquality().hash(_bindings),budget,queries,resourceDiagnostics,const DeepCollectionEquality().hash(_diagnostics),diagnosticFallback,role,material,const DeepCollectionEquality().hash(_contextInputs),const DeepCollectionEquality().hash(_activePresentations),const DeepCollectionEquality().hash(_slots));
}

@override
String toString() {
    return 'PortablePresentationDocument._value(catalog: $catalog, root: $root, bindings: $bindings, budget: $budget, queries: $queries, resourceDiagnostics: $resourceDiagnostics, diagnostics: $diagnostics, diagnosticFallback: $diagnosticFallback, role: $role, material: $material, contextInputs: $contextInputs, activePresentations: $activePresentations, slots: $slots)';
}


}




/// @nodoc
mixin _$PortableInvocationContext {

 Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings; skir.CatalogGeneration get catalogGeneration; PortableExpressionQueries? get queries; ResourceDiagnosticReader get resourceDiagnostics; List<skir.ValueLocation> get expressionReads;



@override
bool operator ==(Object other) {
  final _this = this as PortableInvocationContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableInvocationContext&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.catalogGeneration, _this.catalogGeneration) || other.catalogGeneration == _this.catalogGeneration)&&(identical(other.queries, _this.queries) || other.queries == _this.queries)&&(identical(other.resourceDiagnostics, _this.resourceDiagnostics) || other.resourceDiagnostics == _this.resourceDiagnostics)&&const DeepCollectionEquality().equals(other.expressionReads, _this.expressionReads));
}


@override
int get hashCode {
  final _this = this as PortableInvocationContext;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.bindings),_this.catalogGeneration,_this.queries,_this.resourceDiagnostics,const DeepCollectionEquality().hash(_this.expressionReads));
}

@override
String toString() {
  final _this = this as PortableInvocationContext;
  return 'PortableInvocationContext(bindings: ${_this.bindings}, catalogGeneration: ${_this.catalogGeneration}, queries: ${_this.queries}, resourceDiagnostics: ${_this.resourceDiagnostics}, expressionReads: ${_this.expressionReads})';
}


}





/// @nodoc


class _PortableInvocationContext extends PortableInvocationContext {
  const _PortableInvocationContext({required  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, required this.catalogGeneration, required this.queries, required this.resourceDiagnostics, required  List<skir.ValueLocation> expressionReads}): _bindings = bindings,_expressionReads = expressionReads,super._();
  

 final  Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.CatalogGeneration catalogGeneration;
@override final  PortableExpressionQueries? queries;
@override final  ResourceDiagnosticReader resourceDiagnostics;
 final  List<skir.ValueLocation> _expressionReads;
@override List<skir.ValueLocation> get expressionReads {
  if (_expressionReads is EqualUnmodifiableListView) return _expressionReads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expressionReads);
}





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableInvocationContext&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.catalogGeneration, catalogGeneration) || other.catalogGeneration == catalogGeneration)&&(identical(other.queries, queries) || other.queries == queries)&&(identical(other.resourceDiagnostics, resourceDiagnostics) || other.resourceDiagnostics == resourceDiagnostics)&&const DeepCollectionEquality().equals(other.expressionReads, _expressionReads));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_bindings),catalogGeneration,queries,resourceDiagnostics,const DeepCollectionEquality().hash(_expressionReads));
}

@override
String toString() {
    return 'PortableInvocationContext._value(bindings: $bindings, catalogGeneration: $catalogGeneration, queries: $queries, resourceDiagnostics: $resourceDiagnostics, expressionReads: $expressionReads)';
}


}




/// @nodoc
mixin _$PortablePresentationCapabilities {

 Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? get invokeCommand; Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? get watchSearch; Future<void> Function()? get reload; ValueChanged<skir.ResourceId>? get openResource; Future<PortablePresentationWriteResult> Function(skir.EditorAction action, PortableInvocationContext context)? get resourceAction; Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? get prepareValue;
/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationCapabilitiesCopyWith<PortablePresentationCapabilities> get copyWith => _$PortablePresentationCapabilitiesCopyWithImpl<PortablePresentationCapabilities>(this as PortablePresentationCapabilities, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationCapabilities;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationCapabilities&&(identical(other.invokeCommand, _this.invokeCommand) || other.invokeCommand == _this.invokeCommand)&&(identical(other.watchSearch, _this.watchSearch) || other.watchSearch == _this.watchSearch)&&(identical(other.reload, _this.reload) || other.reload == _this.reload)&&(identical(other.openResource, _this.openResource) || other.openResource == _this.openResource)&&(identical(other.resourceAction, _this.resourceAction) || other.resourceAction == _this.resourceAction)&&(identical(other.prepareValue, _this.prepareValue) || other.prepareValue == _this.prepareValue));
}


@override
int get hashCode {
  final _this = this as PortablePresentationCapabilities;
  return Object.hash(runtimeType,_this.invokeCommand,_this.watchSearch,_this.reload,_this.openResource,_this.resourceAction,_this.prepareValue);
}

@override
String toString() {
  final _this = this as PortablePresentationCapabilities;
  return 'PortablePresentationCapabilities(invokeCommand: ${_this.invokeCommand}, watchSearch: ${_this.watchSearch}, reload: ${_this.reload}, openResource: ${_this.openResource}, resourceAction: ${_this.resourceAction}, prepareValue: ${_this.prepareValue})';
}


}

/// @nodoc
abstract mixin class $PortablePresentationCapabilitiesCopyWith<$Res>  {
  factory $PortablePresentationCapabilitiesCopyWith(PortablePresentationCapabilities value, $Res Function(PortablePresentationCapabilities) _then) = _$PortablePresentationCapabilitiesCopyWithImpl;
@useResult
$Res call({
 Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, Future<void> Function()? reload, ValueChanged<skir.ResourceId>? openResource, Future<PortablePresentationWriteResult> Function(skir.EditorAction action, PortableInvocationContext context)? resourceAction, Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue
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
@pragma('vm:prefer-inline') @override $Res call({Object? invokeCommand = freezed,Object? watchSearch = freezed,Object? reload = freezed,Object? openResource = freezed,Object? resourceAction = freezed,Object? prepareValue = freezed,}) {
  return _then(PortablePresentationCapabilities(
invokeCommand: freezed == invokeCommand ? _self.invokeCommand : invokeCommand // ignore: cast_nullable_to_non_nullable
as Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)?,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reload: freezed == reload ? _self.reload : reload // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,resourceAction: freezed == resourceAction ? _self.resourceAction : resourceAction // ignore: cast_nullable_to_non_nullable
as Future<PortablePresentationWriteResult> Function(skir.EditorAction action, PortableInvocationContext context)?,prepareValue: freezed == prepareValue ? _self.prepareValue : prepareValue // ignore: cast_nullable_to_non_nullable
as Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand,  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch,  Future<void> Function()? reload,  ValueChanged<skir.ResourceId>? openResource,  Future<PortablePresentationWriteResult> Function(skir.EditorAction action, PortableInvocationContext context)? resourceAction,  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortablePresentationCapabilities() when $default != null:
return $default(_that.invokeCommand,_that.watchSearch,_that.reload,_that.openResource,_that.resourceAction,_that.prepareValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand,  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch,  Future<void> Function()? reload,  ValueChanged<skir.ResourceId>? openResource,  Future<PortablePresentationWriteResult> Function(skir.EditorAction action, PortableInvocationContext context)? resourceAction,  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue)  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationCapabilities():
return $default(_that.invokeCommand,_that.watchSearch,_that.reload,_that.openResource,_that.resourceAction,_that.prepareValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand,  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch,  Future<void> Function()? reload,  ValueChanged<skir.ResourceId>? openResource,  Future<PortablePresentationWriteResult> Function(skir.EditorAction action, PortableInvocationContext context)? resourceAction,  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue)?  $default,) {final _that = this;
switch (_that) {
case _PortablePresentationCapabilities() when $default != null:
return $default(_that.invokeCommand,_that.watchSearch,_that.reload,_that.openResource,_that.resourceAction,_that.prepareValue);case _:
  return null;

}
}

}

/// @nodoc


class _PortablePresentationCapabilities implements PortablePresentationCapabilities {
  const _PortablePresentationCapabilities({this.invokeCommand, this.watchSearch, this.reload, this.openResource, this.resourceAction, this.prepareValue});
  

@override final  Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand;
@override final  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch;
@override final  Future<void> Function()? reload;
@override final  ValueChanged<skir.ResourceId>? openResource;
@override final  Future<PortablePresentationWriteResult> Function(skir.EditorAction action, PortableInvocationContext context)? resourceAction;
@override final  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue;

/// Create a copy of PortablePresentationCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePresentationCapabilitiesCopyWith<_PortablePresentationCapabilities> get copyWith => __$PortablePresentationCapabilitiesCopyWithImpl<_PortablePresentationCapabilities>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationCapabilities&&(identical(other.invokeCommand, invokeCommand) || other.invokeCommand == invokeCommand)&&(identical(other.watchSearch, watchSearch) || other.watchSearch == watchSearch)&&(identical(other.reload, reload) || other.reload == reload)&&(identical(other.openResource, openResource) || other.openResource == openResource)&&(identical(other.resourceAction, resourceAction) || other.resourceAction == resourceAction)&&(identical(other.prepareValue, prepareValue) || other.prepareValue == prepareValue));
}


@override
int get hashCode {
    return Object.hash(runtimeType,invokeCommand,watchSearch,reload,openResource,resourceAction,prepareValue);
}

@override
String toString() {
    return 'PortablePresentationCapabilities(invokeCommand: $invokeCommand, watchSearch: $watchSearch, reload: $reload, openResource: $openResource, resourceAction: $resourceAction, prepareValue: $prepareValue)';
}


}

/// @nodoc
abstract mixin class _$PortablePresentationCapabilitiesCopyWith<$Res> implements $PortablePresentationCapabilitiesCopyWith<$Res> {
  factory _$PortablePresentationCapabilitiesCopyWith(_PortablePresentationCapabilities value, $Res Function(_PortablePresentationCapabilities) _then) = __$PortablePresentationCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)? invokeCommand, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, Future<void> Function()? reload, ValueChanged<skir.ResourceId>? openResource, Future<PortablePresentationWriteResult> Function(skir.EditorAction action, PortableInvocationContext context)? resourceAction, Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)? prepareValue
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
@override @pragma('vm:prefer-inline') $Res call({Object? invokeCommand = freezed,Object? watchSearch = freezed,Object? reload = freezed,Object? openResource = freezed,Object? resourceAction = freezed,Object? prepareValue = freezed,}) {
  return _then(_PortablePresentationCapabilities(
invokeCommand: freezed == invokeCommand ? _self.invokeCommand : invokeCommand // ignore: cast_nullable_to_non_nullable
as Future<void> Function(skir.CapabilityId capabilityId, skir.DataValue payload)?,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reload: freezed == reload ? _self.reload : reload // ignore: cast_nullable_to_non_nullable
as Future<void> Function()?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,resourceAction: freezed == resourceAction ? _self.resourceAction : resourceAction // ignore: cast_nullable_to_non_nullable
as Future<PortablePresentationWriteResult> Function(skir.EditorAction action, PortableInvocationContext context)?,prepareValue: freezed == prepareValue ? _self.prepareValue : prepareValue // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  applied,TResult Function( List<PortablePresentationDiagnostic> diagnostics)?  rejected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortablePresentationWriteApplied() when applied != null:
return applied();case PortablePresentationWriteRejected() when rejected != null:
return rejected(_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  applied,required TResult Function( List<PortablePresentationDiagnostic> diagnostics)  rejected,}) {final _that = this;
switch (_that) {
case PortablePresentationWriteApplied():
return applied();case PortablePresentationWriteRejected():
return rejected(_that.diagnostics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  applied,TResult? Function( List<PortablePresentationDiagnostic> diagnostics)?  rejected,}) {final _that = this;
switch (_that) {
case PortablePresentationWriteApplied() when applied != null:
return applied();case PortablePresentationWriteRejected() when rejected != null:
return rejected(_that.diagnostics);case _:
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
  const PortablePresentationWriteRejected( List<PortablePresentationDiagnostic> diagnostics): _diagnostics = diagnostics;
  

 final  List<PortablePresentationDiagnostic> _diagnostics;
 List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of PortablePresentationWriteResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationWriteRejectedCopyWith<PortablePresentationWriteRejected> get copyWith => _$PortablePresentationWriteRejectedCopyWithImpl<PortablePresentationWriteRejected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationWriteRejected&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'PortablePresentationWriteResult.rejected(diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $PortablePresentationWriteRejectedCopyWith<$Res> implements $PortablePresentationWriteResultCopyWith<$Res> {
  factory $PortablePresentationWriteRejectedCopyWith(PortablePresentationWriteRejected value, $Res Function(PortablePresentationWriteRejected) _then) = _$PortablePresentationWriteRejectedCopyWithImpl;
@useResult
$Res call({
 List<PortablePresentationDiagnostic> diagnostics
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
@pragma('vm:prefer-inline') $Res call({Object? diagnostics = null,}) {
  return _then(PortablePresentationWriteRejected(
null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$PortableCollectionRowProjection {

 skir.ResourceId get resource; skir.TypeSelection get configuration; String get label; skir.DataValue get row; skir.DataValue get key; String get canonicalKey; bool get selectable;
/// Create a copy of PortableCollectionRowProjection
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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


/// Adds pattern-matching-related methods to [PortableCollectionRowProjection].
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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

 skir.ResourceId get resource; skir.TypeSelection get configuration; skir.ResourceAppearance get appearance; skir.DataValue get value; List<PortablePresentationDiagnostic> get diagnostics; PortableDiagnosticFallback get diagnosticFallback;
/// Create a copy of PortableResourceProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableResourceProjectionCopyWith<PortableResourceProjection> get copyWith => _$PortableResourceProjectionCopyWithImpl<PortableResourceProjection>(this as PortableResourceProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableResourceProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableResourceProjection&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.configuration, _this.configuration) || other.configuration == _this.configuration)&&(identical(other.appearance, _this.appearance) || other.appearance == _this.appearance)&&(identical(other.value, _this.value) || other.value == _this.value)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics)&&(identical(other.diagnosticFallback, _this.diagnosticFallback) || other.diagnosticFallback == _this.diagnosticFallback));
}


@override
int get hashCode {
  final _this = this as PortableResourceProjection;
  return Object.hash(runtimeType,_this.resource,_this.configuration,_this.appearance,_this.value,const DeepCollectionEquality().hash(_this.diagnostics),_this.diagnosticFallback);
}

@override
String toString() {
  final _this = this as PortableResourceProjection;
  return 'PortableResourceProjection(resource: ${_this.resource}, configuration: ${_this.configuration}, appearance: ${_this.appearance}, value: ${_this.value}, diagnostics: ${_this.diagnostics}, diagnosticFallback: ${_this.diagnosticFallback})';
}


}

/// @nodoc
abstract mixin class $PortableResourceProjectionCopyWith<$Res>  {
  factory $PortableResourceProjectionCopyWith(PortableResourceProjection value, $Res Function(PortableResourceProjection) _then) = _$PortableResourceProjectionCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, skir.TypeSelection configuration, skir.ResourceAppearance appearance, skir.DataValue value, List<PortablePresentationDiagnostic> diagnostics, PortableDiagnosticFallback diagnosticFallback
});




}
/// @nodoc
class _$PortableResourceProjectionCopyWithImpl<$Res>
    implements $PortableResourceProjectionCopyWith<$Res> {
  _$PortableResourceProjectionCopyWithImpl(this._self, this._then);

  final PortableResourceProjection _self;
  final $Res Function(PortableResourceProjection) _then;

/// Create a copy of PortableResourceProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? configuration = null,Object? appearance = null,Object? value = null,Object? diagnostics = null,Object? diagnosticFallback = null,}) {
  return _then(PortableResourceProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.ResourceAppearance,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,diagnosticFallback: null == diagnosticFallback ? _self.diagnosticFallback : diagnosticFallback // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticFallback,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableResourceProjection].
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.TypeSelection configuration,  skir.ResourceAppearance appearance,  skir.DataValue value,  List<PortablePresentationDiagnostic> diagnostics,  PortableDiagnosticFallback diagnosticFallback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableResourceProjection() when $default != null:
return $default(_that.resource,_that.configuration,_that.appearance,_that.value,_that.diagnostics,_that.diagnosticFallback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.TypeSelection configuration,  skir.ResourceAppearance appearance,  skir.DataValue value,  List<PortablePresentationDiagnostic> diagnostics,  PortableDiagnosticFallback diagnosticFallback)  $default,) {final _that = this;
switch (_that) {
case _PortableResourceProjection():
return $default(_that.resource,_that.configuration,_that.appearance,_that.value,_that.diagnostics,_that.diagnosticFallback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId resource,  skir.TypeSelection configuration,  skir.ResourceAppearance appearance,  skir.DataValue value,  List<PortablePresentationDiagnostic> diagnostics,  PortableDiagnosticFallback diagnosticFallback)?  $default,) {final _that = this;
switch (_that) {
case _PortableResourceProjection() when $default != null:
return $default(_that.resource,_that.configuration,_that.appearance,_that.value,_that.diagnostics,_that.diagnosticFallback);case _:
  return null;

}
}

}

/// @nodoc


class _PortableResourceProjection implements PortableResourceProjection {
  const _PortableResourceProjection({required this.resource, required this.configuration, required this.appearance, required this.value,  List<PortablePresentationDiagnostic> diagnostics = const [], this.diagnosticFallback = PortableDiagnosticFallback.presentation}): _diagnostics = diagnostics;
  

@override final  skir.ResourceId resource;
@override final  skir.TypeSelection configuration;
@override final  skir.ResourceAppearance appearance;
@override final  skir.DataValue value;
 final  List<PortablePresentationDiagnostic> _diagnostics;
@override@JsonKey() List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

@override@JsonKey() final  PortableDiagnosticFallback diagnosticFallback;

/// Create a copy of PortableResourceProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableResourceProjectionCopyWith<_PortableResourceProjection> get copyWith => __$PortableResourceProjectionCopyWithImpl<_PortableResourceProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableResourceProjection&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.configuration, configuration) || other.configuration == configuration)&&(identical(other.appearance, appearance) || other.appearance == appearance)&&(identical(other.value, value) || other.value == value)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics)&&(identical(other.diagnosticFallback, diagnosticFallback) || other.diagnosticFallback == diagnosticFallback));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,configuration,appearance,value,const DeepCollectionEquality().hash(_diagnostics),diagnosticFallback);
}

@override
String toString() {
    return 'PortableResourceProjection(resource: $resource, configuration: $configuration, appearance: $appearance, value: $value, diagnostics: $diagnostics, diagnosticFallback: $diagnosticFallback)';
}


}

/// @nodoc
abstract mixin class _$PortableResourceProjectionCopyWith<$Res> implements $PortableResourceProjectionCopyWith<$Res> {
  factory _$PortableResourceProjectionCopyWith(_PortableResourceProjection value, $Res Function(_PortableResourceProjection) _then) = __$PortableResourceProjectionCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, skir.TypeSelection configuration, skir.ResourceAppearance appearance, skir.DataValue value, List<PortablePresentationDiagnostic> diagnostics, PortableDiagnosticFallback diagnosticFallback
});




}
/// @nodoc
class __$PortableResourceProjectionCopyWithImpl<$Res>
    implements _$PortableResourceProjectionCopyWith<$Res> {
  __$PortableResourceProjectionCopyWithImpl(this._self, this._then);

  final _PortableResourceProjection _self;
  final $Res Function(_PortableResourceProjection) _then;

/// Create a copy of PortableResourceProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? configuration = null,Object? appearance = null,Object? value = null,Object? diagnostics = null,Object? diagnosticFallback = null,}) {
  return _then(_PortableResourceProjection(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.ResourceAppearance,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,diagnosticFallback: null == diagnosticFallback ? _self.diagnosticFallback : diagnosticFallback // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticFallback,
  ));
}


}

/// @nodoc
mixin _$PortableLinkCounterpartRequest {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableLinkCounterpartRequest);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableLinkCounterpartRequest()';
}


}

/// @nodoc
class $PortableLinkCounterpartRequestCopyWith<$Res>  {
$PortableLinkCounterpartRequestCopyWith(PortableLinkCounterpartRequest _, $Res Function(PortableLinkCounterpartRequest) __);
}


/// Adds pattern-matching-related methods to [PortableLinkCounterpartRequest].
extension PortableLinkCounterpartRequestPatterns on PortableLinkCounterpartRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortableAutomaticCounterpart value)?  automatic,TResult Function( PortableExistingCounterpart value)?  existing,TResult Function( PortableCreatedCounterpart value)?  created,TResult Function( PortableCollectionCounterpart value)?  collection,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortableAutomaticCounterpart() when automatic != null:
return automatic(_that);case PortableExistingCounterpart() when existing != null:
return existing(_that);case PortableCreatedCounterpart() when created != null:
return created(_that);case PortableCollectionCounterpart() when collection != null:
return collection(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortableAutomaticCounterpart value)  automatic,required TResult Function( PortableExistingCounterpart value)  existing,required TResult Function( PortableCreatedCounterpart value)  created,required TResult Function( PortableCollectionCounterpart value)  collection,}){
final _that = this;
switch (_that) {
case PortableAutomaticCounterpart():
return automatic(_that);case PortableExistingCounterpart():
return existing(_that);case PortableCreatedCounterpart():
return created(_that);case PortableCollectionCounterpart():
return collection(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortableAutomaticCounterpart value)?  automatic,TResult? Function( PortableExistingCounterpart value)?  existing,TResult? Function( PortableCreatedCounterpart value)?  created,TResult? Function( PortableCollectionCounterpart value)?  collection,}){
final _that = this;
switch (_that) {
case PortableAutomaticCounterpart() when automatic != null:
return automatic(_that);case PortableExistingCounterpart() when existing != null:
return existing(_that);case PortableCreatedCounterpart() when created != null:
return created(_that);case PortableCollectionCounterpart() when collection != null:
return collection(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  automatic,TResult Function( skir.LinkOccurrence occurrence)?  existing,TResult Function( PortableNewCounterpartChoice slot)?  created,TResult Function( skir.ValueLocation containing)?  collection,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortableAutomaticCounterpart() when automatic != null:
return automatic();case PortableExistingCounterpart() when existing != null:
return existing(_that.occurrence);case PortableCreatedCounterpart() when created != null:
return created(_that.slot);case PortableCollectionCounterpart() when collection != null:
return collection(_that.containing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  automatic,required TResult Function( skir.LinkOccurrence occurrence)  existing,required TResult Function( PortableNewCounterpartChoice slot)  created,required TResult Function( skir.ValueLocation containing)  collection,}) {final _that = this;
switch (_that) {
case PortableAutomaticCounterpart():
return automatic();case PortableExistingCounterpart():
return existing(_that.occurrence);case PortableCreatedCounterpart():
return created(_that.slot);case PortableCollectionCounterpart():
return collection(_that.containing);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  automatic,TResult? Function( skir.LinkOccurrence occurrence)?  existing,TResult? Function( PortableNewCounterpartChoice slot)?  created,TResult? Function( skir.ValueLocation containing)?  collection,}) {final _that = this;
switch (_that) {
case PortableAutomaticCounterpart() when automatic != null:
return automatic();case PortableExistingCounterpart() when existing != null:
return existing(_that.occurrence);case PortableCreatedCounterpart() when created != null:
return created(_that.slot);case PortableCollectionCounterpart() when collection != null:
return collection(_that.containing);case _:
  return null;

}
}

}

/// @nodoc


class PortableAutomaticCounterpart implements PortableLinkCounterpartRequest {
  const PortableAutomaticCounterpart();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableAutomaticCounterpart);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableLinkCounterpartRequest.automatic()';
}


}




/// @nodoc


class PortableExistingCounterpart implements PortableLinkCounterpartRequest {
  const PortableExistingCounterpart(this.occurrence);
  

 final  skir.LinkOccurrence occurrence;

/// Create a copy of PortableLinkCounterpartRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableExistingCounterpartCopyWith<PortableExistingCounterpart> get copyWith => _$PortableExistingCounterpartCopyWithImpl<PortableExistingCounterpart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableExistingCounterpart&&(identical(other.occurrence, occurrence) || other.occurrence == occurrence));
}


@override
int get hashCode {
    return Object.hash(runtimeType,occurrence);
}

@override
String toString() {
    return 'PortableLinkCounterpartRequest.existing(occurrence: $occurrence)';
}


}

/// @nodoc
abstract mixin class $PortableExistingCounterpartCopyWith<$Res> implements $PortableLinkCounterpartRequestCopyWith<$Res> {
  factory $PortableExistingCounterpartCopyWith(PortableExistingCounterpart value, $Res Function(PortableExistingCounterpart) _then) = _$PortableExistingCounterpartCopyWithImpl;
@useResult
$Res call({
 skir.LinkOccurrence occurrence
});




}
/// @nodoc
class _$PortableExistingCounterpartCopyWithImpl<$Res>
    implements $PortableExistingCounterpartCopyWith<$Res> {
  _$PortableExistingCounterpartCopyWithImpl(this._self, this._then);

  final PortableExistingCounterpart _self;
  final $Res Function(PortableExistingCounterpart) _then;

/// Create a copy of PortableLinkCounterpartRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? occurrence = null,}) {
  return _then(PortableExistingCounterpart(
null == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence,
  ));
}


}

/// @nodoc


class PortableCreatedCounterpart implements PortableLinkCounterpartRequest {
  const PortableCreatedCounterpart(this.slot);
  

 final  PortableNewCounterpartChoice slot;

/// Create a copy of PortableLinkCounterpartRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableCreatedCounterpartCopyWith<PortableCreatedCounterpart> get copyWith => _$PortableCreatedCounterpartCopyWithImpl<PortableCreatedCounterpart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableCreatedCounterpart&&(identical(other.slot, slot) || other.slot == slot));
}


@override
int get hashCode {
    return Object.hash(runtimeType,slot);
}

@override
String toString() {
    return 'PortableLinkCounterpartRequest.created(slot: $slot)';
}


}

/// @nodoc
abstract mixin class $PortableCreatedCounterpartCopyWith<$Res> implements $PortableLinkCounterpartRequestCopyWith<$Res> {
  factory $PortableCreatedCounterpartCopyWith(PortableCreatedCounterpart value, $Res Function(PortableCreatedCounterpart) _then) = _$PortableCreatedCounterpartCopyWithImpl;
@useResult
$Res call({
 PortableNewCounterpartChoice slot
});


$PortableNewCounterpartChoiceCopyWith<$Res> get slot;

}
/// @nodoc
class _$PortableCreatedCounterpartCopyWithImpl<$Res>
    implements $PortableCreatedCounterpartCopyWith<$Res> {
  _$PortableCreatedCounterpartCopyWithImpl(this._self, this._then);

  final PortableCreatedCounterpart _self;
  final $Res Function(PortableCreatedCounterpart) _then;

/// Create a copy of PortableLinkCounterpartRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? slot = null,}) {
  return _then(PortableCreatedCounterpart(
null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as PortableNewCounterpartChoice,
  ));
}

/// Create a copy of PortableLinkCounterpartRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableNewCounterpartChoiceCopyWith<$Res> get slot {
  
  return $PortableNewCounterpartChoiceCopyWith<$Res>(_self.slot, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}

/// @nodoc


class PortableCollectionCounterpart implements PortableLinkCounterpartRequest {
  const PortableCollectionCounterpart(this.containing);
  

 final  skir.ValueLocation containing;

/// Create a copy of PortableLinkCounterpartRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableCollectionCounterpartCopyWith<PortableCollectionCounterpart> get copyWith => _$PortableCollectionCounterpartCopyWithImpl<PortableCollectionCounterpart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableCollectionCounterpart&&(identical(other.containing, containing) || other.containing == containing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,containing);
}

@override
String toString() {
    return 'PortableLinkCounterpartRequest.collection(containing: $containing)';
}


}

/// @nodoc
abstract mixin class $PortableCollectionCounterpartCopyWith<$Res> implements $PortableLinkCounterpartRequestCopyWith<$Res> {
  factory $PortableCollectionCounterpartCopyWith(PortableCollectionCounterpart value, $Res Function(PortableCollectionCounterpart) _then) = _$PortableCollectionCounterpartCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation containing
});




}
/// @nodoc
class _$PortableCollectionCounterpartCopyWithImpl<$Res>
    implements $PortableCollectionCounterpartCopyWith<$Res> {
  _$PortableCollectionCounterpartCopyWithImpl(this._self, this._then);

  final PortableCollectionCounterpart _self;
  final $Res Function(PortableCollectionCounterpart) _then;

/// Create a copy of PortableLinkCounterpartRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? containing = null,}) {
  return _then(PortableCollectionCounterpart(
null == containing ? _self.containing : containing // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,
  ));
}


}

/// @nodoc
mixin _$PortableGraphPlacement {

 int get x; int get y; int get width; int get height;
/// Create a copy of PortableGraphPlacement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableGraphPlacementCopyWith<PortableGraphPlacement> get copyWith => _$PortableGraphPlacementCopyWithImpl<PortableGraphPlacement>(this as PortableGraphPlacement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableGraphPlacement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableGraphPlacement&&(identical(other.x, _this.x) || other.x == _this.x)&&(identical(other.y, _this.y) || other.y == _this.y)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height));
}


@override
int get hashCode {
  final _this = this as PortableGraphPlacement;
  return Object.hash(runtimeType,_this.x,_this.y,_this.width,_this.height);
}

@override
String toString() {
  final _this = this as PortableGraphPlacement;
  return 'PortableGraphPlacement(x: ${_this.x}, y: ${_this.y}, width: ${_this.width}, height: ${_this.height})';
}


}

/// @nodoc
abstract mixin class $PortableGraphPlacementCopyWith<$Res>  {
  factory $PortableGraphPlacementCopyWith(PortableGraphPlacement value, $Res Function(PortableGraphPlacement) _then) = _$PortableGraphPlacementCopyWithImpl;
@useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class _$PortableGraphPlacementCopyWithImpl<$Res>
    implements $PortableGraphPlacementCopyWith<$Res> {
  _$PortableGraphPlacementCopyWithImpl(this._self, this._then);

  final PortableGraphPlacement _self;
  final $Res Function(PortableGraphPlacement) _then;

/// Create a copy of PortableGraphPlacement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(PortableGraphPlacement(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableGraphPlacement].
extension PortableGraphPlacementPatterns on PortableGraphPlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableGraphPlacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableGraphPlacement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableGraphPlacement value)  $default,){
final _that = this;
switch (_that) {
case _PortableGraphPlacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableGraphPlacement value)?  $default,){
final _that = this;
switch (_that) {
case _PortableGraphPlacement() when $default != null:
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
case _PortableGraphPlacement() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _PortableGraphPlacement():
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
case _PortableGraphPlacement() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _PortableGraphPlacement implements PortableGraphPlacement {
  const _PortableGraphPlacement({required this.x, required this.y, required this.width, required this.height});
  

@override final  int x;
@override final  int y;
@override final  int width;
@override final  int height;

/// Create a copy of PortableGraphPlacement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableGraphPlacementCopyWith<_PortableGraphPlacement> get copyWith => __$PortableGraphPlacementCopyWithImpl<_PortableGraphPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableGraphPlacement&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode {
    return Object.hash(runtimeType,x,y,width,height);
}

@override
String toString() {
    return 'PortableGraphPlacement(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$PortableGraphPlacementCopyWith<$Res> implements $PortableGraphPlacementCopyWith<$Res> {
  factory _$PortableGraphPlacementCopyWith(_PortableGraphPlacement value, $Res Function(_PortableGraphPlacement) _then) = __$PortableGraphPlacementCopyWithImpl;
@override @useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class __$PortableGraphPlacementCopyWithImpl<$Res>
    implements _$PortableGraphPlacementCopyWith<$Res> {
  __$PortableGraphPlacementCopyWithImpl(this._self, this._then);

  final _PortableGraphPlacement _self;
  final $Res Function(_PortableGraphPlacement) _then;

/// Create a copy of PortableGraphPlacement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_PortableGraphPlacement(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PortableResourceMember {

 skir.ResourceId get resource; skir.LinkOccurrence get occurrence; skir.DataValue get link; PortableResourceProjection get resourceProjection; PortableGraphPlacement? get graph;
/// Create a copy of PortableResourceMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableResourceMemberCopyWith<PortableResourceMember> get copyWith => _$PortableResourceMemberCopyWithImpl<PortableResourceMember>(this as PortableResourceMember, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableResourceMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableResourceMember&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.occurrence, _this.occurrence) || other.occurrence == _this.occurrence)&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.resourceProjection, _this.resourceProjection) || other.resourceProjection == _this.resourceProjection)&&(identical(other.graph, _this.graph) || other.graph == _this.graph));
}


@override
int get hashCode {
  final _this = this as PortableResourceMember;
  return Object.hash(runtimeType,_this.resource,_this.occurrence,_this.link,_this.resourceProjection,_this.graph);
}

@override
String toString() {
  final _this = this as PortableResourceMember;
  return 'PortableResourceMember(resource: ${_this.resource}, occurrence: ${_this.occurrence}, link: ${_this.link}, resourceProjection: ${_this.resourceProjection}, graph: ${_this.graph})';
}


}

/// @nodoc
abstract mixin class $PortableResourceMemberCopyWith<$Res>  {
  factory $PortableResourceMemberCopyWith(PortableResourceMember value, $Res Function(PortableResourceMember) _then) = _$PortableResourceMemberCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, skir.LinkOccurrence occurrence, skir.DataValue link, PortableResourceProjection resourceProjection, PortableGraphPlacement? graph
});


$PortableResourceProjectionCopyWith<$Res> get resourceProjection;$PortableGraphPlacementCopyWith<$Res>? get graph;

}
/// @nodoc
class _$PortableResourceMemberCopyWithImpl<$Res>
    implements $PortableResourceMemberCopyWith<$Res> {
  _$PortableResourceMemberCopyWithImpl(this._self, this._then);

  final PortableResourceMember _self;
  final $Res Function(PortableResourceMember) _then;

/// Create a copy of PortableResourceMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? occurrence = null,Object? link = null,Object? resourceProjection = null,Object? graph = freezed,}) {
  return _then(PortableResourceMember(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,occurrence: null == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as skir.DataValue,resourceProjection: null == resourceProjection ? _self.resourceProjection : resourceProjection // ignore: cast_nullable_to_non_nullable
as PortableResourceProjection,graph: freezed == graph ? _self.graph : graph // ignore: cast_nullable_to_non_nullable
as PortableGraphPlacement?,
  ));
}
/// Create a copy of PortableResourceMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableResourceProjectionCopyWith<$Res> get resourceProjection {
  
  return $PortableResourceProjectionCopyWith<$Res>(_self.resourceProjection, (value) {
    return _then(_self.copyWith(resourceProjection: value));
  });
}/// Create a copy of PortableResourceMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableGraphPlacementCopyWith<$Res>? get graph {
    if (_self.graph == null) {
    return null;
  }

  return $PortableGraphPlacementCopyWith<$Res>(_self.graph!, (value) {
    return _then(_self.copyWith(graph: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortableResourceMember].
extension PortableResourceMemberPatterns on PortableResourceMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableResourceMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableResourceMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableResourceMember value)  $default,){
final _that = this;
switch (_that) {
case _PortableResourceMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableResourceMember value)?  $default,){
final _that = this;
switch (_that) {
case _PortableResourceMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.LinkOccurrence occurrence,  skir.DataValue link,  PortableResourceProjection resourceProjection,  PortableGraphPlacement? graph)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableResourceMember() when $default != null:
return $default(_that.resource,_that.occurrence,_that.link,_that.resourceProjection,_that.graph);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId resource,  skir.LinkOccurrence occurrence,  skir.DataValue link,  PortableResourceProjection resourceProjection,  PortableGraphPlacement? graph)  $default,) {final _that = this;
switch (_that) {
case _PortableResourceMember():
return $default(_that.resource,_that.occurrence,_that.link,_that.resourceProjection,_that.graph);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId resource,  skir.LinkOccurrence occurrence,  skir.DataValue link,  PortableResourceProjection resourceProjection,  PortableGraphPlacement? graph)?  $default,) {final _that = this;
switch (_that) {
case _PortableResourceMember() when $default != null:
return $default(_that.resource,_that.occurrence,_that.link,_that.resourceProjection,_that.graph);case _:
  return null;

}
}

}

/// @nodoc


class _PortableResourceMember extends PortableResourceMember {
  const _PortableResourceMember({required this.resource, required this.occurrence, required this.link, required this.resourceProjection, this.graph}): super._();
  

@override final  skir.ResourceId resource;
@override final  skir.LinkOccurrence occurrence;
@override final  skir.DataValue link;
@override final  PortableResourceProjection resourceProjection;
@override final  PortableGraphPlacement? graph;

/// Create a copy of PortableResourceMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableResourceMemberCopyWith<_PortableResourceMember> get copyWith => __$PortableResourceMemberCopyWithImpl<_PortableResourceMember>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableResourceMember&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.occurrence, occurrence) || other.occurrence == occurrence)&&(identical(other.link, link) || other.link == link)&&(identical(other.resourceProjection, resourceProjection) || other.resourceProjection == resourceProjection)&&(identical(other.graph, graph) || other.graph == graph));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,occurrence,link,resourceProjection,graph);
}

@override
String toString() {
    return 'PortableResourceMember(resource: $resource, occurrence: $occurrence, link: $link, resourceProjection: $resourceProjection, graph: $graph)';
}


}

/// @nodoc
abstract mixin class _$PortableResourceMemberCopyWith<$Res> implements $PortableResourceMemberCopyWith<$Res> {
  factory _$PortableResourceMemberCopyWith(_PortableResourceMember value, $Res Function(_PortableResourceMember) _then) = __$PortableResourceMemberCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, skir.LinkOccurrence occurrence, skir.DataValue link, PortableResourceProjection resourceProjection, PortableGraphPlacement? graph
});


@override $PortableResourceProjectionCopyWith<$Res> get resourceProjection;@override $PortableGraphPlacementCopyWith<$Res>? get graph;

}
/// @nodoc
class __$PortableResourceMemberCopyWithImpl<$Res>
    implements _$PortableResourceMemberCopyWith<$Res> {
  __$PortableResourceMemberCopyWithImpl(this._self, this._then);

  final _PortableResourceMember _self;
  final $Res Function(_PortableResourceMember) _then;

/// Create a copy of PortableResourceMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? occurrence = null,Object? link = null,Object? resourceProjection = null,Object? graph = freezed,}) {
  return _then(_PortableResourceMember(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,occurrence: null == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as skir.DataValue,resourceProjection: null == resourceProjection ? _self.resourceProjection : resourceProjection // ignore: cast_nullable_to_non_nullable
as PortableResourceProjection,graph: freezed == graph ? _self.graph : graph // ignore: cast_nullable_to_non_nullable
as PortableGraphPlacement?,
  ));
}

/// Create a copy of PortableResourceMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableResourceProjectionCopyWith<$Res> get resourceProjection {
  
  return $PortableResourceProjectionCopyWith<$Res>(_self.resourceProjection, (value) {
    return _then(_self.copyWith(resourceProjection: value));
  });
}/// Create a copy of PortableResourceMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableGraphPlacementCopyWith<$Res>? get graph {
    if (_self.graph == null) {
    return null;
  }

  return $PortableGraphPlacementCopyWith<$Res>(_self.graph!, (value) {
    return _then(_self.copyWith(graph: value));
  });
}
}

/// @nodoc
mixin _$PortableResourceEdge {

 String get id; skir.ResourceId get source; skir.ResourceId get target;
/// Create a copy of PortableResourceEdge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableResourceEdgeCopyWith<PortableResourceEdge> get copyWith => _$PortableResourceEdgeCopyWithImpl<PortableResourceEdge>(this as PortableResourceEdge, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableResourceEdge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableResourceEdge&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.target, _this.target) || other.target == _this.target));
}


@override
int get hashCode {
  final _this = this as PortableResourceEdge;
  return Object.hash(runtimeType,_this.id,_this.source,_this.target);
}

@override
String toString() {
  final _this = this as PortableResourceEdge;
  return 'PortableResourceEdge(id: ${_this.id}, source: ${_this.source}, target: ${_this.target})';
}


}

/// @nodoc
abstract mixin class $PortableResourceEdgeCopyWith<$Res>  {
  factory $PortableResourceEdgeCopyWith(PortableResourceEdge value, $Res Function(PortableResourceEdge) _then) = _$PortableResourceEdgeCopyWithImpl;
@useResult
$Res call({
 String id, skir.ResourceId source, skir.ResourceId target
});




}
/// @nodoc
class _$PortableResourceEdgeCopyWithImpl<$Res>
    implements $PortableResourceEdgeCopyWith<$Res> {
  _$PortableResourceEdgeCopyWithImpl(this._self, this._then);

  final PortableResourceEdge _self;
  final $Res Function(PortableResourceEdge) _then;

/// Create a copy of PortableResourceEdge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? target = null,}) {
  return _then(PortableResourceEdge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableResourceEdge].
extension PortableResourceEdgePatterns on PortableResourceEdge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableResourceEdge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableResourceEdge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableResourceEdge value)  $default,){
final _that = this;
switch (_that) {
case _PortableResourceEdge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableResourceEdge value)?  $default,){
final _that = this;
switch (_that) {
case _PortableResourceEdge() when $default != null:
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
case _PortableResourceEdge() when $default != null:
return $default(_that.id,_that.source,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  skir.ResourceId source,  skir.ResourceId target)  $default,) {final _that = this;
switch (_that) {
case _PortableResourceEdge():
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
case _PortableResourceEdge() when $default != null:
return $default(_that.id,_that.source,_that.target);case _:
  return null;

}
}

}

/// @nodoc


class _PortableResourceEdge implements PortableResourceEdge {
  const _PortableResourceEdge({required this.id, required this.source, required this.target});
  

@override final  String id;
@override final  skir.ResourceId source;
@override final  skir.ResourceId target;

/// Create a copy of PortableResourceEdge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableResourceEdgeCopyWith<_PortableResourceEdge> get copyWith => __$PortableResourceEdgeCopyWithImpl<_PortableResourceEdge>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableResourceEdge&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,source,target);
}

@override
String toString() {
    return 'PortableResourceEdge(id: $id, source: $source, target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableResourceEdgeCopyWith<$Res> implements $PortableResourceEdgeCopyWith<$Res> {
  factory _$PortableResourceEdgeCopyWith(_PortableResourceEdge value, $Res Function(_PortableResourceEdge) _then) = __$PortableResourceEdgeCopyWithImpl;
@override @useResult
$Res call({
 String id, skir.ResourceId source, skir.ResourceId target
});




}
/// @nodoc
class __$PortableResourceEdgeCopyWithImpl<$Res>
    implements _$PortableResourceEdgeCopyWith<$Res> {
  __$PortableResourceEdgeCopyWithImpl(this._self, this._then);

  final _PortableResourceEdge _self;
  final $Res Function(_PortableResourceEdge) _then;

/// Create a copy of PortableResourceEdge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? target = null,}) {
  return _then(_PortableResourceEdge(
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


/// Adds pattern-matching-related methods to [PortableTimelinePlacement].
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
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
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableTimelinePlacementCopyWith<$Res> get placement {
  
  return $PortableTimelinePlacementCopyWith<$Res>(_self.placement, (value) {
    return _then(_self.copyWith(placement: value));
  });
}
}

/// @nodoc
mixin _$PortableResourcesProjection {

 List<PortableResourceMember> get members; List<PortableResourceEdge> get edges; Map<skir.ResourceId, List<PortableTimelineCueProjection>> get timeline; String? get problem;
/// Create a copy of PortableResourcesProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableResourcesProjectionCopyWith<PortableResourcesProjection> get copyWith => _$PortableResourcesProjectionCopyWithImpl<PortableResourcesProjection>(this as PortableResourcesProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableResourcesProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableResourcesProjection&&const DeepCollectionEquality().equals(other.members, _this.members)&&const DeepCollectionEquality().equals(other.edges, _this.edges)&&const DeepCollectionEquality().equals(other.timeline, _this.timeline)&&(identical(other.problem, _this.problem) || other.problem == _this.problem));
}


@override
int get hashCode {
  final _this = this as PortableResourcesProjection;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.members),const DeepCollectionEquality().hash(_this.edges),const DeepCollectionEquality().hash(_this.timeline),_this.problem);
}

@override
String toString() {
  final _this = this as PortableResourcesProjection;
  return 'PortableResourcesProjection(members: ${_this.members}, edges: ${_this.edges}, timeline: ${_this.timeline}, problem: ${_this.problem})';
}


}

/// @nodoc
abstract mixin class $PortableResourcesProjectionCopyWith<$Res>  {
  factory $PortableResourcesProjectionCopyWith(PortableResourcesProjection value, $Res Function(PortableResourcesProjection) _then) = _$PortableResourcesProjectionCopyWithImpl;
@useResult
$Res call({
 List<PortableResourceMember> members, List<PortableResourceEdge> edges, Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline, String? problem
});




}
/// @nodoc
class _$PortableResourcesProjectionCopyWithImpl<$Res>
    implements $PortableResourcesProjectionCopyWith<$Res> {
  _$PortableResourcesProjectionCopyWithImpl(this._self, this._then);

  final PortableResourcesProjection _self;
  final $Res Function(PortableResourcesProjection) _then;

/// Create a copy of PortableResourcesProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? members = null,Object? edges = null,Object? timeline = null,Object? problem = freezed,}) {
  return _then(PortableResourcesProjection(
members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<PortableResourceMember>,edges: null == edges ? _self.edges : edges // ignore: cast_nullable_to_non_nullable
as List<PortableResourceEdge>,timeline: null == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<PortableTimelineCueProjection>>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}



/// @nodoc


class _PortableResourcesProjection implements PortableResourcesProjection {
  const _PortableResourcesProjection({required  List<PortableResourceMember> members, required  List<PortableResourceEdge> edges, required  Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline, required this.problem}): _members = members,_edges = edges,_timeline = timeline;
  

 final  List<PortableResourceMember> _members;
@override List<PortableResourceMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

 final  List<PortableResourceEdge> _edges;
@override List<PortableResourceEdge> get edges {
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

/// Create a copy of PortableResourcesProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableResourcesProjectionCopyWith<_PortableResourcesProjection> get copyWith => __$PortableResourcesProjectionCopyWithImpl<_PortableResourcesProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableResourcesProjection&&const DeepCollectionEquality().equals(other.members, _members)&&const DeepCollectionEquality().equals(other.edges, _edges)&&const DeepCollectionEquality().equals(other.timeline, _timeline)&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_edges),const DeepCollectionEquality().hash(_timeline),problem);
}

@override
String toString() {
    return 'PortableResourcesProjection._value(members: $members, edges: $edges, timeline: $timeline, problem: $problem)';
}


}

/// @nodoc
abstract mixin class _$PortableResourcesProjectionCopyWith<$Res> implements $PortableResourcesProjectionCopyWith<$Res> {
  factory _$PortableResourcesProjectionCopyWith(_PortableResourcesProjection value, $Res Function(_PortableResourcesProjection) _then) = __$PortableResourcesProjectionCopyWithImpl;
@override @useResult
$Res call({
 List<PortableResourceMember> members, List<PortableResourceEdge> edges, Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline, String? problem
});




}
/// @nodoc
class __$PortableResourcesProjectionCopyWithImpl<$Res>
    implements _$PortableResourcesProjectionCopyWith<$Res> {
  __$PortableResourcesProjectionCopyWithImpl(this._self, this._then);

  final _PortableResourcesProjection _self;
  final $Res Function(_PortableResourcesProjection) _then;

/// Create a copy of PortableResourcesProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? members = null,Object? edges = null,Object? timeline = null,Object? problem = freezed,}) {
  return _then(_PortableResourcesProjection(
members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<PortableResourceMember>,edges: null == edges ? _self._edges : edges // ignore: cast_nullable_to_non_nullable
as List<PortableResourceEdge>,timeline: null == timeline ? _self._timeline : timeline // ignore: cast_nullable_to_non_nullable
as Map<skir.ResourceId, List<PortableTimelineCueProjection>>,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
