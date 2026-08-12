// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationDefinition {

 PresentationId get id; TypeExpression get target; PresentationNode get root;
/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationDefinitionCopyWith<PresentationDefinition> get copyWith => _$PresentationDefinitionCopyWithImpl<PresentationDefinition>(this as PresentationDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.target, target) || other.target == target)&&(identical(other.root, root) || other.root == root));
}


@override
int get hashCode => Object.hash(runtimeType,id,target,root);

@override
String toString() {
  return 'PresentationDefinition(id: $id, target: $target, root: $root)';
}


}

/// @nodoc
abstract mixin class $PresentationDefinitionCopyWith<$Res>  {
  factory $PresentationDefinitionCopyWith(PresentationDefinition value, $Res Function(PresentationDefinition) _then) = _$PresentationDefinitionCopyWithImpl;
@useResult
$Res call({
 PresentationId id, TypeExpression target, PresentationNode root
});


$PresentationIdCopyWith<$Res> get id;$TypeExpressionCopyWith<$Res> get target;$PresentationNodeCopyWith<$Res> get root;

}
/// @nodoc
class _$PresentationDefinitionCopyWithImpl<$Res>
    implements $PresentationDefinitionCopyWith<$Res> {
  _$PresentationDefinitionCopyWithImpl(this._self, this._then);

  final PresentationDefinition _self;
  final $Res Function(PresentationDefinition) _then;

/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? target = null,Object? root = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationId,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as TypeExpression,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,
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
$TypeExpressionCopyWith<$Res> get target {
  
  return $TypeExpressionCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationNodeCopyWith<$Res> get root {
  
  return $PresentationNodeCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PresentationId id,  TypeExpression target,  PresentationNode root)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationDefinition() when $default != null:
return $default(_that.id,_that.target,_that.root);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PresentationId id,  TypeExpression target,  PresentationNode root)  $default,) {final _that = this;
switch (_that) {
case _PresentationDefinition():
return $default(_that.id,_that.target,_that.root);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PresentationId id,  TypeExpression target,  PresentationNode root)?  $default,) {final _that = this;
switch (_that) {
case _PresentationDefinition() when $default != null:
return $default(_that.id,_that.target,_that.root);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationDefinition implements PresentationDefinition {
  const _PresentationDefinition({required this.id, required this.target, required this.root});
  

@override final  PresentationId id;
@override final  TypeExpression target;
@override final  PresentationNode root;

/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationDefinitionCopyWith<_PresentationDefinition> get copyWith => __$PresentationDefinitionCopyWithImpl<_PresentationDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.target, target) || other.target == target)&&(identical(other.root, root) || other.root == root));
}


@override
int get hashCode => Object.hash(runtimeType,id,target,root);

@override
String toString() {
  return 'PresentationDefinition(id: $id, target: $target, root: $root)';
}


}

/// @nodoc
abstract mixin class _$PresentationDefinitionCopyWith<$Res> implements $PresentationDefinitionCopyWith<$Res> {
  factory _$PresentationDefinitionCopyWith(_PresentationDefinition value, $Res Function(_PresentationDefinition) _then) = __$PresentationDefinitionCopyWithImpl;
@override @useResult
$Res call({
 PresentationId id, TypeExpression target, PresentationNode root
});


@override $PresentationIdCopyWith<$Res> get id;@override $TypeExpressionCopyWith<$Res> get target;@override $PresentationNodeCopyWith<$Res> get root;

}
/// @nodoc
class __$PresentationDefinitionCopyWithImpl<$Res>
    implements _$PresentationDefinitionCopyWith<$Res> {
  __$PresentationDefinitionCopyWithImpl(this._self, this._then);

  final _PresentationDefinition _self;
  final $Res Function(_PresentationDefinition) _then;

/// Create a copy of PresentationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? target = null,Object? root = null,}) {
  return _then(_PresentationDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PresentationId,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as TypeExpression,root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as PresentationNode,
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
$TypeExpressionCopyWith<$Res> get target {
  
  return $TypeExpressionCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of PresentationDefinition
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
mixin _$RealmActionDefinition {

 RealmActionId get id; ResolvedTypeRef get payloadType; ResolvedTypeRef? get resultType;
/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmActionDefinitionCopyWith<RealmActionDefinition> get copyWith => _$RealmActionDefinitionCopyWithImpl<RealmActionDefinition>(this as RealmActionDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmActionDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.payloadType, payloadType) || other.payloadType == payloadType)&&(identical(other.resultType, resultType) || other.resultType == resultType));
}


@override
int get hashCode => Object.hash(runtimeType,id,payloadType,resultType);

@override
String toString() {
  return 'RealmActionDefinition(id: $id, payloadType: $payloadType, resultType: $resultType)';
}


}

/// @nodoc
abstract mixin class $RealmActionDefinitionCopyWith<$Res>  {
  factory $RealmActionDefinitionCopyWith(RealmActionDefinition value, $Res Function(RealmActionDefinition) _then) = _$RealmActionDefinitionCopyWithImpl;
@useResult
$Res call({
 RealmActionId id, ResolvedTypeRef payloadType, ResolvedTypeRef? resultType
});


$RealmActionIdCopyWith<$Res> get id;$ResolvedTypeRefCopyWith<$Res> get payloadType;$ResolvedTypeRefCopyWith<$Res>? get resultType;

}
/// @nodoc
class _$RealmActionDefinitionCopyWithImpl<$Res>
    implements $RealmActionDefinitionCopyWith<$Res> {
  _$RealmActionDefinitionCopyWithImpl(this._self, this._then);

  final RealmActionDefinition _self;
  final $Res Function(RealmActionDefinition) _then;

/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? payloadType = null,Object? resultType = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as RealmActionId,payloadType: null == payloadType ? _self.payloadType : payloadType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,resultType: freezed == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef?,
  ));
}
/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionIdCopyWith<$Res> get id {
  
  return $RealmActionIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get payloadType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.payloadType, (value) {
    return _then(_self.copyWith(payloadType: value));
  });
}/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res>? get resultType {
    if (_self.resultType == null) {
    return null;
  }

  return $ResolvedTypeRefCopyWith<$Res>(_self.resultType!, (value) {
    return _then(_self.copyWith(resultType: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmActionDefinition].
extension RealmActionDefinitionPatterns on RealmActionDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmActionDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmActionDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmActionDefinition value)  $default,){
final _that = this;
switch (_that) {
case _RealmActionDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmActionDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _RealmActionDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RealmActionId id,  ResolvedTypeRef payloadType,  ResolvedTypeRef? resultType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmActionDefinition() when $default != null:
return $default(_that.id,_that.payloadType,_that.resultType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RealmActionId id,  ResolvedTypeRef payloadType,  ResolvedTypeRef? resultType)  $default,) {final _that = this;
switch (_that) {
case _RealmActionDefinition():
return $default(_that.id,_that.payloadType,_that.resultType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RealmActionId id,  ResolvedTypeRef payloadType,  ResolvedTypeRef? resultType)?  $default,) {final _that = this;
switch (_that) {
case _RealmActionDefinition() when $default != null:
return $default(_that.id,_that.payloadType,_that.resultType);case _:
  return null;

}
}

}

/// @nodoc


class _RealmActionDefinition implements RealmActionDefinition {
  const _RealmActionDefinition({required this.id, required this.payloadType, this.resultType});
  

@override final  RealmActionId id;
@override final  ResolvedTypeRef payloadType;
@override final  ResolvedTypeRef? resultType;

/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmActionDefinitionCopyWith<_RealmActionDefinition> get copyWith => __$RealmActionDefinitionCopyWithImpl<_RealmActionDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmActionDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.payloadType, payloadType) || other.payloadType == payloadType)&&(identical(other.resultType, resultType) || other.resultType == resultType));
}


@override
int get hashCode => Object.hash(runtimeType,id,payloadType,resultType);

@override
String toString() {
  return 'RealmActionDefinition(id: $id, payloadType: $payloadType, resultType: $resultType)';
}


}

/// @nodoc
abstract mixin class _$RealmActionDefinitionCopyWith<$Res> implements $RealmActionDefinitionCopyWith<$Res> {
  factory _$RealmActionDefinitionCopyWith(_RealmActionDefinition value, $Res Function(_RealmActionDefinition) _then) = __$RealmActionDefinitionCopyWithImpl;
@override @useResult
$Res call({
 RealmActionId id, ResolvedTypeRef payloadType, ResolvedTypeRef? resultType
});


@override $RealmActionIdCopyWith<$Res> get id;@override $ResolvedTypeRefCopyWith<$Res> get payloadType;@override $ResolvedTypeRefCopyWith<$Res>? get resultType;

}
/// @nodoc
class __$RealmActionDefinitionCopyWithImpl<$Res>
    implements _$RealmActionDefinitionCopyWith<$Res> {
  __$RealmActionDefinitionCopyWithImpl(this._self, this._then);

  final _RealmActionDefinition _self;
  final $Res Function(_RealmActionDefinition) _then;

/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? payloadType = null,Object? resultType = freezed,}) {
  return _then(_RealmActionDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as RealmActionId,payloadType: null == payloadType ? _self.payloadType : payloadType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,resultType: freezed == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef?,
  ));
}

/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmActionIdCopyWith<$Res> get id {
  
  return $RealmActionIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get payloadType {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.payloadType, (value) {
    return _then(_self.copyWith(payloadType: value));
  });
}/// Create a copy of RealmActionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res>? get resultType {
    if (_self.resultType == null) {
    return null;
  }

  return $ResolvedTypeRefCopyWith<$Res>(_self.resultType!, (value) {
    return _then(_self.copyWith(resultType: value));
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypedValueEnvelope&&(identical(other.rootType, rootType) || other.rootType == rootType)&&(identical(other.rootValue, rootValue) || other.rootValue == rootValue));
}


@override
int get hashCode => Object.hash(runtimeType,rootType,rootValue);

@override
String toString() {
  return 'TypedValueEnvelope(rootType: $rootType, rootValue: $rootValue)';
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
  return _then(_self.copyWith(
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
int get hashCode => Object.hash(runtimeType,rootType,rootValue);

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
