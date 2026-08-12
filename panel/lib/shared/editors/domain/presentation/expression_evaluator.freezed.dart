// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expression_evaluator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExpressionContext {

 BindingEnvironment get bindings; Map<ConversionId, ConversionDefinition> get conversions;
/// Create a copy of ExpressionContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpressionContextCopyWith<ExpressionContext> get copyWith => _$ExpressionContextCopyWithImpl<ExpressionContext>(this as ExpressionContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpressionContext&&(identical(other.bindings, bindings) || other.bindings == bindings)&&const DeepCollectionEquality().equals(other.conversions, conversions));
}


@override
int get hashCode => Object.hash(runtimeType,bindings,const DeepCollectionEquality().hash(conversions));

@override
String toString() {
  return 'ExpressionContext(bindings: $bindings, conversions: $conversions)';
}


}

/// @nodoc
abstract mixin class $ExpressionContextCopyWith<$Res>  {
  factory $ExpressionContextCopyWith(ExpressionContext value, $Res Function(ExpressionContext) _then) = _$ExpressionContextCopyWithImpl;
@useResult
$Res call({
 BindingEnvironment bindings, Map<ConversionId, ConversionDefinition> conversions
});


$BindingEnvironmentCopyWith<$Res> get bindings;

}
/// @nodoc
class _$ExpressionContextCopyWithImpl<$Res>
    implements $ExpressionContextCopyWith<$Res> {
  _$ExpressionContextCopyWithImpl(this._self, this._then);

  final ExpressionContext _self;
  final $Res Function(ExpressionContext) _then;

/// Create a copy of ExpressionContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bindings = null,Object? conversions = null,}) {
  return _then(_self.copyWith(
bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as BindingEnvironment,conversions: null == conversions ? _self.conversions : conversions // ignore: cast_nullable_to_non_nullable
as Map<ConversionId, ConversionDefinition>,
  ));
}
/// Create a copy of ExpressionContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingEnvironmentCopyWith<$Res> get bindings {
  
  return $BindingEnvironmentCopyWith<$Res>(_self.bindings, (value) {
    return _then(_self.copyWith(bindings: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExpressionContext].
extension ExpressionContextPatterns on ExpressionContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpressionContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpressionContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpressionContext value)  $default,){
final _that = this;
switch (_that) {
case _ExpressionContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpressionContext value)?  $default,){
final _that = this;
switch (_that) {
case _ExpressionContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BindingEnvironment bindings,  Map<ConversionId, ConversionDefinition> conversions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpressionContext() when $default != null:
return $default(_that.bindings,_that.conversions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BindingEnvironment bindings,  Map<ConversionId, ConversionDefinition> conversions)  $default,) {final _that = this;
switch (_that) {
case _ExpressionContext():
return $default(_that.bindings,_that.conversions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BindingEnvironment bindings,  Map<ConversionId, ConversionDefinition> conversions)?  $default,) {final _that = this;
switch (_that) {
case _ExpressionContext() when $default != null:
return $default(_that.bindings,_that.conversions);case _:
  return null;

}
}

}

/// @nodoc


class _ExpressionContext extends ExpressionContext {
  const _ExpressionContext({required this.bindings, final  Map<ConversionId, ConversionDefinition> conversions = const {}}): _conversions = conversions,super._();
  

@override final  BindingEnvironment bindings;
 final  Map<ConversionId, ConversionDefinition> _conversions;
@override@JsonKey() Map<ConversionId, ConversionDefinition> get conversions {
  if (_conversions is EqualUnmodifiableMapView) return _conversions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_conversions);
}


/// Create a copy of ExpressionContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpressionContextCopyWith<_ExpressionContext> get copyWith => __$ExpressionContextCopyWithImpl<_ExpressionContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpressionContext&&(identical(other.bindings, bindings) || other.bindings == bindings)&&const DeepCollectionEquality().equals(other._conversions, _conversions));
}


@override
int get hashCode => Object.hash(runtimeType,bindings,const DeepCollectionEquality().hash(_conversions));

@override
String toString() {
  return 'ExpressionContext(bindings: $bindings, conversions: $conversions)';
}


}

/// @nodoc
abstract mixin class _$ExpressionContextCopyWith<$Res> implements $ExpressionContextCopyWith<$Res> {
  factory _$ExpressionContextCopyWith(_ExpressionContext value, $Res Function(_ExpressionContext) _then) = __$ExpressionContextCopyWithImpl;
@override @useResult
$Res call({
 BindingEnvironment bindings, Map<ConversionId, ConversionDefinition> conversions
});


@override $BindingEnvironmentCopyWith<$Res> get bindings;

}
/// @nodoc
class __$ExpressionContextCopyWithImpl<$Res>
    implements _$ExpressionContextCopyWith<$Res> {
  __$ExpressionContextCopyWithImpl(this._self, this._then);

  final _ExpressionContext _self;
  final $Res Function(_ExpressionContext) _then;

/// Create a copy of ExpressionContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bindings = null,Object? conversions = null,}) {
  return _then(_ExpressionContext(
bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as BindingEnvironment,conversions: null == conversions ? _self._conversions : conversions // ignore: cast_nullable_to_non_nullable
as Map<ConversionId, ConversionDefinition>,
  ));
}

/// Create a copy of ExpressionContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BindingEnvironmentCopyWith<$Res> get bindings {
  
  return $BindingEnvironmentCopyWith<$Res>(_self.bindings, (value) {
    return _then(_self.copyWith(bindings: value));
  });
}
}

// dart format on
