// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_named_control.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortableNamedPayload {

 skir.BindingRef get reference; skir.NamedTypeUse get actualType; skir.DataValue get value; skir.ValueLocation get location; Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings; skir.EvaluationBudget get budget; PortableBindingSetter get setBinding;
/// Create a copy of PortableNamedPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableNamedPayloadCopyWith<PortableNamedPayload> get copyWith => _$PortableNamedPayloadCopyWithImpl<PortableNamedPayload>(this as PortableNamedPayload, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableNamedPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableNamedPayload&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.actualType, _this.actualType) || other.actualType == _this.actualType)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.location, _this.location) || other.location == _this.location)&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&(identical(other.setBinding, _this.setBinding) || other.setBinding == _this.setBinding));
}


@override
int get hashCode {
  final _this = this as PortableNamedPayload;
  return Object.hash(runtimeType,_this.reference,_this.actualType,_this.value,_this.location,const DeepCollectionEquality().hash(_this.bindings),_this.budget,_this.setBinding);
}

@override
String toString() {
  final _this = this as PortableNamedPayload;
  return 'PortableNamedPayload(reference: ${_this.reference}, actualType: ${_this.actualType}, value: ${_this.value}, location: ${_this.location}, bindings: ${_this.bindings}, budget: ${_this.budget}, setBinding: ${_this.setBinding})';
}


}

/// @nodoc
abstract mixin class $PortableNamedPayloadCopyWith<$Res>  {
  factory $PortableNamedPayloadCopyWith(PortableNamedPayload value, $Res Function(PortableNamedPayload) _then) = _$PortableNamedPayloadCopyWithImpl;
@useResult
$Res call({
 skir.BindingRef reference, skir.NamedTypeUse actualType, skir.DataValue value, skir.ValueLocation location, Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, PortableBindingSetter setBinding
});




}
/// @nodoc
class _$PortableNamedPayloadCopyWithImpl<$Res>
    implements $PortableNamedPayloadCopyWith<$Res> {
  _$PortableNamedPayloadCopyWithImpl(this._self, this._then);

  final PortableNamedPayload _self;
  final $Res Function(PortableNamedPayload) _then;

/// Create a copy of PortableNamedPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? actualType = null,Object? value = null,Object? location = null,Object? bindings = null,Object? budget = null,Object? setBinding = null,}) {
  return _then(PortableNamedPayload(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as skir.BindingRef,actualType: null == actualType ? _self.actualType : actualType // ignore: cast_nullable_to_non_nullable
as skir.NamedTypeUse,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,setBinding: null == setBinding ? _self.setBinding : setBinding // ignore: cast_nullable_to_non_nullable
as PortableBindingSetter,
  ));
}

}


/// Adds pattern-matching-related methods to [PortableNamedPayload].
extension PortableNamedPayloadPatterns on PortableNamedPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableNamedPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableNamedPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableNamedPayload value)  $default,){
final _that = this;
switch (_that) {
case _PortableNamedPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableNamedPayload value)?  $default,){
final _that = this;
switch (_that) {
case _PortableNamedPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.BindingRef reference,  skir.NamedTypeUse actualType,  skir.DataValue value,  skir.ValueLocation location,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget,  PortableBindingSetter setBinding)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableNamedPayload() when $default != null:
return $default(_that.reference,_that.actualType,_that.value,_that.location,_that.bindings,_that.budget,_that.setBinding);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.BindingRef reference,  skir.NamedTypeUse actualType,  skir.DataValue value,  skir.ValueLocation location,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget,  PortableBindingSetter setBinding)  $default,) {final _that = this;
switch (_that) {
case _PortableNamedPayload():
return $default(_that.reference,_that.actualType,_that.value,_that.location,_that.bindings,_that.budget,_that.setBinding);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.BindingRef reference,  skir.NamedTypeUse actualType,  skir.DataValue value,  skir.ValueLocation location,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget,  PortableBindingSetter setBinding)?  $default,) {final _that = this;
switch (_that) {
case _PortableNamedPayload() when $default != null:
return $default(_that.reference,_that.actualType,_that.value,_that.location,_that.bindings,_that.budget,_that.setBinding);case _:
  return null;

}
}

}

/// @nodoc


class _PortableNamedPayload extends PortableNamedPayload {
  const _PortableNamedPayload({required this.reference, required this.actualType, required this.value, required this.location, required  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, required this.budget, required this.setBinding}): _bindings = bindings,super._();
  

@override final  skir.BindingRef reference;
@override final  skir.NamedTypeUse actualType;
@override final  skir.DataValue value;
@override final  skir.ValueLocation location;
 final  Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;
@override final  PortableBindingSetter setBinding;

/// Create a copy of PortableNamedPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableNamedPayloadCopyWith<_PortableNamedPayload> get copyWith => __$PortableNamedPayloadCopyWithImpl<_PortableNamedPayload>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableNamedPayload&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.actualType, actualType) || other.actualType == actualType)&&(identical(other.value, value) || other.value == value)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.setBinding, setBinding) || other.setBinding == setBinding));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reference,actualType,value,location,const DeepCollectionEquality().hash(_bindings),budget,setBinding);
}

@override
String toString() {
    return 'PortableNamedPayload(reference: $reference, actualType: $actualType, value: $value, location: $location, bindings: $bindings, budget: $budget, setBinding: $setBinding)';
}


}

/// @nodoc
abstract mixin class _$PortableNamedPayloadCopyWith<$Res> implements $PortableNamedPayloadCopyWith<$Res> {
  factory _$PortableNamedPayloadCopyWith(_PortableNamedPayload value, $Res Function(_PortableNamedPayload) _then) = __$PortableNamedPayloadCopyWithImpl;
@override @useResult
$Res call({
 skir.BindingRef reference, skir.NamedTypeUse actualType, skir.DataValue value, skir.ValueLocation location, Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, PortableBindingSetter setBinding
});




}
/// @nodoc
class __$PortableNamedPayloadCopyWithImpl<$Res>
    implements _$PortableNamedPayloadCopyWith<$Res> {
  __$PortableNamedPayloadCopyWithImpl(this._self, this._then);

  final _PortableNamedPayload _self;
  final $Res Function(_PortableNamedPayload) _then;

/// Create a copy of PortableNamedPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? actualType = null,Object? value = null,Object? location = null,Object? bindings = null,Object? budget = null,Object? setBinding = null,}) {
  return _then(_PortableNamedPayload(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as skir.BindingRef,actualType: null == actualType ? _self.actualType : actualType // ignore: cast_nullable_to_non_nullable
as skir.NamedTypeUse,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation,bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,setBinding: null == setBinding ? _self.setBinding : setBinding // ignore: cast_nullable_to_non_nullable
as PortableBindingSetter,
  ));
}


}

// dart format on
