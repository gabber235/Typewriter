// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'type_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TypeParameter {

 String get name; TypeExpression get bound; TypeVariance get variance;
/// Create a copy of TypeParameter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeParameterCopyWith<TypeParameter> get copyWith => _$TypeParameterCopyWithImpl<TypeParameter>(this as TypeParameter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeParameter&&(identical(other.name, name) || other.name == name)&&(identical(other.bound, bound) || other.bound == bound)&&(identical(other.variance, variance) || other.variance == variance));
}


@override
int get hashCode => Object.hash(runtimeType,name,bound,variance);

@override
String toString() {
  return 'TypeParameter(name: $name, bound: $bound, variance: $variance)';
}


}

/// @nodoc
abstract mixin class $TypeParameterCopyWith<$Res>  {
  factory $TypeParameterCopyWith(TypeParameter value, $Res Function(TypeParameter) _then) = _$TypeParameterCopyWithImpl;
@useResult
$Res call({
 String name, TypeExpression bound, TypeVariance variance
});


$TypeExpressionCopyWith<$Res> get bound;

}
/// @nodoc
class _$TypeParameterCopyWithImpl<$Res>
    implements $TypeParameterCopyWith<$Res> {
  _$TypeParameterCopyWithImpl(this._self, this._then);

  final TypeParameter _self;
  final $Res Function(TypeParameter) _then;

/// Create a copy of TypeParameter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? bound = null,Object? variance = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bound: null == bound ? _self.bound : bound // ignore: cast_nullable_to_non_nullable
as TypeExpression,variance: null == variance ? _self.variance : variance // ignore: cast_nullable_to_non_nullable
as TypeVariance,
  ));
}
/// Create a copy of TypeParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get bound {
  
  return $TypeExpressionCopyWith<$Res>(_self.bound, (value) {
    return _then(_self.copyWith(bound: value));
  });
}
}


/// Adds pattern-matching-related methods to [TypeParameter].
extension TypeParameterPatterns on TypeParameter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypeParameter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypeParameter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypeParameter value)  $default,){
final _that = this;
switch (_that) {
case _TypeParameter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypeParameter value)?  $default,){
final _that = this;
switch (_that) {
case _TypeParameter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  TypeExpression bound,  TypeVariance variance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypeParameter() when $default != null:
return $default(_that.name,_that.bound,_that.variance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  TypeExpression bound,  TypeVariance variance)  $default,) {final _that = this;
switch (_that) {
case _TypeParameter():
return $default(_that.name,_that.bound,_that.variance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  TypeExpression bound,  TypeVariance variance)?  $default,) {final _that = this;
switch (_that) {
case _TypeParameter() when $default != null:
return $default(_that.name,_that.bound,_that.variance);case _:
  return null;

}
}

}

/// @nodoc


class _TypeParameter implements TypeParameter {
  const _TypeParameter({required this.name, this.bound = const AnyType(), this.variance = TypeVariance.invariant}): assert(name != "", 'Parameter name must not be empty.');
  

@override final  String name;
@override@JsonKey() final  TypeExpression bound;
@override@JsonKey() final  TypeVariance variance;

/// Create a copy of TypeParameter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypeParameterCopyWith<_TypeParameter> get copyWith => __$TypeParameterCopyWithImpl<_TypeParameter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypeParameter&&(identical(other.name, name) || other.name == name)&&(identical(other.bound, bound) || other.bound == bound)&&(identical(other.variance, variance) || other.variance == variance));
}


@override
int get hashCode => Object.hash(runtimeType,name,bound,variance);

@override
String toString() {
  return 'TypeParameter(name: $name, bound: $bound, variance: $variance)';
}


}

/// @nodoc
abstract mixin class _$TypeParameterCopyWith<$Res> implements $TypeParameterCopyWith<$Res> {
  factory _$TypeParameterCopyWith(_TypeParameter value, $Res Function(_TypeParameter) _then) = __$TypeParameterCopyWithImpl;
@override @useResult
$Res call({
 String name, TypeExpression bound, TypeVariance variance
});


@override $TypeExpressionCopyWith<$Res> get bound;

}
/// @nodoc
class __$TypeParameterCopyWithImpl<$Res>
    implements _$TypeParameterCopyWith<$Res> {
  __$TypeParameterCopyWithImpl(this._self, this._then);

  final _TypeParameter _self;
  final $Res Function(_TypeParameter) _then;

/// Create a copy of TypeParameter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? bound = null,Object? variance = null,}) {
  return _then(_TypeParameter(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bound: null == bound ? _self.bound : bound // ignore: cast_nullable_to_non_nullable
as TypeExpression,variance: null == variance ? _self.variance : variance // ignore: cast_nullable_to_non_nullable
as TypeVariance,
  ));
}

/// Create a copy of TypeParameter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get bound {
  
  return $TypeExpressionCopyWith<$Res>(_self.bound, (value) {
    return _then(_self.copyWith(bound: value));
  });
}
}

/// @nodoc
mixin _$TypeDefinition {

 ResolvedTypeRef get id; NominalTypeKind get kind; TypeExpression get representation; List<TypeParameter> get parameters; List<ResolvedTypeRef> get parents; PresentationId? get defaultPresentationId; Map<String, PresentationId> get namedPresentations;
/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeDefinitionCopyWith<TypeDefinition> get copyWith => _$TypeDefinitionCopyWithImpl<TypeDefinition>(this as TypeDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.representation, representation) || other.representation == representation)&&const DeepCollectionEquality().equals(other.parameters, parameters)&&const DeepCollectionEquality().equals(other.parents, parents)&&(identical(other.defaultPresentationId, defaultPresentationId) || other.defaultPresentationId == defaultPresentationId)&&const DeepCollectionEquality().equals(other.namedPresentations, namedPresentations));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,representation,const DeepCollectionEquality().hash(parameters),const DeepCollectionEquality().hash(parents),defaultPresentationId,const DeepCollectionEquality().hash(namedPresentations));

@override
String toString() {
  return 'TypeDefinition(id: $id, kind: $kind, representation: $representation, parameters: $parameters, parents: $parents, defaultPresentationId: $defaultPresentationId, namedPresentations: $namedPresentations)';
}


}

/// @nodoc
abstract mixin class $TypeDefinitionCopyWith<$Res>  {
  factory $TypeDefinitionCopyWith(TypeDefinition value, $Res Function(TypeDefinition) _then) = _$TypeDefinitionCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef id, NominalTypeKind kind, TypeExpression representation, List<TypeParameter> parameters, List<ResolvedTypeRef> parents, PresentationId? defaultPresentationId, Map<String, PresentationId> namedPresentations
});


$ResolvedTypeRefCopyWith<$Res> get id;$TypeExpressionCopyWith<$Res> get representation;$PresentationIdCopyWith<$Res>? get defaultPresentationId;

}
/// @nodoc
class _$TypeDefinitionCopyWithImpl<$Res>
    implements $TypeDefinitionCopyWith<$Res> {
  _$TypeDefinitionCopyWithImpl(this._self, this._then);

  final TypeDefinition _self;
  final $Res Function(TypeDefinition) _then;

/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? representation = null,Object? parameters = null,Object? parents = null,Object? defaultPresentationId = freezed,Object? namedPresentations = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NominalTypeKind,representation: null == representation ? _self.representation : representation // ignore: cast_nullable_to_non_nullable
as TypeExpression,parameters: null == parameters ? _self.parameters : parameters // ignore: cast_nullable_to_non_nullable
as List<TypeParameter>,parents: null == parents ? _self.parents : parents // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,defaultPresentationId: freezed == defaultPresentationId ? _self.defaultPresentationId : defaultPresentationId // ignore: cast_nullable_to_non_nullable
as PresentationId?,namedPresentations: null == namedPresentations ? _self.namedPresentations : namedPresentations // ignore: cast_nullable_to_non_nullable
as Map<String, PresentationId>,
  ));
}
/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get id {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get representation {
  
  return $TypeExpressionCopyWith<$Res>(_self.representation, (value) {
    return _then(_self.copyWith(representation: value));
  });
}/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationIdCopyWith<$Res>? get defaultPresentationId {
    if (_self.defaultPresentationId == null) {
    return null;
  }

  return $PresentationIdCopyWith<$Res>(_self.defaultPresentationId!, (value) {
    return _then(_self.copyWith(defaultPresentationId: value));
  });
}
}


/// Adds pattern-matching-related methods to [TypeDefinition].
extension TypeDefinitionPatterns on TypeDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypeDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypeDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypeDefinition value)  $default,){
final _that = this;
switch (_that) {
case _TypeDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypeDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _TypeDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTypeRef id,  NominalTypeKind kind,  TypeExpression representation,  List<TypeParameter> parameters,  List<ResolvedTypeRef> parents,  PresentationId? defaultPresentationId,  Map<String, PresentationId> namedPresentations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypeDefinition() when $default != null:
return $default(_that.id,_that.kind,_that.representation,_that.parameters,_that.parents,_that.defaultPresentationId,_that.namedPresentations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTypeRef id,  NominalTypeKind kind,  TypeExpression representation,  List<TypeParameter> parameters,  List<ResolvedTypeRef> parents,  PresentationId? defaultPresentationId,  Map<String, PresentationId> namedPresentations)  $default,) {final _that = this;
switch (_that) {
case _TypeDefinition():
return $default(_that.id,_that.kind,_that.representation,_that.parameters,_that.parents,_that.defaultPresentationId,_that.namedPresentations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTypeRef id,  NominalTypeKind kind,  TypeExpression representation,  List<TypeParameter> parameters,  List<ResolvedTypeRef> parents,  PresentationId? defaultPresentationId,  Map<String, PresentationId> namedPresentations)?  $default,) {final _that = this;
switch (_that) {
case _TypeDefinition() when $default != null:
return $default(_that.id,_that.kind,_that.representation,_that.parameters,_that.parents,_that.defaultPresentationId,_that.namedPresentations);case _:
  return null;

}
}

}

/// @nodoc


class _TypeDefinition implements TypeDefinition {
  const _TypeDefinition({required this.id, required this.kind, this.representation = const AnyType(), final  List<TypeParameter> parameters = const [], final  List<ResolvedTypeRef> parents = const [], this.defaultPresentationId, final  Map<String, PresentationId> namedPresentations = const {}}): _parameters = parameters,_parents = parents,_namedPresentations = namedPresentations;
  

@override final  ResolvedTypeRef id;
@override final  NominalTypeKind kind;
@override@JsonKey() final  TypeExpression representation;
 final  List<TypeParameter> _parameters;
@override@JsonKey() List<TypeParameter> get parameters {
  if (_parameters is EqualUnmodifiableListView) return _parameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parameters);
}

 final  List<ResolvedTypeRef> _parents;
@override@JsonKey() List<ResolvedTypeRef> get parents {
  if (_parents is EqualUnmodifiableListView) return _parents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parents);
}

@override final  PresentationId? defaultPresentationId;
 final  Map<String, PresentationId> _namedPresentations;
@override@JsonKey() Map<String, PresentationId> get namedPresentations {
  if (_namedPresentations is EqualUnmodifiableMapView) return _namedPresentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_namedPresentations);
}


/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypeDefinitionCopyWith<_TypeDefinition> get copyWith => __$TypeDefinitionCopyWithImpl<_TypeDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypeDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.representation, representation) || other.representation == representation)&&const DeepCollectionEquality().equals(other._parameters, _parameters)&&const DeepCollectionEquality().equals(other._parents, _parents)&&(identical(other.defaultPresentationId, defaultPresentationId) || other.defaultPresentationId == defaultPresentationId)&&const DeepCollectionEquality().equals(other._namedPresentations, _namedPresentations));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,representation,const DeepCollectionEquality().hash(_parameters),const DeepCollectionEquality().hash(_parents),defaultPresentationId,const DeepCollectionEquality().hash(_namedPresentations));

@override
String toString() {
  return 'TypeDefinition(id: $id, kind: $kind, representation: $representation, parameters: $parameters, parents: $parents, defaultPresentationId: $defaultPresentationId, namedPresentations: $namedPresentations)';
}


}

/// @nodoc
abstract mixin class _$TypeDefinitionCopyWith<$Res> implements $TypeDefinitionCopyWith<$Res> {
  factory _$TypeDefinitionCopyWith(_TypeDefinition value, $Res Function(_TypeDefinition) _then) = __$TypeDefinitionCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTypeRef id, NominalTypeKind kind, TypeExpression representation, List<TypeParameter> parameters, List<ResolvedTypeRef> parents, PresentationId? defaultPresentationId, Map<String, PresentationId> namedPresentations
});


@override $ResolvedTypeRefCopyWith<$Res> get id;@override $TypeExpressionCopyWith<$Res> get representation;@override $PresentationIdCopyWith<$Res>? get defaultPresentationId;

}
/// @nodoc
class __$TypeDefinitionCopyWithImpl<$Res>
    implements _$TypeDefinitionCopyWith<$Res> {
  __$TypeDefinitionCopyWithImpl(this._self, this._then);

  final _TypeDefinition _self;
  final $Res Function(_TypeDefinition) _then;

/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? representation = null,Object? parameters = null,Object? parents = null,Object? defaultPresentationId = freezed,Object? namedPresentations = null,}) {
  return _then(_TypeDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NominalTypeKind,representation: null == representation ? _self.representation : representation // ignore: cast_nullable_to_non_nullable
as TypeExpression,parameters: null == parameters ? _self._parameters : parameters // ignore: cast_nullable_to_non_nullable
as List<TypeParameter>,parents: null == parents ? _self._parents : parents // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,defaultPresentationId: freezed == defaultPresentationId ? _self.defaultPresentationId : defaultPresentationId // ignore: cast_nullable_to_non_nullable
as PresentationId?,namedPresentations: null == namedPresentations ? _self._namedPresentations : namedPresentations // ignore: cast_nullable_to_non_nullable
as Map<String, PresentationId>,
  ));
}

/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get id {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get representation {
  
  return $TypeExpressionCopyWith<$Res>(_self.representation, (value) {
    return _then(_self.copyWith(representation: value));
  });
}/// Create a copy of TypeDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationIdCopyWith<$Res>? get defaultPresentationId {
    if (_self.defaultPresentationId == null) {
    return null;
  }

  return $PresentationIdCopyWith<$Res>(_self.defaultPresentationId!, (value) {
    return _then(_self.copyWith(defaultPresentationId: value));
  });
}
}

/// @nodoc
mixin _$TypeCatalog {

 List<TypeDefinition> get definitions;
/// Create a copy of TypeCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TypeCatalogCopyWith<TypeCatalog> get copyWith => _$TypeCatalogCopyWithImpl<TypeCatalog>(this as TypeCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypeCatalog&&const DeepCollectionEquality().equals(other.definitions, definitions));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(definitions));

@override
String toString() {
  return 'TypeCatalog(definitions: $definitions)';
}


}

/// @nodoc
abstract mixin class $TypeCatalogCopyWith<$Res>  {
  factory $TypeCatalogCopyWith(TypeCatalog value, $Res Function(TypeCatalog) _then) = _$TypeCatalogCopyWithImpl;
@useResult
$Res call({
 List<TypeDefinition> definitions
});




}
/// @nodoc
class _$TypeCatalogCopyWithImpl<$Res>
    implements $TypeCatalogCopyWith<$Res> {
  _$TypeCatalogCopyWithImpl(this._self, this._then);

  final TypeCatalog _self;
  final $Res Function(TypeCatalog) _then;

/// Create a copy of TypeCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definitions = null,}) {
  return _then(_self.copyWith(
definitions: null == definitions ? _self.definitions : definitions // ignore: cast_nullable_to_non_nullable
as List<TypeDefinition>,
  ));
}

}


/// Adds pattern-matching-related methods to [TypeCatalog].
extension TypeCatalogPatterns on TypeCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TypeCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TypeCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TypeCatalog value)  $default,){
final _that = this;
switch (_that) {
case _TypeCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TypeCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _TypeCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TypeDefinition> definitions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TypeCatalog() when $default != null:
return $default(_that.definitions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TypeDefinition> definitions)  $default,) {final _that = this;
switch (_that) {
case _TypeCatalog():
return $default(_that.definitions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TypeDefinition> definitions)?  $default,) {final _that = this;
switch (_that) {
case _TypeCatalog() when $default != null:
return $default(_that.definitions);case _:
  return null;

}
}

}

/// @nodoc


class _TypeCatalog implements TypeCatalog {
  const _TypeCatalog(final  List<TypeDefinition> definitions): _definitions = definitions;
  

 final  List<TypeDefinition> _definitions;
@override List<TypeDefinition> get definitions {
  if (_definitions is EqualUnmodifiableListView) return _definitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_definitions);
}


/// Create a copy of TypeCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TypeCatalogCopyWith<_TypeCatalog> get copyWith => __$TypeCatalogCopyWithImpl<_TypeCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TypeCatalog&&const DeepCollectionEquality().equals(other._definitions, _definitions));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_definitions));

@override
String toString() {
  return 'TypeCatalog(definitions: $definitions)';
}


}

/// @nodoc
abstract mixin class _$TypeCatalogCopyWith<$Res> implements $TypeCatalogCopyWith<$Res> {
  factory _$TypeCatalogCopyWith(_TypeCatalog value, $Res Function(_TypeCatalog) _then) = __$TypeCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<TypeDefinition> definitions
});




}
/// @nodoc
class __$TypeCatalogCopyWithImpl<$Res>
    implements _$TypeCatalogCopyWith<$Res> {
  __$TypeCatalogCopyWithImpl(this._self, this._then);

  final _TypeCatalog _self;
  final $Res Function(_TypeCatalog) _then;

/// Create a copy of TypeCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definitions = null,}) {
  return _then(_TypeCatalog(
null == definitions ? _self._definitions : definitions // ignore: cast_nullable_to_non_nullable
as List<TypeDefinition>,
  ));
}


}

/// @nodoc
mixin _$ResolvedType {

 ResolvedTypeRef get reference; NominalTypeKind get kind; TypeExpression get representation; Set<ResolvedTypeRef> get ancestors; Set<ResolvedTypeRef> get directParents;
/// Create a copy of ResolvedType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedTypeCopyWith<ResolvedType> get copyWith => _$ResolvedTypeCopyWithImpl<ResolvedType>(this as ResolvedType, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedType&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.representation, representation) || other.representation == representation)&&const DeepCollectionEquality().equals(other.ancestors, ancestors)&&const DeepCollectionEquality().equals(other.directParents, directParents));
}


@override
int get hashCode => Object.hash(runtimeType,reference,kind,representation,const DeepCollectionEquality().hash(ancestors),const DeepCollectionEquality().hash(directParents));

@override
String toString() {
  return 'ResolvedType(reference: $reference, kind: $kind, representation: $representation, ancestors: $ancestors, directParents: $directParents)';
}


}

/// @nodoc
abstract mixin class $ResolvedTypeCopyWith<$Res>  {
  factory $ResolvedTypeCopyWith(ResolvedType value, $Res Function(ResolvedType) _then) = _$ResolvedTypeCopyWithImpl;
@useResult
$Res call({
 ResolvedTypeRef reference, NominalTypeKind kind, TypeExpression representation, Set<ResolvedTypeRef> ancestors, Set<ResolvedTypeRef> directParents
});


$ResolvedTypeRefCopyWith<$Res> get reference;$TypeExpressionCopyWith<$Res> get representation;

}
/// @nodoc
class _$ResolvedTypeCopyWithImpl<$Res>
    implements $ResolvedTypeCopyWith<$Res> {
  _$ResolvedTypeCopyWithImpl(this._self, this._then);

  final ResolvedType _self;
  final $Res Function(ResolvedType) _then;

/// Create a copy of ResolvedType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? kind = null,Object? representation = null,Object? ancestors = null,Object? directParents = null,}) {
  return _then(_self.copyWith(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NominalTypeKind,representation: null == representation ? _self.representation : representation // ignore: cast_nullable_to_non_nullable
as TypeExpression,ancestors: null == ancestors ? _self.ancestors : ancestors // ignore: cast_nullable_to_non_nullable
as Set<ResolvedTypeRef>,directParents: null == directParents ? _self.directParents : directParents // ignore: cast_nullable_to_non_nullable
as Set<ResolvedTypeRef>,
  ));
}
/// Create a copy of ResolvedType
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get reference {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of ResolvedType
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get representation {
  
  return $TypeExpressionCopyWith<$Res>(_self.representation, (value) {
    return _then(_self.copyWith(representation: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResolvedType].
extension ResolvedTypePatterns on ResolvedType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedType() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedType value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedType():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedType value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedType() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResolvedTypeRef reference,  NominalTypeKind kind,  TypeExpression representation,  Set<ResolvedTypeRef> ancestors,  Set<ResolvedTypeRef> directParents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedType() when $default != null:
return $default(_that.reference,_that.kind,_that.representation,_that.ancestors,_that.directParents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResolvedTypeRef reference,  NominalTypeKind kind,  TypeExpression representation,  Set<ResolvedTypeRef> ancestors,  Set<ResolvedTypeRef> directParents)  $default,) {final _that = this;
switch (_that) {
case _ResolvedType():
return $default(_that.reference,_that.kind,_that.representation,_that.ancestors,_that.directParents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResolvedTypeRef reference,  NominalTypeKind kind,  TypeExpression representation,  Set<ResolvedTypeRef> ancestors,  Set<ResolvedTypeRef> directParents)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedType() when $default != null:
return $default(_that.reference,_that.kind,_that.representation,_that.ancestors,_that.directParents);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedType extends ResolvedType {
  const _ResolvedType({required this.reference, required this.kind, required this.representation, required final  Set<ResolvedTypeRef> ancestors, final  Set<ResolvedTypeRef> directParents = const {}}): _ancestors = ancestors,_directParents = directParents,super._();
  

@override final  ResolvedTypeRef reference;
@override final  NominalTypeKind kind;
@override final  TypeExpression representation;
 final  Set<ResolvedTypeRef> _ancestors;
@override Set<ResolvedTypeRef> get ancestors {
  if (_ancestors is EqualUnmodifiableSetView) return _ancestors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_ancestors);
}

 final  Set<ResolvedTypeRef> _directParents;
@override@JsonKey() Set<ResolvedTypeRef> get directParents {
  if (_directParents is EqualUnmodifiableSetView) return _directParents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_directParents);
}


/// Create a copy of ResolvedType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedTypeCopyWith<_ResolvedType> get copyWith => __$ResolvedTypeCopyWithImpl<_ResolvedType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedType&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.representation, representation) || other.representation == representation)&&const DeepCollectionEquality().equals(other._ancestors, _ancestors)&&const DeepCollectionEquality().equals(other._directParents, _directParents));
}


@override
int get hashCode => Object.hash(runtimeType,reference,kind,representation,const DeepCollectionEquality().hash(_ancestors),const DeepCollectionEquality().hash(_directParents));

@override
String toString() {
  return 'ResolvedType(reference: $reference, kind: $kind, representation: $representation, ancestors: $ancestors, directParents: $directParents)';
}


}

/// @nodoc
abstract mixin class _$ResolvedTypeCopyWith<$Res> implements $ResolvedTypeCopyWith<$Res> {
  factory _$ResolvedTypeCopyWith(_ResolvedType value, $Res Function(_ResolvedType) _then) = __$ResolvedTypeCopyWithImpl;
@override @useResult
$Res call({
 ResolvedTypeRef reference, NominalTypeKind kind, TypeExpression representation, Set<ResolvedTypeRef> ancestors, Set<ResolvedTypeRef> directParents
});


@override $ResolvedTypeRefCopyWith<$Res> get reference;@override $TypeExpressionCopyWith<$Res> get representation;

}
/// @nodoc
class __$ResolvedTypeCopyWithImpl<$Res>
    implements _$ResolvedTypeCopyWith<$Res> {
  __$ResolvedTypeCopyWithImpl(this._self, this._then);

  final _ResolvedType _self;
  final $Res Function(_ResolvedType) _then;

/// Create a copy of ResolvedType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? kind = null,Object? representation = null,Object? ancestors = null,Object? directParents = null,}) {
  return _then(_ResolvedType(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NominalTypeKind,representation: null == representation ? _self.representation : representation // ignore: cast_nullable_to_non_nullable
as TypeExpression,ancestors: null == ancestors ? _self._ancestors : ancestors // ignore: cast_nullable_to_non_nullable
as Set<ResolvedTypeRef>,directParents: null == directParents ? _self._directParents : directParents // ignore: cast_nullable_to_non_nullable
as Set<ResolvedTypeRef>,
  ));
}

/// Create a copy of ResolvedType
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get reference {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of ResolvedType
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeExpressionCopyWith<$Res> get representation {
  
  return $TypeExpressionCopyWith<$Res>(_self.representation, (value) {
    return _then(_self.copyWith(representation: value));
  });
}
}

// dart format on
