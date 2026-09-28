// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationDefinition {

 PresentationId get id; List<PresentationInputParameter> get inputs; PresentationNode get root; BindingId? get primaryInput; Map<PresentationCollectionSourceId, PresentationCollectionSchema> get collections;
/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationDefinitionCopyWith<PresentationDefinition> get copyWith => _$PresentationDefinitionCopyWithImpl<PresentationDefinition>(this as PresentationDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PresentationDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationDefinition&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.inputs, _this.inputs)&&(identical(other.root, _this.root) || other.root == _this.root)&&(identical(other.primaryInput, _this.primaryInput) || other.primaryInput == _this.primaryInput)&&const DeepCollectionEquality().equals(other.collections, _this.collections));
}


@override
int get hashCode {
  final _this = this as PresentationDefinition;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.inputs),_this.root,_this.primaryInput,const DeepCollectionEquality().hash(_this.collections));
}

@override
String toString() {
  final _this = this as PresentationDefinition;
  return 'PresentationDefinition(id: ${_this.id}, inputs: ${_this.inputs}, root: ${_this.root}, primaryInput: ${_this.primaryInput}, collections: ${_this.collections})';
}


}

/// @nodoc
abstract mixin class $PresentationDefinitionCopyWith<$Res>  {
  factory $PresentationDefinitionCopyWith(PresentationDefinition value, $Res Function(PresentationDefinition) _then) = _$PresentationDefinitionCopyWithImpl;
@useResult
$Res call({
 PresentationId id, List<PresentationInputParameter> inputs, PresentationNode root, BindingId? primaryInput, Map<PresentationCollectionSourceId, PresentationCollectionSchema> collections
});


$PresentationIdCopyWith<$Res> get id;$PresentationNodeCopyWith<$Res> get root;$BindingIdCopyWith<$Res>? get primaryInput;

}
/// @nodoc
class _$PresentationDefinitionCopyWithImpl<$Res>
    implements $PresentationDefinitionCopyWith<$Res> {
  _$PresentationDefinitionCopyWithImpl(this._self, this._then);

  final PresentationDefinition _self;
  final $Res Function(PresentationDefinition) _then;

/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? inputs = null,Object? root = null,Object? primaryInput = freezed,Object? collections = null,}) {
  return _then(PresentationDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationId,inputs: null == inputs ? _self.inputs : inputs // ignore: cast_nullable_to_non_nullable
as List<PresentationInputParameter>,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,primaryInput: freezed == primaryInput ? _self.primaryInput : primaryInput // ignore: cast_nullable_to_non_nullable
as BindingId?,collections: null == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, PresentationCollectionSchema>,
  ));
}
/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationIdCopyWith<$Res> get id {
  
  return $PresentationIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get root {
  
  return $PresentationNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}/// Create a copy of PresentationDefinition
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


/// Adds pattern-matching-related methods to [PresentationDefinition].
extension PresentationDefinitionPatterns on PresentationDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationDefinition value)  $default,){
final _that = this;
switch (_that) {
case _PresentationDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PresentationId id,  List<PresentationInputParameter> inputs,  PresentationNode root,  BindingId? primaryInput,  Map<PresentationCollectionSourceId, PresentationCollectionSchema> collections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationDefinition() when $default != null:
return $default(_that.id,_that.inputs,_that.root,_that.primaryInput,_that.collections);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PresentationId id,  List<PresentationInputParameter> inputs,  PresentationNode root,  BindingId? primaryInput,  Map<PresentationCollectionSourceId, PresentationCollectionSchema> collections)  $default,) {final _that = this;
switch (_that) {
case _PresentationDefinition():
return $default(_that.id,_that.inputs,_that.root,_that.primaryInput,_that.collections);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PresentationId id,  List<PresentationInputParameter> inputs,  PresentationNode root,  BindingId? primaryInput,  Map<PresentationCollectionSourceId, PresentationCollectionSchema> collections)?  $default,) {final _that = this;
switch (_that) {
case _PresentationDefinition() when $default != null:
return $default(_that.id,_that.inputs,_that.root,_that.primaryInput,_that.collections);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationDefinition extends PresentationDefinition {
  const _PresentationDefinition({required this.id, required  List<PresentationInputParameter> inputs, required this.root, this.primaryInput,  Map<PresentationCollectionSourceId, PresentationCollectionSchema> collections = const <PresentationCollectionSourceId, PresentationCollectionSchema>{}}): _inputs = inputs,_collections = collections,super._();
  

@override final  PresentationId id;
 final  List<PresentationInputParameter> _inputs;
@override List<PresentationInputParameter> get inputs {
  if (_inputs is EqualUnmodifiableListView) return _inputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inputs);
}

@override final  PresentationNode root;
@override final  BindingId? primaryInput;
 final  Map<PresentationCollectionSourceId, PresentationCollectionSchema> _collections;
@override@JsonKey() Map<PresentationCollectionSourceId, PresentationCollectionSchema> get collections {
  if (_collections is EqualUnmodifiableMapView) return _collections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_collections);
}


/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationDefinitionCopyWith<_PresentationDefinition> get copyWith => __$PresentationDefinitionCopyWithImpl<_PresentationDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationDefinition&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.inputs, _inputs)&&(identical(other.root, root) || other.root == root)&&(identical(other.primaryInput, primaryInput) || other.primaryInput == primaryInput)&&const DeepCollectionEquality().equals(other.collections, _collections));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_inputs),root,primaryInput,const DeepCollectionEquality().hash(_collections));
}

@override
String toString() {
    return 'PresentationDefinition(id: $id, inputs: $inputs, root: $root, primaryInput: $primaryInput, collections: $collections)';
}


}

/// @nodoc
abstract mixin class _$PresentationDefinitionCopyWith<$Res> implements $PresentationDefinitionCopyWith<$Res> {
  factory _$PresentationDefinitionCopyWith(_PresentationDefinition value, $Res Function(_PresentationDefinition) _then) = __$PresentationDefinitionCopyWithImpl;
@override @useResult
$Res call({
 PresentationId id, List<PresentationInputParameter> inputs, PresentationNode root, BindingId? primaryInput, Map<PresentationCollectionSourceId, PresentationCollectionSchema> collections
});


@override $PresentationIdCopyWith<$Res> get id;@override $PresentationNodeCopyWith<$Res> get root;@override $BindingIdCopyWith<$Res>? get primaryInput;

}
/// @nodoc
class __$PresentationDefinitionCopyWithImpl<$Res>
    implements _$PresentationDefinitionCopyWith<$Res> {
  __$PresentationDefinitionCopyWithImpl(this._self, this._then);

  final _PresentationDefinition _self;
  final $Res Function(_PresentationDefinition) _then;

/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? inputs = null,Object? root = null,Object? primaryInput = freezed,Object? collections = null,}) {
  return _then(_PresentationDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationId,inputs: null == inputs ? _self._inputs : inputs // ignore: cast_nullable_to_non_nullable
as List<PresentationInputParameter>,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,primaryInput: freezed == primaryInput ? _self.primaryInput : primaryInput // ignore: cast_nullable_to_non_nullable
as BindingId?,collections: null == collections ? _self._collections : collections // ignore: cast_nullable_to_non_nullable
as Map<PresentationCollectionSourceId, PresentationCollectionSchema>,
  ));
}

/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationIdCopyWith<$Res> get id {
  
  return $PresentationIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get root {
  
  return $PresentationNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}/// Create a copy of PresentationDefinition
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
mixin _$PresentationInputParameter {

 BindingId get id; String get name; TypeExpression get type; PresentationInputAccess get access;
/// Create a copy of PresentationInputParameter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationInputParameterCopyWith<PresentationInputParameter> get copyWith => _$PresentationInputParameterCopyWithImpl<PresentationInputParameter>(this as PresentationInputParameter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PresentationInputParameter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationInputParameter&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.access, _this.access) || other.access == _this.access));
}


@override
int get hashCode {
  final _this = this as PresentationInputParameter;
  return Object.hash(runtimeType,_this.id,_this.name,_this.type,_this.access);
}

@override
String toString() {
  final _this = this as PresentationInputParameter;
  return 'PresentationInputParameter(id: ${_this.id}, name: ${_this.name}, type: ${_this.type}, access: ${_this.access})';
}


}

/// @nodoc
abstract mixin class $PresentationInputParameterCopyWith<$Res>  {
  factory $PresentationInputParameterCopyWith(PresentationInputParameter value, $Res Function(PresentationInputParameter) _then) = _$PresentationInputParameterCopyWithImpl;
@useResult
$Res call({
 BindingId id, String name, TypeExpression type, PresentationInputAccess access
});


$BindingIdCopyWith<$Res> get id;$TypeExpressionCopyWith<$Res> get type;

}
/// @nodoc
class _$PresentationInputParameterCopyWithImpl<$Res>
    implements $PresentationInputParameterCopyWith<$Res> {
  _$PresentationInputParameterCopyWithImpl(this._self, this._then);

  final PresentationInputParameter _self;
  final $Res Function(PresentationInputParameter) _then;

/// Create a copy of PresentationInputParameter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? access = null,}) {
  return _then(PresentationInputParameter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as BindingId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as PresentationInputAccess,
  ));
}
/// Create a copy of PresentationInputParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get id {
  
  return $BindingIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of PresentationInputParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationInputParameter].
extension PresentationInputParameterPatterns on PresentationInputParameter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationInputParameter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationInputParameter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationInputParameter value)  $default,){
final _that = this;
switch (_that) {
case _PresentationInputParameter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationInputParameter value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationInputParameter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingId id,  String name,  TypeExpression type,  PresentationInputAccess access)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationInputParameter() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.access);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingId id,  String name,  TypeExpression type,  PresentationInputAccess access)  $default,) {final _that = this;
switch (_that) {
case _PresentationInputParameter():
return $default(_that.id,_that.name,_that.type,_that.access);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingId id,  String name,  TypeExpression type,  PresentationInputAccess access)?  $default,) {final _that = this;
switch (_that) {
case _PresentationInputParameter() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.access);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationInputParameter implements PresentationInputParameter {
  const _PresentationInputParameter({required this.id, required this.name, required this.type, this.access = PresentationInputAccess.read});
  

@override final  BindingId id;
@override final  String name;
@override final  TypeExpression type;
@override@JsonKey() final  PresentationInputAccess access;

/// Create a copy of PresentationInputParameter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationInputParameterCopyWith<_PresentationInputParameter> get copyWith => __$PresentationInputParameterCopyWithImpl<_PresentationInputParameter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationInputParameter&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.access, access) || other.access == access));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,type,access);
}

@override
String toString() {
    return 'PresentationInputParameter(id: $id, name: $name, type: $type, access: $access)';
}


}

/// @nodoc
abstract mixin class _$PresentationInputParameterCopyWith<$Res> implements $PresentationInputParameterCopyWith<$Res> {
  factory _$PresentationInputParameterCopyWith(_PresentationInputParameter value, $Res Function(_PresentationInputParameter) _then) = __$PresentationInputParameterCopyWithImpl;
@override @useResult
$Res call({
 BindingId id, String name, TypeExpression type, PresentationInputAccess access
});


@override $BindingIdCopyWith<$Res> get id;@override $TypeExpressionCopyWith<$Res> get type;

}
/// @nodoc
class __$PresentationInputParameterCopyWithImpl<$Res>
    implements _$PresentationInputParameterCopyWith<$Res> {
  __$PresentationInputParameterCopyWithImpl(this._self, this._then);

  final _PresentationInputParameter _self;
  final $Res Function(_PresentationInputParameter) _then;

/// Create a copy of PresentationInputParameter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? access = null,}) {
  return _then(_PresentationInputParameter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as BindingId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeExpression,access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as PresentationInputAccess,
  ));
}

/// Create a copy of PresentationInputParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingIdCopyWith<$Res> get id {
  
  return $BindingIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of PresentationInputParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get type {
  
  return $TypeExpressionCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

/// @nodoc
mixin _$CapabilityDefinition {

 CapabilityId get id; ResolvedTypeRef get requestType;
/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapabilityDefinitionCopyWith<CapabilityDefinition> get copyWith => _$CapabilityDefinitionCopyWithImpl<CapabilityDefinition>(this as CapabilityDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CapabilityDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapabilityDefinition&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.requestType, _this.requestType) || other.requestType == _this.requestType));
}


@override
int get hashCode {
  final _this = this as CapabilityDefinition;
  return Object.hash(runtimeType,_this.id,_this.requestType);
}

@override
String toString() {
  final _this = this as CapabilityDefinition;
  return 'CapabilityDefinition(id: ${_this.id}, requestType: ${_this.requestType})';
}


}

/// @nodoc
abstract mixin class $CapabilityDefinitionCopyWith<$Res>  {
  factory $CapabilityDefinitionCopyWith(CapabilityDefinition value, $Res Function(CapabilityDefinition) _then) = _$CapabilityDefinitionCopyWithImpl;
@useResult
$Res call({
 CapabilityId id, ResolvedTypeRef requestType
});


$CapabilityIdCopyWith<$Res> get id;$ResolvedTypeRefCopyWith<$Res> get requestType;

}
/// @nodoc
class _$CapabilityDefinitionCopyWithImpl<$Res>
    implements $CapabilityDefinitionCopyWith<$Res> {
  _$CapabilityDefinitionCopyWithImpl(this._self, this._then);

  final CapabilityDefinition _self;
  final $Res Function(CapabilityDefinition) _then;

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requestType = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CapabilityId,requestType: null == requestType ? _self.requestType : requestType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,
  ));
}
/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapabilityIdCopyWith<$Res> get id {
  
  return $CapabilityIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get requestType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.requestType, (value) {
    return _then(_self.copyWith(requestType: value));
  });
}
}


/// Adds pattern-matching-related methods to [CapabilityDefinition].
extension CapabilityDefinitionPatterns on CapabilityDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchCapabilityDefinition value)?  search,TResult Function( ComputationCapabilityDefinition value)?  computation,TResult Function( CommandCapabilityDefinition value)?  command,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchCapabilityDefinition() when search != null:
return search(_that);case ComputationCapabilityDefinition() when computation != null:
return computation(_that);case CommandCapabilityDefinition() when command != null:
return command(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchCapabilityDefinition value)  search,required TResult Function( ComputationCapabilityDefinition value)  computation,required TResult Function( CommandCapabilityDefinition value)  command,}){
final _that = this;
switch (_that) {
case SearchCapabilityDefinition():
return search(_that);case ComputationCapabilityDefinition():
return computation(_that);case CommandCapabilityDefinition():
return command(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchCapabilityDefinition value)?  search,TResult? Function( ComputationCapabilityDefinition value)?  computation,TResult? Function( CommandCapabilityDefinition value)?  command,}){
final _that = this;
switch (_that) {
case SearchCapabilityDefinition() when search != null:
return search(_that);case ComputationCapabilityDefinition() when computation != null:
return computation(_that);case CommandCapabilityDefinition() when command != null:
return command(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CapabilityId id,  ResolvedTypeRef requestType,  ResolvedTypeRef resultType)?  search,TResult Function( CapabilityId id,  ResolvedTypeRef requestType,  ResolvedTypeRef resultType)?  computation,TResult Function( CapabilityId id,  ResolvedTypeRef requestType)?  command,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchCapabilityDefinition() when search != null:
return search(_that.id,_that.requestType,_that.resultType);case ComputationCapabilityDefinition() when computation != null:
return computation(_that.id,_that.requestType,_that.resultType);case CommandCapabilityDefinition() when command != null:
return command(_that.id,_that.requestType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CapabilityId id,  ResolvedTypeRef requestType,  ResolvedTypeRef resultType)  search,required TResult Function( CapabilityId id,  ResolvedTypeRef requestType,  ResolvedTypeRef resultType)  computation,required TResult Function( CapabilityId id,  ResolvedTypeRef requestType)  command,}) {final _that = this;
switch (_that) {
case SearchCapabilityDefinition():
return search(_that.id,_that.requestType,_that.resultType);case ComputationCapabilityDefinition():
return computation(_that.id,_that.requestType,_that.resultType);case CommandCapabilityDefinition():
return command(_that.id,_that.requestType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CapabilityId id,  ResolvedTypeRef requestType,  ResolvedTypeRef resultType)?  search,TResult? Function( CapabilityId id,  ResolvedTypeRef requestType,  ResolvedTypeRef resultType)?  computation,TResult? Function( CapabilityId id,  ResolvedTypeRef requestType)?  command,}) {final _that = this;
switch (_that) {
case SearchCapabilityDefinition() when search != null:
return search(_that.id,_that.requestType,_that.resultType);case ComputationCapabilityDefinition() when computation != null:
return computation(_that.id,_that.requestType,_that.resultType);case CommandCapabilityDefinition() when command != null:
return command(_that.id,_that.requestType);case _:
  return null;

}
}

}

/// @nodoc


class SearchCapabilityDefinition implements CapabilityDefinition {
  const SearchCapabilityDefinition({required this.id, required this.requestType, required this.resultType});
  

@override final  CapabilityId id;
@override final  ResolvedTypeRef requestType;
 final  ResolvedTypeRef resultType;

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCapabilityDefinitionCopyWith<SearchCapabilityDefinition> get copyWith => _$SearchCapabilityDefinitionCopyWithImpl<SearchCapabilityDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCapabilityDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.requestType, requestType) || other.requestType == requestType)&&(identical(other.resultType, resultType) || other.resultType == resultType));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,requestType,resultType);
}

@override
String toString() {
    return 'CapabilityDefinition.search(id: $id, requestType: $requestType, resultType: $resultType)';
}


}

/// @nodoc
abstract mixin class $SearchCapabilityDefinitionCopyWith<$Res> implements $CapabilityDefinitionCopyWith<$Res> {
  factory $SearchCapabilityDefinitionCopyWith(SearchCapabilityDefinition value, $Res Function(SearchCapabilityDefinition) _then) = _$SearchCapabilityDefinitionCopyWithImpl;
@override @useResult
$Res call({
 CapabilityId id, ResolvedTypeRef requestType, ResolvedTypeRef resultType
});


@override $CapabilityIdCopyWith<$Res> get id;@override $ResolvedTypeRefCopyWith<$Res> get requestType;$ResolvedTypeRefCopyWith<$Res> get resultType;

}
/// @nodoc
class _$SearchCapabilityDefinitionCopyWithImpl<$Res>
    implements $SearchCapabilityDefinitionCopyWith<$Res> {
  _$SearchCapabilityDefinitionCopyWithImpl(this._self, this._then);

  final SearchCapabilityDefinition _self;
  final $Res Function(SearchCapabilityDefinition) _then;

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestType = null,Object? resultType = null,}) {
  return _then(SearchCapabilityDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CapabilityId,requestType: null == requestType ? _self.requestType : requestType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,
  ));
}

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapabilityIdCopyWith<$Res> get id {
  
  return $CapabilityIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get requestType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.requestType, (value) {
    return _then(_self.copyWith(requestType: value));
  });
}/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get resultType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.resultType, (value) {
    return _then(_self.copyWith(resultType: value));
  });
}
}

/// @nodoc


class ComputationCapabilityDefinition implements CapabilityDefinition {
  const ComputationCapabilityDefinition({required this.id, required this.requestType, required this.resultType});
  

@override final  CapabilityId id;
@override final  ResolvedTypeRef requestType;
 final  ResolvedTypeRef resultType;

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComputationCapabilityDefinitionCopyWith<ComputationCapabilityDefinition> get copyWith => _$ComputationCapabilityDefinitionCopyWithImpl<ComputationCapabilityDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ComputationCapabilityDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.requestType, requestType) || other.requestType == requestType)&&(identical(other.resultType, resultType) || other.resultType == resultType));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,requestType,resultType);
}

@override
String toString() {
    return 'CapabilityDefinition.computation(id: $id, requestType: $requestType, resultType: $resultType)';
}


}

/// @nodoc
abstract mixin class $ComputationCapabilityDefinitionCopyWith<$Res> implements $CapabilityDefinitionCopyWith<$Res> {
  factory $ComputationCapabilityDefinitionCopyWith(ComputationCapabilityDefinition value, $Res Function(ComputationCapabilityDefinition) _then) = _$ComputationCapabilityDefinitionCopyWithImpl;
@override @useResult
$Res call({
 CapabilityId id, ResolvedTypeRef requestType, ResolvedTypeRef resultType
});


@override $CapabilityIdCopyWith<$Res> get id;@override $ResolvedTypeRefCopyWith<$Res> get requestType;$ResolvedTypeRefCopyWith<$Res> get resultType;

}
/// @nodoc
class _$ComputationCapabilityDefinitionCopyWithImpl<$Res>
    implements $ComputationCapabilityDefinitionCopyWith<$Res> {
  _$ComputationCapabilityDefinitionCopyWithImpl(this._self, this._then);

  final ComputationCapabilityDefinition _self;
  final $Res Function(ComputationCapabilityDefinition) _then;

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestType = null,Object? resultType = null,}) {
  return _then(ComputationCapabilityDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CapabilityId,requestType: null == requestType ? _self.requestType : requestType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,
  ));
}

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapabilityIdCopyWith<$Res> get id {
  
  return $CapabilityIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get requestType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.requestType, (value) {
    return _then(_self.copyWith(requestType: value));
  });
}/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get resultType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.resultType, (value) {
    return _then(_self.copyWith(resultType: value));
  });
}
}

/// @nodoc


class CommandCapabilityDefinition implements CapabilityDefinition {
  const CommandCapabilityDefinition({required this.id, required this.requestType});
  

@override final  CapabilityId id;
@override final  ResolvedTypeRef requestType;

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandCapabilityDefinitionCopyWith<CommandCapabilityDefinition> get copyWith => _$CommandCapabilityDefinitionCopyWithImpl<CommandCapabilityDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandCapabilityDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.requestType, requestType) || other.requestType == requestType));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,requestType);
}

@override
String toString() {
    return 'CapabilityDefinition.command(id: $id, requestType: $requestType)';
}


}

/// @nodoc
abstract mixin class $CommandCapabilityDefinitionCopyWith<$Res> implements $CapabilityDefinitionCopyWith<$Res> {
  factory $CommandCapabilityDefinitionCopyWith(CommandCapabilityDefinition value, $Res Function(CommandCapabilityDefinition) _then) = _$CommandCapabilityDefinitionCopyWithImpl;
@override @useResult
$Res call({
 CapabilityId id, ResolvedTypeRef requestType
});


@override $CapabilityIdCopyWith<$Res> get id;@override $ResolvedTypeRefCopyWith<$Res> get requestType;

}
/// @nodoc
class _$CommandCapabilityDefinitionCopyWithImpl<$Res>
    implements $CommandCapabilityDefinitionCopyWith<$Res> {
  _$CommandCapabilityDefinitionCopyWithImpl(this._self, this._then);

  final CommandCapabilityDefinition _self;
  final $Res Function(CommandCapabilityDefinition) _then;

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestType = null,}) {
  return _then(CommandCapabilityDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CapabilityId,requestType: null == requestType ? _self.requestType : requestType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,
  ));
}

/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapabilityIdCopyWith<$Res> get id {
  
  return $CapabilityIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get requestType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.requestType, (value) {
    return _then(_self.copyWith(requestType: value));
  });
}
}

/// @nodoc
mixin _$TypedValueEnvelope {

 ResolvedTypeRef get rootType; DataValue get rootValue;
/// Create a copy of TypedValueEnvelope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypedValueEnvelopeCopyWith<TypedValueEnvelope> get copyWith => _$TypedValueEnvelopeCopyWithImpl<TypedValueEnvelope>(this as TypedValueEnvelope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TypedValueEnvelope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypedValueEnvelope&&(identical(other.rootType, _this.rootType) || other.rootType == _this.rootType)&&(identical(other.rootValue, _this.rootValue) || other.rootValue == _this.rootValue));
}


@override
int get hashCode {
  final _this = this as TypedValueEnvelope;
  return Object.hash(runtimeType,_this.rootType,_this.rootValue);
}

@override
String toString() {
  final _this = this as TypedValueEnvelope;
  return 'TypedValueEnvelope(rootType: ${_this.rootType}, rootValue: ${_this.rootValue})';
}


}

/// @nodoc
abstract mixin class $TypedValueEnvelopeCopyWith<$Res>  {
  factory $TypedValueEnvelopeCopyWith(TypedValueEnvelope value, $Res Function(TypedValueEnvelope) _then) = _$TypedValueEnvelopeCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef rootType, DataValue rootValue
});


$ResolvedTypeRefCopyWith<$Res> get rootType;$DataValueCopyWith<$Res> get rootValue;

}
/// @nodoc
class _$TypedValueEnvelopeCopyWithImpl<$Res>
    implements $TypedValueEnvelopeCopyWith<$Res> {
  _$TypedValueEnvelopeCopyWithImpl(this._self, this._then);

  final TypedValueEnvelope _self;
  final $Res Function(TypedValueEnvelope) _then;

/// Create a copy of TypedValueEnvelope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rootType = null,Object? rootValue = null,}) {
  return _then(TypedValueEnvelope(
rootType: null == rootType ? _self.rootType : rootType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,rootValue: null == rootValue ? _self.rootValue : rootValue // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}
/// Create a copy of TypedValueEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get rootType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.rootType, (value) {
    return _then(_self.copyWith(rootType: value));
  });
}/// Create a copy of TypedValueEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get rootValue {
  
  return $DataValueCopyWith<$Res>(_self.rootValue, (value) {
    return _then(_self.copyWith(rootValue: value));
  });
}
}


/// Adds pattern-matching-related methods to [TypedValueEnvelope].
extension TypedValueEnvelopePatterns on TypedValueEnvelope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypedValueEnvelope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypedValueEnvelope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypedValueEnvelope value)  $default,){
final _that = this;
switch (_that) {
case _TypedValueEnvelope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypedValueEnvelope value)?  $default,){
final _that = this;
switch (_that) {
case _TypedValueEnvelope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTypeRef rootType,  DataValue rootValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypedValueEnvelope() when $default != null:
return $default(_that.rootType,_that.rootValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTypeRef rootType,  DataValue rootValue)  $default,) {final _that = this;
switch (_that) {
case _TypedValueEnvelope():
return $default(_that.rootType,_that.rootValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTypeRef rootType,  DataValue rootValue)?  $default,) {final _that = this;
switch (_that) {
case _TypedValueEnvelope() when $default != null:
return $default(_that.rootType,_that.rootValue);case _:
  return null;

}
}

}

/// @nodoc


class _TypedValueEnvelope implements TypedValueEnvelope {
  const _TypedValueEnvelope({required this.rootType, required this.rootValue});
  

@override final  ResolvedTypeRef rootType;
@override final  DataValue rootValue;

/// Create a copy of TypedValueEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypedValueEnvelopeCopyWith<_TypedValueEnvelope> get copyWith => __$TypedValueEnvelopeCopyWithImpl<_TypedValueEnvelope>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypedValueEnvelope&&(identical(other.rootType, rootType) || other.rootType == rootType)&&(identical(other.rootValue, rootValue) || other.rootValue == rootValue));
}


@override
int get hashCode {
    return Object.hash(runtimeType,rootType,rootValue);
}

@override
String toString() {
    return 'TypedValueEnvelope(rootType: $rootType, rootValue: $rootValue)';
}


}

/// @nodoc
abstract mixin class _$TypedValueEnvelopeCopyWith<$Res> implements $TypedValueEnvelopeCopyWith<$Res> {
  factory _$TypedValueEnvelopeCopyWith(_TypedValueEnvelope value, $Res Function(_TypedValueEnvelope) _then) = __$TypedValueEnvelopeCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTypeRef rootType, DataValue rootValue
});


@override $ResolvedTypeRefCopyWith<$Res> get rootType;@override $DataValueCopyWith<$Res> get rootValue;

}
/// @nodoc
class __$TypedValueEnvelopeCopyWithImpl<$Res>
    implements _$TypedValueEnvelopeCopyWith<$Res> {
  __$TypedValueEnvelopeCopyWithImpl(this._self, this._then);

  final _TypedValueEnvelope _self;
  final $Res Function(_TypedValueEnvelope) _then;

/// Create a copy of TypedValueEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rootType = null,Object? rootValue = null,}) {
  return _then(_TypedValueEnvelope(
rootType: null == rootType ? _self.rootType : rootType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,rootValue: null == rootValue ? _self.rootValue : rootValue // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of TypedValueEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get rootType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.rootType, (value) {
    return _then(_self.copyWith(rootType: value));
  });
}/// Create a copy of TypedValueEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get rootValue {
  
  return $DataValueCopyWith<$Res>(_self.rootValue, (value) {
    return _then(_self.copyWith(rootValue: value));
  });
}
}

// dart format on
