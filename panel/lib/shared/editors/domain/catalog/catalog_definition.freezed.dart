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
mixin _$CapabilityDefinition {

 CapabilityId get id; ResolvedTypeRef get requestType;
/// Create a copy of CapabilityDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapabilityDefinitionCopyWith<CapabilityDefinition> get copyWith => _$CapabilityDefinitionCopyWithImpl<CapabilityDefinition>(this as CapabilityDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapabilityDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.requestType, requestType) || other.requestType == requestType));
}


@override
int get hashCode => Object.hash(runtimeType,id,requestType);

@override
String toString() {
  return 'CapabilityDefinition(id: $id, requestType: $requestType)';
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
int get hashCode => Object.hash(runtimeType,id,requestType,resultType);

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
int get hashCode => Object.hash(runtimeType,id,requestType,resultType);

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
int get hashCode => Object.hash(runtimeType,id,requestType);

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
