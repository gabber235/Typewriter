// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversion_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversionDefinition {

 ConversionId get id; ResolvedTypeRef get source; ResolvedTypeRef get target; ConversionRule get rule; ConversionSafety get safety; bool get fallible; ConversionLocality get locality; int get cost;
/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionDefinitionCopyWith<ConversionDefinition> get copyWith => _$ConversionDefinitionCopyWithImpl<ConversionDefinition>(this as ConversionDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.rule, rule) || other.rule == rule)&&(identical(other.safety, safety) || other.safety == safety)&&(identical(other.fallible, fallible) || other.fallible == fallible)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.cost, cost) || other.cost == cost));
}


@override
int get hashCode => Object.hash(runtimeType,id,source,target,rule,safety,fallible,locality,cost);

@override
String toString() {
  return 'ConversionDefinition(id: $id, source: $source, target: $target, rule: $rule, safety: $safety, fallible: $fallible, locality: $locality, cost: $cost)';
}


}

/// @nodoc
abstract mixin class $ConversionDefinitionCopyWith<$Res>  {
  factory $ConversionDefinitionCopyWith(ConversionDefinition value, $Res Function(ConversionDefinition) _then) = _$ConversionDefinitionCopyWithImpl;
@useResult
$Res call({
 ConversionId id, ResolvedTypeRef source, ResolvedTypeRef target, ConversionRule rule, ConversionSafety safety, bool fallible, ConversionLocality locality, int cost
});


$ConversionIdCopyWith<$Res> get id;$ResolvedTypeRefCopyWith<$Res> get source;$ResolvedTypeRefCopyWith<$Res> get target;$ConversionRuleCopyWith<$Res> get rule;

}
/// @nodoc
class _$ConversionDefinitionCopyWithImpl<$Res>
    implements $ConversionDefinitionCopyWith<$Res> {
  _$ConversionDefinitionCopyWithImpl(this._self, this._then);

  final ConversionDefinition _self;
  final $Res Function(ConversionDefinition) _then;

/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? target = null,Object? rule = null,Object? safety = null,Object? fallible = null,Object? locality = null,Object? cost = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ConversionId,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as ConversionRule,safety: null == safety ? _self.safety : safety // ignore: cast_nullable_to_non_nullable
as ConversionSafety,fallible: null == fallible ? _self.fallible : fallible // ignore: cast_nullable_to_non_nullable
as bool,locality: null == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as ConversionLocality,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res> get id {
  
  return $ConversionIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get source {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get target {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionRuleCopyWith<$Res> get rule {
  
  return $ConversionRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversionDefinition].
extension ConversionDefinitionPatterns on ConversionDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversionDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversionDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversionDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ConversionDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversionDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ConversionDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ConversionId id,  ResolvedTypeRef source,  ResolvedTypeRef target,  ConversionRule rule,  ConversionSafety safety,  bool fallible,  ConversionLocality locality,  int cost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversionDefinition() when $default != null:
return $default(_that.id,_that.source,_that.target,_that.rule,_that.safety,_that.fallible,_that.locality,_that.cost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ConversionId id,  ResolvedTypeRef source,  ResolvedTypeRef target,  ConversionRule rule,  ConversionSafety safety,  bool fallible,  ConversionLocality locality,  int cost)  $default,) {final _that = this;
switch (_that) {
case _ConversionDefinition():
return $default(_that.id,_that.source,_that.target,_that.rule,_that.safety,_that.fallible,_that.locality,_that.cost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ConversionId id,  ResolvedTypeRef source,  ResolvedTypeRef target,  ConversionRule rule,  ConversionSafety safety,  bool fallible,  ConversionLocality locality,  int cost)?  $default,) {final _that = this;
switch (_that) {
case _ConversionDefinition() when $default != null:
return $default(_that.id,_that.source,_that.target,_that.rule,_that.safety,_that.fallible,_that.locality,_that.cost);case _:
  return null;

}
}

}

/// @nodoc


class _ConversionDefinition implements ConversionDefinition {
  const _ConversionDefinition({required this.id, required this.source, required this.target, required this.rule, this.safety = ConversionSafety.lossless, this.fallible = false, this.locality = ConversionLocality.local, this.cost = 1}): assert(cost >= 0, 'Cost must not be negative.');
  

@override final  ConversionId id;
@override final  ResolvedTypeRef source;
@override final  ResolvedTypeRef target;
@override final  ConversionRule rule;
@override@JsonKey() final  ConversionSafety safety;
@override@JsonKey() final  bool fallible;
@override@JsonKey() final  ConversionLocality locality;
@override@JsonKey() final  int cost;

/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversionDefinitionCopyWith<_ConversionDefinition> get copyWith => __$ConversionDefinitionCopyWithImpl<_ConversionDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversionDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&(identical(other.rule, rule) || other.rule == rule)&&(identical(other.safety, safety) || other.safety == safety)&&(identical(other.fallible, fallible) || other.fallible == fallible)&&(identical(other.locality, locality) || other.locality == locality)&&(identical(other.cost, cost) || other.cost == cost));
}


@override
int get hashCode => Object.hash(runtimeType,id,source,target,rule,safety,fallible,locality,cost);

@override
String toString() {
  return 'ConversionDefinition(id: $id, source: $source, target: $target, rule: $rule, safety: $safety, fallible: $fallible, locality: $locality, cost: $cost)';
}


}

/// @nodoc
abstract mixin class _$ConversionDefinitionCopyWith<$Res> implements $ConversionDefinitionCopyWith<$Res> {
  factory _$ConversionDefinitionCopyWith(_ConversionDefinition value, $Res Function(_ConversionDefinition) _then) = __$ConversionDefinitionCopyWithImpl;
@override @useResult
$Res call({
 ConversionId id, ResolvedTypeRef source, ResolvedTypeRef target, ConversionRule rule, ConversionSafety safety, bool fallible, ConversionLocality locality, int cost
});


@override $ConversionIdCopyWith<$Res> get id;@override $ResolvedTypeRefCopyWith<$Res> get source;@override $ResolvedTypeRefCopyWith<$Res> get target;@override $ConversionRuleCopyWith<$Res> get rule;

}
/// @nodoc
class __$ConversionDefinitionCopyWithImpl<$Res>
    implements _$ConversionDefinitionCopyWith<$Res> {
  __$ConversionDefinitionCopyWithImpl(this._self, this._then);

  final _ConversionDefinition _self;
  final $Res Function(_ConversionDefinition) _then;

/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? target = null,Object? rule = null,Object? safety = null,Object? fallible = null,Object? locality = null,Object? cost = null,}) {
  return _then(_ConversionDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ConversionId,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as ResolvedTypeRef,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as ConversionRule,safety: null == safety ? _self.safety : safety // ignore: cast_nullable_to_non_nullable
as ConversionSafety,fallible: null == fallible ? _self.fallible : fallible // ignore: cast_nullable_to_non_nullable
as bool,locality: null == locality ? _self.locality : locality // ignore: cast_nullable_to_non_nullable
as ConversionLocality,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionIdCopyWith<$Res> get id {
  
  return $ConversionIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get source {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedTypeRefCopyWith<$Res> get target {
  
  return $ResolvedTypeRefCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of ConversionDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversionRuleCopyWith<$Res> get rule {
  
  return $ConversionRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}

// dart format on
