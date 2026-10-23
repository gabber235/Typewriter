// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_link_choices.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortableLinkPlanResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableLinkPlanResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableLinkPlanResult()';
}


}

/// @nodoc
class $PortableLinkPlanResultCopyWith<$Res>  {
$PortableLinkPlanResultCopyWith(PortableLinkPlanResult _, $Res Function(PortableLinkPlanResult) __);
}


/// Adds pattern-matching-related methods to [PortableLinkPlanResult].
extension PortableLinkPlanResultPatterns on PortableLinkPlanResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortableLinkPlanReady value)?  ready,TResult Function( PortableLinkPlanUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortableLinkPlanReady() when ready != null:
return ready(_that);case PortableLinkPlanUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortableLinkPlanReady value)  ready,required TResult Function( PortableLinkPlanUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case PortableLinkPlanReady():
return ready(_that);case PortableLinkPlanUnavailable():
return unavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortableLinkPlanReady value)?  ready,TResult? Function( PortableLinkPlanUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case PortableLinkPlanReady() when ready != null:
return ready(_that);case PortableLinkPlanUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<PortableLinkPlan> plans)?  ready,TResult Function( String message)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortableLinkPlanReady() when ready != null:
return ready(_that.plans);case PortableLinkPlanUnavailable() when unavailable != null:
return unavailable(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<PortableLinkPlan> plans)  ready,required TResult Function( String message)  unavailable,}) {final _that = this;
switch (_that) {
case PortableLinkPlanReady():
return ready(_that.plans);case PortableLinkPlanUnavailable():
return unavailable(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<PortableLinkPlan> plans)?  ready,TResult? Function( String message)?  unavailable,}) {final _that = this;
switch (_that) {
case PortableLinkPlanReady() when ready != null:
return ready(_that.plans);case PortableLinkPlanUnavailable() when unavailable != null:
return unavailable(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class PortableLinkPlanReady implements PortableLinkPlanResult {
  const PortableLinkPlanReady( List<PortableLinkPlan> plans): _plans = plans;
  

 final  List<PortableLinkPlan> _plans;
 List<PortableLinkPlan> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}


/// Create a copy of PortableLinkPlanResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableLinkPlanReadyCopyWith<PortableLinkPlanReady> get copyWith => _$PortableLinkPlanReadyCopyWithImpl<PortableLinkPlanReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableLinkPlanReady&&const DeepCollectionEquality().equals(other.plans, _plans));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_plans));
}

@override
String toString() {
    return 'PortableLinkPlanResult.ready(plans: $plans)';
}


}

/// @nodoc
abstract mixin class $PortableLinkPlanReadyCopyWith<$Res> implements $PortableLinkPlanResultCopyWith<$Res> {
  factory $PortableLinkPlanReadyCopyWith(PortableLinkPlanReady value, $Res Function(PortableLinkPlanReady) _then) = _$PortableLinkPlanReadyCopyWithImpl;
@useResult
$Res call({
 List<PortableLinkPlan> plans
});




}
/// @nodoc
class _$PortableLinkPlanReadyCopyWithImpl<$Res>
    implements $PortableLinkPlanReadyCopyWith<$Res> {
  _$PortableLinkPlanReadyCopyWithImpl(this._self, this._then);

  final PortableLinkPlanReady _self;
  final $Res Function(PortableLinkPlanReady) _then;

/// Create a copy of PortableLinkPlanResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? plans = null,}) {
  return _then(PortableLinkPlanReady(
null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<PortableLinkPlan>,
  ));
}


}

/// @nodoc


class PortableLinkPlanUnavailable implements PortableLinkPlanResult {
  const PortableLinkPlanUnavailable(this.message);
  

 final  String message;

/// Create a copy of PortableLinkPlanResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableLinkPlanUnavailableCopyWith<PortableLinkPlanUnavailable> get copyWith => _$PortableLinkPlanUnavailableCopyWithImpl<PortableLinkPlanUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableLinkPlanUnavailable&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'PortableLinkPlanResult.unavailable(message: $message)';
}


}

/// @nodoc
abstract mixin class $PortableLinkPlanUnavailableCopyWith<$Res> implements $PortableLinkPlanResultCopyWith<$Res> {
  factory $PortableLinkPlanUnavailableCopyWith(PortableLinkPlanUnavailable value, $Res Function(PortableLinkPlanUnavailable) _then) = _$PortableLinkPlanUnavailableCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PortableLinkPlanUnavailableCopyWithImpl<$Res>
    implements $PortableLinkPlanUnavailableCopyWith<$Res> {
  _$PortableLinkPlanUnavailableCopyWithImpl(this._self, this._then);

  final PortableLinkPlanUnavailable _self;
  final $Res Function(PortableLinkPlanUnavailable) _then;

/// Create a copy of PortableLinkPlanResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PortableLinkPlanUnavailable(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PortableLinkPlan {

 skir.LinkOccurrence get source; skir.RelationContract get relation; skir.EndpointDefinition get opposite; skir.TypeUse get targetType; List<PortableLinkTargetChoice> get targets;
/// Create a copy of PortableLinkPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<PortableLinkPlan> get copyWith => _$PortableLinkPlanCopyWithImpl<PortableLinkPlan>(this as PortableLinkPlan, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableLinkPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableLinkPlan&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.relation, _this.relation) || other.relation == _this.relation)&&(identical(other.opposite, _this.opposite) || other.opposite == _this.opposite)&&(identical(other.targetType, _this.targetType) || other.targetType == _this.targetType)&&const DeepCollectionEquality().equals(other.targets, _this.targets));
}


@override
int get hashCode {
  final _this = this as PortableLinkPlan;
  return Object.hash(runtimeType,_this.source,_this.relation,_this.opposite,_this.targetType,const DeepCollectionEquality().hash(_this.targets));
}

@override
String toString() {
  final _this = this as PortableLinkPlan;
  return 'PortableLinkPlan(source: ${_this.source}, relation: ${_this.relation}, opposite: ${_this.opposite}, targetType: ${_this.targetType}, targets: ${_this.targets})';
}


}

/// @nodoc
abstract mixin class $PortableLinkPlanCopyWith<$Res>  {
  factory $PortableLinkPlanCopyWith(PortableLinkPlan value, $Res Function(PortableLinkPlan) _then) = _$PortableLinkPlanCopyWithImpl;
@useResult
$Res call({
 skir.LinkOccurrence source, skir.RelationContract relation, skir.EndpointDefinition opposite, skir.TypeUse targetType, List<PortableLinkTargetChoice> targets
});




}
/// @nodoc
class _$PortableLinkPlanCopyWithImpl<$Res>
    implements $PortableLinkPlanCopyWith<$Res> {
  _$PortableLinkPlanCopyWithImpl(this._self, this._then);

  final PortableLinkPlan _self;
  final $Res Function(PortableLinkPlan) _then;

/// Create a copy of PortableLinkPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? relation = null,Object? opposite = null,Object? targetType = null,Object? targets = null,}) {
  return _then(PortableLinkPlan(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as skir.RelationContract,opposite: null == opposite ? _self.opposite : opposite // ignore: cast_nullable_to_non_nullable
as skir.EndpointDefinition,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as skir.TypeUse,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as List<PortableLinkTargetChoice>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableLinkPlan].
extension PortableLinkPlanPatterns on PortableLinkPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableLinkPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableLinkPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableLinkPlan value)  $default,){
final _that = this;
switch (_that) {
case _PortableLinkPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableLinkPlan value)?  $default,){
final _that = this;
switch (_that) {
case _PortableLinkPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.LinkOccurrence source,  skir.RelationContract relation,  skir.EndpointDefinition opposite,  skir.TypeUse targetType,  List<PortableLinkTargetChoice> targets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableLinkPlan() when $default != null:
return $default(_that.source,_that.relation,_that.opposite,_that.targetType,_that.targets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.LinkOccurrence source,  skir.RelationContract relation,  skir.EndpointDefinition opposite,  skir.TypeUse targetType,  List<PortableLinkTargetChoice> targets)  $default,) {final _that = this;
switch (_that) {
case _PortableLinkPlan():
return $default(_that.source,_that.relation,_that.opposite,_that.targetType,_that.targets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.LinkOccurrence source,  skir.RelationContract relation,  skir.EndpointDefinition opposite,  skir.TypeUse targetType,  List<PortableLinkTargetChoice> targets)?  $default,) {final _that = this;
switch (_that) {
case _PortableLinkPlan() when $default != null:
return $default(_that.source,_that.relation,_that.opposite,_that.targetType,_that.targets);case _:
  return null;

}
}

}

/// @nodoc


class _PortableLinkPlan implements PortableLinkPlan {
  const _PortableLinkPlan({required this.source, required this.relation, required this.opposite, required this.targetType, required  List<PortableLinkTargetChoice> targets}): _targets = targets;
  

@override final  skir.LinkOccurrence source;
@override final  skir.RelationContract relation;
@override final  skir.EndpointDefinition opposite;
@override final  skir.TypeUse targetType;
 final  List<PortableLinkTargetChoice> _targets;
@override List<PortableLinkTargetChoice> get targets {
  if (_targets is EqualUnmodifiableListView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targets);
}


/// Create a copy of PortableLinkPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableLinkPlanCopyWith<_PortableLinkPlan> get copyWith => __$PortableLinkPlanCopyWithImpl<_PortableLinkPlan>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableLinkPlan&&(identical(other.source, source) || other.source == source)&&(identical(other.relation, relation) || other.relation == relation)&&(identical(other.opposite, opposite) || other.opposite == opposite)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&const DeepCollectionEquality().equals(other.targets, _targets));
}


@override
int get hashCode {
    return Object.hash(runtimeType,source,relation,opposite,targetType,const DeepCollectionEquality().hash(_targets));
}

@override
String toString() {
    return 'PortableLinkPlan(source: $source, relation: $relation, opposite: $opposite, targetType: $targetType, targets: $targets)';
}


}

/// @nodoc
abstract mixin class _$PortableLinkPlanCopyWith<$Res> implements $PortableLinkPlanCopyWith<$Res> {
  factory _$PortableLinkPlanCopyWith(_PortableLinkPlan value, $Res Function(_PortableLinkPlan) _then) = __$PortableLinkPlanCopyWithImpl;
@override @useResult
$Res call({
 skir.LinkOccurrence source, skir.RelationContract relation, skir.EndpointDefinition opposite, skir.TypeUse targetType, List<PortableLinkTargetChoice> targets
});




}
/// @nodoc
class __$PortableLinkPlanCopyWithImpl<$Res>
    implements _$PortableLinkPlanCopyWith<$Res> {
  __$PortableLinkPlanCopyWithImpl(this._self, this._then);

  final _PortableLinkPlan _self;
  final $Res Function(_PortableLinkPlan) _then;

/// Create a copy of PortableLinkPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? relation = null,Object? opposite = null,Object? targetType = null,Object? targets = null,}) {
  return _then(_PortableLinkPlan(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as skir.RelationContract,opposite: null == opposite ? _self.opposite : opposite // ignore: cast_nullable_to_non_nullable
as skir.EndpointDefinition,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as skir.TypeUse,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as List<PortableLinkTargetChoice>,
  ));
}


}

/// @nodoc
mixin _$PortableLinkTargetChoice {

 skir.ResourceId get resource; bool get automaticCounterpart; List<skir.LinkOccurrence> get existing; List<PortableNewCounterpartChoice> get creatable; List<skir.ValueLocation> get collections; String? get disabledReason;
/// Create a copy of PortableLinkTargetChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<PortableLinkTargetChoice> get copyWith => _$PortableLinkTargetChoiceCopyWithImpl<PortableLinkTargetChoice>(this as PortableLinkTargetChoice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableLinkTargetChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableLinkTargetChoice&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.automaticCounterpart, _this.automaticCounterpart) || other.automaticCounterpart == _this.automaticCounterpart)&&const DeepCollectionEquality().equals(other.existing, _this.existing)&&const DeepCollectionEquality().equals(other.creatable, _this.creatable)&&const DeepCollectionEquality().equals(other.collections, _this.collections)&&(identical(other.disabledReason, _this.disabledReason) || other.disabledReason == _this.disabledReason));
}


@override
int get hashCode {
  final _this = this as PortableLinkTargetChoice;
  return Object.hash(runtimeType,_this.resource,_this.automaticCounterpart,const DeepCollectionEquality().hash(_this.existing),const DeepCollectionEquality().hash(_this.creatable),const DeepCollectionEquality().hash(_this.collections),_this.disabledReason);
}

@override
String toString() {
  final _this = this as PortableLinkTargetChoice;
  return 'PortableLinkTargetChoice(resource: ${_this.resource}, automaticCounterpart: ${_this.automaticCounterpart}, existing: ${_this.existing}, creatable: ${_this.creatable}, collections: ${_this.collections}, disabledReason: ${_this.disabledReason})';
}


}

/// @nodoc
abstract mixin class $PortableLinkTargetChoiceCopyWith<$Res>  {
  factory $PortableLinkTargetChoiceCopyWith(PortableLinkTargetChoice value, $Res Function(PortableLinkTargetChoice) _then) = _$PortableLinkTargetChoiceCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId resource, bool automaticCounterpart, List<skir.LinkOccurrence> existing, List<PortableNewCounterpartChoice> creatable, List<skir.ValueLocation> collections, String? disabledReason
});




}
/// @nodoc
class _$PortableLinkTargetChoiceCopyWithImpl<$Res>
    implements $PortableLinkTargetChoiceCopyWith<$Res> {
  _$PortableLinkTargetChoiceCopyWithImpl(this._self, this._then);

  final PortableLinkTargetChoice _self;
  final $Res Function(PortableLinkTargetChoice) _then;

/// Create a copy of PortableLinkTargetChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? automaticCounterpart = null,Object? existing = null,Object? creatable = null,Object? collections = null,Object? disabledReason = freezed,}) {
  return _then(PortableLinkTargetChoice(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,automaticCounterpart: null == automaticCounterpart ? _self.automaticCounterpart : automaticCounterpart // ignore: cast_nullable_to_non_nullable
as bool,existing: null == existing ? _self.existing : existing // ignore: cast_nullable_to_non_nullable
as List<skir.LinkOccurrence>,creatable: null == creatable ? _self.creatable : creatable // ignore: cast_nullable_to_non_nullable
as List<PortableNewCounterpartChoice>,collections: null == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as List<skir.ValueLocation>,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableLinkTargetChoice].
extension PortableLinkTargetChoicePatterns on PortableLinkTargetChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableLinkTargetChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableLinkTargetChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableLinkTargetChoice value)  $default,){
final _that = this;
switch (_that) {
case _PortableLinkTargetChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableLinkTargetChoice value)?  $default,){
final _that = this;
switch (_that) {
case _PortableLinkTargetChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId resource,  bool automaticCounterpart,  List<skir.LinkOccurrence> existing,  List<PortableNewCounterpartChoice> creatable,  List<skir.ValueLocation> collections,  String? disabledReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableLinkTargetChoice() when $default != null:
return $default(_that.resource,_that.automaticCounterpart,_that.existing,_that.creatable,_that.collections,_that.disabledReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId resource,  bool automaticCounterpart,  List<skir.LinkOccurrence> existing,  List<PortableNewCounterpartChoice> creatable,  List<skir.ValueLocation> collections,  String? disabledReason)  $default,) {final _that = this;
switch (_that) {
case _PortableLinkTargetChoice():
return $default(_that.resource,_that.automaticCounterpart,_that.existing,_that.creatable,_that.collections,_that.disabledReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId resource,  bool automaticCounterpart,  List<skir.LinkOccurrence> existing,  List<PortableNewCounterpartChoice> creatable,  List<skir.ValueLocation> collections,  String? disabledReason)?  $default,) {final _that = this;
switch (_that) {
case _PortableLinkTargetChoice() when $default != null:
return $default(_that.resource,_that.automaticCounterpart,_that.existing,_that.creatable,_that.collections,_that.disabledReason);case _:
  return null;

}
}

}

/// @nodoc


class _PortableLinkTargetChoice implements PortableLinkTargetChoice {
  const _PortableLinkTargetChoice({required this.resource, required this.automaticCounterpart, required  List<skir.LinkOccurrence> existing, required  List<PortableNewCounterpartChoice> creatable,  List<skir.ValueLocation> collections = const [], this.disabledReason}): _existing = existing,_creatable = creatable,_collections = collections;
  

@override final  skir.ResourceId resource;
@override final  bool automaticCounterpart;
 final  List<skir.LinkOccurrence> _existing;
@override List<skir.LinkOccurrence> get existing {
  if (_existing is EqualUnmodifiableListView) return _existing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_existing);
}

 final  List<PortableNewCounterpartChoice> _creatable;
@override List<PortableNewCounterpartChoice> get creatable {
  if (_creatable is EqualUnmodifiableListView) return _creatable;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_creatable);
}

 final  List<skir.ValueLocation> _collections;
@override@JsonKey() List<skir.ValueLocation> get collections {
  if (_collections is EqualUnmodifiableListView) return _collections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_collections);
}

@override final  String? disabledReason;

/// Create a copy of PortableLinkTargetChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableLinkTargetChoiceCopyWith<_PortableLinkTargetChoice> get copyWith => __$PortableLinkTargetChoiceCopyWithImpl<_PortableLinkTargetChoice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableLinkTargetChoice&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.automaticCounterpart, automaticCounterpart) || other.automaticCounterpart == automaticCounterpart)&&const DeepCollectionEquality().equals(other.existing, _existing)&&const DeepCollectionEquality().equals(other.creatable, _creatable)&&const DeepCollectionEquality().equals(other.collections, _collections)&&(identical(other.disabledReason, disabledReason) || other.disabledReason == disabledReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resource,automaticCounterpart,const DeepCollectionEquality().hash(_existing),const DeepCollectionEquality().hash(_creatable),const DeepCollectionEquality().hash(_collections),disabledReason);
}

@override
String toString() {
    return 'PortableLinkTargetChoice(resource: $resource, automaticCounterpart: $automaticCounterpart, existing: $existing, creatable: $creatable, collections: $collections, disabledReason: $disabledReason)';
}


}

/// @nodoc
abstract mixin class _$PortableLinkTargetChoiceCopyWith<$Res> implements $PortableLinkTargetChoiceCopyWith<$Res> {
  factory _$PortableLinkTargetChoiceCopyWith(_PortableLinkTargetChoice value, $Res Function(_PortableLinkTargetChoice) _then) = __$PortableLinkTargetChoiceCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId resource, bool automaticCounterpart, List<skir.LinkOccurrence> existing, List<PortableNewCounterpartChoice> creatable, List<skir.ValueLocation> collections, String? disabledReason
});




}
/// @nodoc
class __$PortableLinkTargetChoiceCopyWithImpl<$Res>
    implements _$PortableLinkTargetChoiceCopyWith<$Res> {
  __$PortableLinkTargetChoiceCopyWithImpl(this._self, this._then);

  final _PortableLinkTargetChoice _self;
  final $Res Function(_PortableLinkTargetChoice) _then;

/// Create a copy of PortableLinkTargetChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? automaticCounterpart = null,Object? existing = null,Object? creatable = null,Object? collections = null,Object? disabledReason = freezed,}) {
  return _then(_PortableLinkTargetChoice(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,automaticCounterpart: null == automaticCounterpart ? _self.automaticCounterpart : automaticCounterpart // ignore: cast_nullable_to_non_nullable
as bool,existing: null == existing ? _self._existing : existing // ignore: cast_nullable_to_non_nullable
as List<skir.LinkOccurrence>,creatable: null == creatable ? _self._creatable : creatable // ignore: cast_nullable_to_non_nullable
as List<PortableNewCounterpartChoice>,collections: null == collections ? _self._collections : collections // ignore: cast_nullable_to_non_nullable
as List<skir.ValueLocation>,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PortableNewCounterpartChoice {

 skir.ValueLocation get containing; skir.TypeSelection get selection;
/// Create a copy of PortableNewCounterpartChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableNewCounterpartChoiceCopyWith<PortableNewCounterpartChoice> get copyWith => _$PortableNewCounterpartChoiceCopyWithImpl<PortableNewCounterpartChoice>(this as PortableNewCounterpartChoice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableNewCounterpartChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableNewCounterpartChoice&&(identical(other.containing, _this.containing) || other.containing == _this.containing)&&(identical(other.selection, _this.selection) || other.selection == _this.selection));
}


@override
int get hashCode {
  final _this = this as PortableNewCounterpartChoice;
  return Object.hash(runtimeType,_this.containing,_this.selection);
}

@override
String toString() {
  final _this = this as PortableNewCounterpartChoice;
  return 'PortableNewCounterpartChoice(containing: ${_this.containing}, selection: ${_this.selection})';
}


}

/// @nodoc
abstract mixin class $PortableNewCounterpartChoiceCopyWith<$Res>  {
  factory $PortableNewCounterpartChoiceCopyWith(PortableNewCounterpartChoice value, $Res Function(PortableNewCounterpartChoice) _then) = _$PortableNewCounterpartChoiceCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation containing, skir.TypeSelection selection
});




}
/// @nodoc
class _$PortableNewCounterpartChoiceCopyWithImpl<$Res>
    implements $PortableNewCounterpartChoiceCopyWith<$Res> {
  _$PortableNewCounterpartChoiceCopyWithImpl(this._self, this._then);

  final PortableNewCounterpartChoice _self;
  final $Res Function(PortableNewCounterpartChoice) _then;

/// Create a copy of PortableNewCounterpartChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? containing = null,Object? selection = null,}) {
  return _then(PortableNewCounterpartChoice(
containing: null == containing ? _self.containing : containing // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableNewCounterpartChoice].
extension PortableNewCounterpartChoicePatterns on PortableNewCounterpartChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableNewCounterpartChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableNewCounterpartChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableNewCounterpartChoice value)  $default,){
final _that = this;
switch (_that) {
case _PortableNewCounterpartChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableNewCounterpartChoice value)?  $default,){
final _that = this;
switch (_that) {
case _PortableNewCounterpartChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ValueLocation containing,  skir.TypeSelection selection)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableNewCounterpartChoice() when $default != null:
return $default(_that.containing,_that.selection);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ValueLocation containing,  skir.TypeSelection selection)  $default,) {final _that = this;
switch (_that) {
case _PortableNewCounterpartChoice():
return $default(_that.containing,_that.selection);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ValueLocation containing,  skir.TypeSelection selection)?  $default,) {final _that = this;
switch (_that) {
case _PortableNewCounterpartChoice() when $default != null:
return $default(_that.containing,_that.selection);case _:
  return null;

}
}

}

/// @nodoc


class _PortableNewCounterpartChoice implements PortableNewCounterpartChoice {
  const _PortableNewCounterpartChoice({required this.containing, required this.selection});
  

@override final  skir.ValueLocation containing;
@override final  skir.TypeSelection selection;

/// Create a copy of PortableNewCounterpartChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableNewCounterpartChoiceCopyWith<_PortableNewCounterpartChoice> get copyWith => __$PortableNewCounterpartChoiceCopyWithImpl<_PortableNewCounterpartChoice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableNewCounterpartChoice&&(identical(other.containing, containing) || other.containing == containing)&&(identical(other.selection, selection) || other.selection == selection));
}


@override
int get hashCode {
    return Object.hash(runtimeType,containing,selection);
}

@override
String toString() {
    return 'PortableNewCounterpartChoice(containing: $containing, selection: $selection)';
}


}

/// @nodoc
abstract mixin class _$PortableNewCounterpartChoiceCopyWith<$Res> implements $PortableNewCounterpartChoiceCopyWith<$Res> {
  factory _$PortableNewCounterpartChoiceCopyWith(_PortableNewCounterpartChoice value, $Res Function(_PortableNewCounterpartChoice) _then) = __$PortableNewCounterpartChoiceCopyWithImpl;
@override @useResult
$Res call({
 skir.ValueLocation containing, skir.TypeSelection selection
});




}
/// @nodoc
class __$PortableNewCounterpartChoiceCopyWithImpl<$Res>
    implements _$PortableNewCounterpartChoiceCopyWith<$Res> {
  __$PortableNewCounterpartChoiceCopyWithImpl(this._self, this._then);

  final _PortableNewCounterpartChoice _self;
  final $Res Function(_PortableNewCounterpartChoice) _then;

/// Create a copy of PortableNewCounterpartChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? containing = null,Object? selection = null,}) {
  return _then(_PortableNewCounterpartChoice(
containing: null == containing ? _self.containing : containing // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,
  ));
}


}

/// @nodoc
mixin _$ResolvedReference {

 skir.ConnectIntent get connection; List<ReferenceMaterialization> get materializations;
/// Create a copy of ResolvedReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedReferenceCopyWith<ResolvedReference> get copyWith => _$ResolvedReferenceCopyWithImpl<ResolvedReference>(this as ResolvedReference, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResolvedReference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedReference&&(identical(other.connection, _this.connection) || other.connection == _this.connection)&&const DeepCollectionEquality().equals(other.materializations, _this.materializations));
}


@override
int get hashCode {
  final _this = this as ResolvedReference;
  return Object.hash(runtimeType,_this.connection,const DeepCollectionEquality().hash(_this.materializations));
}

@override
String toString() {
  final _this = this as ResolvedReference;
  return 'ResolvedReference(connection: ${_this.connection}, materializations: ${_this.materializations})';
}


}

/// @nodoc
abstract mixin class $ResolvedReferenceCopyWith<$Res>  {
  factory $ResolvedReferenceCopyWith(ResolvedReference value, $Res Function(ResolvedReference) _then) = _$ResolvedReferenceCopyWithImpl;
@useResult
$Res call({
 skir.ConnectIntent connection, List<ReferenceMaterialization> materializations
});




}
/// @nodoc
class _$ResolvedReferenceCopyWithImpl<$Res>
    implements $ResolvedReferenceCopyWith<$Res> {
  _$ResolvedReferenceCopyWithImpl(this._self, this._then);

  final ResolvedReference _self;
  final $Res Function(ResolvedReference) _then;

/// Create a copy of ResolvedReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connection = null,Object? materializations = null,}) {
  return _then(ResolvedReference(
connection: null == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as skir.ConnectIntent,materializations: null == materializations ? _self.materializations : materializations // ignore: cast_nullable_to_non_nullable
as List<ReferenceMaterialization>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResolvedReference].
extension ResolvedReferencePatterns on ResolvedReference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedReference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedReference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedReference value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedReference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedReference value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedReference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ConnectIntent connection,  List<ReferenceMaterialization> materializations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedReference() when $default != null:
return $default(_that.connection,_that.materializations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ConnectIntent connection,  List<ReferenceMaterialization> materializations)  $default,) {final _that = this;
switch (_that) {
case _ResolvedReference():
return $default(_that.connection,_that.materializations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ConnectIntent connection,  List<ReferenceMaterialization> materializations)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedReference() when $default != null:
return $default(_that.connection,_that.materializations);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedReference implements ResolvedReference {
  const _ResolvedReference({required this.connection,  List<ReferenceMaterialization> materializations = const []}): _materializations = materializations;
  

@override final  skir.ConnectIntent connection;
 final  List<ReferenceMaterialization> _materializations;
@override@JsonKey() List<ReferenceMaterialization> get materializations {
  if (_materializations is EqualUnmodifiableListView) return _materializations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_materializations);
}


/// Create a copy of ResolvedReference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedReferenceCopyWith<_ResolvedReference> get copyWith => __$ResolvedReferenceCopyWithImpl<_ResolvedReference>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedReference&&(identical(other.connection, connection) || other.connection == connection)&&const DeepCollectionEquality().equals(other.materializations, _materializations));
}


@override
int get hashCode {
    return Object.hash(runtimeType,connection,const DeepCollectionEquality().hash(_materializations));
}

@override
String toString() {
    return 'ResolvedReference(connection: $connection, materializations: $materializations)';
}


}

/// @nodoc
abstract mixin class _$ResolvedReferenceCopyWith<$Res> implements $ResolvedReferenceCopyWith<$Res> {
  factory _$ResolvedReferenceCopyWith(_ResolvedReference value, $Res Function(_ResolvedReference) _then) = __$ResolvedReferenceCopyWithImpl;
@override @useResult
$Res call({
 skir.ConnectIntent connection, List<ReferenceMaterialization> materializations
});




}
/// @nodoc
class __$ResolvedReferenceCopyWithImpl<$Res>
    implements _$ResolvedReferenceCopyWith<$Res> {
  __$ResolvedReferenceCopyWithImpl(this._self, this._then);

  final _ResolvedReference _self;
  final $Res Function(_ResolvedReference) _then;

/// Create a copy of ResolvedReference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connection = null,Object? materializations = null,}) {
  return _then(_ResolvedReference(
connection: null == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as skir.ConnectIntent,materializations: null == materializations ? _self._materializations : materializations // ignore: cast_nullable_to_non_nullable
as List<ReferenceMaterialization>,
  ));
}


}

/// @nodoc
mixin _$ReferenceMaterialization {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceMaterialization);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReferenceMaterialization()';
}


}

/// @nodoc
class $ReferenceMaterializationCopyWith<$Res>  {
$ReferenceMaterializationCopyWith(ReferenceMaterialization _, $Res Function(ReferenceMaterialization) __);
}


/// Adds pattern-matching-related methods to [ReferenceMaterialization].
extension ReferenceMaterializationPatterns on ReferenceMaterialization {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReferenceValueInsertion value)?  value,TResult Function( PreparedReferenceInsertion value)?  preparedItem,TResult Function( PreparedReferenceRecord value)?  preparedRecord,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReferenceValueInsertion() when value != null:
return value(_that);case PreparedReferenceInsertion() when preparedItem != null:
return preparedItem(_that);case PreparedReferenceRecord() when preparedRecord != null:
return preparedRecord(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReferenceValueInsertion value)  value,required TResult Function( PreparedReferenceInsertion value)  preparedItem,required TResult Function( PreparedReferenceRecord value)  preparedRecord,}){
final _that = this;
switch (_that) {
case ReferenceValueInsertion():
return value(_that);case PreparedReferenceInsertion():
return preparedItem(_that);case PreparedReferenceRecord():
return preparedRecord(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReferenceValueInsertion value)?  value,TResult? Function( PreparedReferenceInsertion value)?  preparedItem,TResult? Function( PreparedReferenceRecord value)?  preparedRecord,}){
final _that = this;
switch (_that) {
case ReferenceValueInsertion() when value != null:
return value(_that);case PreparedReferenceInsertion() when preparedItem != null:
return preparedItem(_that);case PreparedReferenceRecord() when preparedRecord != null:
return preparedRecord(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.InsertIntent intent)?  value,TResult Function( skir.ValueLocation at,  skir.ItemId? after,  skir.ItemId item,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)?  preparedItem,TResult Function( skir.ValueLocation at,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)?  preparedRecord,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReferenceValueInsertion() when value != null:
return value(_that.intent);case PreparedReferenceInsertion() when preparedItem != null:
return preparedItem(_that.at,_that.after,_that.item,_that.request,_that.prepared);case PreparedReferenceRecord() when preparedRecord != null:
return preparedRecord(_that.at,_that.request,_that.prepared);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.InsertIntent intent)  value,required TResult Function( skir.ValueLocation at,  skir.ItemId? after,  skir.ItemId item,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)  preparedItem,required TResult Function( skir.ValueLocation at,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)  preparedRecord,}) {final _that = this;
switch (_that) {
case ReferenceValueInsertion():
return value(_that.intent);case PreparedReferenceInsertion():
return preparedItem(_that.at,_that.after,_that.item,_that.request,_that.prepared);case PreparedReferenceRecord():
return preparedRecord(_that.at,_that.request,_that.prepared);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.InsertIntent intent)?  value,TResult? Function( skir.ValueLocation at,  skir.ItemId? after,  skir.ItemId item,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)?  preparedItem,TResult? Function( skir.ValueLocation at,  skir.ValuePreparationRequest request,  skir.PreparedValue prepared)?  preparedRecord,}) {final _that = this;
switch (_that) {
case ReferenceValueInsertion() when value != null:
return value(_that.intent);case PreparedReferenceInsertion() when preparedItem != null:
return preparedItem(_that.at,_that.after,_that.item,_that.request,_that.prepared);case PreparedReferenceRecord() when preparedRecord != null:
return preparedRecord(_that.at,_that.request,_that.prepared);case _:
  return null;

}
}

}

/// @nodoc


class ReferenceValueInsertion implements ReferenceMaterialization {
  const ReferenceValueInsertion(this.intent);
  

 final  skir.InsertIntent intent;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferenceValueInsertionCopyWith<ReferenceValueInsertion> get copyWith => _$ReferenceValueInsertionCopyWithImpl<ReferenceValueInsertion>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceValueInsertion&&(identical(other.intent, intent) || other.intent == intent));
}


@override
int get hashCode {
    return Object.hash(runtimeType,intent);
}

@override
String toString() {
    return 'ReferenceMaterialization.value(intent: $intent)';
}


}

/// @nodoc
abstract mixin class $ReferenceValueInsertionCopyWith<$Res> implements $ReferenceMaterializationCopyWith<$Res> {
  factory $ReferenceValueInsertionCopyWith(ReferenceValueInsertion value, $Res Function(ReferenceValueInsertion) _then) = _$ReferenceValueInsertionCopyWithImpl;
@useResult
$Res call({
 skir.InsertIntent intent
});




}
/// @nodoc
class _$ReferenceValueInsertionCopyWithImpl<$Res>
    implements $ReferenceValueInsertionCopyWith<$Res> {
  _$ReferenceValueInsertionCopyWithImpl(this._self, this._then);

  final ReferenceValueInsertion _self;
  final $Res Function(ReferenceValueInsertion) _then;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? intent = null,}) {
  return _then(ReferenceValueInsertion(
null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as skir.InsertIntent,
  ));
}


}

/// @nodoc


class PreparedReferenceInsertion implements ReferenceMaterialization {
  const PreparedReferenceInsertion({required this.at, required this.after, required this.item, required this.request, required this.prepared});
  

 final  skir.ValueLocation at;
 final  skir.ItemId? after;
 final  skir.ItemId item;
 final  skir.ValuePreparationRequest request;
 final  skir.PreparedValue prepared;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreparedReferenceInsertionCopyWith<PreparedReferenceInsertion> get copyWith => _$PreparedReferenceInsertionCopyWithImpl<PreparedReferenceInsertion>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PreparedReferenceInsertion&&(identical(other.at, at) || other.at == at)&&(identical(other.after, after) || other.after == after)&&(identical(other.item, item) || other.item == item)&&(identical(other.request, request) || other.request == request)&&(identical(other.prepared, prepared) || other.prepared == prepared));
}


@override
int get hashCode {
    return Object.hash(runtimeType,at,after,item,request,prepared);
}

@override
String toString() {
    return 'ReferenceMaterialization.preparedItem(at: $at, after: $after, item: $item, request: $request, prepared: $prepared)';
}


}

/// @nodoc
abstract mixin class $PreparedReferenceInsertionCopyWith<$Res> implements $ReferenceMaterializationCopyWith<$Res> {
  factory $PreparedReferenceInsertionCopyWith(PreparedReferenceInsertion value, $Res Function(PreparedReferenceInsertion) _then) = _$PreparedReferenceInsertionCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation at, skir.ItemId? after, skir.ItemId item, skir.ValuePreparationRequest request, skir.PreparedValue prepared
});




}
/// @nodoc
class _$PreparedReferenceInsertionCopyWithImpl<$Res>
    implements $PreparedReferenceInsertionCopyWith<$Res> {
  _$PreparedReferenceInsertionCopyWithImpl(this._self, this._then);

  final PreparedReferenceInsertion _self;
  final $Res Function(PreparedReferenceInsertion) _then;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? at = null,Object? after = freezed,Object? item = null,Object? request = null,Object? prepared = null,}) {
  return _then(PreparedReferenceInsertion(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,after: freezed == after ? _self.after : after // ignore: cast_nullable_to_non_nullable
as skir.ItemId?,item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as skir.ItemId,request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as skir.ValuePreparationRequest,prepared: null == prepared ? _self.prepared : prepared // ignore: cast_nullable_to_non_nullable
as skir.PreparedValue,
  ));
}


}

/// @nodoc


class PreparedReferenceRecord implements ReferenceMaterialization {
  const PreparedReferenceRecord({required this.at, required this.request, required this.prepared});
  

 final  skir.ValueLocation at;
 final  skir.ValuePreparationRequest request;
 final  skir.PreparedValue prepared;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreparedReferenceRecordCopyWith<PreparedReferenceRecord> get copyWith => _$PreparedReferenceRecordCopyWithImpl<PreparedReferenceRecord>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PreparedReferenceRecord&&(identical(other.at, at) || other.at == at)&&(identical(other.request, request) || other.request == request)&&(identical(other.prepared, prepared) || other.prepared == prepared));
}


@override
int get hashCode {
    return Object.hash(runtimeType,at,request,prepared);
}

@override
String toString() {
    return 'ReferenceMaterialization.preparedRecord(at: $at, request: $request, prepared: $prepared)';
}


}

/// @nodoc
abstract mixin class $PreparedReferenceRecordCopyWith<$Res> implements $ReferenceMaterializationCopyWith<$Res> {
  factory $PreparedReferenceRecordCopyWith(PreparedReferenceRecord value, $Res Function(PreparedReferenceRecord) _then) = _$PreparedReferenceRecordCopyWithImpl;
@useResult
$Res call({
 skir.ValueLocation at, skir.ValuePreparationRequest request, skir.PreparedValue prepared
});




}
/// @nodoc
class _$PreparedReferenceRecordCopyWithImpl<$Res>
    implements $PreparedReferenceRecordCopyWith<$Res> {
  _$PreparedReferenceRecordCopyWithImpl(this._self, this._then);

  final PreparedReferenceRecord _self;
  final $Res Function(PreparedReferenceRecord) _then;

/// Create a copy of ReferenceMaterialization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? at = null,Object? request = null,Object? prepared = null,}) {
  return _then(PreparedReferenceRecord(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as skir.ValuePreparationRequest,prepared: null == prepared ? _self.prepared : prepared // ignore: cast_nullable_to_non_nullable
as skir.PreparedValue,
  ));
}


}

/// @nodoc
mixin _$ReferenceChoice {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceChoice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReferenceChoice()';
}


}

/// @nodoc
class $ReferenceChoiceCopyWith<$Res>  {
$ReferenceChoiceCopyWith(ReferenceChoice _, $Res Function(ReferenceChoice) __);
}


/// Adds pattern-matching-related methods to [ReferenceChoice].
extension ReferenceChoicePatterns on ReferenceChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExistingReference value)?  existing,TResult Function( NewResourceReference value)?  createResource,TResult Function( NewEmbeddedCounterpart value)?  createCounterpart,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExistingReference() when existing != null:
return existing(_that);case NewResourceReference() when createResource != null:
return createResource(_that);case NewEmbeddedCounterpart() when createCounterpart != null:
return createCounterpart(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExistingReference value)  existing,required TResult Function( NewResourceReference value)  createResource,required TResult Function( NewEmbeddedCounterpart value)  createCounterpart,}){
final _that = this;
switch (_that) {
case ExistingReference():
return existing(_that);case NewResourceReference():
return createResource(_that);case NewEmbeddedCounterpart():
return createCounterpart(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExistingReference value)?  existing,TResult? Function( NewResourceReference value)?  createResource,TResult? Function( NewEmbeddedCounterpart value)?  createCounterpart,}){
final _that = this;
switch (_that) {
case ExistingReference() when existing != null:
return existing(_that);case NewResourceReference() when createResource != null:
return createResource(_that);case NewEmbeddedCounterpart() when createCounterpart != null:
return createCounterpart(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ResolvedReference reference)?  existing,TResult Function( ResourceCreationTemplate template)?  createResource,TResult Function( PortableNewCounterpartChoice slot)?  createCounterpart,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExistingReference() when existing != null:
return existing(_that.reference);case NewResourceReference() when createResource != null:
return createResource(_that.template);case NewEmbeddedCounterpart() when createCounterpart != null:
return createCounterpart(_that.slot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ResolvedReference reference)  existing,required TResult Function( ResourceCreationTemplate template)  createResource,required TResult Function( PortableNewCounterpartChoice slot)  createCounterpart,}) {final _that = this;
switch (_that) {
case ExistingReference():
return existing(_that.reference);case NewResourceReference():
return createResource(_that.template);case NewEmbeddedCounterpart():
return createCounterpart(_that.slot);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ResolvedReference reference)?  existing,TResult? Function( ResourceCreationTemplate template)?  createResource,TResult? Function( PortableNewCounterpartChoice slot)?  createCounterpart,}) {final _that = this;
switch (_that) {
case ExistingReference() when existing != null:
return existing(_that.reference);case NewResourceReference() when createResource != null:
return createResource(_that.template);case NewEmbeddedCounterpart() when createCounterpart != null:
return createCounterpart(_that.slot);case _:
  return null;

}
}

}

/// @nodoc


class ExistingReference implements ReferenceChoice {
  const ExistingReference(this.reference);
  

 final  ResolvedReference reference;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExistingReferenceCopyWith<ExistingReference> get copyWith => _$ExistingReferenceCopyWithImpl<ExistingReference>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExistingReference&&(identical(other.reference, reference) || other.reference == reference));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reference);
}

@override
String toString() {
    return 'ReferenceChoice.existing(reference: $reference)';
}


}

/// @nodoc
abstract mixin class $ExistingReferenceCopyWith<$Res> implements $ReferenceChoiceCopyWith<$Res> {
  factory $ExistingReferenceCopyWith(ExistingReference value, $Res Function(ExistingReference) _then) = _$ExistingReferenceCopyWithImpl;
@useResult
$Res call({
 ResolvedReference reference
});


$ResolvedReferenceCopyWith<$Res> get reference;

}
/// @nodoc
class _$ExistingReferenceCopyWithImpl<$Res>
    implements $ExistingReferenceCopyWith<$Res> {
  _$ExistingReferenceCopyWithImpl(this._self, this._then);

  final ExistingReference _self;
  final $Res Function(ExistingReference) _then;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reference = null,}) {
  return _then(ExistingReference(
null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as ResolvedReference,
  ));
}

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedReferenceCopyWith<$Res> get reference {
  
  return $ResolvedReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}

/// @nodoc


class NewResourceReference implements ReferenceChoice {
  const NewResourceReference(this.template);
  

 final  ResourceCreationTemplate template;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewResourceReferenceCopyWith<NewResourceReference> get copyWith => _$NewResourceReferenceCopyWithImpl<NewResourceReference>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NewResourceReference&&(identical(other.template, template) || other.template == template));
}


@override
int get hashCode {
    return Object.hash(runtimeType,template);
}

@override
String toString() {
    return 'ReferenceChoice.createResource(template: $template)';
}


}

/// @nodoc
abstract mixin class $NewResourceReferenceCopyWith<$Res> implements $ReferenceChoiceCopyWith<$Res> {
  factory $NewResourceReferenceCopyWith(NewResourceReference value, $Res Function(NewResourceReference) _then) = _$NewResourceReferenceCopyWithImpl;
@useResult
$Res call({
 ResourceCreationTemplate template
});


$ResourceCreationTemplateCopyWith<$Res> get template;

}
/// @nodoc
class _$NewResourceReferenceCopyWithImpl<$Res>
    implements $NewResourceReferenceCopyWith<$Res> {
  _$NewResourceReferenceCopyWithImpl(this._self, this._then);

  final NewResourceReference _self;
  final $Res Function(NewResourceReference) _then;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? template = null,}) {
  return _then(NewResourceReference(
null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as ResourceCreationTemplate,
  ));
}

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResourceCreationTemplateCopyWith<$Res> get template {
  
  return $ResourceCreationTemplateCopyWith<$Res>(_self.template, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}

/// @nodoc


class NewEmbeddedCounterpart implements ReferenceChoice {
  const NewEmbeddedCounterpart(this.slot);
  

 final  PortableNewCounterpartChoice slot;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewEmbeddedCounterpartCopyWith<NewEmbeddedCounterpart> get copyWith => _$NewEmbeddedCounterpartCopyWithImpl<NewEmbeddedCounterpart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NewEmbeddedCounterpart&&(identical(other.slot, slot) || other.slot == slot));
}


@override
int get hashCode {
    return Object.hash(runtimeType,slot);
}

@override
String toString() {
    return 'ReferenceChoice.createCounterpart(slot: $slot)';
}


}

/// @nodoc
abstract mixin class $NewEmbeddedCounterpartCopyWith<$Res> implements $ReferenceChoiceCopyWith<$Res> {
  factory $NewEmbeddedCounterpartCopyWith(NewEmbeddedCounterpart value, $Res Function(NewEmbeddedCounterpart) _then) = _$NewEmbeddedCounterpartCopyWithImpl;
@useResult
$Res call({
 PortableNewCounterpartChoice slot
});


$PortableNewCounterpartChoiceCopyWith<$Res> get slot;

}
/// @nodoc
class _$NewEmbeddedCounterpartCopyWithImpl<$Res>
    implements $NewEmbeddedCounterpartCopyWith<$Res> {
  _$NewEmbeddedCounterpartCopyWithImpl(this._self, this._then);

  final NewEmbeddedCounterpart _self;
  final $Res Function(NewEmbeddedCounterpart) _then;

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? slot = null,}) {
  return _then(NewEmbeddedCounterpart(
null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as PortableNewCounterpartChoice,
  ));
}

/// Create a copy of ReferenceChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableNewCounterpartChoiceCopyWith<$Res> get slot {
  
  return $PortableNewCounterpartChoiceCopyWith<$Res>(_self.slot, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}

// dart format on
