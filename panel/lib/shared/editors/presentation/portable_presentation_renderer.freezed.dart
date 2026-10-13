// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_presentation_renderer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortableAppearanceLayer {

 skir.InputAppearance get appearance; Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings; skir.EvaluationBudget get budget;
/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableAppearanceLayerCopyWith<PortableAppearanceLayer> get copyWith => _$PortableAppearanceLayerCopyWithImpl<PortableAppearanceLayer>(this as PortableAppearanceLayer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableAppearanceLayer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableAppearanceLayer&&(identical(other.appearance, _this.appearance) || other.appearance == _this.appearance)&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget));
}


@override
int get hashCode {
  final _this = this as PortableAppearanceLayer;
  return Object.hash(runtimeType,_this.appearance,const DeepCollectionEquality().hash(_this.bindings),_this.budget);
}

@override
String toString() {
  final _this = this as PortableAppearanceLayer;
  return 'PortableAppearanceLayer(appearance: ${_this.appearance}, bindings: ${_this.bindings}, budget: ${_this.budget})';
}


}

/// @nodoc
abstract mixin class $PortableAppearanceLayerCopyWith<$Res>  {
  factory $PortableAppearanceLayerCopyWith(PortableAppearanceLayer value, $Res Function(PortableAppearanceLayer) _then) = _$PortableAppearanceLayerCopyWithImpl;
@useResult
$Res call({
 skir.InputAppearance appearance, Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget
});




}
/// @nodoc
class _$PortableAppearanceLayerCopyWithImpl<$Res>
    implements $PortableAppearanceLayerCopyWith<$Res> {
  _$PortableAppearanceLayerCopyWithImpl(this._self, this._then);

  final PortableAppearanceLayer _self;
  final $Res Function(PortableAppearanceLayer) _then;

/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appearance = null,Object? bindings = null,Object? budget = null,}) {
  return _then(PortableAppearanceLayer(
appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.InputAppearance,bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,
  ));
}

}


/// Adds pattern matching related methods to [PortableAppearanceLayer].
extension PortableAppearanceLayerPatterns on PortableAppearanceLayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableAppearanceLayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableAppearanceLayer value)  $default,){
final _that = this;
switch (_that) {
case _PortableAppearanceLayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableAppearanceLayer value)?  $default,){
final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.InputAppearance appearance,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
return $default(_that.appearance,_that.bindings,_that.budget);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.InputAppearance appearance,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget)  $default,) {final _that = this;
switch (_that) {
case _PortableAppearanceLayer():
return $default(_that.appearance,_that.bindings,_that.budget);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.InputAppearance appearance,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget)?  $default,) {final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
return $default(_that.appearance,_that.bindings,_that.budget);case _:
  return null;

}
}

}

/// @nodoc


class _PortableAppearanceLayer implements PortableAppearanceLayer {
  const _PortableAppearanceLayer({required this.appearance, required  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, required this.budget}): _bindings = bindings;


@override final  skir.InputAppearance appearance;
 final  Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;

/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAppearanceLayerCopyWith<_PortableAppearanceLayer> get copyWith => __$PortableAppearanceLayerCopyWithImpl<_PortableAppearanceLayer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAppearanceLayer&&(identical(other.appearance, appearance) || other.appearance == appearance)&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget));
}


@override
int get hashCode {
    return Object.hash(runtimeType,appearance,const DeepCollectionEquality().hash(_bindings),budget);
}

@override
String toString() {
    return 'PortableAppearanceLayer(appearance: $appearance, bindings: $bindings, budget: $budget)';
}


}

/// @nodoc
abstract mixin class _$PortableAppearanceLayerCopyWith<$Res> implements $PortableAppearanceLayerCopyWith<$Res> {
  factory _$PortableAppearanceLayerCopyWith(_PortableAppearanceLayer value, $Res Function(_PortableAppearanceLayer) _then) = __$PortableAppearanceLayerCopyWithImpl;
@override @useResult
$Res call({
 skir.InputAppearance appearance, Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget
});




}
/// @nodoc
class __$PortableAppearanceLayerCopyWithImpl<$Res>
    implements _$PortableAppearanceLayerCopyWith<$Res> {
  __$PortableAppearanceLayerCopyWithImpl(this._self, this._then);

  final _PortableAppearanceLayer _self;
  final $Res Function(_PortableAppearanceLayer) _then;

/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appearance = null,Object? bindings = null,Object? budget = null,}) {
  return _then(_PortableAppearanceLayer(
appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.InputAppearance,bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,
  ));
}


}

/// @nodoc
mixin _$PortableControlStyle {

 InputDecoration get decoration; TextStyle get valueStyle; TextStyle get labelStyle; TextStyle get descriptionStyle; TextAlign get alignment; double get iconSize; Color? get iconColor; EdgeInsetsGeometry? get padding; bool? get dense;
/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableControlStyleCopyWith<_PortableControlStyle> get copyWith => __$PortableControlStyleCopyWithImpl<_PortableControlStyle>(this as _PortableControlStyle, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _PortableControlStyle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableControlStyle&&(identical(other.decoration, _this.decoration) || other.decoration == _this.decoration)&&(identical(other.valueStyle, _this.valueStyle) || other.valueStyle == _this.valueStyle)&&(identical(other.labelStyle, _this.labelStyle) || other.labelStyle == _this.labelStyle)&&(identical(other.descriptionStyle, _this.descriptionStyle) || other.descriptionStyle == _this.descriptionStyle)&&(identical(other.alignment, _this.alignment) || other.alignment == _this.alignment)&&(identical(other.iconSize, _this.iconSize) || other.iconSize == _this.iconSize)&&(identical(other.iconColor, _this.iconColor) || other.iconColor == _this.iconColor)&&(identical(other.padding, _this.padding) || other.padding == _this.padding)&&(identical(other.dense, _this.dense) || other.dense == _this.dense));
}


@override
int get hashCode {
  final _this = this as _PortableControlStyle;
  return Object.hash(runtimeType,_this.decoration,_this.valueStyle,_this.labelStyle,_this.descriptionStyle,_this.alignment,_this.iconSize,_this.iconColor,_this.padding,_this.dense);
}

@override
String toString() {
  final _this = this as _PortableControlStyle;
  return '_PortableControlStyle(decoration: ${_this.decoration}, valueStyle: ${_this.valueStyle}, labelStyle: ${_this.labelStyle}, descriptionStyle: ${_this.descriptionStyle}, alignment: ${_this.alignment}, iconSize: ${_this.iconSize}, iconColor: ${_this.iconColor}, padding: ${_this.padding}, dense: ${_this.dense})';
}


}

/// @nodoc
abstract mixin class _$PortableControlStyleCopyWith<$Res>  {
  factory _$PortableControlStyleCopyWith(_PortableControlStyle value, $Res Function(_PortableControlStyle) _then) = __$PortableControlStyleCopyWithImpl;
@useResult
$Res call({
 InputDecoration decoration, TextStyle valueStyle, TextStyle labelStyle, TextStyle descriptionStyle, TextAlign alignment, double iconSize, Color? iconColor, EdgeInsetsGeometry? padding, bool? dense
});




}
/// @nodoc
class __$PortableControlStyleCopyWithImpl<$Res>
    implements _$PortableControlStyleCopyWith<$Res> {
  __$PortableControlStyleCopyWithImpl(this._self, this._then);

  final _PortableControlStyle _self;
  final $Res Function(_PortableControlStyle) _then;

/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decoration = null,Object? valueStyle = null,Object? labelStyle = null,Object? descriptionStyle = null,Object? alignment = null,Object? iconSize = null,Object? iconColor = freezed,Object? padding = freezed,Object? dense = freezed,}) {
  return _then(_PortableControlStyle(
decoration: null == decoration ? _self.decoration : decoration // ignore: cast_nullable_to_non_nullable
as InputDecoration,valueStyle: null == valueStyle ? _self.valueStyle : valueStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,labelStyle: null == labelStyle ? _self.labelStyle : labelStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,descriptionStyle: null == descriptionStyle ? _self.descriptionStyle : descriptionStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as TextAlign,iconSize: null == iconSize ? _self.iconSize : iconSize // ignore: cast_nullable_to_non_nullable
as double,iconColor: freezed == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as Color?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as EdgeInsetsGeometry?,dense: freezed == dense ? _self.dense : dense // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern matching related methods to [_PortableControlStyle].
extension _PortableControlStylePatterns on _PortableControlStyle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedPortableControlStyle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedPortableControlStyle value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedPortableControlStyle value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InputDecoration decoration,  TextStyle valueStyle,  TextStyle labelStyle,  TextStyle descriptionStyle,  TextAlign alignment,  double iconSize,  Color? iconColor,  EdgeInsetsGeometry? padding,  bool? dense)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
return $default(_that.decoration,_that.valueStyle,_that.labelStyle,_that.descriptionStyle,_that.alignment,_that.iconSize,_that.iconColor,_that.padding,_that.dense);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InputDecoration decoration,  TextStyle valueStyle,  TextStyle labelStyle,  TextStyle descriptionStyle,  TextAlign alignment,  double iconSize,  Color? iconColor,  EdgeInsetsGeometry? padding,  bool? dense)  $default,) {final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle():
return $default(_that.decoration,_that.valueStyle,_that.labelStyle,_that.descriptionStyle,_that.alignment,_that.iconSize,_that.iconColor,_that.padding,_that.dense);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InputDecoration decoration,  TextStyle valueStyle,  TextStyle labelStyle,  TextStyle descriptionStyle,  TextAlign alignment,  double iconSize,  Color? iconColor,  EdgeInsetsGeometry? padding,  bool? dense)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
return $default(_that.decoration,_that.valueStyle,_that.labelStyle,_that.descriptionStyle,_that.alignment,_that.iconSize,_that.iconColor,_that.padding,_that.dense);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedPortableControlStyle implements _PortableControlStyle {
  const _ResolvedPortableControlStyle({required this.decoration, required this.valueStyle, required this.labelStyle, required this.descriptionStyle, required this.alignment, required this.iconSize, this.iconColor, this.padding, this.dense});


@override final  InputDecoration decoration;
@override final  TextStyle valueStyle;
@override final  TextStyle labelStyle;
@override final  TextStyle descriptionStyle;
@override final  TextAlign alignment;
@override final  double iconSize;
@override final  Color? iconColor;
@override final  EdgeInsetsGeometry? padding;
@override final  bool? dense;

/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedPortableControlStyleCopyWith<_ResolvedPortableControlStyle> get copyWith => __$ResolvedPortableControlStyleCopyWithImpl<_ResolvedPortableControlStyle>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedPortableControlStyle&&(identical(other.decoration, decoration) || other.decoration == decoration)&&(identical(other.valueStyle, valueStyle) || other.valueStyle == valueStyle)&&(identical(other.labelStyle, labelStyle) || other.labelStyle == labelStyle)&&(identical(other.descriptionStyle, descriptionStyle) || other.descriptionStyle == descriptionStyle)&&(identical(other.alignment, alignment) || other.alignment == alignment)&&(identical(other.iconSize, iconSize) || other.iconSize == iconSize)&&(identical(other.iconColor, iconColor) || other.iconColor == iconColor)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.dense, dense) || other.dense == dense));
}


@override
int get hashCode {
    return Object.hash(runtimeType,decoration,valueStyle,labelStyle,descriptionStyle,alignment,iconSize,iconColor,padding,dense);
}

@override
String toString() {
    return '_PortableControlStyle(decoration: $decoration, valueStyle: $valueStyle, labelStyle: $labelStyle, descriptionStyle: $descriptionStyle, alignment: $alignment, iconSize: $iconSize, iconColor: $iconColor, padding: $padding, dense: $dense)';
}


}

/// @nodoc
abstract mixin class _$ResolvedPortableControlStyleCopyWith<$Res> implements _$PortableControlStyleCopyWith<$Res> {
  factory _$ResolvedPortableControlStyleCopyWith(_ResolvedPortableControlStyle value, $Res Function(_ResolvedPortableControlStyle) _then) = __$ResolvedPortableControlStyleCopyWithImpl;
@override @useResult
$Res call({
 InputDecoration decoration, TextStyle valueStyle, TextStyle labelStyle, TextStyle descriptionStyle, TextAlign alignment, double iconSize, Color? iconColor, EdgeInsetsGeometry? padding, bool? dense
});




}
/// @nodoc
class __$ResolvedPortableControlStyleCopyWithImpl<$Res>
    implements _$ResolvedPortableControlStyleCopyWith<$Res> {
  __$ResolvedPortableControlStyleCopyWithImpl(this._self, this._then);

  final _ResolvedPortableControlStyle _self;
  final $Res Function(_ResolvedPortableControlStyle) _then;

/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decoration = null,Object? valueStyle = null,Object? labelStyle = null,Object? descriptionStyle = null,Object? alignment = null,Object? iconSize = null,Object? iconColor = freezed,Object? padding = freezed,Object? dense = freezed,}) {
  return _then(_ResolvedPortableControlStyle(
decoration: null == decoration ? _self.decoration : decoration // ignore: cast_nullable_to_non_nullable
as InputDecoration,valueStyle: null == valueStyle ? _self.valueStyle : valueStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,labelStyle: null == labelStyle ? _self.labelStyle : labelStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,descriptionStyle: null == descriptionStyle ? _self.descriptionStyle : descriptionStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as TextAlign,iconSize: null == iconSize ? _self.iconSize : iconSize // ignore: cast_nullable_to_non_nullable
as double,iconColor: freezed == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as Color?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as EdgeInsetsGeometry?,dense: freezed == dense ? _self.dense : dense // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$PortableOperationKey {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableOperationKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableOperationKey()';
}


}

/// @nodoc
class $PortableOperationKeyCopyWith<$Res>  {
$PortableOperationKeyCopyWith(PortableOperationKey _, $Res Function(PortableOperationKey) __);
}


/// Adds pattern matching related methods to [PortableOperationKey].
extension PortableOperationKeyPatterns on PortableOperationKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _PortableWriteKey value)?  write,TResult Function( _PortableExecuteKey value)?  execute,TResult Function( _PortableAddItemKey value)?  addItem,TResult Function( _PortableAddMapRowKey value)?  addMapRow,TResult Function( _PortableMappingKey value)?  mapping,TResult Function( _PortableStatusKey value)?  status,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that);case _PortableExecuteKey() when execute != null:
return execute(_that);case _PortableAddItemKey() when addItem != null:
return addItem(_that);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that);case _PortableMappingKey() when mapping != null:
return mapping(_that);case _PortableStatusKey() when status != null:
return status(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _PortableWriteKey value)  write,required TResult Function( _PortableExecuteKey value)  execute,required TResult Function( _PortableAddItemKey value)  addItem,required TResult Function( _PortableAddMapRowKey value)  addMapRow,required TResult Function( _PortableMappingKey value)  mapping,required TResult Function( _PortableStatusKey value)  status,}){
final _that = this;
switch (_that) {
case _PortableWriteKey():
return write(_that);case _PortableExecuteKey():
return execute(_that);case _PortableAddItemKey():
return addItem(_that);case _PortableAddMapRowKey():
return addMapRow(_that);case _PortableMappingKey():
return mapping(_that);case _PortableStatusKey():
return status(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _PortableWriteKey value)?  write,TResult? Function( _PortableExecuteKey value)?  execute,TResult? Function( _PortableAddItemKey value)?  addItem,TResult? Function( _PortableAddMapRowKey value)?  addMapRow,TResult? Function( _PortableMappingKey value)?  mapping,TResult? Function( _PortableStatusKey value)?  status,}){
final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that);case _PortableExecuteKey() when execute != null:
return execute(_that);case _PortableAddItemKey() when addItem != null:
return addItem(_that);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that);case _PortableMappingKey() when mapping != null:
return mapping(_that);case _PortableStatusKey() when status != null:
return status(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PortableDiagnosticTarget target)?  write,TResult Function( skir.EditorAction action)?  execute,TResult Function( PortableDiagnosticTarget target)?  addItem,TResult Function( PortableDiagnosticTarget target)?  addMapRow,TResult Function( PortableDiagnosticTarget target,  bool completion)?  mapping,TResult Function()?  status,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that.target);case _PortableExecuteKey() when execute != null:
return execute(_that.action);case _PortableAddItemKey() when addItem != null:
return addItem(_that.target);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that.target);case _PortableMappingKey() when mapping != null:
return mapping(_that.target,_that.completion);case _PortableStatusKey() when status != null:
return status();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PortableDiagnosticTarget target)  write,required TResult Function( skir.EditorAction action)  execute,required TResult Function( PortableDiagnosticTarget target)  addItem,required TResult Function( PortableDiagnosticTarget target)  addMapRow,required TResult Function( PortableDiagnosticTarget target,  bool completion)  mapping,required TResult Function()  status,}) {final _that = this;
switch (_that) {
case _PortableWriteKey():
return write(_that.target);case _PortableExecuteKey():
return execute(_that.action);case _PortableAddItemKey():
return addItem(_that.target);case _PortableAddMapRowKey():
return addMapRow(_that.target);case _PortableMappingKey():
return mapping(_that.target,_that.completion);case _PortableStatusKey():
return status();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PortableDiagnosticTarget target)?  write,TResult? Function( skir.EditorAction action)?  execute,TResult? Function( PortableDiagnosticTarget target)?  addItem,TResult? Function( PortableDiagnosticTarget target)?  addMapRow,TResult? Function( PortableDiagnosticTarget target,  bool completion)?  mapping,TResult? Function()?  status,}) {final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that.target);case _PortableExecuteKey() when execute != null:
return execute(_that.action);case _PortableAddItemKey() when addItem != null:
return addItem(_that.target);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that.target);case _PortableMappingKey() when mapping != null:
return mapping(_that.target,_that.completion);case _PortableStatusKey() when status != null:
return status();case _:
  return null;

}
}

}

/// @nodoc


class _PortableWriteKey implements PortableOperationKey {
  const _PortableWriteKey(this.target);


 final  PortableDiagnosticTarget target;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableWriteKeyCopyWith<_PortableWriteKey> get copyWith => __$PortableWriteKeyCopyWithImpl<_PortableWriteKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableWriteKey&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'PortableOperationKey.write(target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableWriteKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableWriteKeyCopyWith(_PortableWriteKey value, $Res Function(_PortableWriteKey) _then) = __$PortableWriteKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableWriteKeyCopyWithImpl<$Res>
    implements _$PortableWriteKeyCopyWith<$Res> {
  __$PortableWriteKeyCopyWithImpl(this._self, this._then);

  final _PortableWriteKey _self;
  final $Res Function(_PortableWriteKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_PortableWriteKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableExecuteKey implements PortableOperationKey {
  const _PortableExecuteKey(this.action);


 final  skir.EditorAction action;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableExecuteKeyCopyWith<_PortableExecuteKey> get copyWith => __$PortableExecuteKeyCopyWithImpl<_PortableExecuteKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableExecuteKey&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode {
    return Object.hash(runtimeType,action);
}

@override
String toString() {
    return 'PortableOperationKey.execute(action: $action)';
}


}

/// @nodoc
abstract mixin class _$PortableExecuteKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableExecuteKeyCopyWith(_PortableExecuteKey value, $Res Function(_PortableExecuteKey) _then) = __$PortableExecuteKeyCopyWithImpl;
@useResult
$Res call({
 skir.EditorAction action
});




}
/// @nodoc
class __$PortableExecuteKeyCopyWithImpl<$Res>
    implements _$PortableExecuteKeyCopyWith<$Res> {
  __$PortableExecuteKeyCopyWithImpl(this._self, this._then);

  final _PortableExecuteKey _self;
  final $Res Function(_PortableExecuteKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(_PortableExecuteKey(
null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as skir.EditorAction,
  ));
}


}

/// @nodoc


class _PortableAddItemKey implements PortableOperationKey {
  const _PortableAddItemKey(this.target);


 final  PortableDiagnosticTarget target;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAddItemKeyCopyWith<_PortableAddItemKey> get copyWith => __$PortableAddItemKeyCopyWithImpl<_PortableAddItemKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAddItemKey&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'PortableOperationKey.addItem(target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableAddItemKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableAddItemKeyCopyWith(_PortableAddItemKey value, $Res Function(_PortableAddItemKey) _then) = __$PortableAddItemKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableAddItemKeyCopyWithImpl<$Res>
    implements _$PortableAddItemKeyCopyWith<$Res> {
  __$PortableAddItemKeyCopyWithImpl(this._self, this._then);

  final _PortableAddItemKey _self;
  final $Res Function(_PortableAddItemKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_PortableAddItemKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableAddMapRowKey implements PortableOperationKey {
  const _PortableAddMapRowKey(this.target);


 final  PortableDiagnosticTarget target;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAddMapRowKeyCopyWith<_PortableAddMapRowKey> get copyWith => __$PortableAddMapRowKeyCopyWithImpl<_PortableAddMapRowKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAddMapRowKey&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'PortableOperationKey.addMapRow(target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableAddMapRowKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableAddMapRowKeyCopyWith(_PortableAddMapRowKey value, $Res Function(_PortableAddMapRowKey) _then) = __$PortableAddMapRowKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableAddMapRowKeyCopyWithImpl<$Res>
    implements _$PortableAddMapRowKeyCopyWith<$Res> {
  __$PortableAddMapRowKeyCopyWithImpl(this._self, this._then);

  final _PortableAddMapRowKey _self;
  final $Res Function(_PortableAddMapRowKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_PortableAddMapRowKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableMappingKey implements PortableOperationKey {
  const _PortableMappingKey(this.target, {required this.completion});


 final  PortableDiagnosticTarget target;
 final  bool completion;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableMappingKeyCopyWith<_PortableMappingKey> get copyWith => __$PortableMappingKeyCopyWithImpl<_PortableMappingKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableMappingKey&&(identical(other.target, target) || other.target == target)&&(identical(other.completion, completion) || other.completion == completion));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target,completion);
}

@override
String toString() {
    return 'PortableOperationKey.mapping(target: $target, completion: $completion)';
}


}

/// @nodoc
abstract mixin class _$PortableMappingKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableMappingKeyCopyWith(_PortableMappingKey value, $Res Function(_PortableMappingKey) _then) = __$PortableMappingKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target, bool completion
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableMappingKeyCopyWithImpl<$Res>
    implements _$PortableMappingKeyCopyWith<$Res> {
  __$PortableMappingKeyCopyWithImpl(this._self, this._then);

  final _PortableMappingKey _self;
  final $Res Function(_PortableMappingKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? completion = null,}) {
  return _then(_PortableMappingKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,completion: null == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableStatusKey implements PortableOperationKey {
  const _PortableStatusKey();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableStatusKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableOperationKey.status()';
}


}




/// @nodoc
mixin _$PortableOperationOutcome {

 Object get request; PortableDiagnosticObservation? get input; bool get pending; List<PortablePresentationDiagnostic> get diagnostics;
/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableOperationOutcomeCopyWith<PortableOperationOutcome> get copyWith => _$PortableOperationOutcomeCopyWithImpl<PortableOperationOutcome>(this as PortableOperationOutcome, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableOperationOutcome;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableOperationOutcome&&const DeepCollectionEquality().equals(other.request, _this.request)&&(identical(other.input, _this.input) || other.input == _this.input)&&(identical(other.pending, _this.pending) || other.pending == _this.pending)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as PortableOperationOutcome;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.request),_this.input,_this.pending,const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as PortableOperationOutcome;
  return 'PortableOperationOutcome(request: ${_this.request}, input: ${_this.input}, pending: ${_this.pending}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $PortableOperationOutcomeCopyWith<$Res>  {
  factory $PortableOperationOutcomeCopyWith(PortableOperationOutcome value, $Res Function(PortableOperationOutcome) _then) = _$PortableOperationOutcomeCopyWithImpl;
@useResult
$Res call({
 Object request, PortableDiagnosticObservation? input, bool pending, List<PortablePresentationDiagnostic> diagnostics
});


$PortableDiagnosticObservationCopyWith<$Res>? get input;

}
/// @nodoc
class _$PortableOperationOutcomeCopyWithImpl<$Res>
    implements $PortableOperationOutcomeCopyWith<$Res> {
  _$PortableOperationOutcomeCopyWithImpl(this._self, this._then);

  final PortableOperationOutcome _self;
  final $Res Function(PortableOperationOutcome) _then;

/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? request = null,Object? input = freezed,Object? pending = null,Object? diagnostics = null,}) {
  return _then(PortableOperationOutcome(
request: null == request ? _self.request : request ,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticObservation?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}
/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticObservationCopyWith<$Res>? get input {
    if (_self.input == null) {
    return null;
  }

  return $PortableDiagnosticObservationCopyWith<$Res>(_self.input!, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}


/// Adds pattern matching related methods to [PortableOperationOutcome].
extension PortableOperationOutcomePatterns on PortableOperationOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableOperationOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableOperationOutcome value)  $default,){
final _that = this;
switch (_that) {
case _PortableOperationOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableOperationOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object request,  PortableDiagnosticObservation? input,  bool pending,  List<PortablePresentationDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
return $default(_that.request,_that.input,_that.pending,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object request,  PortableDiagnosticObservation? input,  bool pending,  List<PortablePresentationDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _PortableOperationOutcome():
return $default(_that.request,_that.input,_that.pending,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object request,  PortableDiagnosticObservation? input,  bool pending,  List<PortablePresentationDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
return $default(_that.request,_that.input,_that.pending,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _PortableOperationOutcome implements PortableOperationOutcome {
  const _PortableOperationOutcome({required this.request, this.input, this.pending = false,  List<PortablePresentationDiagnostic> diagnostics = const []}): _diagnostics = diagnostics;


@override final  Object request;
@override final  PortableDiagnosticObservation? input;
@override@JsonKey() final  bool pending;
 final  List<PortablePresentationDiagnostic> _diagnostics;
@override@JsonKey() List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableOperationOutcomeCopyWith<_PortableOperationOutcome> get copyWith => __$PortableOperationOutcomeCopyWithImpl<_PortableOperationOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableOperationOutcome&&const DeepCollectionEquality().equals(other.request, request)&&(identical(other.input, input) || other.input == input)&&(identical(other.pending, pending) || other.pending == pending)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(request),input,pending,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'PortableOperationOutcome(request: $request, input: $input, pending: $pending, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$PortableOperationOutcomeCopyWith<$Res> implements $PortableOperationOutcomeCopyWith<$Res> {
  factory _$PortableOperationOutcomeCopyWith(_PortableOperationOutcome value, $Res Function(_PortableOperationOutcome) _then) = __$PortableOperationOutcomeCopyWithImpl;
@override @useResult
$Res call({
 Object request, PortableDiagnosticObservation? input, bool pending, List<PortablePresentationDiagnostic> diagnostics
});


@override $PortableDiagnosticObservationCopyWith<$Res>? get input;

}
/// @nodoc
class __$PortableOperationOutcomeCopyWithImpl<$Res>
    implements _$PortableOperationOutcomeCopyWith<$Res> {
  __$PortableOperationOutcomeCopyWithImpl(this._self, this._then);

  final _PortableOperationOutcome _self;
  final $Res Function(_PortableOperationOutcome) _then;

/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? request = null,Object? input = freezed,Object? pending = null,Object? diagnostics = null,}) {
  return _then(_PortableOperationOutcome(
request: null == request ? _self.request : request ,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticObservation?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticObservationCopyWith<$Res>? get input {
    if (_self.input == null) {
    return null;
  }

  return $PortableDiagnosticObservationCopyWith<$Res>(_self.input!, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}

/// @nodoc
mixin _$PortableOperationState {

 Map<PortableOperationKey, PortableOperationOutcome> get outcomes;
/// Create a copy of PortableOperationState
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableOperationStateCopyWith<PortableOperationState> get copyWith => _$PortableOperationStateCopyWithImpl<PortableOperationState>(this as PortableOperationState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableOperationState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableOperationState&&const DeepCollectionEquality().equals(other.outcomes, _this.outcomes));
}


@override
int get hashCode {
  final _this = this as PortableOperationState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.outcomes));
}

@override
String toString() {
  final _this = this as PortableOperationState;
  return 'PortableOperationState(outcomes: ${_this.outcomes})';
}


}

/// @nodoc
abstract mixin class $PortableOperationStateCopyWith<$Res>  {
  factory $PortableOperationStateCopyWith(PortableOperationState value, $Res Function(PortableOperationState) _then) = _$PortableOperationStateCopyWithImpl;
@useResult
$Res call({
 Map<PortableOperationKey, PortableOperationOutcome> outcomes
});




}
/// @nodoc
class _$PortableOperationStateCopyWithImpl<$Res>
    implements $PortableOperationStateCopyWith<$Res> {
  _$PortableOperationStateCopyWithImpl(this._self, this._then);

  final PortableOperationState _self;
  final $Res Function(PortableOperationState) _then;

/// Create a copy of PortableOperationState
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? outcomes = null,}) {
  return _then(PortableOperationState(
outcomes: null == outcomes ? _self.outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as Map<PortableOperationKey, PortableOperationOutcome>,
  ));
}

}


/// Adds pattern matching related methods to [PortableOperationState].
extension PortableOperationStatePatterns on PortableOperationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableOperationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableOperationState value)  $default,){
final _that = this;
switch (_that) {
case _PortableOperationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableOperationState value)?  $default,){
final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<PortableOperationKey, PortableOperationOutcome> outcomes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
return $default(_that.outcomes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<PortableOperationKey, PortableOperationOutcome> outcomes)  $default,) {final _that = this;
switch (_that) {
case _PortableOperationState():
return $default(_that.outcomes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<PortableOperationKey, PortableOperationOutcome> outcomes)?  $default,) {final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
return $default(_that.outcomes);case _:
  return null;

}
}

}

/// @nodoc


class _PortableOperationState extends PortableOperationState {
  const _PortableOperationState({ Map<PortableOperationKey, PortableOperationOutcome> outcomes = const {}}): _outcomes = outcomes,super._();


 final  Map<PortableOperationKey, PortableOperationOutcome> _outcomes;
@override@JsonKey() Map<PortableOperationKey, PortableOperationOutcome> get outcomes {
  if (_outcomes is EqualUnmodifiableMapView) return _outcomes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_outcomes);
}


/// Create a copy of PortableOperationState
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableOperationStateCopyWith<_PortableOperationState> get copyWith => __$PortableOperationStateCopyWithImpl<_PortableOperationState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableOperationState&&const DeepCollectionEquality().equals(other.outcomes, _outcomes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_outcomes));
}

@override
String toString() {
    return 'PortableOperationState(outcomes: $outcomes)';
}


}

/// @nodoc
abstract mixin class _$PortableOperationStateCopyWith<$Res> implements $PortableOperationStateCopyWith<$Res> {
  factory _$PortableOperationStateCopyWith(_PortableOperationState value, $Res Function(_PortableOperationState) _then) = __$PortableOperationStateCopyWithImpl;
@override @useResult
$Res call({
 Map<PortableOperationKey, PortableOperationOutcome> outcomes
});




}
/// @nodoc
class __$PortableOperationStateCopyWithImpl<$Res>
    implements _$PortableOperationStateCopyWith<$Res> {
  __$PortableOperationStateCopyWithImpl(this._self, this._then);

  final _PortableOperationState _self;
  final $Res Function(_PortableOperationState) _then;

/// Create a copy of PortableOperationState
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? outcomes = null,}) {
  return _then(_PortableOperationState(
outcomes: null == outcomes ? _self._outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as Map<PortableOperationKey, PortableOperationOutcome>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticObservation {

 PortableDiagnosticTarget get target; skir.DataValue? get value;
/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticObservationCopyWith<PortableDiagnosticObservation> get copyWith => _$PortableDiagnosticObservationCopyWithImpl<PortableDiagnosticObservation>(this as PortableDiagnosticObservation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticObservation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticObservation&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticObservation;
  return Object.hash(runtimeType,_this.target,_this.value);
}

@override
String toString() {
  final _this = this as PortableDiagnosticObservation;
  return 'PortableDiagnosticObservation(target: ${_this.target}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticObservationCopyWith<$Res>  {
  factory $PortableDiagnosticObservationCopyWith(PortableDiagnosticObservation value, $Res Function(PortableDiagnosticObservation) _then) = _$PortableDiagnosticObservationCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target, skir.DataValue? value
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class _$PortableDiagnosticObservationCopyWithImpl<$Res>
    implements $PortableDiagnosticObservationCopyWith<$Res> {
  _$PortableDiagnosticObservationCopyWithImpl(this._self, this._then);

  final PortableDiagnosticObservation _self;
  final $Res Function(PortableDiagnosticObservation) _then;

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? target = null,Object? value = freezed,}) {
  return _then(PortableDiagnosticObservation(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue?,
  ));
}
/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern matching related methods to [PortableDiagnosticObservation].
extension PortableDiagnosticObservationPatterns on PortableDiagnosticObservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticObservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticObservation value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticObservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticObservation value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortableDiagnosticTarget target,  skir.DataValue? value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
return $default(_that.target,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortableDiagnosticTarget target,  skir.DataValue? value)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticObservation():
return $default(_that.target,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortableDiagnosticTarget target,  skir.DataValue? value)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
return $default(_that.target,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticObservation extends PortableDiagnosticObservation {
  const _PortableDiagnosticObservation({required this.target, required this.value}): super._();


@override final  PortableDiagnosticTarget target;
@override final  skir.DataValue? value;

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticObservationCopyWith<_PortableDiagnosticObservation> get copyWith => __$PortableDiagnosticObservationCopyWithImpl<_PortableDiagnosticObservation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticObservation&&(identical(other.target, target) || other.target == target)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target,value);
}

@override
String toString() {
    return 'PortableDiagnosticObservation(target: $target, value: $value)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticObservationCopyWith<$Res> implements $PortableDiagnosticObservationCopyWith<$Res> {
  factory _$PortableDiagnosticObservationCopyWith(_PortableDiagnosticObservation value, $Res Function(_PortableDiagnosticObservation) _then) = __$PortableDiagnosticObservationCopyWithImpl;
@override @useResult
$Res call({
 PortableDiagnosticTarget target, skir.DataValue? value
});


@override $PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableDiagnosticObservationCopyWithImpl<$Res>
    implements _$PortableDiagnosticObservationCopyWith<$Res> {
  __$PortableDiagnosticObservationCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticObservation _self;
  final $Res Function(_PortableDiagnosticObservation) _then;

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? target = null,Object? value = freezed,}) {
  return _then(_PortableDiagnosticObservation(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue?,
  ));
}

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc
mixin _$PortableDiagnosticNode {

 PortableDiagnosticNodeKind get kind; Object? get parent; List<PortableDiagnosticObservation> get observations; List<PortablePresentationDiagnostic> get diagnostics;
/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticNodeCopyWith<PortableDiagnosticNode> get copyWith => _$PortableDiagnosticNodeCopyWithImpl<PortableDiagnosticNode>(this as PortableDiagnosticNode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticNode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticNode&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.parent, _this.parent)&&const DeepCollectionEquality().equals(other.observations, _this.observations)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticNode;
  return Object.hash(runtimeType,_this.kind,const DeepCollectionEquality().hash(_this.parent),const DeepCollectionEquality().hash(_this.observations),const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as PortableDiagnosticNode;
  return 'PortableDiagnosticNode(kind: ${_this.kind}, parent: ${_this.parent}, observations: ${_this.observations}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticNodeCopyWith<$Res>  {
  factory $PortableDiagnosticNodeCopyWith(PortableDiagnosticNode value, $Res Function(PortableDiagnosticNode) _then) = _$PortableDiagnosticNodeCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticNodeKind kind, Object? parent, List<PortableDiagnosticObservation> observations, List<PortablePresentationDiagnostic> diagnostics
});




}
/// @nodoc
class _$PortableDiagnosticNodeCopyWithImpl<$Res>
    implements $PortableDiagnosticNodeCopyWith<$Res> {
  _$PortableDiagnosticNodeCopyWithImpl(this._self, this._then);

  final PortableDiagnosticNode _self;
  final $Res Function(PortableDiagnosticNode) _then;

/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? parent = freezed,Object? observations = null,Object? diagnostics = null,}) {
  return _then(PortableDiagnosticNode(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticNodeKind,parent: freezed == parent ? _self.parent : parent ,observations: null == observations ? _self.observations : observations // ignore: cast_nullable_to_non_nullable
as List<PortableDiagnosticObservation>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

}


/// Adds pattern matching related methods to [PortableDiagnosticNode].
extension PortableDiagnosticNodePatterns on PortableDiagnosticNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticNode value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticNode value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortableDiagnosticNodeKind kind,  Object? parent,  List<PortableDiagnosticObservation> observations,  List<PortablePresentationDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
return $default(_that.kind,_that.parent,_that.observations,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortableDiagnosticNodeKind kind,  Object? parent,  List<PortableDiagnosticObservation> observations,  List<PortablePresentationDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticNode():
return $default(_that.kind,_that.parent,_that.observations,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortableDiagnosticNodeKind kind,  Object? parent,  List<PortableDiagnosticObservation> observations,  List<PortablePresentationDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
return $default(_that.kind,_that.parent,_that.observations,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticNode extends PortableDiagnosticNode {
  const _PortableDiagnosticNode({required this.kind, this.parent,  List<PortableDiagnosticObservation> observations = const [],  List<PortablePresentationDiagnostic> diagnostics = const []}): _observations = observations,_diagnostics = diagnostics,super._();


@override final  PortableDiagnosticNodeKind kind;
@override final  Object? parent;
 final  List<PortableDiagnosticObservation> _observations;
@override@JsonKey() List<PortableDiagnosticObservation> get observations {
  if (_observations is EqualUnmodifiableListView) return _observations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_observations);
}

 final  List<PortablePresentationDiagnostic> _diagnostics;
@override@JsonKey() List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticNodeCopyWith<_PortableDiagnosticNode> get copyWith => __$PortableDiagnosticNodeCopyWithImpl<_PortableDiagnosticNode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticNode&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.parent, parent)&&const DeepCollectionEquality().equals(other.observations, _observations)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(parent),const DeepCollectionEquality().hash(_observations),const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'PortableDiagnosticNode(kind: $kind, parent: $parent, observations: $observations, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticNodeCopyWith<$Res> implements $PortableDiagnosticNodeCopyWith<$Res> {
  factory _$PortableDiagnosticNodeCopyWith(_PortableDiagnosticNode value, $Res Function(_PortableDiagnosticNode) _then) = __$PortableDiagnosticNodeCopyWithImpl;
@override @useResult
$Res call({
 PortableDiagnosticNodeKind kind, Object? parent, List<PortableDiagnosticObservation> observations, List<PortablePresentationDiagnostic> diagnostics
});




}
/// @nodoc
class __$PortableDiagnosticNodeCopyWithImpl<$Res>
    implements _$PortableDiagnosticNodeCopyWith<$Res> {
  __$PortableDiagnosticNodeCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticNode _self;
  final $Res Function(_PortableDiagnosticNode) _then;

/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? parent = freezed,Object? observations = null,Object? diagnostics = null,}) {
  return _then(_PortableDiagnosticNode(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticNodeKind,parent: freezed == parent ? _self.parent : parent ,observations: null == observations ? _self._observations : observations // ignore: cast_nullable_to_non_nullable
as List<PortableDiagnosticObservation>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticPresentation {

 Map<Object, PortableDiagnosticNode> get nodes;
/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticPresentationCopyWith<PortableDiagnosticPresentation> get copyWith => _$PortableDiagnosticPresentationCopyWithImpl<PortableDiagnosticPresentation>(this as PortableDiagnosticPresentation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticPresentation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticPresentation&&const DeepCollectionEquality().equals(other.nodes, _this.nodes));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticPresentation;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.nodes));
}

@override
String toString() {
  final _this = this as PortableDiagnosticPresentation;
  return 'PortableDiagnosticPresentation(nodes: ${_this.nodes})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticPresentationCopyWith<$Res>  {
  factory $PortableDiagnosticPresentationCopyWith(PortableDiagnosticPresentation value, $Res Function(PortableDiagnosticPresentation) _then) = _$PortableDiagnosticPresentationCopyWithImpl;
@useResult
$Res call({
 Map<Object, PortableDiagnosticNode> nodes
});




}
/// @nodoc
class _$PortableDiagnosticPresentationCopyWithImpl<$Res>
    implements $PortableDiagnosticPresentationCopyWith<$Res> {
  _$PortableDiagnosticPresentationCopyWithImpl(this._self, this._then);

  final PortableDiagnosticPresentation _self;
  final $Res Function(PortableDiagnosticPresentation) _then;

/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodes = null,}) {
  return _then(PortableDiagnosticPresentation(
nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticNode>,
  ));
}

}


/// Adds pattern matching related methods to [PortableDiagnosticPresentation].
extension PortableDiagnosticPresentationPatterns on PortableDiagnosticPresentation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticPresentation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticPresentation value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticPresentation value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticNode> nodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
return $default(_that.nodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticNode> nodes)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation():
return $default(_that.nodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<Object, PortableDiagnosticNode> nodes)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
return $default(_that.nodes);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticPresentation extends PortableDiagnosticPresentation {
  const _PortableDiagnosticPresentation({ Map<Object, PortableDiagnosticNode> nodes = const {}}): _nodes = nodes,super._();


 final  Map<Object, PortableDiagnosticNode> _nodes;
@override@JsonKey() Map<Object, PortableDiagnosticNode> get nodes {
  if (_nodes is EqualUnmodifiableMapView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nodes);
}


/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticPresentationCopyWith<_PortableDiagnosticPresentation> get copyWith => __$PortableDiagnosticPresentationCopyWithImpl<_PortableDiagnosticPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticPresentation&&const DeepCollectionEquality().equals(other.nodes, _nodes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_nodes));
}

@override
String toString() {
    return 'PortableDiagnosticPresentation(nodes: $nodes)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticPresentationCopyWith<$Res> implements $PortableDiagnosticPresentationCopyWith<$Res> {
  factory _$PortableDiagnosticPresentationCopyWith(_PortableDiagnosticPresentation value, $Res Function(_PortableDiagnosticPresentation) _then) = __$PortableDiagnosticPresentationCopyWithImpl;
@override @useResult
$Res call({
 Map<Object, PortableDiagnosticNode> nodes
});




}
/// @nodoc
class __$PortableDiagnosticPresentationCopyWithImpl<$Res>
    implements _$PortableDiagnosticPresentationCopyWith<$Res> {
  __$PortableDiagnosticPresentationCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticPresentation _self;
  final $Res Function(_PortableDiagnosticPresentation) _then;

/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodes = null,}) {
  return _then(_PortableDiagnosticPresentation(
nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticNode>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticSummary {

 List<PortablePresentationDiagnostic> get direct; List<PortablePresentationDiagnostic> get descendants;
/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticSummaryCopyWith<PortableDiagnosticSummary> get copyWith => _$PortableDiagnosticSummaryCopyWithImpl<PortableDiagnosticSummary>(this as PortableDiagnosticSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticSummary&&const DeepCollectionEquality().equals(other.direct, _this.direct)&&const DeepCollectionEquality().equals(other.descendants, _this.descendants));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticSummary;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.direct),const DeepCollectionEquality().hash(_this.descendants));
}

@override
String toString() {
  final _this = this as PortableDiagnosticSummary;
  return 'PortableDiagnosticSummary(direct: ${_this.direct}, descendants: ${_this.descendants})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticSummaryCopyWith<$Res>  {
  factory $PortableDiagnosticSummaryCopyWith(PortableDiagnosticSummary value, $Res Function(PortableDiagnosticSummary) _then) = _$PortableDiagnosticSummaryCopyWithImpl;
@useResult
$Res call({
 List<PortablePresentationDiagnostic> direct, List<PortablePresentationDiagnostic> descendants
});




}
/// @nodoc
class _$PortableDiagnosticSummaryCopyWithImpl<$Res>
    implements $PortableDiagnosticSummaryCopyWith<$Res> {
  _$PortableDiagnosticSummaryCopyWithImpl(this._self, this._then);

  final PortableDiagnosticSummary _self;
  final $Res Function(PortableDiagnosticSummary) _then;

/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direct = null,Object? descendants = null,}) {
  return _then(PortableDiagnosticSummary(
direct: null == direct ? _self.direct : direct // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,descendants: null == descendants ? _self.descendants : descendants // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

}


/// Adds pattern matching related methods to [PortableDiagnosticSummary].
extension PortableDiagnosticSummaryPatterns on PortableDiagnosticSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticSummary value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PortablePresentationDiagnostic> direct,  List<PortablePresentationDiagnostic> descendants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
return $default(_that.direct,_that.descendants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PortablePresentationDiagnostic> direct,  List<PortablePresentationDiagnostic> descendants)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticSummary():
return $default(_that.direct,_that.descendants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PortablePresentationDiagnostic> direct,  List<PortablePresentationDiagnostic> descendants)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
return $default(_that.direct,_that.descendants);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticSummary extends PortableDiagnosticSummary {
  const _PortableDiagnosticSummary({ List<PortablePresentationDiagnostic> direct = const [],  List<PortablePresentationDiagnostic> descendants = const []}): _direct = direct,_descendants = descendants,super._();


 final  List<PortablePresentationDiagnostic> _direct;
@override@JsonKey() List<PortablePresentationDiagnostic> get direct {
  if (_direct is EqualUnmodifiableListView) return _direct;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_direct);
}

 final  List<PortablePresentationDiagnostic> _descendants;
@override@JsonKey() List<PortablePresentationDiagnostic> get descendants {
  if (_descendants is EqualUnmodifiableListView) return _descendants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_descendants);
}


/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticSummaryCopyWith<_PortableDiagnosticSummary> get copyWith => __$PortableDiagnosticSummaryCopyWithImpl<_PortableDiagnosticSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticSummary&&const DeepCollectionEquality().equals(other.direct, _direct)&&const DeepCollectionEquality().equals(other.descendants, _descendants));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_direct),const DeepCollectionEquality().hash(_descendants));
}

@override
String toString() {
    return 'PortableDiagnosticSummary(direct: $direct, descendants: $descendants)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticSummaryCopyWith<$Res> implements $PortableDiagnosticSummaryCopyWith<$Res> {
  factory _$PortableDiagnosticSummaryCopyWith(_PortableDiagnosticSummary value, $Res Function(_PortableDiagnosticSummary) _then) = __$PortableDiagnosticSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<PortablePresentationDiagnostic> direct, List<PortablePresentationDiagnostic> descendants
});




}
/// @nodoc
class __$PortableDiagnosticSummaryCopyWithImpl<$Res>
    implements _$PortableDiagnosticSummaryCopyWith<$Res> {
  __$PortableDiagnosticSummaryCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticSummary _self;
  final $Res Function(_PortableDiagnosticSummary) _then;

/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direct = null,Object? descendants = null,}) {
  return _then(_PortableDiagnosticSummary(
direct: null == direct ? _self._direct : direct // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,descendants: null == descendants ? _self._descendants : descendants // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticPlacement {

 Map<Object, PortableDiagnosticSummary> get summaries; List<PortablePresentationDiagnostic> get general;
/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticPlacementCopyWith<PortableDiagnosticPlacement> get copyWith => _$PortableDiagnosticPlacementCopyWithImpl<PortableDiagnosticPlacement>(this as PortableDiagnosticPlacement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticPlacement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticPlacement&&const DeepCollectionEquality().equals(other.summaries, _this.summaries)&&const DeepCollectionEquality().equals(other.general, _this.general));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticPlacement;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.summaries),const DeepCollectionEquality().hash(_this.general));
}

@override
String toString() {
  final _this = this as PortableDiagnosticPlacement;
  return 'PortableDiagnosticPlacement(summaries: ${_this.summaries}, general: ${_this.general})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticPlacementCopyWith<$Res>  {
  factory $PortableDiagnosticPlacementCopyWith(PortableDiagnosticPlacement value, $Res Function(PortableDiagnosticPlacement) _then) = _$PortableDiagnosticPlacementCopyWithImpl;
@useResult
$Res call({
 Map<Object, PortableDiagnosticSummary> summaries, List<PortablePresentationDiagnostic> general
});




}
/// @nodoc
class _$PortableDiagnosticPlacementCopyWithImpl<$Res>
    implements $PortableDiagnosticPlacementCopyWith<$Res> {
  _$PortableDiagnosticPlacementCopyWithImpl(this._self, this._then);

  final PortableDiagnosticPlacement _self;
  final $Res Function(PortableDiagnosticPlacement) _then;

/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summaries = null,Object? general = null,}) {
  return _then(PortableDiagnosticPlacement(
summaries: null == summaries ? _self.summaries : summaries // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticSummary>,general: null == general ? _self.general : general // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

}


/// Adds pattern matching related methods to [PortableDiagnosticPlacement].
extension PortableDiagnosticPlacementPatterns on PortableDiagnosticPlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticPlacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticPlacement value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticPlacement value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticSummary> summaries,  List<PortablePresentationDiagnostic> general)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
return $default(_that.summaries,_that.general);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticSummary> summaries,  List<PortablePresentationDiagnostic> general)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement():
return $default(_that.summaries,_that.general);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<Object, PortableDiagnosticSummary> summaries,  List<PortablePresentationDiagnostic> general)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
return $default(_that.summaries,_that.general);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticPlacement extends PortableDiagnosticPlacement {
  const _PortableDiagnosticPlacement({ Map<Object, PortableDiagnosticSummary> summaries = const {},  List<PortablePresentationDiagnostic> general = const []}): _summaries = summaries,_general = general,super._();


 final  Map<Object, PortableDiagnosticSummary> _summaries;
@override@JsonKey() Map<Object, PortableDiagnosticSummary> get summaries {
  if (_summaries is EqualUnmodifiableMapView) return _summaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_summaries);
}

 final  List<PortablePresentationDiagnostic> _general;
@override@JsonKey() List<PortablePresentationDiagnostic> get general {
  if (_general is EqualUnmodifiableListView) return _general;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_general);
}


/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticPlacementCopyWith<_PortableDiagnosticPlacement> get copyWith => __$PortableDiagnosticPlacementCopyWithImpl<_PortableDiagnosticPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticPlacement&&const DeepCollectionEquality().equals(other.summaries, _summaries)&&const DeepCollectionEquality().equals(other.general, _general));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_summaries),const DeepCollectionEquality().hash(_general));
}

@override
String toString() {
    return 'PortableDiagnosticPlacement(summaries: $summaries, general: $general)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticPlacementCopyWith<$Res> implements $PortableDiagnosticPlacementCopyWith<$Res> {
  factory _$PortableDiagnosticPlacementCopyWith(_PortableDiagnosticPlacement value, $Res Function(_PortableDiagnosticPlacement) _then) = __$PortableDiagnosticPlacementCopyWithImpl;
@override @useResult
$Res call({
 Map<Object, PortableDiagnosticSummary> summaries, List<PortablePresentationDiagnostic> general
});




}
/// @nodoc
class __$PortableDiagnosticPlacementCopyWithImpl<$Res>
    implements _$PortableDiagnosticPlacementCopyWith<$Res> {
  __$PortableDiagnosticPlacementCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticPlacement _self;
  final $Res Function(_PortableDiagnosticPlacement) _then;

/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summaries = null,Object? general = null,}) {
  return _then(_PortableDiagnosticPlacement(
summaries: null == summaries ? _self._summaries : summaries // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticSummary>,general: null == general ? _self._general : general // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$PortableControlValidationIdentity {

 Object get owner; PortableDiagnosticTarget get target;
/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableControlValidationIdentityCopyWith<PortableControlValidationIdentity> get copyWith => _$PortableControlValidationIdentityCopyWithImpl<PortableControlValidationIdentity>(this as PortableControlValidationIdentity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableControlValidationIdentity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableControlValidationIdentity&&const DeepCollectionEquality().equals(other.owner, _this.owner)&&(identical(other.target, _this.target) || other.target == _this.target));
}


@override
int get hashCode {
  final _this = this as PortableControlValidationIdentity;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.owner),_this.target);
}

@override
String toString() {
  final _this = this as PortableControlValidationIdentity;
  return 'PortableControlValidationIdentity(owner: ${_this.owner}, target: ${_this.target})';
}


}

/// @nodoc
abstract mixin class $PortableControlValidationIdentityCopyWith<$Res>  {
  factory $PortableControlValidationIdentityCopyWith(PortableControlValidationIdentity value, $Res Function(PortableControlValidationIdentity) _then) = _$PortableControlValidationIdentityCopyWithImpl;
@useResult
$Res call({
 Object owner, PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class _$PortableControlValidationIdentityCopyWithImpl<$Res>
    implements $PortableControlValidationIdentityCopyWith<$Res> {
  _$PortableControlValidationIdentityCopyWithImpl(this._self, this._then);

  final PortableControlValidationIdentity _self;
  final $Res Function(PortableControlValidationIdentity) _then;

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? target = null,}) {
  return _then(PortableControlValidationIdentity(
owner: null == owner ? _self.owner : owner ,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}
/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern matching related methods to [PortableControlValidationIdentity].
extension PortableControlValidationIdentityPatterns on PortableControlValidationIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableControlValidationIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableControlValidationIdentity value)  $default,){
final _that = this;
switch (_that) {
case _PortableControlValidationIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableControlValidationIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object owner,  PortableDiagnosticTarget target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
return $default(_that.owner,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object owner,  PortableDiagnosticTarget target)  $default,) {final _that = this;
switch (_that) {
case _PortableControlValidationIdentity():
return $default(_that.owner,_that.target);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object owner,  PortableDiagnosticTarget target)?  $default,) {final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
return $default(_that.owner,_that.target);case _:
  return null;

}
}

}

/// @nodoc


class _PortableControlValidationIdentity implements PortableControlValidationIdentity {
  const _PortableControlValidationIdentity({required this.owner, required this.target});


@override final  Object owner;
@override final  PortableDiagnosticTarget target;

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableControlValidationIdentityCopyWith<_PortableControlValidationIdentity> get copyWith => __$PortableControlValidationIdentityCopyWithImpl<_PortableControlValidationIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableControlValidationIdentity&&const DeepCollectionEquality().equals(other.owner, owner)&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(owner),target);
}

@override
String toString() {
    return 'PortableControlValidationIdentity(owner: $owner, target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableControlValidationIdentityCopyWith<$Res> implements $PortableControlValidationIdentityCopyWith<$Res> {
  factory _$PortableControlValidationIdentityCopyWith(_PortableControlValidationIdentity value, $Res Function(_PortableControlValidationIdentity) _then) = __$PortableControlValidationIdentityCopyWithImpl;
@override @useResult
$Res call({
 Object owner, PortableDiagnosticTarget target
});


@override $PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableControlValidationIdentityCopyWithImpl<$Res>
    implements _$PortableControlValidationIdentityCopyWith<$Res> {
  __$PortableControlValidationIdentityCopyWithImpl(this._self, this._then);

  final _PortableControlValidationIdentity _self;
  final $Res Function(_PortableControlValidationIdentity) _then;

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? target = null,}) {
  return _then(_PortableControlValidationIdentity(
owner: null == owner ? _self.owner : owner ,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc
mixin _$PortablePresentationScope {

 Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings; skir.EvaluationBudget get budget; PortableOperationResults get operations; List<PortableAppearanceLayer> get appearanceLayers; Map<skir.ExpressionBindingId, AuthoredBindingAddress> get authoredAliases; AuthoredPresentationIndex? get authoredIndex; bool get readOnly; bool get enabled; Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? get watchSearch; ValueChanged<String>? get reportStatus; CheckedEditorCatalog? get catalog; skir.ResourceId? get resource; String? get searchHistoryNamespace; ValueChanged<skir.ResourceId>? get openResource; skir.PresentationRole? get role; skir.PresentationMaterial? get material; Set<skir.PresentationId> get activePresentations; Map<String, skir.PresentationNode> get slots; Map<String, PortableSlotBuilder> get slotBuilders; PortablePresentationHost? get host; Map<skir.ExpressionBindingId, PortableBindingSetter> get projectedWriters;
/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<PortablePresentationScope> get copyWith => _$PortablePresentationScopeCopyWithImpl<PortablePresentationScope>(this as PortablePresentationScope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationScope&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&(identical(other.operations, _this.operations) || other.operations == _this.operations)&&const DeepCollectionEquality().equals(other.appearanceLayers, _this.appearanceLayers)&&const DeepCollectionEquality().equals(other.authoredAliases, _this.authoredAliases)&&(identical(other.authoredIndex, _this.authoredIndex) || other.authoredIndex == _this.authoredIndex)&&(identical(other.readOnly, _this.readOnly) || other.readOnly == _this.readOnly)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.watchSearch, _this.watchSearch) || other.watchSearch == _this.watchSearch)&&(identical(other.reportStatus, _this.reportStatus) || other.reportStatus == _this.reportStatus)&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.searchHistoryNamespace, _this.searchHistoryNamespace) || other.searchHistoryNamespace == _this.searchHistoryNamespace)&&(identical(other.openResource, _this.openResource) || other.openResource == _this.openResource)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.material, _this.material) || other.material == _this.material)&&const DeepCollectionEquality().equals(other.activePresentations, _this.activePresentations)&&const DeepCollectionEquality().equals(other.slots, _this.slots)&&const DeepCollectionEquality().equals(other.slotBuilders, _this.slotBuilders)&&(identical(other.host, _this.host) || other.host == _this.host)&&const DeepCollectionEquality().equals(other.projectedWriters, _this.projectedWriters));
}


@override
int get hashCode {
  final _this = this as PortablePresentationScope;
  return Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_this.bindings),_this.budget,_this.operations,const DeepCollectionEquality().hash(_this.appearanceLayers),const DeepCollectionEquality().hash(_this.authoredAliases),_this.authoredIndex,_this.readOnly,_this.enabled,_this.watchSearch,_this.reportStatus,_this.catalog,_this.resource,_this.searchHistoryNamespace,_this.openResource,_this.role,_this.material,const DeepCollectionEquality().hash(_this.activePresentations),const DeepCollectionEquality().hash(_this.slots),const DeepCollectionEquality().hash(_this.slotBuilders),_this.host,const DeepCollectionEquality().hash(_this.projectedWriters)]);
}

@override
String toString() {
  final _this = this as PortablePresentationScope;
  return 'PortablePresentationScope(bindings: ${_this.bindings}, budget: ${_this.budget}, operations: ${_this.operations}, appearanceLayers: ${_this.appearanceLayers}, authoredAliases: ${_this.authoredAliases}, authoredIndex: ${_this.authoredIndex}, readOnly: ${_this.readOnly}, enabled: ${_this.enabled}, watchSearch: ${_this.watchSearch}, reportStatus: ${_this.reportStatus}, catalog: ${_this.catalog}, resource: ${_this.resource}, searchHistoryNamespace: ${_this.searchHistoryNamespace}, openResource: ${_this.openResource}, role: ${_this.role}, material: ${_this.material}, activePresentations: ${_this.activePresentations}, slots: ${_this.slots}, slotBuilders: ${_this.slotBuilders}, host: ${_this.host}, projectedWriters: ${_this.projectedWriters})';
}


}

/// @nodoc
abstract mixin class $PortablePresentationScopeCopyWith<$Res>  {
  factory $PortablePresentationScopeCopyWith(PortablePresentationScope value, $Res Function(PortablePresentationScope) _then) = _$PortablePresentationScopeCopyWithImpl;
@useResult
$Res call({
 Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, PortableOperationResults operations, List<PortableAppearanceLayer> appearanceLayers, Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases, AuthoredPresentationIndex? authoredIndex, bool readOnly, bool enabled, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, ValueChanged<String>? reportStatus, CheckedEditorCatalog? catalog, skir.ResourceId? resource, String? searchHistoryNamespace, ValueChanged<skir.ResourceId>? openResource, skir.PresentationRole? role, skir.PresentationMaterial? material, Set<skir.PresentationId> activePresentations, Map<String, skir.PresentationNode> slots, Map<String, PortableSlotBuilder> slotBuilders, PortablePresentationHost? host, Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters
});


$AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex;

}
/// @nodoc
class _$PortablePresentationScopeCopyWithImpl<$Res>
    implements $PortablePresentationScopeCopyWith<$Res> {
  _$PortablePresentationScopeCopyWithImpl(this._self, this._then);

  final PortablePresentationScope _self;
  final $Res Function(PortablePresentationScope) _then;

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bindings = null,Object? budget = null,Object? operations = null,Object? appearanceLayers = null,Object? authoredAliases = null,Object? authoredIndex = freezed,Object? readOnly = null,Object? enabled = null,Object? watchSearch = freezed,Object? reportStatus = freezed,Object? catalog = freezed,Object? resource = freezed,Object? searchHistoryNamespace = freezed,Object? openResource = freezed,Object? role = freezed,Object? material = freezed,Object? activePresentations = null,Object? slots = null,Object? slotBuilders = null,Object? host = freezed,Object? projectedWriters = null,}) {
  return _then(PortablePresentationScope(
bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as PortableOperationResults,appearanceLayers: null == appearanceLayers ? _self.appearanceLayers : appearanceLayers // ignore: cast_nullable_to_non_nullable
as List<PortableAppearanceLayer>,authoredAliases: null == authoredAliases ? _self.authoredAliases : authoredAliases // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, AuthoredBindingAddress>,authoredIndex: freezed == authoredIndex ? _self.authoredIndex : authoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reportStatus: freezed == reportStatus ? _self.reportStatus : reportStatus // ignore: cast_nullable_to_non_nullable
as ValueChanged<String>?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,resource: freezed == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,searchHistoryNamespace: freezed == searchHistoryNamespace ? _self.searchHistoryNamespace : searchHistoryNamespace // ignore: cast_nullable_to_non_nullable
as String?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial?,activePresentations: null == activePresentations ? _self.activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationId>,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,slotBuilders: null == slotBuilders ? _self.slotBuilders : slotBuilders // ignore: cast_nullable_to_non_nullable
as Map<String, PortableSlotBuilder>,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost?,projectedWriters: null == projectedWriters ? _self.projectedWriters : projectedWriters // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableBindingSetter>,
  ));
}
/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex {
    if (_self.authoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.authoredIndex!, (value) {
    return _then(_self.copyWith(authoredIndex: value));
  });
}
}



/// @nodoc


class _PortablePresentationScope extends PortablePresentationScope {
  const _PortablePresentationScope({required  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, required this.budget, required this.operations, required  List<PortableAppearanceLayer> appearanceLayers, required  Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases, required this.authoredIndex, required this.readOnly, required this.enabled, required this.watchSearch, required this.reportStatus, required this.catalog, required this.resource, required this.searchHistoryNamespace, required this.openResource, required this.role, required this.material, required  Set<skir.PresentationId> activePresentations, required  Map<String, skir.PresentationNode> slots, required  Map<String, PortableSlotBuilder> slotBuilders, required this.host, required  Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters}): _bindings = bindings,_appearanceLayers = appearanceLayers,_authoredAliases = authoredAliases,_activePresentations = activePresentations,_slots = slots,_slotBuilders = slotBuilders,_projectedWriters = projectedWriters,super._();


 final  Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;
@override final  PortableOperationResults operations;
 final  List<PortableAppearanceLayer> _appearanceLayers;
@override List<PortableAppearanceLayer> get appearanceLayers {
  if (_appearanceLayers is EqualUnmodifiableListView) return _appearanceLayers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appearanceLayers);
}

 final  Map<skir.ExpressionBindingId, AuthoredBindingAddress> _authoredAliases;
@override Map<skir.ExpressionBindingId, AuthoredBindingAddress> get authoredAliases {
  if (_authoredAliases is EqualUnmodifiableMapView) return _authoredAliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_authoredAliases);
}

@override final  AuthoredPresentationIndex? authoredIndex;
@override final  bool readOnly;
@override final  bool enabled;
@override final  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch;
@override final  ValueChanged<String>? reportStatus;
@override final  CheckedEditorCatalog? catalog;
@override final  skir.ResourceId? resource;
@override final  String? searchHistoryNamespace;
@override final  ValueChanged<skir.ResourceId>? openResource;
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

 final  Map<String, PortableSlotBuilder> _slotBuilders;
@override Map<String, PortableSlotBuilder> get slotBuilders {
  if (_slotBuilders is EqualUnmodifiableMapView) return _slotBuilders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slotBuilders);
}

@override final  PortablePresentationHost? host;
 final  Map<skir.ExpressionBindingId, PortableBindingSetter> _projectedWriters;
@override Map<skir.ExpressionBindingId, PortableBindingSetter> get projectedWriters {
  if (_projectedWriters is EqualUnmodifiableMapView) return _projectedWriters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_projectedWriters);
}


/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePresentationScopeCopyWith<_PortablePresentationScope> get copyWith => __$PortablePresentationScopeCopyWithImpl<_PortablePresentationScope>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationScope&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.operations, operations) || other.operations == operations)&&const DeepCollectionEquality().equals(other.appearanceLayers, _appearanceLayers)&&const DeepCollectionEquality().equals(other.authoredAliases, _authoredAliases)&&(identical(other.authoredIndex, authoredIndex) || other.authoredIndex == authoredIndex)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.watchSearch, watchSearch) || other.watchSearch == watchSearch)&&(identical(other.reportStatus, reportStatus) || other.reportStatus == reportStatus)&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.searchHistoryNamespace, searchHistoryNamespace) || other.searchHistoryNamespace == searchHistoryNamespace)&&(identical(other.openResource, openResource) || other.openResource == openResource)&&(identical(other.role, role) || other.role == role)&&(identical(other.material, material) || other.material == material)&&const DeepCollectionEquality().equals(other.activePresentations, _activePresentations)&&const DeepCollectionEquality().equals(other.slots, _slots)&&const DeepCollectionEquality().equals(other.slotBuilders, _slotBuilders)&&(identical(other.host, host) || other.host == host)&&const DeepCollectionEquality().equals(other.projectedWriters, _projectedWriters));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_bindings),budget,operations,const DeepCollectionEquality().hash(_appearanceLayers),const DeepCollectionEquality().hash(_authoredAliases),authoredIndex,readOnly,enabled,watchSearch,reportStatus,catalog,resource,searchHistoryNamespace,openResource,role,material,const DeepCollectionEquality().hash(_activePresentations),const DeepCollectionEquality().hash(_slots),const DeepCollectionEquality().hash(_slotBuilders),host,const DeepCollectionEquality().hash(_projectedWriters)]);
}

@override
String toString() {
    return 'PortablePresentationScope._value(bindings: $bindings, budget: $budget, operations: $operations, appearanceLayers: $appearanceLayers, authoredAliases: $authoredAliases, authoredIndex: $authoredIndex, readOnly: $readOnly, enabled: $enabled, watchSearch: $watchSearch, reportStatus: $reportStatus, catalog: $catalog, resource: $resource, searchHistoryNamespace: $searchHistoryNamespace, openResource: $openResource, role: $role, material: $material, activePresentations: $activePresentations, slots: $slots, slotBuilders: $slotBuilders, host: $host, projectedWriters: $projectedWriters)';
}


}

/// @nodoc
abstract mixin class _$PortablePresentationScopeCopyWith<$Res> implements $PortablePresentationScopeCopyWith<$Res> {
  factory _$PortablePresentationScopeCopyWith(_PortablePresentationScope value, $Res Function(_PortablePresentationScope) _then) = __$PortablePresentationScopeCopyWithImpl;
@override @useResult
$Res call({
 Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, PortableOperationResults operations, List<PortableAppearanceLayer> appearanceLayers, Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases, AuthoredPresentationIndex? authoredIndex, bool readOnly, bool enabled, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, ValueChanged<String>? reportStatus, CheckedEditorCatalog? catalog, skir.ResourceId? resource, String? searchHistoryNamespace, ValueChanged<skir.ResourceId>? openResource, skir.PresentationRole? role, skir.PresentationMaterial? material, Set<skir.PresentationId> activePresentations, Map<String, skir.PresentationNode> slots, Map<String, PortableSlotBuilder> slotBuilders, PortablePresentationHost? host, Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters
});


@override $AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex;

}
/// @nodoc
class __$PortablePresentationScopeCopyWithImpl<$Res>
    implements _$PortablePresentationScopeCopyWith<$Res> {
  __$PortablePresentationScopeCopyWithImpl(this._self, this._then);

  final _PortablePresentationScope _self;
  final $Res Function(_PortablePresentationScope) _then;

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bindings = null,Object? budget = null,Object? operations = null,Object? appearanceLayers = null,Object? authoredAliases = null,Object? authoredIndex = freezed,Object? readOnly = null,Object? enabled = null,Object? watchSearch = freezed,Object? reportStatus = freezed,Object? catalog = freezed,Object? resource = freezed,Object? searchHistoryNamespace = freezed,Object? openResource = freezed,Object? role = freezed,Object? material = freezed,Object? activePresentations = null,Object? slots = null,Object? slotBuilders = null,Object? host = freezed,Object? projectedWriters = null,}) {
  return _then(_PortablePresentationScope(
bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as PortableOperationResults,appearanceLayers: null == appearanceLayers ? _self._appearanceLayers : appearanceLayers // ignore: cast_nullable_to_non_nullable
as List<PortableAppearanceLayer>,authoredAliases: null == authoredAliases ? _self._authoredAliases : authoredAliases // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, AuthoredBindingAddress>,authoredIndex: freezed == authoredIndex ? _self.authoredIndex : authoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reportStatus: freezed == reportStatus ? _self.reportStatus : reportStatus // ignore: cast_nullable_to_non_nullable
as ValueChanged<String>?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,resource: freezed == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,searchHistoryNamespace: freezed == searchHistoryNamespace ? _self.searchHistoryNamespace : searchHistoryNamespace // ignore: cast_nullable_to_non_nullable
as String?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial?,activePresentations: null == activePresentations ? _self._activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationId>,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,slotBuilders: null == slotBuilders ? _self._slotBuilders : slotBuilders // ignore: cast_nullable_to_non_nullable
as Map<String, PortableSlotBuilder>,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost?,projectedWriters: null == projectedWriters ? _self._projectedWriters : projectedWriters // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableBindingSetter>,
  ));
}

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex {
    if (_self.authoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.authoredIndex!, (value) {
    return _then(_self.copyWith(authoredIndex: value));
  });
}
}

// dart format on
